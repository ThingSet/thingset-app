import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/connector.dart';

class HomeScreen extends StatelessWidget {
  final String title = 'ThingSet App';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(child: NodesList()),
    );
  }
}

class NodesList extends StatelessWidget {
  const NodesList({super.key});

  @override
  Widget build(BuildContext context) {
    const connectorName = 'dummy';
    final connector = Provider.of<AppModel>(context).connector(connectorName)!;
    final nodeIds = connector.nodeIds;
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: nodeIds.length,
      itemBuilder: (BuildContext context, int index) => NodeItem(
          connectorName: connectorName,
          connector: connector,
          nodeId: nodeIds[index]),
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}

class NodeItem extends StatelessWidget {
  final String connectorName;
  final ConnectorModel connector;
  final String nodeId;

  const NodeItem({
    super.key,
    required this.connectorName,
    required this.connector,
    required this.nodeId,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.go('/$connectorName/$nodeId');
        },
        child: Container(
          height: 50,
          color: Colors.grey[300],
          child: Center(
            child: Text(
              '$nodeId (${connector.client.type})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
