import 'package:flutter/foundation.dart';

class NodeModel extends ChangeNotifier {
  String nodeName = 'ThingSet Node';
  final Map<String, dynamic> _desired = {};
  final Map<String, dynamic> _reported = {};

  get desired => _desired;

  get reported => _reported;

  String get name => nodeName;

  set name(String name) {
    nodeName = name;
  }

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
    notifyListeners();
  }

  void setDesired(String path, dynamic jsonData) {
    Map<String, dynamic> obj = _desired;
    if (path.isNotEmpty) {
      for (final chunk in path.split('/')) {
        if (chunk[0].toLowerCase() == chunk[0]) {
          obj[chunk] = jsonData;
          break;
        } else if (!obj.containsKey(chunk) || obj[chunk] == null) {
          Map<String, dynamic> newMap = {};
          obj[chunk] = newMap;
          obj = obj[chunk];
        } else {
          obj = obj[chunk];
        }
      }
    }
  }
}
