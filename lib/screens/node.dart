// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/connector.dart';
import '../models/node.dart';
import '../widgets/stateful_input.dart';

class NodeScreen extends StatelessWidget {
  final String _connectorName;
  final String _nodeId;

  const NodeScreen({super.key, required connectorName, required nodeId})
      : _connectorName = connectorName,
        _nodeId = nodeId;

  @override
  Widget build(BuildContext context) {
    ConnectorModel? connector =
        Provider.of<AppModel>(context).connector(_connectorName);
    NodeModel? node = connector?.nodes[_nodeId];
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
                _nodeId,
                style: const TextStyle(
                  color: Color.fromARGB(255, 179, 179, 179),
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
        body: FutureBuilder<void>(
          future: connector.pull(_nodeId, ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return NodeData(
                  connector: connector, node: node, nodeId: _nodeId);
            } else {
              return const LinearProgressIndicator();
            }
          },
        ),
        backgroundColor: const Color(0xFFF0F0F0),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(_nodeId),
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
        builder: (_, model, __) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          children: _listDataObjects(
            context,
            connector,
            node,
            nodeId,
            '',
            node.reported,
          ),
        ),
      ),
    );
  }
}

List<Widget> _listDataObjects(
  BuildContext context,
  ConnectorModel connector,
  NodeModel node,
  String nodeId,
  String path,
  Map<String, dynamic> data,
) {
  return <Widget>[
    for (final item in data.keys)
      if (item[0].toUpperCase() == item[0] && item[0] != '_')
        DataGroup(
          connector: connector,
          node: node,
          nodeId: nodeId,
          groupName: item,
          path: path.isEmpty ? item : '$path/$item',
          data: data[item],
        )
      else if (item[0] == 'a' || item[0] == 'e' || item[0] == 'm')
        Subset(
          connector: connector,
          node: node,
          nodeId: nodeId,
          subsetName: item,
          path: path.isEmpty ? item : '$path/$item',
          data: data[item],
        )
      else if (data[item] != null &&
          item != 'pNodeID' &&
          item != 'cMetadataURL')
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

  Widget? _icons() {
    return SizedBox(
      width: 100.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (node.hasDesiredChanged(path))
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                await connector.push(nodeId, path);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload data from device',
            onPressed: () async {
              node.clearReported(path);
              node.clearDesired(path);
              await connector.pull(nodeId, path);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        child: ExpansionTile(
          trailing: _icons(),
          controlAffinity: ListTileControlAffinity.leading,
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
              ..._listDataObjects(
                context,
                connector,
                node,
                nodeId,
                path,
                data,
              )
          ],
          onExpansionChanged: (value) async {
            if (value == true) {
              await connector.pull(nodeId, path);
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
        ? chunks[1] + (chunks.length > 2 ? '/${chunks[2]}' : '')
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
          child: Text('$data'),
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
          '$data $unit',
          softWrap: true,
          style: const TextStyle(fontSize: 16),
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

class Subset extends StatelessWidget {
  final ConnectorModel connector;
  final NodeModel node;
  final String nodeId;
  final String subsetName;
  final String path;
  final dynamic data;

  const Subset({
    super.key,
    required this.connector,
    required this.node,
    required this.nodeId,
    required this.subsetName,
    required this.path,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final chunks = subsetName.split('_');

    // split camel case name
    var descr = chunks[0].substring(1);
    descr = descr.replaceAllMapped(RegExp(r'([a-z])([A-Z0-9])'),
        (Match m) => '${m.group(1)} ${m.group(2)}');
    descr = descr.replaceAllMapped(RegExp(r'([A-Z0-9])([A-Z][a-z])'),
        (Match m) => '${m.group(1)} ${m.group(2)}');

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                '$descr Subset',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (data is List && data.length > 0)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final item in data)
                      Chip(
                        label: Text(item),
                        //onDeleted: () => {}
                      )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
