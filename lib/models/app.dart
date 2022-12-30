import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'connector.dart';
import 'ble_scanner.dart';
import '../clients/thingset_ws.dart';

class AppModel extends ChangeNotifier {
  /// Map of all connectors supported by the app
  final Map<String, ConnectorModel> _connectors = {};

  /// Global Bluetooth interface (only used in mobile apps)
  FlutterReactiveBle? ble;

  /// Bluetooth scanner (only used in mobile apps)
  BleScanner? scanner;

  get connectorNames => _connectors.keys.toList();

  get connectors => _connectors;

  ConnectorModel? connector(String name) => _connectors[name];

  AppModel() {
    // initialize available clients and create a connector for them
    _connectors['ws'] =
        ConnectorModel(WebSocketClient('ws://127.0.0.1:8000/app'));

    if (Platform.isIOS || Platform.isAndroid) {
      ble = FlutterReactiveBle();
      scanner = BleScanner(ble!);
    }
  }

  void addConnector(String name, ConnectorModel model) {
    _connectors[name] = model;
    notifyListeners();
  }
}
