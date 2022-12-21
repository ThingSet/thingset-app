import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/connector.dart';
import '../models/node.dart';

class NodeScreen extends StatelessWidget {
  final String connectorName;
  final String nodeId;

  const NodeScreen(
      {super.key, required this.connectorName, required this.nodeId});

  @override
  Widget build(BuildContext context) {
    var connector = Provider.of<AppModel>(context).connector(connectorName);
    var node = connector?.nodes[nodeId];
    if (connector != null && node != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(nodeId),
        ),
        body: NodeData(connector: connector, node: node, nodeId: nodeId),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(nodeId),
        ),
        body: const Center(child: Text('Node not found')),
      );
    }
  }
}

class NodeData extends StatelessWidget {
  final ConnectorModel connector;
  final NodeModel node;
  final String nodeId;

  const NodeData(
      {super.key,
      required this.connector,
      required this.node,
      required this.nodeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NodeModel>.value(
      value: node,
      child: Consumer<NodeModel>(
        builder: (_, model, __) {
          return FutureBuilder<void>(
            future: connector.pull(nodeId, ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Text(node.reported.toString());
              } else {
                return const CircularProgressIndicator();
              }
            },
          );
        },
      ),
    );
  }
}
