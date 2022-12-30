import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mutex/mutex.dart';

import 'thingset.dart';

Uuid uuidThingSetService = Uuid.parse('00000001-5a19-4887-9c6a-14ad27bfc06d');
Uuid uuidThingSetRequest = Uuid.parse('00000002-5a19-4887-9c6a-14ad27bfc06d');
Uuid uuidThingSetResponse = Uuid.parse('00000003-5a19-4887-9c6a-14ad27bfc06d');

class BleClient extends ThingSetClient {
  final FlutterReactiveBle ble;
  final DiscoveredDevice device;
  final mutex = Mutex();
  Stream? connectionStream;
  StreamSubscription? connection;

  BleClient(this.ble, this.device) : super('Bluetooth');

  @override
  Future<void> connect() async {
    debugPrint('Trying to connect...');

    try {
      connectionStream = ble.connectToAdvertisingDevice(
        id: device.id,
        prescanDuration: const Duration(seconds: 2),
        withServices: [uuidThingSetService],
        connectionTimeout: const Duration(seconds: 3),
      );
    } catch (error) {
      debugPrint('connect error: ${error.toString()}');
    }

    try {
      connection = connectionStream?.listen((event) {
        var id = event.deviceId.toString();
        switch (event.connectionState) {
          case DeviceConnectionState.connecting:
            debugPrint('Connecting to $id');
            break;
          case DeviceConnectionState.connected:
            debugPrint('Connected to $id');
            break;
          case DeviceConnectionState.disconnecting:
            debugPrint('Disconnecting from $id');
            break;
          case DeviceConnectionState.disconnected:
            debugPrint('Disconnected from $id');
            break;
        }
      });
    } catch (error) {
      debugPrint('listen error: ${error.toString()}');
    }
  }

  @override
  Future<ThingSetResponse> request(String msg) async {
    if (msg == '?//') {
      return ThingSetResponse(
          ThingSetStatusCode.content(), '["${device.id.replaceAll(':', '')}"]');
    } else {
      // convert ThingSet request into request with relative path
      final matches = RegExp(reqRegExp).firstMatch(msg);
      if (matches != null && matches.groupCount >= 3) {
        final type = matches[1]!;
        final absPath = matches[2]!;
        final data = matches[3]!;
        final chunks = absPath.split('/');
        if (chunks.length > 1) {
          String nodeId = chunks[1];
          String relPath = chunks.length > 2 ? chunks[2] : '';
          if (nodeId == device.id.replaceAll(':', '')) {
            await mutex.acquire();
            debugPrint('request: $type$relPath $data');
            // ToDo: send '$type$relPath $data'
            // ToDo: wait for response
            mutex.release();
            // ToDo: return response
          }
        }
      }
    }
    return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
  }

  @override
  Future<void> disconnect() async {
    throw Exception('Client not connected');
  }
}
