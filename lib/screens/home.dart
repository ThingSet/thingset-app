import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/connections.dart';

class HomeScreen extends StatelessWidget {
  final String title = 'ThingSet App';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(child: NodesList()),
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
        return NodeItem(node: nodes[index]);
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}

class NodeItem extends StatelessWidget {
  final NodeConnection node;

  const NodeItem({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.go('/node/${node.nodeId}');
        },
        child: Container(
          height: 50,
          color: Colors.grey[300],
          child: Center(
            child: Text(
              node.nodeId + ' (' + node.client.type + ')',
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
