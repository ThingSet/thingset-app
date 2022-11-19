import 'package:flutter/material.dart';

class NodeScreen extends StatelessWidget {
  final String nodeId;

  const NodeScreen({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nodeId),
      ),
      body: const Center(child: Text('Node Screen')),
    );
  }
}
