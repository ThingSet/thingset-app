// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rfc_6901/rfc_6901.dart';

import 'thingset.dart';

const demoNodeID = 'abcd1234';

const initialData = {
  'pNodeName': 'Smart Thermostat Demo',
  'pNodeID': demoNodeID,
  'Sensor': {
    'rRoomTemp_degC': 19.1,
    'rHumidity_pct': 67,
  },
  'Control': {
    'rHeaterOn': false,
    'sTargetTemp_degC': 22.0,
  }
};

class DemoClient extends ThingSetClient {
  final _reports = StreamController<ThingSetMessage>.broadcast();
  var _data = initialData;

  DemoClient() : super('Demo Connector');

  @override
  String get id => 'demo';

  @override
  Future<void> connect() async {}

  @override
  Future<ThingSetMessage> request(String msg) async {
    ThingSetMessage? req = parseThingSetMessage(msg);
    if (req != null) {
      if (req.function.asInt() == '?'.codeUnitAt(0)) {
        if (req.path == '/' && req.payload == 'null') {
          return ThingSetMessage(
            function: ThingSetFunctionCode.content(),
            path: '',
            payload: '["$demoNodeID"]',
          );
        } else {
          final pointer =
              JsonPointer(req.relPath.isEmpty ? '' : '/${req.relPath}');
          try {
            final payload = pointer.read(_data);
            return ThingSetMessage(
              function: ThingSetFunctionCode.content(),
              path: '',
              payload: jsonEncode(payload),
            );
          } catch (e) {
            return ThingSetMessage(
              function: ThingSetFunctionCode.notFound(),
              path: '',
              payload: '',
            );
          }
        }
      } else if (req.function.asInt() == '='.codeUnitAt(0)) {
        try {
          var payload =
              Map<String, Object>.from(jsonDecode(req.payload) as Map);
          payload.forEach((key, value) {
            final path = req.relPath.isEmpty ? '' : '/${req.relPath}';
            final pointer = JsonPointer('$path/$key');
            Object newData = pointer.write(_data, value)!;
            _data = Map<String, Object>.from(newData as Map);
          });
          return ThingSetMessage(
            function: ThingSetFunctionCode.changed(),
            path: '',
            payload: '',
          );
        } catch (e) {
          return ThingSetMessage(
            function: ThingSetFunctionCode.notFound(),
            path: '',
            payload: '',
          );
        }
      }
      debugPrint('Unsupported ThingSetMessage: $req');
    }

    return ThingSetMessage(
      function: ThingSetFunctionCode.badRequest(),
      path: '',
      payload: '',
    );
  }

  @override
  Stream<ThingSetMessage> reports() {
    return _reports.stream;
  }

  @override
  Future<void> disconnect() async {}
}
