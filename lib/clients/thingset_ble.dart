import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mutex/mutex.dart';

import 'thingset.dart';

final Uuid uuidThingSetService =
    Uuid.parse('00000001-5a19-4887-9c6a-14ad27bfc06d');
final Uuid uuidThingSetRequest =
    Uuid.parse('00000002-5a19-4887-9c6a-14ad27bfc06d');
final Uuid uuidThingSetResponse =
    Uuid.parse('00000003-5a19-4887-9c6a-14ad27bfc06d');

// SLIP protocol (RFC 1055) special characters
const slipEnd = 0xC0;
const slipEsc = 0xDB;
const slipEscEnd = 0xDC;
const slipEscEsc = 0xDD;

class BleClient extends ThingSetClient {
  final FlutterReactiveBle _ble;
  final DiscoveredDevice _device;
  final _mutex = Mutex();
  Stream? _connectionStream;
  StreamSubscription? _connection;
  QualifiedCharacteristic? _reqCharacteristic;
  QualifiedCharacteristic? _respCharacteristic;
  Stream? _respDataStream;
  bool _connected = false;
  String _response = '';
  final _receiver = StreamController<String>.broadcast();

  BleClient(this._ble, this._device) : super('Bluetooth');

  @override
  String get id => _device.id.toString();

  void _processReceivedData(List<int> data) {
    for (final byte in data) {
      if (byte == slipEnd) {
        if (_response.isNotEmpty) {
          _receiver.add(_response);
          debugPrint('response: $_response');
          _response = '';
        } // else: ignore character
      } else {
        _response += String.fromCharCode(byte);
      }
    }
  }

  @override
  Future<void> connect() async {
    if (_connected) {
      return;
    }

    debugPrint('Trying to connect...');
    final completer = Completer<void>();

    try {
      _connectionStream = _ble.connectToAdvertisingDevice(
        id: _device.id,
        prescanDuration: const Duration(seconds: 2),
        withServices: [uuidThingSetService],
        connectionTimeout: const Duration(seconds: 3),
      );
    } catch (error) {
      debugPrint('connect error: ${error.toString()}');
      completer.completeError(error);
    }

    try {
      _connection = _connectionStream?.listen((event) {
        var id = event.deviceId.toString();
        switch (event.connectionState) {
          case DeviceConnectionState.connecting:
            debugPrint('Connecting to $id');
            break;
          case DeviceConnectionState.connected:
            debugPrint('Connected to $id');

            _respCharacteristic = QualifiedCharacteristic(
                serviceId: uuidThingSetService,
                characteristicId: uuidThingSetResponse,
                deviceId: event.deviceId);

            _respDataStream =
                _ble.subscribeToCharacteristic(_respCharacteristic!);
            _respDataStream!.listen((data) {
              _processReceivedData(data);
            }, onError: (dynamic error) {
              debugPrint('Error: $error');
            });

            _reqCharacteristic = QualifiedCharacteristic(
                serviceId: uuidThingSetService,
                characteristicId: uuidThingSetRequest,
                deviceId: event.deviceId);

            _connected = true;
            completer.complete();
            break;
          case DeviceConnectionState.disconnecting:
            debugPrint('Disconnecting from $id');
            break;
          case DeviceConnectionState.disconnected:
            debugPrint('Disconnected from $id');
            _connected = false;
            break;
        }
      });

      await completer.future;
    } catch (error) {
      debugPrint('listen error: ${error.toString()}');
      completer.completeError(error);
    }
  }

  @override
  Future<ThingSetResponse> request(String msg) async {
    if (_connected) {
      if (msg == '?//') {
        // only a single node can be connected at the moment, so we hack the
        // request to get the list of nodes
        msg = '?/unknown ["cNodeID"]';
      }

      // convert ThingSet request into request with relative path
      final matches = RegExp(reqRegExp).firstMatch(msg);
      if (matches != null && matches.groupCount >= 3) {
        final type = matches[1]!;
        final absPath = matches[2]!;
        final data = matches[3]!;
        final chunks = absPath.split('/');
        if (chunks.length > 1) {
          // nodeId in chunks[1] currently ignored
          String relPath = chunks.length > 2 ? chunks[2] : '';

          await _mutex.acquire();
          debugPrint('request: $type$relPath $data');

          // assuming that requests are small enough to fit into one message
          List<int> encodedData = [
            slipEnd,
            ...utf8.encode('$type$relPath $data'),
            slipEnd
          ];
          await _ble.writeCharacteristicWithoutResponse(_reqCharacteristic!,
              value: encodedData);

          try {
            await for (final value
                in _receiver.stream.timeout(const Duration(seconds: 2))) {
              // ToDo: Check if receiver stream has to be cancelled here
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
            _mutex.release();
            return ThingSetResponse(
                ThingSetStatusCode.serviceUnavailable(), '');
          }
          _mutex.release();

        }
      }
    }
    return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
  }

  @override
  Future<void> disconnect() async {
    await _connection?.cancel();
    _connected = false;
  }
}
