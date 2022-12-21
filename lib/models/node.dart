import 'package:flutter/foundation.dart';

class NodeModel extends ChangeNotifier {
  final Map<String, dynamic> _desired = {};
  final Map<String, dynamic> _reported = {};

  get desired => _desired;

  get reported => _reported;

  void mergeReported(dynamic data) {
    // ToDo: Proper implementation
    _reported['test'] = data;
  }
}
