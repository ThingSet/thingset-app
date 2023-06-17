// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

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

  ConnectorModel(this._client);

  ThingSetClient get client => _client;

  List<String> get nodeIds => _nodes.keys.toList();

  Map<String, NodeModel> get nodes => _nodes;

  String get clientId => _client.id;

  String get clientType => _client.type;

  NodeModel? node(String name) => _nodes[name];

  // Update list of nodes connected to the client
  Future<void> updateNodes() async {
    // ToDo: place somewhere else
    if (!_connected) {
      await _client.connect();
      _connected = true;
    }

    final resp = await _client.request('?/ null');
    if (resp.status.isContent()) {
      for (final nodeId in jsonDecode(resp.data)) {
        if (_nodes[nodeId] == null && nodeId != '') {
          _nodes[nodeId] = NodeModel(nodeId);

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
    final data = _nodes[nodeId]?.getDesired(path);
    final dataStr = jsonEncode(data);
    final reqString =
        path.isEmpty ? '=/$nodeId $dataStr' : '=/$nodeId/$path $dataStr';
    final resp = await _client.request(reqString);
    if (resp.status.isChanged()) {
      _nodes[nodeId]?.clearDesired(path);
      _nodes[nodeId]?.mergeReported(path, data);
    }
  }

  /// Update data in the node based on desired state
  Future<dynamic> exec(String nodeId, String path, List params) async {
    if (path.isEmpty) {
      return;
    }
    final paramsJson = jsonEncode(params);
    final reqString = '!/$nodeId/$path $paramsJson';
    final resp = await _client.request(reqString);
    if (resp.status.isChanged() && resp.data.isNotEmpty) {
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

  Future<void> connect() async {
    await _client.connect();
  }

  Future<void> disconnect() async {
    await _client.disconnect();
  }
}
