// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../clients/thingset_ble.dart';
import '../models/app.dart';
import '../models/connector.dart';
import '../widgets/stateful_input.dart';

class HomeScreen extends StatelessWidget {
  final String _title = 'ThingSet App';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        drawer: NavigationDrawer(
          children: [
            DrawerHeader(
              child: Image.asset('web/icons/Icon-192.png', width: 50),
            ),
            ListTile(
              leading: const Icon(
                Icons.home,
              ),
              title: const Text('Home Screen'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(_connectorIcon('Demo Connector')),
              title: const Text('Create Demo'),
              onTap: () {
                appModel.addDemoConnector();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.web,
              ),
              title: const Text('Website'),
              onTap: () {
                launchUrlString(
                  'https://thingset.io',
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final PackageInfo? packageInfo = snapshot.data;
                  return AboutListTile(
                    icon: const Icon(
                      Icons.info,
                    ),
                    applicationIcon:
                        Image.asset('web/icons/Icon-192.png', width: 50),
                    applicationName: 'ThingSet App',
                    applicationVersion: packageInfo?.version ?? '',
                    aboutBoxChildren: [
                      ListTile(
                        title: const Text('Privacy Policy'),
                        onTap: () {
                          launchUrlString(
                            'https://thingset.io/app-privacy-policy.html',
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Imprint'),
                        onTap: () {
                          launchUrlString(
                            'https://thingset.io/contact.html',
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                    child: const Text('About'),
                  );
                }
                return const LinearProgressIndicator();
              },
            ),
          ],
        ),
        body: Center(
          child: ListView.builder(
            itemCount: appModel.connectors.length,
            itemBuilder: (BuildContext context, int index) {
              String connectorName = appModel.connectors.keys.elementAt(index);
              ConnectorModel connector = appModel.connectors[connectorName]!;
              return Card(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Icon(
                            _connectorIcon(connector.clientType),
                            color: Colors.grey,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connector.clientType,
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              connector.clientId,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      ]),
                      IconButton(
                        onPressed: () {
                          appModel.deleteConnector(connectorName);
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.grey,
                        ),
                      )
                    ],
                  ),
                  NodesList(
                    connectorName: connectorName,
                    connector: connector,
                  ),
                ]),
              );
            },
          ),
        ),
        backgroundColor: const Color(0xFFF0F0F0),
        floatingActionButton: SpeedDial(
          children: [
            SpeedDialChild(
              child: Icon(_connectorIcon('WebSocket')),
              label: 'WebSocket',
              onTap: () => _webSocketDialog(context, appModel),
            ),
            if (Platform.isIOS || Platform.isAndroid)
              SpeedDialChild(
                child: Icon(_connectorIcon('Bluetooth')),
                label: 'Bluetooth',
                onTap: () => _bleScanDialog(context, appModel),
              )
            else if (!Platform.isAndroid)
              // Serial not working in Android because of permission issues
              // https://github.com/jpnurmi/flutter_libserialport/issues/26
              SpeedDialChild(
                child: Icon(_connectorIcon('Serial')),
                label: 'Serial',
                onTap: () => _serialScanDialog(context, appModel),
              )
          ],
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  IconData _connectorIcon(String clientType) {
    switch (clientType) {
      case 'Bluetooth':
        return Icons.bluetooth;
      case 'Demo Connector':
        return Icons.play_circle;
      case 'Serial':
        return Icons.terminal;
      case 'WebSocket':
        return Icons.cloud_outlined;
      default:
        return Icons.circle;
    }
  }

  Future<void> _webSocketDialog(BuildContext context, AppModel appModel) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        String uri = 'wss://user:password@host:port/app';
        return SimpleDialog(
          title: const Text('Connect WebSocket'),
          children: <Widget>[
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('WebSocket URL:'),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  // ToDo: create custom input field
                  child: StatefulTextField(
                    value: uri,
                    unit: '',
                    onChanged: (value) {
                      uri = value;
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Add'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await appModel.addWebSocketConnector(uri);
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

  Future<void> _serialScanDialog(BuildContext context, AppModel appModel) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        var serialPorts = SerialPort.availablePorts;
        return SimpleDialog(
          title: const Text('Add Serial'),
          children: <Widget>[
            SizedBox(
              height: 200,
              width: 200,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: serialPorts.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(serialPorts[index]),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await appModel.addSerialConnector(serialPorts[index]);
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

  Future<void> _bleScanDialog(BuildContext context, AppModel appModel) {
    var ble = FlutterReactiveBle();
    var bleScanner = BleScanner(ble);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
                        onTap: () async {
                          bleScanner.stopScanning();
                          Navigator.of(context).pop();
                          await appModel
                              .addBleConnector(bleScanner.devices[index].id);
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
        bleScanner.stopScanning();
      },
    );
  }
}

class NodesList extends StatelessWidget {
  final String _connectorName;
  final ConnectorModel _connector;

  const NodesList({super.key, required connectorName, required connector})
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
                  padding: const EdgeInsets.all(5),
                  itemCount: model.nodeIds.length,
                  itemBuilder: (context, index) {
                    var nodeId = model.nodeIds[index];
                    return ListTile(
                      title: Text(model.nodes[nodeId]!.name),
                      subtitle: Text(nodeId),
                      onTap: () {
                        context.go('/$_connectorName/$nodeId');
                      },
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
