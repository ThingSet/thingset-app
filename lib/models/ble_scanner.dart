// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../clients/thingset_ble.dart';

class BleScanner extends ChangeNotifier {
  final FlutterReactiveBle _ble;
  final List<DiscoveredDevice> _discoveredDevices = [];
  Stream? _scanStream;
  StreamSubscription? _scanStreamSubscription;

  BleScanner(this._ble);

  List<DiscoveredDevice> get devices => _discoveredDevices;

  Future<void> startScanning() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    _scanStream = _ble.scanForDevices(
      withServices: [uuidThingSetService],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    );

    _scanStreamSubscription = _scanStream!.listen(
      (device) {
        if (_discoveredDevices
            .every((discovered) => discovered.id != device.id)) {
          debugPrint('New ThingSet node found: ${device.toString()}');
          _discoveredDevices.add(device);
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('BLE error: $err');
        // ToDo: Handle error.
      },
    );
  }

  void stopScanning() async {
    await _scanStreamSubscription?.cancel();
  }

  void clear() {
    _discoveredDevices.clear();
  }
}
