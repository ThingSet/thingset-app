// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:mutex/mutex.dart';

import 'thingset.dart';

class SerialClient extends ThingSetClient {
  final String _portName;
  final SerialPort _port;
  final _responses = StreamController<ThingSetMessage>.broadcast();
  final _reports = StreamController<ThingSetMessage>.broadcast();
  StreamSubscription? _rxStreamSubscription;
  SerialPortReader? _serialPortReader;
  final _mutex = Mutex();
  bool _shellInterface;

  SerialClient(this._portName)
      : _port = SerialPort(_portName),
        _shellInterface = false,
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
        final rxDataStream = _serialPortReader!.stream.map((data) {
          return String.fromCharCodes(data);
        }).transform(const LineSplitter());

        _rxStreamSubscription = rxDataStream.listen((str) {
          // strip all color codes
          str = str.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
          debugPrint(str);

          // check if the Zephyr shell interface is used
          if (str.startsWith('uart:~\$')) {
            _shellInterface = true;
          }

          // check CRC
          if (str.endsWith('#') && str.length > 10) {
            var crcRx = int.parse(str.substring(str.length - 9, str.length - 1),
                radix: 16);
            str = str.substring(0, str.length - 10);
            var crcCalc = crc32(str);
            if (crcRx != crcCalc) {
              // discard invalid message and return timeout (instead of bad
              // request) so that the app will try again
              return;
            }
          }

          final msg = parseThingSetMessage(str);
          if (msg != null) {
            if (msg.function.isReport()) {
              _reports.add(msg);
            } else {
              _responses.add(msg);
            }
          }
        }, onError: (dynamic error) {
          debugPrint('Error: $error');
        });

        // send empty line to trigger response from shell (if used)
        _port.write(Uint8List.fromList('\n\n'.codeUnits), timeout: 100);
        await Future.delayed(const Duration(milliseconds: 200), () {});
      } else {
        debugPrint('Opening serial port $_portName failed');
      }
      _mutex.release();
    }
  }

  @override
  Future<ThingSetMessage> request(String msg) async {
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
          return ThingSetMessage(
            function: ThingSetFunctionCode.badRequest(),
            path: '',
            payload: '',
          );
        }
      }

      if (_shellInterface) {
        // quotation marks have to be escaped on the shell
        msg = msg.replaceAll('"', '\\"');
        // add thingset command prefix to the beginning of the message
        msg = 'thingset $msg';
      } else {
        // add CRC to the end of the message (not used for shell)
        int crc = crc32(msg);
        msg = '$msg ${crc.toRadixString(16).padLeft(8, '0').toUpperCase()}#';
      }

      await _mutex.acquire();
      debugPrint('request: $msg');
      _port.write(Uint8List.fromList('$msg\n'.codeUnits));
      try {
        var rxStream = _responses.stream.timeout(
          const Duration(seconds: 2),
          onTimeout: (sink) => sink.close(), // close sink to stop for loop
        );
        await for (var response in rxStream) {
          debugPrint('response: $response');
          _mutex.release();
          return response;
        }
      } catch (error) {
        debugPrint('Serial error: $error');
      }
      if (_mutex.isLocked) {
        _mutex.release();
      }
    }
    return ThingSetMessage(
      function: ThingSetFunctionCode.gatewayTimeout(),
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
