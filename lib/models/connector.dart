// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

/// Classes and functions to handle connectors
///
/// Initializes different types of clients and assigns them to nodes
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'node.dart';
import '../clients/thingset.dart';

class ConnectorModel extends ChangeNotifier {
  /// Map of all nodes with their node ID as the key
  final Map<String, NodeModel> _nodes = {};

  /// ThingSet client used by this connector
  final ThingSetClient _client;

  StreamSubscription<ThingSetMessage>? _reportSubscription;

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
    if (resp.function.isContent()) {
      List<dynamic> nodesList;
      try {
        nodesList = jsonDecode(resp.payload);
      } catch (e) {
        debugPrint('failed to parse nodes list: ${resp.payload}');
        return;
      }

      for (final nodeId in nodesList) {
        if (_nodes[nodeId] == null && nodeId != '') {
          _nodes[nodeId] = NodeModel(nodeId);

          // try to determine node name
          await pull(nodeId, '');
          if (_nodes[nodeId]!.reported.containsKey('pNodeName')) {
            _nodes[nodeId]!.name = _nodes[nodeId]!.reported['pNodeName'];
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
    if (resp.function.isChanged()) {
      _nodes[nodeId]?.clearDesired(path);
      _nodes[nodeId]?.mergeReported(path, data);
    }
  }

  /// Update data in the node based on desired state
  Future<ThingSetMessage?> exec(String nodeId, String path, List params) async {
    if (path.isEmpty) {
      return null;
    }
    final paramsJson = jsonEncode(params);
    final reqString = '!/$nodeId/$path $paramsJson';
    final resp = await _client.request(reqString);
    return resp;
  }

  Future<void> pullNodeRoot(String nodeId) async {
    // considering root objects static, so we only need to pull once at startup
    if (nodes[nodeId] != null && nodes[nodeId]!.reported.isEmpty) {
      await pull(nodeId, '');
    }
    if (nodes[nodeId] != null &&
        (nodes[nodeId]!.reported['_Reporting'] == null ||
            nodes[nodeId]!.reported['_Reporting'].isEmpty)) {
      await pull(nodeId, '_Reporting');
    }
  }

  /// Retrieve data from node through the client
  Future<void> pull(String nodeId, String path) async {
    final reqString = path.isEmpty ? '?/$nodeId' : '?/$nodeId/$path';
    final resp = await _client.request(reqString);
    if (resp.function.isContent()) {
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(resp.payload);
      } catch (e) {
        debugPrint('failed to parse response payload: ${resp.payload}');
        return;
      }
      _nodes[nodeId]?.mergeReported(path, payload);
    }
  }

  Future<void> connect() async {
    await _client.connect();
    _reportSubscription = _client.reports().listen((msg) {
      /* ToDo: support more nodes per connector */
      if (_nodes.isNotEmpty) {
        _nodes[_nodes.keys.first]?.storeReport(msg.relPath, msg.payload);
      }
    });
  }

  Future<void> disconnect() async {
    await _reportSubscription?.cancel();
    await _client.disconnect();
  }
}
