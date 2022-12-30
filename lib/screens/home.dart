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
        title: Center(child: Text(title)),
      ),
      body: Center(
        child: Consumer<AppModel>(
          builder: (context, appModel, child) {
            return ListView.builder(
              itemCount: appModel.connectors.length,
              itemBuilder: (BuildContext context, int index) {
                String connectorName =
                    appModel.connectors.keys.elementAt(index);
                return NodesList(
                  connectorName: connectorName,
                  connector: appModel.connectors[connectorName],
                );
              },
            );
          },
        ),
      ),
      backgroundColor: const Color(0xFFF0F0F0),
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
                  shrinkWrap: true,
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
    return Card(
      child: ListTile(
        title: Text(connector.nodes[nodeId].name),
        subtitle: Text(nodeId),
        onTap: () {
          context.go('/$connectorName/$nodeId');
        },
      ),
    );
  }
}
