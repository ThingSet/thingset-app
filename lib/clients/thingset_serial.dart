// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:mutex/mutex.dart';

import 'thingset.dart';

class SerialClient extends ThingSetClient {
  final String _portName;
  SerialPort? _port;
  final _receiver = StreamController<String>.broadcast();
  Stream<String>? _rxDataStream;
  final _mutex = Mutex();

  SerialClient(this._portName) : super('Serial');

  @override
  String get id => _portName;

  @override
  Future<void> connect() async {
    if (SerialPort.availablePorts.contains(_portName)) {
      _port = SerialPort(_portName);
      _port!.openReadWrite();
      _port!.config.baudRate = 115200;

      SerialPortReader reader = SerialPortReader(_port!, timeout: 3000);
      _rxDataStream = reader.stream.map((data) {
        return String.fromCharCodes(data);
      }).transform(const LineSplitter());

      _rxDataStream!.listen((data) {
        _receiver.add(data);
      }, onError: (dynamic error) {
        debugPrint('Error: $error');
      });
    }
  }

  @override
  Future<ThingSetResponse> request(String msg) async {
    if (_port != null) {
      if (msg == '?/ null') {
        // only a single node can be connected at the moment, so we hack the
        // request to get the list of nodes
        msg = '? ["cNodeID"]';
      } else {
        var msgRel = reqRelativePath(msg);
        if (msgRel != null) {
          msg = msgRel;
        } else {
          return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
        }
      }

      await _mutex.acquire();
      debugPrint('request: $msg');
      _port!.write(Uint8List.fromList('$msg\n'.codeUnits));
      try {
        await for (final response
            in _receiver.stream.timeout(const Duration(seconds: 2))) {
          debugPrint('response: $response');
          // ToDo: Check if receiver stream has to be cancelled here
          final matches = RegExp(respRegExp).firstMatch(response.toString());
          if (matches != null && matches.groupCount == 2) {
            final status = matches[1];
            final jsonData = matches[2]!;
            _mutex.release();
            return ThingSetResponse(
                ThingSetStatusCode.fromString(status!), jsonData);
          }
        }
      } catch (error) {
        _mutex.release();
        return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
      }
      _mutex.release();
    }
    return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
  }

  @override
  Future<void> disconnect() async {
    _port?.close();
    _port?.dispose();
  }
}