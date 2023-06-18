// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mutex/mutex.dart';

import 'thingset.dart';

class WebSocketClient extends ThingSetClient {
  final String _baseUrl;
  StreamSubscription? _rxStreamSubscription;
  final _responses = StreamController<ThingSetMessage>.broadcast();
  final _reports = StreamController<ThingSetMessage>.broadcast();
  WebSocketSink? _sender;
  final _mutex = Mutex();

  WebSocketClient(this._baseUrl) : super('WebSocket');

  @override
  String get id => _baseUrl;

  @override
  Future<void> connect() async {
    await _mutex.acquire();
    if (_sender == null) {
      // workaround for uncaught exception in web_socket_channel v2.4
      // see: https://github.com/dart-lang/web_socket_channel/issues/249
      try {
        await WebSocket.connect(_baseUrl).then((ws) {
          final wsChannel = IOWebSocketChannel(ws);
          final rxDataStream = wsChannel.stream.asBroadcastStream();
          _rxStreamSubscription = rxDataStream.listen((str) {
            final msg = parseThingSetMessage(str);
            if (msg != null) {
              if (msg.function.isReport()) {
                _reports.add(msg);
              } else {
                _responses.add(msg);
              }
            }
          });
          _sender = wsChannel.sink;
        });
      } catch (e) {
        debugPrint('WebSocket Error $e');
      }
    }
    _mutex.release();
  }

  @override
  Future<ThingSetMessage> request(String msg) async {
    if (_sender != null) {
      await _mutex.acquire();
      _sender!.add(msg);
      try {
        var rxStream = _responses.stream.timeout(
          const Duration(seconds: 2),
          onTimeout: (sink) => sink.close(), // close sink to stop for loop
        );
        await for (final response in rxStream) {
          debugPrint('response: $response');
          _mutex.release();
          return response;
        }
      } catch (error) {
        debugPrint('WebSocket error: $error');
      }
      _mutex.release();
    }
    return ThingSetMessage(ThingSetFunctionCode.gatewayTimeout(), '', '');
  }

  @override
  Stream<ThingSetMessage> reports() {
    return _reports.stream;
  }

  @override
  Future<void> disconnect() async {
    await _rxStreamSubscription?.cancel();
    await _sender?.close();
  }
}
