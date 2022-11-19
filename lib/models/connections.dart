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
  final List<ThingSetClient> _clients = [];

  get nodes => _nodes;

  get count => _nodes.length;

  ConnectionsModel() {
    final dummy = DummyClient("DummyClient");
    _clients.add(dummy);

    for (final client in _clients) {
      for (final node in client.listNodes()) {
        _nodes.add(NodeConnection(node, client));
      }
    }
    notifyListeners();
  }
}
