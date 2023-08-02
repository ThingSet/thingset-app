// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

const reqRegExp = r'^([?=+\-!])([^ ]*) *(.*)$';
const respRegExp = r'^:([0-9A-F]*)[^ ]* ?(.*)$';
const reportRegExp = r'^#([^ ]*) (.*)$';

class ThingSetFunctionCode {
  final int _code;

  ThingSetFunctionCode(this._code);

  ThingSetFunctionCode.fromString(String str)
      : _code = int.parse(str, radix: 16);

  ThingSetFunctionCode.content() : _code = 0x85;
  ThingSetFunctionCode.badRequest() : _code = 0xA0;
  ThingSetFunctionCode.gatewayTimeout() : _code = 0xC4;

  int asInt() => _code;

  @override
  String toString() {
    if (_code > 0x80) {
      // only valid for text mode
      return ':${_code.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    } else {
      return String.fromCharCode(_code);
    }
  }

  bool isReport() => _code == '#'.codeUnitAt(0);
  bool isCreated() => _code == 0x81;
  bool isDeleted() => _code == 0x82;
  bool isChanged() => _code == 0x84;
  bool isContent() => _code == 0x85;
}

class ThingSetMessage {
  ThingSetFunctionCode function;
  String relPath;
  String payload;

  ThingSetMessage(
      {required this.function, required this.relPath, required this.payload});

  @override
  String toString() {
    return '$function$relPath $payload';
  }
}

String getRelPath(String path) {
  if (path.isNotEmpty && path[0] == '/') {
    final chunks = path.split('/');
    return chunks.length > 2 ? chunks.sublist(2).join('/') : '';
  } else {
    return path;
  }
}

ThingSetMessage? parseThingSetMessage(String str) {
  dynamic matches;

  matches = RegExp(respRegExp).firstMatch(str);
  if (matches != null && matches.groupCount == 2) {
    return ThingSetMessage(
      function: ThingSetFunctionCode.fromString(matches[1]!),
      relPath: '',
      payload: matches[2]!,
    );
  }

  matches = RegExp(reportRegExp).firstMatch(str);
  if (matches != null && matches.groupCount == 2) {
    return ThingSetMessage(
      function: ThingSetFunctionCode('#'.codeUnitAt(0)),
      relPath: getRelPath(matches[1]!),
      payload: matches[2]!,
    );
  }

  return null;
}

// This class mainly handles routing of request/response messages and pub/sub
// messages, so that the application has a simple interface to request data.
abstract class ThingSetClient {
  final String _type;

  ThingSetClient(this._type);

  String get type => _type;

  String get id;

  // convert ThingSet request into request with relative path
  String? reqRelativePath(String reqAbsPath) {
    final matches = RegExp(reqRegExp).firstMatch(reqAbsPath);
    if (matches != null && matches.groupCount >= 3) {
      final type = matches[1]!;
      final absPath = matches[2]!;
      final data = matches[3]!;
      final relPath = getRelPath(absPath);
      return '$type$relPath $data';
    }
    return null;
  }

  // Establish connection with the remote node
  Future<void> connect();
  // Send a ThingSet request and await response
  Future<ThingSetMessage> request(String msg);
  // Get stream with reports
  Stream<ThingSetMessage> reports();
  // Disconnect from the node
  Future<void> disconnect();
}
