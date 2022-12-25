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
          child: Center(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              children: listDataObjects(
                context,
                connector,
                node,
                nodeId,
                '',
                node.reported,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> listDataObjects(
  BuildContext context,
  ConnectorModel connector,
  NodeModel node,
  String nodeId,
  String path,
  Map<String, dynamic> data,
) {
  return <Widget>[
    for (final item in data.keys)
      if (item[0].toUpperCase() == item[0] ||
          data[item] == null ||
          data[item] is Map)
        // group
        DataGroup(
          connector: connector,
          node: node,
          nodeId: nodeId,
          groupName: item,
          path: path.isEmpty ? item : '$path/$item',
          data: data[item],
        )
      else
        ListTile(
          title: Text(item.toString()),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4),
            child: Text(
              data[item].toString(),
              softWrap: true,
            ),
          ),
        )
  ];
}

class DataGroup extends StatelessWidget {
  final ConnectorModel connector;
  final NodeModel node;
  final String nodeId;
  final String groupName;
  final String path;
  final dynamic data;

  const DataGroup({
    super.key,
    required this.connector,
    required this.node,
    required this.nodeId,
    required this.groupName,
    required this.path,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        child: ExpansionTile(
          title: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              groupName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          children: <Widget>[
            if (data != null)
              ...listDataObjects(
                context,
                connector,
                node,
                nodeId,
                path,
                data,
              )
            else
              const LinearProgressIndicator(),
          ],
          onExpansionChanged: (value) {
            if (value == true) {
              connector.pull(nodeId, path);
            }
          },
        ),
      ),
    );
  }
}
