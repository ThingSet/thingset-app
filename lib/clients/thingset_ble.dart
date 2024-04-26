// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mutex/mutex.dart';
import 'package:permission_handler/permission_handler.dart';

import 'thingset.dart';

final Uuid uuidThingSetService =
    Uuid.parse('00000001-5423-4887-9c6a-14ad27bfc06d');
final Uuid uuidThingSetDownlink =
    Uuid.parse('00000002-5423-4887-9c6a-14ad27bfc06d');
final Uuid uuidThingSetUplink =
    Uuid.parse('00000003-5423-4887-9c6a-14ad27bfc06d');

// currently only supporting text mode, so not all of the values below are used
const msgEnd = 0x0A;
const msgSkip = 0x0D;
const msgEsc = 0xCE;
const msgEscEnd = 0xCA;
const msgEscSkip = 0xCD;
const msgEscEsc = 0xCF;

class BleClient extends ThingSetClient {
  final FlutterReactiveBle _ble;
  final String _deviceId;
  final _mutex = Mutex();
  Stream? _connectionStream;
  StreamSubscription? _connection;
  QualifiedCharacteristic? _reqCharacteristic;
  QualifiedCharacteristic? _respCharacteristic;
  StreamSubscription? _rxStreamSubscription;
  bool _connected = false;
  String _message = '';
  final _responses = StreamController<ThingSetMessage>.broadcast();
  final _reports = StreamController<ThingSetMessage>.broadcast();
  int _mtu = 20;

  BleClient(this._deviceId)
      : _ble = FlutterReactiveBle(),
        super('Bluetooth');

  @override
  String get id => _deviceId;

  void _processReceivedData(List<int> data) {
    for (final byte in data) {
      if (byte == msgSkip) {
        // ignore skip character
      } else if (byte == msgEnd) {
        if (_message.isNotEmpty) {
          final msg = parseThingSetMessage(_message);
          if (msg != null) {
            if (msg.function.isReport()) {
              _reports.add(msg);
            } else {
              _responses.add(msg);
            }
          }
          _message = '';
        } // else: ignore empty packet
      } else {
        _message += String.fromCharCode(byte);
      }
    }
  }

  @override
  Future<void> connect() async {
    if (_connected) {
      return;
    }

    await _mutex.acquire();

    debugPrint('Trying to connect...');
    final completer = Completer<void>();

    try {
      _connectionStream = _ble.connectToAdvertisingDevice(
        id: _deviceId,
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
                characteristicId: uuidThingSetUplink,
                deviceId: event.deviceId);

            var respDataStream =
                _ble.subscribeToCharacteristic(_respCharacteristic!);
            _rxStreamSubscription = respDataStream.listen((data) {
              _processReceivedData(data);
            }, onError: (dynamic error) {
              debugPrint('Error: $error');
            });

            _reqCharacteristic = QualifiedCharacteristic(
                serviceId: uuidThingSetService,
                characteristicId: uuidThingSetDownlink,
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

      _mtu = await _ble.requestMtu(deviceId: _deviceId, mtu: 250);
    } catch (error) {
      debugPrint('listen error: ${error.toString()}');
      completer.completeError(error);
    }
    _mutex.release();
  }

  @override
  Future<ThingSetMessage> request(String msg) async {
    if (_connected) {
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

      debugPrint('request: $msg');
      await _mutex.acquire();

      List<int> encodedData = [...utf8.encode(msg), msgEnd];
      for (var i = 0; i < encodedData.length; i += _mtu) {
        var end =
            (i + _mtu < encodedData.length) ? i + _mtu : encodedData.length;
        await _ble.writeCharacteristicWithoutResponse(_reqCharacteristic!,
            value: encodedData.sublist(i, end));
      }

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
        debugPrint('Bluetooth error: $error');
      }
      _mutex.release();
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
    await _connection?.cancel();
    _connected = false;
  }
}

class BleScanner extends ChangeNotifier {
  final FlutterReactiveBle _ble;
  final List<DiscoveredDevice> _discoveredDevices = [];
  Stream? _scanStream;
  StreamSubscription? _scanStreamSubscription;

  BleScanner(this._ble);

  List<DiscoveredDevice> get devices => _discoveredDevices;

  Future<void> startScanning() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    _scanStream = _ble.scanForDevices(
      withServices: [uuidThingSetService],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    );

    _scanStreamSubscription = _scanStream!.listen(
      (device) {
        if (_discoveredDevices
            .every((discovered) => discovered.id != device.id)) {
          debugPrint('New ThingSet node found: ${device.toString()}');
          _discoveredDevices.add(device);
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('BLE error: $err');
        // ToDo: Handle error.
      },
    );
  }

  void stopScanning() async {
    await _scanStreamSubscription?.cancel();
  }

  void clear() {
    _discoveredDevices.clear();
  }
}
