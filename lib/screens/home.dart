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
      body: Center(
        child: Consumer<AppModel>(
          builder: (context, appModel, child) {
            const connectorName = 'ws';
            final connector = appModel.connectors[connectorName];
            return NodesList(
                connectorName: connectorName, connector: connector);
          },
        ),
      ),
    );
  }
}

class NodesList extends StatelessWidget {
  final String connectorName;
  final ConnectorModel connector;

  const NodesList(
      {super.key, required this.connectorName, required this.connector});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConnectorModel>(
      create: (_) => connector,
      child: Consumer<ConnectorModel>(
        builder: (_, model, __) {
          return FutureBuilder<void>(
            future: model.updateNodes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: model.nodeIds.length,
                  itemBuilder: (BuildContext context, int index) => NodeItem(
                    connectorName: connectorName,
                    connector: model,
                    nodeId: model.nodeIds[index],
                  ),
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(),
                );
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
