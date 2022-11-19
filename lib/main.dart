import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';

import 'models/connections.dart';
import 'theme.dart';

const double windowWidth = 500;
const double windowHeight = 800;

void main() {
  setupWindow();
  runApp(const ThingSetApp());
}

void setupWindow() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('ThingSet App');
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));
    getCurrentScreen().then((screen) {
      setWindowFrame(Rect.fromCenter(
        center: screen!.frame.center,
        width: windowWidth,
        height: windowHeight,
      ));
    });
  }
}

class ThingSetApp extends StatelessWidget {
  const ThingSetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => ConnectionsModel(),
        child: MaterialApp(
          title: 'ThingSet App',
          theme: theme,
          home: const MyHomePage(title: 'ThingSet App'),
        ));
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  void addNode(BuildContext context) {
    Provider.of<ConnectionsModel>(context, listen: false).add('test');
  }

  @override
  Widget build(BuildContext context) {
    var nodes = Provider.of<ConnectionsModel>(context).nodes;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(child: NodesList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addNode(context);
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NodesList extends StatelessWidget {
  const NodesList({super.key});

  @override
  Widget build(BuildContext context) {
    var nodes = Provider.of<ConnectionsModel>(context).nodes;
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: nodes.length,
      itemBuilder: (BuildContext context, int index) {
        return NodeItem(
            label:
                nodes[index].nodeId + ' (' + nodes[index].connector.type + ')');
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}

class NodeItem extends StatelessWidget {
  final String label;

  const NodeItem({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          print('pressed');
        },
        child: Container(
          height: 50,
          color: Colors.grey[300],
          child: Center(
            child: Text(
              label,
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
