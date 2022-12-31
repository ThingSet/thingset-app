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

  bool _connected = false;

  get client => _client;

  get nodeIds => _nodes.keys.toList();

  get nodes => _nodes;

  NodeModel? node(String name) => _nodes[name];

  ConnectorModel(this._client);

  // Update list of nodes connected to the client
  Future<void> updateNodes() async {
    // ToDo: place somewhere else
    if (!_connected) {
      _client.connect();
      _connected = true;
    }

    final resp = await _client.request('?//');
    if (resp.status.isContent()) {
      for (final nodeId in jsonDecode(resp.data)) {
        if (_nodes[nodeId] == null && nodeId != '') {
          _nodes[nodeId] = NodeModel();

          // try to determine node name
          await pull(nodeId, '');
          if (_nodes[nodeId]!.reported.containsKey('cNodeName')) {
            _nodes[nodeId]!.name = _nodes[nodeId]!.reported['cNodeName'];
          } else if (_nodes[nodeId]!.reported.containsKey('Device')) {
            await pull(nodeId, 'Device');
            var device = _nodes[nodeId]!.reported['Device'];
            if (device.containsKey('cManufacturer') &&
                device.containsKey('cDeviceType')) {
              _nodes[nodeId]!.name =
                  '${device['cManufacturer']} ${device['cDeviceType']}';
            }
          }
        }
      }
    }
  }

  /// Update data in the node based on desired state
  Future<void> push(String nodeId, String path) async {
    throw Exception('Yet to be implemented');
  }

  /// Update data in the node based on desired state
  Future<dynamic> exec(String nodeId, String path, List params) async {
    if (path.isEmpty) {
      return;
    }
    final paramsJson = jsonEncode(params);
    final reqString = '!/$nodeId/$path $paramsJson';
    final resp = await _client.request(reqString);
    if (resp.status.isValid() && resp.data.isNotEmpty) {
      return jsonDecode(resp.data);
    }
  }

  /// Retrieve data from node through the client
  Future<void> pull(String nodeId, String path) async {
    final reqString = path.isEmpty ? '?/$nodeId' : '?/$nodeId/$path';
    final resp = await _client.request(reqString);
    if (resp.status.isContent()) {
      final jsonData = jsonDecode(resp.data);
      if (jsonData is Map) {
        _nodes[nodeId]?.mergeReported(path, jsonData);
      }
    }
  }
}
