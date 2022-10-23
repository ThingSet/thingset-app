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
    Provider.of<ConnectionsModel>(context, listen: false).add("test");
  }

  @override
  Widget build(BuildContext context) {
    var nodes = Provider.of<ConnectionsModel>(context).nodes;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Connected nodes:',
            ),
            Text(
              '$nodes',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
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
