// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:rfc_6901/rfc_6901.dart';

import 'thingset.dart';

const demoNodeID = 'abcd1234';

var initialData = {
  'pNodeName': 'Smart Thermostat',
  'pNodeID': demoNodeID,
  'Sensor': {
    'rRoomTemp_degC': 19.1,
    'rHumidity_pct': 67,
  },
  'Control': {
    'rHeaterOn': false,
    'sTargetTemp_degC': 22.0,
  },
  'mLive': [
    'Sensor/rRoomTemp_degC',
    'Sensor/rHumidity_pct',
    'Control/rHeaterOn'
  ],
};

class DemoClient extends ThingSetClient {
  final _reports = StreamController<ThingSetMessage>.broadcast();
  StreamSubscription? _rxStreamSubscription;
  Map<String, Object> _data = initialData;

  DemoClient() : super('Demo Connector');

  @override
  String get id => 'demo';

  @override
  Future<void> connect() async {
    var rng = Random();
    if (_rxStreamSubscription != null) {
      return;
    }

    _rxStreamSubscription = Stream.periodic(const Duration(seconds: 1), (i) {
      // get references to device data
      var sensor = _data['Sensor'] as Map;
      var control = _data['Control'] as Map;
      var roomTemp = sensor['rRoomTemp_degC'] as double;
      var targetTemp = control['sTargetTemp_degC'] as double;

      // simulate simple thermostat behaviour
      roomTemp = roomTemp * 0.95 + (16 + rng.nextDouble() * 10) * 0.05;
      roomTemp = (roomTemp * 10).roundToDouble() / 10;
      bool heaterOn = roomTemp < targetTemp;

      // write back variables
      sensor['rRoomTemp_degC'] = roomTemp;
      control['rHeaterOn'] = heaterOn;

      // generate report
      return ThingSetMessage(
        function: ThingSetFunctionCode('#'.codeUnitAt(0)),
        path: 'mLive',
        payload: '{'
            '"Sensor":{'
            '"rRoomTemp_degC":${sensor['rRoomTemp_degC']},'
            '"rHumidity_pct":${sensor['rHumidity_pct']}'
            '},'
            '"Control":{"rHeaterOn":$heaterOn}'
            '}',
      );
    }).listen((msg) {
      _reports.add(msg);
    });
  }

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
  Future<void> disconnect() async {
    await _rxStreamSubscription?.cancel();
  }
}
