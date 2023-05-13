// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mutex/mutex.dart';

import 'thingset.dart';

class WebSocketClient extends ThingSetClient {
  final String _baseUrl;
  Stream? _receiver;
  WebSocketSink? _sender;
  final _mutex = Mutex();

  WebSocketClient(this._baseUrl) : super('WebSocket');

  @override
  String get id => _baseUrl;

  @override
  Future<void> connect() async {
    final wsChannel = WebSocketChannel.connect(Uri.parse(_baseUrl));
    _receiver = wsChannel.stream.asBroadcastStream();
    _sender = wsChannel.sink;
  }

  @override
  Future<ThingSetResponse> request(String msg) async {
    if (_sender != null && _receiver != null) {
      await _mutex.acquire();
      _sender!.add(msg);
      try {
        var rxStream = _receiver!.timeout(
          const Duration(seconds: 2),
          onTimeout: (sink) => sink.close(), // close sink to stop for loop
        );
        await for (final value in rxStream) {
          final matches = RegExp(respRegExp).firstMatch(value.toString());
          if (matches != null && matches.groupCount == 2) {
            final status = matches[1];
            final jsonData = matches[2]!;
            _mutex.release();
            return ThingSetResponse(
                ThingSetStatusCode.fromString(status!), jsonData);
          }
        }
      } catch (error) {
        debugPrint('WebSocket error: $error');
      }
      _mutex.release();
    }
    return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
  }

  @override
  Future<void> disconnect() async {
    await _sender?.close();
  }
}
