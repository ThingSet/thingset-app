import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../clients/thingset_ble.dart';

class BleScanner extends ChangeNotifier {
  final FlutterReactiveBle ble;
  final List<DiscoveredDevice> discoveredDevices = [];
  Stream? scanStream;
  StreamSubscription? scanStreamSubscription;

  BleScanner(this.ble);

  List<DiscoveredDevice> get devices => discoveredDevices;

  Future<void> startScanning() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    scanStream = ble.scanForDevices(
      withServices: [uuidThingSetService],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    );

    scanStreamSubscription = scanStream!.listen(
      (device) {
        if (discoveredDevices
            .every((discovered) => discovered.id != device.id)) {
          debugPrint("New ThingSet node found: ${device.toString()}");
          discoveredDevices.add(device);
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint("BLE error: $err");
        // ToDo: Handle error.
      },
    );
  }

  void stopScanning() async {
    await scanStreamSubscription?.cancel();
  }

  void clear() {
    discoveredDevices.clear();
  }
}
