// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'connector.dart';
import 'ble_scanner.dart';

import '../clients/thingset_ble.dart';
import '../clients/thingset_serial.dart';
import '../clients/thingset_ws.dart';

class AppModel extends ChangeNotifier {
  /// Map of all connectors supported by the app
  final Map<String, ConnectorModel> _connectors = {};

  /// Global Bluetooth interface (only used in mobile apps)
  FlutterReactiveBle? ble;

  /// Bluetooth scanner (only used in mobile apps)
  BleScanner? scanner;

  AppModel() {
    if (Platform.isIOS || Platform.isAndroid) {
      ble = FlutterReactiveBle();
      scanner = BleScanner(ble!);
    }
  }

  List<String> get connectorNames => _connectors.keys.toList();

  Map<String, ConnectorModel> get connectors => _connectors;

  ConnectorModel? connector(String name) => _connectors[name];

  Future<String?> addBleConnector(String bleDeviceId) async {
    String name = 'ble_${bleDeviceId.replaceAll(':', '')}';
    var bleClient = BleClient(ble!, bleDeviceId);
    var model = ConnectorModel(bleClient);
    try {
      await model.connect().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      return null;
    }
    _connectors[name] = model;
    notifyListeners();
    return name;
  }

  Future<String?> addSerialConnector(String serialPort) async {
    String name = 'serial_${serialPort.replaceAll('/', '_')}';
    var serialClient = SerialClient(serialPort);
    var model = ConnectorModel(serialClient);
    try {
      await model.connect().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      return null;
    }
    _connectors[name] = model;
    notifyListeners();
    return name;
  }

  Future<String?> addWebSocketConnector(String uri) async {
    String name = 'ws_${uri.replaceAll(RegExp(r'/|:|\.'), '_')}';
    var websocketClient = WebSocketClient(uri);
    var model = ConnectorModel(websocketClient);
    try {
      await model.connect().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      return null;
    }
    _connectors[name] = model;
    notifyListeners();
    return name;
  }

  Future<void> deleteConnector(String name) async {
    await _connectors[name]?.disconnect();
    _connectors.remove(name);
    notifyListeners();
  }
}
