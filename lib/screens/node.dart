// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/connector.dart';
import '../models/node.dart';
import '../theme.dart';
import '../widgets/stateful_input.dart';

class NodeScreen extends StatefulWidget {
  final String connectorName;
  final String nodeId;

  const NodeScreen(
      {super.key, required this.connectorName, required this.nodeId});

  @override
  State<NodeScreen> createState() => NodeScreenState();
}

class NodeScreenState extends State<NodeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ConnectorModel? connector =
        Provider.of<AppModel>(context).connector(widget.connectorName);
    NodeModel? node = connector?.nodes[widget.nodeId];
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
                node.id,
                style: const TextStyle(
                  color: Color.fromARGB(255, 179, 179, 179),
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
        body: FutureBuilder<void>(
          future: Future.wait([
            connector.pull(node.id, ''),
            connector.pull(node.id, '_Reporting'),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              switch (_selectedIndex) {
                case 0:
                  return NodeData(connector: connector, node: node);
                default:
                  return const Text('Live Data Screen');
              }
            } else {
              return const LinearProgressIndicator();
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_rounded),
              label: 'Data Tree',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.stacked_line_chart_rounded),
              label: 'Live View',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
        backgroundColor: const Color(0xFFF0F0F0),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.nodeId),
        ),
        body: const Center(child: Text('Node not found')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class NodeData extends StatelessWidget {
  final ConnectorModel connector;
  final NodeModel node;

  const NodeData({super.key, required this.connector, required this.node});

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
  String path,
  Map<String, dynamic> data,
) {
  var list = <Widget>[
    for (final item in data.keys)
      if (item[0].toUpperCase() == item[0] && item[0] != '_')
        DataGroup(
          connector: connector,
          node: node,
          groupName: item,
          path: path.isEmpty ? item : '$path/$item',
          data: data[item],
        )
      else if (item[0] == 'a' || item[0] == 'e' || item[0] == 'm')
        Subset(
          connector: connector,
          node: node,
          subsetName: item,
          path: path.isEmpty ? item : '$path/$item',
          data: data[item],
        )
      else if (data[item] != null &&
          item != 'pNodeID' &&
          item != 'pNodeName' &&
          item != 'cMetadataURL' &&
          item[0] != 'o' &&
          item[0] != '_')
        DataItem(
          connector: connector,
          node: node,
          itemName: item,
          path: path.isEmpty ? item : '$path/$item',
          data: data[item],
        )
  ];

  List<String> tags = [];
  for (final item in data.keys) {
    if (item[0] == 'o') {
      tags.add('${item.substring(1)}: ${data[item]}');
    }
  }
  if (tags.isNotEmpty) {
    list.add(Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) => Chip(label: Text(tag))).toList(),
      ),
    ));
  }

  return list;
}

class DataGroup extends StatelessWidget {
  final ConnectorModel connector;
  final NodeModel node;
  final String groupName;
  final String path;
  final dynamic data;

  const DataGroup({
    super.key,
    required this.connector,
    required this.node,
    required this.groupName,
    required this.path,
    required this.data,
  });

  Widget? _icons(BuildContext context) {
    return SizedBox(
      width: 100.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (node.hasDesiredChanged(path))
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                await connector.push(node.id, path);
              },
            ),
          if (node.hasReportingSetup(path))
            IconButton(
              icon: const Icon(Icons.notifications, color: primaryColor),
              onPressed: () async {
                await _reportingSetupDialog(
                    context, connector, node, groupName, '_Reporting/$path/_');
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload data from device',
            onPressed: () async {
              node.clearReported(path);
              node.clearDesired(path);
              await connector.pull(node.id, path);
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
          trailing: _icons(context),
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
                path,
                data,
              )
          ],
          onExpansionChanged: (value) async {
            if (value == true) {
              await connector.pull(node.id, path);
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
  final String itemName;
  final String path;
  final dynamic data;

  const DataItem({
    super.key,
    required this.connector,
    required this.node,
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
            connector.exec(node.id, path, []);
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
  final String subsetName;
  final String path;
  final dynamic data;

  const Subset({
    super.key,
    required this.connector,
    required this.node,
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
            Row(
              children: [
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
                const Spacer(),
                if (node.hasReportingSetup(path))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: IconButton(
                      icon:
                          const Icon(Icons.notifications, color: primaryColor),
                      onPressed: () async {
                        await _reportingSetupDialog(context, connector, node,
                            subsetName, '_Reporting/$path');
                      },
                    ),
                  ),
              ],
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

Future<void> _reportingSetupDialog(
    BuildContext context,
    ConnectorModel connector,
    NodeModel node,
    String groupName,
    String path) async {
  await connector.pull(node.id, path);
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      var data = node.getReported(path);
      return SimpleDialog(
        title: const Text('Reporting Setup'),
        children: <Widget>[
          if (data != null)
            ..._listDataObjects(
              context,
              connector,
              node,
              path,
              data,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Save'),
                onPressed: () async {
                  if (node.hasDesiredChanged(path)) {
                    await connector.push(node.id, path);
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            ],
          ),
        ],
      );
    },
  );
}
