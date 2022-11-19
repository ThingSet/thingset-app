import 'package:flutter/material.dart';

class NodeScreen extends StatelessWidget {
  final String title = "Node XYZ";

  const NodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(child: Text('Node Screen')),
    );
  }
}
