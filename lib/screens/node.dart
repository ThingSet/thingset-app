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
        body: FutureBuilder<void>(
          future: connector.pull(nodeId, ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return NodeData(connector: connector, node: node, nodeId: nodeId);
            } else {
              return const LinearProgressIndicator();
            }
          },
        ),
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
        builder: (_, model, __) => SingleChildScrollView(
          child: DataObjects(
            connector: connector,
            node: node,
            nodeId: nodeId,
          ),
        ),
      ),
    );
  }
}

class DataObjects extends StatelessWidget {
  final ConnectorModel connector;
  final NodeModel node;
  final String nodeId;

  const DataObjects({
    super.key,
    required this.connector,
    required this.node,
    required this.nodeId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: node.reported.length,
        itemBuilder: (BuildContext context, int index) {
          String key = node.reported.keys.elementAt(index);
          return DataGroup(
            connector: connector,
            node: node,
            nodeId: nodeId,
            groupName: key,
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    );
  }
}

class DataGroup extends StatelessWidget {
  final ConnectorModel connector;
  final NodeModel node;
  final String nodeId;
  final String groupName;

  const DataGroup({
    super.key,
    required this.connector,
    required this.node,
    required this.nodeId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(groupName),
        ),
        children: <Widget>[
          if (node.reported[groupName] != null)
            if (node.reported[groupName] is Map)
              for (final item in node.reported[groupName].keys)
                ListTile(
                  title: Text(item.toString()),
                  trailing: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.4),
                    child: Text(
                      node.reported[groupName][item].toString(),
                      softWrap: true,
                    ),
                  ),
                )
          else
            const LinearProgressIndicator(),
        ],
        onExpansionChanged: (value) {
          if (value == true) {
            connector.pull(nodeId, groupName);
          }
        },
      ),
    );
  }
}
