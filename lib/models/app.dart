// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'connector.dart';

import '../clients/thingset_ble.dart';
import '../clients/thingset_serial.dart';
import '../clients/thingset_ws.dart';

class AppModel extends ChangeNotifier {
  /// Map of all connectors supported by the app
  final Map<String, ConnectorModel> _connectors = {};
  static const _storage = FlutterSecureStorage();

  List<String> get connectorNames => _connectors.keys.toList();

  Map<String, ConnectorModel> get connectors => _connectors;

  ConnectorModel? connector(String name) => _connectors[name];

Future<void> storeSettings(String connectorType, String newConnection) async {
    String? data = await _storage.read(key: connectorType);
    List<String> connections;
    if (data != null) {
      connections = jsonDecode(data);
    } else {
      connections = [];
    }
    if (!connections.contains(newConnection)) {
      connections.add(newConnection);
    }
    await _storage.write(key: connectorType, value: jsonEncode(connections));
  }

  Future<void> restoreSettings() async {
    String? serialConns = await _storage.read(key: 'serial');
    if (serialConns != null) {
      List<String> ports = jsonDecode(serialConns);
      for (final port in ports) {
        await addSerialConnector(port);
      }
    }

    String? bleConns = await _storage.read(key: 'ble');
    if (bleConns != null) {
      List<String> bleDeviceIds = jsonDecode(bleConns);
      for (final id in bleDeviceIds) {
        await addBleConnector(id);
      }
    }

    String? wsConns = await _storage.read(key: 'ws');
    if (wsConns != null) {
      List<String> uris = jsonDecode(wsConns);
      for (final uri in uris) {
        await addWebSocketConnector(uri);
      }
    }
  }

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
    await storeSettings('ble', bleDeviceId);
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
    await storeSettings('serial', serialPort);
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
    await storeSettings('websocket', uri);
    return name;
  }

  Future<void> deleteConnector(String name) async {
    await _connectors[name]?.disconnect();
    _connectors.remove(name);
    notifyListeners();
  }
}
