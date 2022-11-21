import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';

class NodeScreen extends StatelessWidget {
  final String connectorName;
  final String nodeId;

  const NodeScreen(
      {super.key, required this.connectorName, required this.nodeId});

  @override
  Widget build(BuildContext context) {
    var conn = Provider.of<AppModel>(context).connector(connectorName);
    return Scaffold(
      appBar: AppBar(
        title: Text(nodeId),
      ),
      body: const Center(child: Text('Node Screen')),
    );
  }
}
