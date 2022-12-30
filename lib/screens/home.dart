import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../clients/thingset_ble.dart';
import '../models/app.dart';
import '../models/ble_scanner.dart';
import '../models/connector.dart';

class HomeScreen extends StatelessWidget {
  final String title = 'ThingSet App';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) => Scaffold(
        appBar: AppBar(
          title: Center(child: Text(title)),
        ),
        body: Center(
          child: ListView.builder(
            itemCount: appModel.connectors.length,
            itemBuilder: (BuildContext context, int index) {
              String connectorName = appModel.connectors.keys.elementAt(index);
              return NodesList(
                connectorName: connectorName,
                connector: appModel.connectors[connectorName],
              );
            },
          ),
        ),
        backgroundColor: const Color(0xFFF0F0F0),
        floatingActionButton: (Platform.isIOS || Platform.isAndroid)
            ? FloatingActionButton(
                onPressed: () => bleScanDialog(context, appModel),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Future<void> bleScanDialog(BuildContext context, AppModel appModel) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        var bleScanner = appModel.scanner!;
        bleScanner.clear();
        return SimpleDialog(
          title: const Text('Bluetooth Scan'),
          children: <Widget>[
            SizedBox(
              height: 200,
              width: 200,
              child: ChangeNotifierProvider<BleScanner>.value(
                value: bleScanner,
                child: Consumer<BleScanner>(
                  builder: (_, model, __) => ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: bleScanner.devices.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(bleScanner.devices[index].name),
                        subtitle: Text(bleScanner.devices[index].id),
                        onTap: () {
                          bleScanner.stopScanning();
                          var bleDevice = bleScanner.devices[index];
                          var bleClient = BleClient(appModel.ble!, bleDevice);
                          String connectorName =
                              'ble_${bleDevice.id.replaceAll(':', '')}';
                          appModel.addConnector(
                              connectorName, ConnectorModel(bleClient));
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Scan'),
                  onPressed: () => bleScanner.startScanning(),
                ),
                TextButton(
                    style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: const Text('Cancel'),
                    onPressed: () {
                      bleScanner.stopScanning();
                      Navigator.of(context).pop();
                    }),
              ],
            ),
          ],
        );
      },
    ).then(
      (value) {
        // make sure we stop scanning when the dialog is closed
        appModel.scanner?.stopScanning();
      },
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
                return const LinearProgressIndicator();
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
