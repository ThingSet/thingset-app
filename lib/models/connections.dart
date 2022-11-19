import 'package:flutter/foundation.dart';

import '../clients/thingset.dart';

class NodeConnection {
  final String _nodeId;
  final ThingSetClient _client;

  get nodeId => _nodeId;

  get client => _client;

  NodeConnection(this._nodeId, this._client);
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
