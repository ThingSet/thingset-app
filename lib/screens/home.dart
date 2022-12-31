import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../clients/thingset_ble.dart';
import '../models/app.dart';
import '../models/ble_scanner.dart';
import '../models/connector.dart';

class HomeScreen extends StatelessWidget {
  final String _title = 'ThingSet App';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) => Scaffold(
        appBar: AppBar(
          title: Center(child: Text(_title)),
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
                onPressed: () => _bleScanDialog(context, appModel),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Future<void> _bleScanDialog(BuildContext context, AppModel appModel) {
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
  final String _connectorName;
  final ConnectorModel _connector;

  const NodesList(
      {super.key, required connectorName, required connector})
      : _connectorName = connectorName,
        _connector = connector;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConnectorModel>(
      create: (_) => _connector,
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
                  itemBuilder: (context, index) {
                    var nodeId = model.nodeIds[index];
                    return Card(
                      child: ListTile(
                        title: Text(model.nodes[nodeId].name),
                        subtitle: Text(nodeId),
                        onTap: () {
                          context.go('/$_connectorName/$nodeId');
                        },
                      ),
                    );
                  },
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
