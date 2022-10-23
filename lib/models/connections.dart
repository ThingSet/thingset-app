import 'package:flutter/foundation.dart';

class ConnectionsModel extends ChangeNotifier {
  final List<String> _nodes = [];

  get nodes => _nodes;

  get count => _nodes.length;

  void add(String item) {
    _nodes.add(item);
    notifyListeners();
  }
}
