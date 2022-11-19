import 'package:flutter/foundation.dart';

import '../connectors/thingset.dart';

class NodeConnection {
  final String _nodeId;
  final ThingSetConnector _connector;

  get nodeId => _nodeId;

  get connector => _connector;

  NodeConnection(this._nodeId, this._connector);
}

class ConnectionsModel extends ChangeNotifier {
  final List<NodeConnection> _nodes = [];

  get nodes => _nodes;

  get count => _nodes.length;

  void add(String item) {
    _nodes.add(NodeConnection(item, DummyClient("DummyClient")));
    notifyListeners();
  }
}
