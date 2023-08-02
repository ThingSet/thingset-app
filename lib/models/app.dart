// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'connector.dart';
import 'ble_scanner.dart';

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

  Future<void> addConnector(String name, ConnectorModel model) async {
    await model.connect();
    _connectors[name] = model;
    notifyListeners();
  }

  Future<void> deleteConnector(String name) async {
    await _connectors[name]?.disconnect();
    _connectors.remove(name);
    notifyListeners();
  }
}
