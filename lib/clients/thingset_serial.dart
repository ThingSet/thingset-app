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
  final SerialPort _port;
  final _receiver = StreamController<String>.broadcast();
  Stream<String>? _rxDataStream;
  SerialPortReader? _serialPortReader;
  final _mutex = Mutex();

  SerialClient(this._portName)
      : _port = SerialPort(_portName),
        super('Serial');

  @override
  String get id => _portName;

  @override
  Future<void> connect() async {
    if (!_port.isOpen) {
      await _mutex.acquire();
      if (_port.openReadWrite()) {
        _port.config.baudRate = 115200;
        _port.config.bits = 8;
        _port.config.parity = 0;
        _port.config.stopBits = 1;

        _serialPortReader = SerialPortReader(_port, timeout: 3000);
        _rxDataStream = _serialPortReader!.stream.map((data) {
          return String.fromCharCodes(data);
        }).transform(const LineSplitter());

        _rxDataStream!.listen((data) {
          _receiver.add(data);
        }, onError: (dynamic error) {
          debugPrint('Error: $error');
        });
      } else {
        debugPrint('Opening serial port $_portName failed');
      }
      _mutex.release();
    }
  }

  @override
  Future<ThingSetResponse> request(String msg) async {
    if (_port.isOpen) {
      if (msg == '?/ null') {
        // only a single node can be connected at the moment, so we hack the
        // request to get the list of nodes
        msg = '? ["pNodeID"]';
      } else {
        var msgRel = reqRelativePath(msg);
        if (msgRel != null) {
          msg = msgRel;
        } else {
          return ThingSetResponse(ThingSetStatusCode.badRequest(), '');
        }
      }

      // add CRC to message
      int crc = crc32(msg);
      msg = '$msg ${crc.toRadixString(16).padLeft(8, '0').toUpperCase()}#';

      await _mutex.acquire();
      debugPrint('request: $msg');
      _port.write(Uint8List.fromList('$msg\n'.codeUnits));
      try {
        var rxStream = _receiver.stream.timeout(
          const Duration(seconds: 2),
          onTimeout: (sink) => sink.close(), // close sink to stop for loop
        );
        await for (var response in rxStream) {
          debugPrint('response: $response');

          // check CRC
          if (response.endsWith('#') && response.length > 10) {
            var crcRx = int.parse(
                response.substring(response.length - 9, response.length - 1),
                radix: 16);
            response = response.substring(0, response.length - 10);
            var crcCalc = crc32(response);
            if (crcRx != crcCalc) {
              // discard invalid message and return timeout (instead of bad
              // request) so that the app will try again
              _mutex.release();
              return ThingSetResponse(ThingSetStatusCode.gatewayTimeout(), '');
            }
          }

          final matches = RegExp(respRegExp).firstMatch(response.toString());
          if (matches != null && matches.groupCount == 2) {
            final status = ThingSetStatusCode.fromString(matches[1]!);
            final jsonData = matches[2]!;
            _mutex.release();
            return ThingSetResponse(status, jsonData);
          }
        }
      } catch (error) {
        debugPrint('Serial error: $error');
      }
      _mutex.release();
    }
    return ThingSetResponse(ThingSetStatusCode.gatewayTimeout(), '');
  }

  @override
  Future<void> disconnect() async {
    _serialPortReader?.close();
    _port.flush();
    _port.close();
  }

  // implementation from Zephyr RTOS file zephyr/lib/os/crc32_sw.c
  int crc32(String data) {
    // crc table generated from polynomial 0xedb88320
    const table = [
      0x00000000,
      0x1db71064,
      0x3b6e20c8,
      0x26d930ac,
      0x76dc4190,
      0x6b6b51f4,
      0x4db26158,
      0x5005713c,
      0xedb88320,
      0xf00f9344,
      0xd6d6a3e8,
      0xcb61b38c,
      0x9b64c2b0,
      0x86d3d2d4,
      0xa00ae278,
      0xbdbdf21c,
    ];

    var crc = 0xFFFFFFFF;

    for (var byte in utf8.encode(data)) {
      crc = (crc >> 4) ^ table[(crc ^ byte) & 0x0f];
      crc = (crc >> 4) ^ table[(crc ^ (byte >> 4)) & 0x0f];
    }

    return (~crc).toUnsigned(32);
  }
}
