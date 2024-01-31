import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notifi_service.dart';
import '../services/beaconscan.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int rssiValue = 0; // RSSI 값을 저장할 변수

  String seatStatus = '';
  String beltStatus = '';
  String isofixStatus = '';

  String detectedUuid = 'No beacon detected';
  String previousUuid = ''; // 이전 UUID 값 저장 변수
  Timer? notificationTimer; // 푸시 알림을 보낼 타이머 변수

  DateTime? lastUuidNotificationTime;
  DateTime? lastNotificationTime;

  /// UUID 값을 받아와 착석 및 체결 데이터
  void updateStatus(String uuid) {
    DateTime now = DateTime.now();

    // 마지막 알림 이후 2초가 지났는지 확인
    if (lastNotificationTime != null && now.difference(lastNotificationTime!) < Duration(seconds: 2)) {
      return; // 2초가 지나지 않았으면 알림을 보내지 않고 함수 종료
    }

    if (uuid != previousUuid) {
      // 새로운 UUID인 경우에만 업데이트
      detectedUuid = uuid;
      NotificationService.lastUuid = uuid;
      previousUuid = uuid; // 이전 UUID 업데이트
      notificationTimer?.cancel(); //이전 타이머가 있다면 취소.

      // 현재 시간을 가져옵니다.
      DateTime now = DateTime.now();
      Duration notificationCooldown = Duration(seconds: 3); // 3초초 쿨다운 간

      // 쿨다운 기간이 지났는지 확인
      bool canSendNotification = lastUuidNotificationTime == null ||
          now.difference(lastUuidNotificationTime!) > notificationCooldown;

      switch (uuid) {
        case '9999-9999-2222-2222':
          setState(() {
            seatStatus = '미착석';
            beltStatus = '미체결';
            isofixStatus = '체결';
          });
          break;

        case '9999-9999-3333-3333':
          setState(() {
            seatStatus = '미착석';
            beltStatus = '미체결';
            isofixStatus = '미체결';
          });
          break;

        case '0000-1111-2222-2222':
          setState(() {
            seatStatus = '미착석';
            beltStatus = '체결';
            isofixStatus = '체결';
          });
          break;

        case '0000-1111-3333-3333':
          setState(() {
            seatStatus = '미착석';
            beltStatus = '체결';
            isofixStatus = '미체결';
          });
          break;

        case '1111-0000-2222-2222':
          if (canSendNotification) {
            // 쿨다운 기간이 지났다면 알림 보내기
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              NotificationService().showNotification(
                title: '안전벨트가 풀렸습니다.',
                body: '안전벨트가 풀렸습니다. 확인해주세요.',
              );
              lastUuidNotificationTime = now; // 마지막 알림 시간 업데이트
            });
          }
          setState(() {
            seatStatus = '착석';
            beltStatus = '미체결';
            isofixStatus = '체결';
          });
          notificationTimer = Timer(Duration(seconds: 60), sendNotification);

          break;

        case '1111-0000-3333-3333':
          if (canSendNotification) {
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              NotificationService().showNotification(
                title: '안전벨트와 아이소픽스가 풀렸습니다.',
                body: '안전벨트와 아이소픽스가 풀렸습니다. 확인해주세요.',
              );
              lastUuidNotificationTime = now; // 마지막 알림 시간 업데이트
            });
          }
          setState(() {
            seatStatus = '착석';
            beltStatus = '미체결';
            isofixStatus = '미체결';
          });
          notificationTimer = Timer(Duration(seconds: 60), sendNotification);
          break;

        case '1111-1111-2222-2222':
          setState(() {
            seatStatus = '착석';
            beltStatus = '체결';
            isofixStatus = '체결';
          });
          break;

        case '1111-1111-3333-3333':
          if (canSendNotification) {
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              NotificationService().showNotification(
                title: '아이소픽스가 풀렸습니다.',
                body: '아이소픽스가 풀렸습니다. 확인해주세요.',
              );
              lastUuidNotificationTime = now; // 마지막 알림 시간 업데이트
            });
          }

          setState(() {
            seatStatus = '착석';
            beltStatus = '체결';
            isofixStatus = '미체결';
          });
          notificationTimer = Timer(Duration(seconds: 60), sendNotification);
          break;

        default:
          setState(() {
            seatStatus = 'No beacon detected';
            beltStatus = 'No beacon detected';
            isofixStatus = 'No beacon detected';
          });
      } //switch문

      print(uuid);
    }
  }

  /// 푸시알림 (3가지)
  void sendNotification() {
    if (detectedUuid == '1111-0000-2222-2222') {
      NotificationService().showNotification(
        title: '안전벨트가 풀렸습니다.',
        body: '안전벨트가 풀렸습니다. 확인해주세요.',
      );
    } else if (detectedUuid == '1111-0000-3333-3333') {
      NotificationService().showNotification(
        title: '안전벨트와 아이소픽스가 풀렸습니다.',
        body: '안전벨트와 아이소픽스가 풀렸습니다. 확인해주세요.',
      );
    } else if (detectedUuid == '1111-1111-3333-3333') {
      NotificationService().showNotification(
        title: '아이소픽스가 풀렸습니다.',
        body: '아이소픽스가 풀렸습니다. 확인해주세요.',
      );
    }
    notificationTimer = Timer(Duration(seconds: 60), sendNotification);
  }

  /// RSSI가 -75 이하로 3초 유지되면 경고음 울림
  bool wasAboveThreshold = true; // RSSI가 임계값 위로 올라간 적이 있는지 추적
  DateTime? lastThresholdMetTime;
  DateTime? lastRssiNotificationTime;

  void checkRssiAndNotify(int rssi) {
    int threshold = -75; // RSSI 임계값 설정
    Duration thresholdDuration = Duration(seconds: 3); // 3초 동안 -75 유지되면
    Duration notificationCooldown = Duration(seconds: 5); // 5초 후에 다시 경고음 울리기

    DateTime now = DateTime.now();

    if (seatStatus == '착석' && rssi <= threshold) {
      if (lastThresholdMetTime == null) {
        lastThresholdMetTime = now; // 조건 충족 시작 시간 설정
      } else if (now.difference(lastThresholdMetTime!) >= thresholdDuration) {
        // 조건이 3초 이상 지속되고 마지막 알림 이후 5초가 지났는지 확인
        if (lastRssiNotificationTime == null || now.difference(lastRssiNotificationTime!) >= notificationCooldown) {
          // 알림 보내기
          NotificationService().showNotification(
            title: '아이가 아직 차안에 있어요!',
            body: '아이를 두고 내리진 않으셨나요? 확인해주세요!',
            customDetails: NotificationService().rssiNotificationDetails(),
          );
          lastRssiNotificationTime = now; // 마지막 알림 시간 업데이트
        }
      }
    } else {
      lastThresholdMetTime = null; // 조건이 충족되지 않으면 시작 시간 리셋
    }
  }



  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Silver Fox'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0.0,
      ),
      body: Column(
        children: [
          ///윗부분
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.350,
            child: Container(
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          /// 카시트 사진
                          Container(
                            height: detectedUuid == 'No beacon detected' ? 110 : 200, // 크기 변경
                            width: detectedUuid == 'No beacon detected' ? 110 : 200, // 크기 변경
                            child: Center(
                              child: Image.asset(
                                getCarseatImageForUuid(detectedUuid), // detectedUuid에 따라 이미지 선택
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 알림 창
                  if (detectedUuid == 'No beacon detected')
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            width: 1.0,
                            color: Colors.grey,
                          ),
                          bottom: BorderSide(
                            width: 1.0,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '카시트가 감지되지 않았습니다!', // You can change this as per your requirement
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 17.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),




          ///착석 및 체결 데이터
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.650 - 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 착석 여부
                buildContainerWithIconAndText(
                  'assets/no_seat.png',
                  '착석',
                  seatStatus,
                  Colors.grey[600]!,
                  seatStatus == '착석' ? Colors.blue : Colors.red,
                  icon2: seatStatus == '미착석' ? null : null,
                ),

                // 안전벨트
                buildContainerWithIconAndText(
                  'assets/no_belt.png',
                  '안전벨트',
                  beltStatus,
                  Colors.grey[600]!,
                  beltStatus == '체결' ? Colors.blue : Colors.red,
                  icon2: beltStatus == '미체결' ? 'assets/warning.gif' : null,
                ),

                // 아이소픽스
                buildContainerWithIconAndText(
                  'assets/isofix.png',
                  '아이소픽스',
                  isofixStatus,
                  Colors.grey[600]!,
                  isofixStatus == '체결' ? Colors.blue : Colors.red,
                  icon2: isofixStatus == '미체결' ? 'assets/warning.gif' : null,
                ),
              ],
            ),
          ),
          BeaconScan(
            onBeaconDetected: (String uuid, int rssi) {
              updateStatus(uuid);
              checkRssiAndNotify(rssi);
            },
          ),
        ],
      ),

    );
  }


  /// 상태에 따른 카시트 사진 변경
  String getCarseatImageForUuid(String uuid) {
    switch (uuid) {
      case '9999-9999-3333-3333':
        return 'assets/carseat_color/카시트_울상.png';
      case '9999-9999-2222-2222':
        return 'assets/carseat_color/카시트_착석x_벨트x_아이소픽스o.png';
      case '0000-1111-2222-2222':
        return 'assets/carseat_color/카시트_착석x_벨트o_아이소픽스o.png';
      case '0000-1111-3333-3333':
        return 'assets/carseat_color/카시트_착석x_벨트o_아이소픽스x.png';
      case '1111-0000-3333-3333':
        return 'assets/carseat_color/카시트_착석o_벨트x_아이소픽스x.png';
      case '1111-0000-2222-2222':
        return 'assets/carseat_color/카시트_착석o_벨트x_아이소픽스o.png';
      case '1111-1111-3333-3333':
        return 'assets/carseat_color/카시트_착석o_벨트o_아이소픽스x.png';
      case '1111-1111-2222-2222':
        return 'assets/carseat_color/카시트_웃상.png';
      default:
        return 'assets/carseat.png'; // 기본 이미지 파일 경로
    }
  }

  Container buildContainerWithIconAndText(
      String icon,
      String title,
      String subtitle,
      Color titleColor,
      Color subtitleColor, {
        String? icon2,
      }) {
    if (title == '아이소픽스') {
      if (subtitle == '체결') {
        icon = 'assets/yes_isofix.png';
      } else {
        icon = 'assets/isofix.png';
      }
    } else if (title == '안전벨트') {
      if (subtitle == '체결') {
        icon = 'assets/yes_belt.png';
      } else {
        icon = 'assets/belt.png';
      }
    } else if (title == '착석') {
      if (subtitle == '착석') {
        icon = 'assets/seat.png';
      } else {
        icon = 'assets/no_seat.png';
      }
    }

    return Container(
      height: 90,
      width: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            height: 65,
            width: 65,
            child: Center(
              child: Image.asset(
                icon,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            height: 65,
            width: 100,
            child: Center(
              child: Column(
                children: [
                  Container(
                    height: 25,
                    width: 80,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 80,
                    child: detectedUuid == 'No beacon detected'
                        ? null
                        : Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 65,
            width: 65,
            child: detectedUuid == 'No beacon detected'
                ? null
                : (icon2 != null
                ? Center(
              child: Image.asset(
                icon2,
                fit: BoxFit.cover,
              ),
            )
                : null),
          ),

        ],
      ),
    );
  }
}

