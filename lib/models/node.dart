// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/foundation.dart';

class NodeModel extends ChangeNotifier {
  String name = 'ThingSet Node';
  final Map<String, dynamic> _desired = {};
  final Map<String, dynamic> _reported = {};

  Map<String, dynamic> get desired => _desired;

  Map<String, dynamic> get reported => _reported;

  bool hasDesiredChanged(String path) {
    Map<String, dynamic> obj = _desired;
    if (path.isNotEmpty) {
      for (final chunk in path.split('/')) {
        if (obj.containsKey(chunk) &&
            obj[chunk] is Map &&
            obj[chunk].isNotEmpty) {
          obj = obj[chunk];
        } else {
          return false;
        }
      }
    }
    return true;
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
    notifyListeners();
  }

  Map<String, dynamic> getDesired(String path) {
    Map<String, dynamic> obj = _desired;
    if (path.isNotEmpty) {
      for (final chunk in path.split('/')) {
        if (obj.containsKey(chunk)) {
          obj = obj[chunk];
        } else {
          return {};
        }
      }
    }
    return obj;
  }

  void clearReported(String path) {
    Map<String, dynamic> obj = _reported;
    if (path.isNotEmpty) {
      for (final chunk in path.split('/')) {
        if (obj.containsKey(chunk) &&
            obj[chunk] is Map &&
            obj[chunk].isNotEmpty) {
          obj = obj[chunk];
        } else {
          // the path is already empty
          return;
        }
      }
    }
    obj.clear();
    notifyListeners();
  }

  void clearDesired(String path) {
    Map<String, dynamic> obj = _desired;
    if (path.isNotEmpty) {
      for (final chunk in path.split('/')) {
        if (obj.containsKey(chunk) &&
            obj[chunk] is Map &&
            obj[chunk].isNotEmpty) {
          obj = obj[chunk];
        } else {
          // the path is already empty
          return;
        }
      }
    }
    obj.clear();
    notifyListeners();
  }
}
