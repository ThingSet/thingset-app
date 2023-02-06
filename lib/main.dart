// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';

import 'models/app.dart';
import 'screens/home.dart';
import 'screens/node.dart';
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

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: ':conn/:id',
          builder: (context, state) => NodeScreen(
            connectorName: state.params['conn']!,
            nodeId: state.params['id']!,
          ),
        ),
      ],
    ),
  ],
);

class ThingSetApp extends StatelessWidget {
  const ThingSetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => AppModel(),
        child: MaterialApp.router(
          title: 'ThingSet App',
          theme: theme,
          routerConfig: _router,
        ));
  }
}
