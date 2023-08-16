// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connector.dart';

import '../clients/thingset_ble.dart';
import '../clients/thingset_serial.dart';
import '../clients/thingset_ws.dart';

class AppModel extends ChangeNotifier {
  /// Map of all connectors supported by the app
  final Map<String, ConnectorModel> _connectors = {};

  List<String> get connectorNames => _connectors.keys.toList();

  Map<String, ConnectorModel> get connectors => _connectors;

  ConnectorModel? connector(String name) => _connectors[name];

  Future<String?> addBleConnector(String bleDeviceId) async {
    String name = 'ble_${bleDeviceId.replaceAll(':', '')}';
    var bleClient = BleClient(bleDeviceId);
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
