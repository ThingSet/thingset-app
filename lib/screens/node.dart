import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/connector.dart';
import '../models/node.dart';
import '../widgets/stateful_input.dart';

class NodeScreen extends StatelessWidget {
  final String connectorName;
  final String nodeId;

  const NodeScreen(
      {super.key, required this.connectorName, required this.nodeId});

  @override
  Widget build(BuildContext context) {
    ConnectorModel? connector =
        Provider.of<AppModel>(context).connector(connectorName);
    NodeModel? node = connector?.nodes[nodeId];
    if (connector != null && node != null) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                  ),
                ),
                Text(
                  nodeId,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 179, 179, 179),
                    fontSize: 12.0,
                  ),
                )
              ]),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload data from device',
              onPressed: () {
                connector.pull(nodeId, '');
              },
            ),
          ],
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
        DataGroup(
          connector: connector,
          node: node,
          nodeId: nodeId,
          groupName: item,
          path: path.isEmpty ? item : '$path/$item',
          data: data[item],
        )
      else if (item != "cNodeID" &&
          item[0] != 'a' &&
          item[0] != 'e' &&
          item[0] != 'm')
        DataItem(
          connector: connector,
          node: node,
          nodeId: nodeId,
          itemName: item,
          path: path.isEmpty ? item : '$path/$item',
          data: data[item],
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
              FutureBuilder<void>(
                  future: connector.pull(nodeId, path),
                  builder: (context, snapshot) =>
                      const LinearProgressIndicator()),
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

// correct UTF-8 string for units simplified for ThingSet
const unitFix = {
  'deg': '°',
  'degC': '°C',
  'pct': '%',
  'm2': 'm²',
  'm3': 'm³',
};

class DataItem extends StatelessWidget {
  final ConnectorModel connector;
  final NodeModel node;
  final String nodeId;
  final String itemName;
  final String path;
  final dynamic data;

  const DataItem({
    super.key,
    required this.connector,
    required this.node,
    required this.nodeId,
    required this.itemName,
    required this.path,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final chunks = itemName.split('_');

    // parse unit
    var unit = chunks.length > 1
        ? chunks[1] + (chunks.length > 2 ? '/$chunks[2]' : '')
        : '';
    if (unitFix.containsKey(unit)) {
      unit = unitFix[unit]!;
    }

    // split camel case name
    var descr = chunks[0].substring(1);
    descr = descr.replaceAllMapped(RegExp(r'([a-z])([A-Z0-9])'),
        (Match m) => '${m.group(1)} ${m.group(2)}');
    descr = descr.replaceAllMapped(RegExp(r'([A-Z0-9])([A-Z][a-z])'),
        (Match m) => '${m.group(1)} ${m.group(2)}');

    if (itemName[0] == 'x') {
      Widget? paramsWidget;
      if (data is List && data.isNotEmpty) {
        paramsWidget = ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
          child: Text("$data"),
        );
      }
      return ListTile(
        title: ElevatedButton(
          child: Text(descr),
          onPressed: () {
            connector.exec(nodeId, path, []);
          },
        ),
        trailing: paramsWidget,
      );
    } else {
      Widget valueWidget;
      if (itemName[0] == 'w' || itemName[0] == 's') {
        if (data is bool) {
          valueWidget = StatefulSwitch(
            value: data,
            onChanged: (value) {
              node.setDesired(path, value);
            },
          );
        } else {
          valueWidget = StatefulTextField(
            value: data,
            unit: unit,
            onChanged: (value) {
              node.setDesired(path, value);
            },
          );
        }
      } else {
        valueWidget = Text(
          "$data $unit",
          softWrap: true,
        );
      }
      return ListTile(
        title: Text(descr),
        trailing: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
          child: valueWidget,
        ),
      );
    }
  }
}
