import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import "dart:math";

class BeaconScan extends StatefulWidget {
  final void Function(String uuid, int rssi) onBeaconDetected;

  const BeaconScan({Key? key, required this.onBeaconDetected}) : super(key: key);

  @override
  _BeaconScanState createState() => _BeaconScanState();
}

class _BeaconScanState extends State<BeaconScan> {
  late StreamSubscription<RangingResult>? _streamRanging;
  List<Beacon> _beacons = [];
  Timer? _noBeaconTimer;
  final Duration noBeaconThreshold = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      initBeaconScanning();
    });
  }

  void initBeaconScanning() async {
    // 비콘 Ranging 시작
    List<Region> regions = [];
    // Android platform
    regions.add(Region(
      identifier: 'com.beacon',
    ));

    _streamRanging = flutterBeacon.ranging(regions).listen((RangingResult result) {
      // 검색된 비콘 리스트 업데이트
      List<Beacon> beacons = result.beacons.where((beacon) =>
      beacon.proximityUUID.substring(0, 8) == 'ABCD0000').toList();

      // 비콘이 감지되었을 때만 _beacons 리스트를 업데이트
      if (beacons.isNotEmpty) {
        _noBeaconTimer?.cancel();
        _noBeaconTimer = null;
        setState(() {
          _beacons = beacons;
        });

        // _beacons 리스트가 변경될 때만 onBeaconDetected 호출
        for (var beacon in beacons) {
          String extractedUuid = beacon.proximityUUID.substring(9, 28);
          widget.onBeaconDetected(extractedUuid, beacon.rssi);
          print('$extractedUuid rssi: ${beacon.rssi}');
          distance(beacon.rssi);
        }
      } else {
        if (_noBeaconTimer == null) {
          _noBeaconTimer = Timer(noBeaconThreshold, () {
            widget.onBeaconDetected('No beacon detected', 0);
          });
        }
      }
    });
  }


 // rssi에 따른 거리 측정 - 비활성화중
  void distance(rssi) {
    int n =2;        // constant N
    int alpha = -65;  // rssi at 1m
    num distance = pow(10.0,((alpha-rssi)/(10*n)));
    print(distance.toStringAsFixed(2));
  }

  @override
  void dispose() {
    // 스트림 구독 해제 및 비콘 모듈 종료
    _streamRanging?.cancel();
    flutterBeacon.close;

    super.dispose();
  }

  void refreshBeaconScan() {
    // 비콘 스캔을 중지하고 다시 시작합니다.
    _streamRanging?.cancel();
    initBeaconScanning();
  }

  @override
  Widget build(BuildContext context) {
    // Do not do anything visual in this widget
    return Container();
  }
}
