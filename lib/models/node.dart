// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';

class NodeModel extends ChangeNotifier {
  String name = 'ThingSet Node';
  final Map<String, dynamic> _desired = {};
  final Map<String, dynamic> _reported = {};
  final Map<String, List<FlSpot>> _timeseries = {};
  final List<String> _selectedSeries = [];
  // set the timestamp of the last full hour as the starting value
  final _startTime =
      (DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ 3600 * 3600).toDouble();
  final String _nodeId;

  Map<String, dynamic> get desired => _desired;

  Map<String, dynamic> get reported => _reported;

  Map<String, List<FlSpot>> get timeseries => _timeseries;

  List<String> get selectedSeries => _selectedSeries;

  double get startTime => _startTime;

  String get id => _nodeId;

  NodeModel(this._nodeId);

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

    // only return true if an item (not a group) at this level has been changed
    for (final item in obj.keys) {
      if (obj[item] is! Map) {
        return true;
      }
    }

    return false;
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

  void _addTimeSeriesData(String name, double time, dynamic jsonValue) {
    double value;
    if (jsonValue is num) {
      value = jsonValue.toDouble();
    } else if (jsonValue is bool) {
      value = jsonValue ? 1 : 0;
    } else {
      return;
    }

    if (!_timeseries.containsKey(name)) {
      _timeseries[name] = [];
    }
    _timeseries[name]!.add(FlSpot(time - _startTime, value));
    if (_timeseries[name]!.length > 300) {
      _timeseries[name]!.removeAt(0);
    }
  }

  void storeReport(String path, String payload) {
    // set path to empty string if subset was reported
    path = (path.isNotEmpty && path[0].toUpperCase() == path[0]) ? path : '';
    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(payload);
    } catch (e) {
      debugPrint('failed to parse report payload: $payload');
      return;
    }

    mergeReported(path, obj);

    // add path as prefix
    String prefix = path.isNotEmpty ? '$path/' : '';
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    for (final key1 in obj.keys) {
      if (obj[key1] is Map) {
        /* supporting max. depth of 2 for now */
        for (final key2 in obj[key1].keys) {
          _addTimeSeriesData('$prefix$key1/$key2', time, obj[key1][key2]);
        }
      } else {
        _addTimeSeriesData('$prefix$key1', time, obj[key1]);
      }
    }
    notifyListeners();
  }

  dynamic getReported(String path) {
    dynamic obj = _reported;
    if (path.isNotEmpty) {
      for (final chunk in path.split('/')) {
        if (obj is Map && obj.containsKey(chunk)) {
          obj = obj[chunk];
        } else {
          return null;
        }
      }
    }
    return obj;
  }

  bool hasReportingSetup(String path) {
    path = '_Reporting/$path';
    bool ret = true;
    Map<String, dynamic> obj = _reported;
    if (path.isEmpty) {
      return false;
    } else {
      for (final chunk in path.split('/')) {
        if (obj.containsKey(chunk)) {
          if (obj[chunk] is Map && obj[chunk].isNotEmpty) {
            obj = obj[chunk];
          }
        } else {
          ret = false;
        }
      }
    }
    return ret;
  }

  void setDesired(String path, dynamic jsonData) {
    Map<String, dynamic> obj = _desired;
    if (path.isNotEmpty) {
      var chunks = path.split('/');
      for (final chunk in chunks) {
        if (chunk == chunks.last && chunk[0].toLowerCase() == chunk[0]) {
          obj[chunk] = jsonData;
          break;
        } else if (!obj.containsKey(chunk) || obj[chunk] == null) {
          Map<String, dynamic> newMap = {};
          obj[chunk] = newMap;
        }
        obj = obj[chunk];
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
