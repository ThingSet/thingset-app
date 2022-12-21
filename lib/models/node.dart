import 'package:flutter/foundation.dart';

class NodeModel extends ChangeNotifier {
  final Map<String, dynamic> _desired = {};
  final Map<String, dynamic> _reported = {};

  get desired => _desired;

  get reported => _reported;

  void mergeReported(String path, dynamic jsonData) {
    Map<String, dynamic> obj = _reported;
    if (path.isNotEmpty) {
      for (final chunk in path.split('/')) {
        if (!obj.containsKey(chunk) || obj[chunk] == null) {
          Map<String, dynamic> newMap = {};
          obj[chunk] = newMap;
        }
        obj = obj[chunk];
      }
    }
    obj.addAll(jsonData);
  }
}
