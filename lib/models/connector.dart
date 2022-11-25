/// Classes and functions to handle connectors
///
/// Initializes different types of clients and assigns them to nodes

import 'dart:convert';

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

  ConnectorModel(this._client);

  // Update list of nodes connected to the client
  Future<void> updateNodes() async {
    // ToDo: place somewhere else
    _client.connect();

    final resp = await _client.request('?//');
    if (resp.status.isContent()) {
      for (final nodeId in jsonDecode(resp.data)) {
        if (_nodes[nodeId] == null && nodeId != '') {
          _nodes[nodeId] = NodeModel();
        }
      }
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
