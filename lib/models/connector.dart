/// Classes and functions to handle connectors
///
/// Initializes different types of clients and assigns them to nodes

import 'package:flutter/foundation.dart';

import 'node.dart';
import '../clients/thingset.dart';

class ConnectorModel extends ChangeNotifier {
  /// Map of all nodes with their node ID as the key
  final Map<String, NodeModel> _nodes = {};

  /// ThingSet client used by this connector
  final ThingSetClient _client;

  get client => _client;

  get nodeIds => _nodes.keys.toList();

  get nodes => _nodes;

  NodeModel? node(String name) => _nodes[name];

  ConnectorModel(this._client) {
    for (var nodeId in _client.listNodes()) {
      nodes[nodeId] = NodeModel();
    }
  }

  /// Update data in the node based on desired state
  Future<void> push(String nodeId, String path) async {
    throw Exception('Yet to be implemented');
  }

  /// Retrieve data from node through the client
  Future<void> pull(String nodeId, String path) async {
    throw Exception('Yet to be implemented');
  }
}
