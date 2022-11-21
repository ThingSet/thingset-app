import 'package:flutter/foundation.dart';

import 'connector.dart';
import '../clients/thingset.dart';

class AppModel extends ChangeNotifier {
  /// Map of all connectors supported by the app
  final Map<String, ConnectorModel> _connectors = {};

  get connectorNames => _connectors.keys.toList();

  get connectors => _connectors;

  ConnectorModel? connector(String name) => _connectors[name];

  AppModel() {
    // initialize available clients and create a connector for them
    _connectors['dummy'] = ConnectorModel(DummyClient('DummyClient'));
  }
}
