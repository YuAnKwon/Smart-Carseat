import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  static String lastUuid = 'No beacon detected';

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
    const AndroidInitializationSettings('silverfox');
    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await notificationsPlugin.initialize(initializationSettings);

  }

  notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails(
          'channelId 5',
          'channelmame',
          icon: 'silverfox',
          importance: Importance.max,
          // sound: RawResourceAndroidNotificationSound('noti_sound')
        ),
        iOS: DarwinNotificationDetails());
  }

  Future showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    NotificationDetails? customDetails, // 이 매개변수 추가
  }) async {
    return notificationsPlugin.show(
      id,
      title,
      body,
      customDetails ?? await notificationDetails(), // customDetails가 제공되면 사용
      payload: payload,
    );
  }
  NotificationDetails rssiNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'rssiChannelId', // 새로운 채널 ID
        'RSSI Channel',
        icon: 'silverfox',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('beepsound'), // 사용자 지정 소리
      ),
      iOS: DarwinNotificationDetails(),
    );
  }


}
