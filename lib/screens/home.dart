import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/connections.dart';

class HomeScreen extends StatelessWidget {
  final String title = 'ThingSet App';

  const HomeScreen({super.key});

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
          context.go('/node');
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
