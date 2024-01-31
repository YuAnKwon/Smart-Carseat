import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'services/notifi_service.dart';
import 'screen/mainscreen.dart';
import 'package:wakelock/wakelock.dart';

Future<void> main() async {
  // WidgetsFlutterBinding을 초기화합니다.
  WidgetsFlutterBinding.ensureInitialized();
  Wakelock.enable(); // 화면이 꺼지지 않도록 설정

  // // 비콘 모듈 초기화
  await flutterBeacon.initializeScanning;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService = NotificationService();
  final Location location = Location();

  @override
  Widget build(BuildContext context) {
    // 앱 초기화 및 권한 확인
    initializeApp();

    return MaterialApp(
      title: 'Silver Fox',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
    );
  }

  /// 블루투스, 위치, 알림 권한 실행하기
  Future<void> initializeApp() async {
    // Bluetooth 스캔 권한 확인
    var bluetoothScanStatus = await Permission.bluetoothScan.status;
    if (!bluetoothScanStatus.isGranted) {
      await Permission.bluetoothScan.request();
    }

    // Bluetooth 광고 권한 확인
    var bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.status;
    if (!bluetoothAdvertiseStatus.isGranted) {
      await Permission.bluetoothAdvertise.request();
    }

    // 위치 권한 확인
    var locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      await Permission.location.request();
    }

    await notificationService.initNotification();

    // 블루투스가 켜져있지 않을경우, 활성화 시키도록 팝업창 띄우기
    var subscription = FlutterBluePlus.adapterState.listen((state) async {
      if (state == BluetoothAdapterState.off) {
        await FlutterBluePlus.turnOn();
      }
    });

    // 위치 비활성화인 경우, 알림창 띄우기
    bool _isLocationServiceEnabled = await location.serviceEnabled();
    if (!_isLocationServiceEnabled) {
      _isLocationServiceEnabled = await location.requestService();
    }
  }
}
