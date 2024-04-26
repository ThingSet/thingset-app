// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

const reqRegExp = r'^([?=+\-!])([^ ]*) *(.*)$';
const respRegExp = r'^:([0-9A-F]*)[^ ]* ?(.*)$';
const reportRegExp = r'^#([^ ]*) (.*)$';

// correct UTF-8 string for units simplified for ThingSet
const unitFix = {
  'deg': '°',
  'degC': '°C',
  'pct': '%',
  'm2': 'm²',
  'm3': 'm³',
};

String thingsetSplitCamelCaseName(String name) {
  name = name.replaceAllMapped(
      RegExp(r'([a-z])([A-Z0-9])'), (Match m) => '${m.group(1)} ${m.group(2)}');
  name = name.replaceAllMapped(RegExp(r'([A-Z0-9])([A-Z][a-z])'),
      (Match m) => '${m.group(1)} ${m.group(2)}');

  return name;
}

String thingsetParseUnit(String name) {
  final chunks = name.split('_');

  var unit = chunks.length > 1
      ? chunks[1] + (chunks.length > 2 ? '/${chunks[2]}' : '')
      : '';
  if (unitFix.containsKey(unit)) {
    unit = unitFix[unit]!;
  }

  return unit;
}

class ThingSetFunctionCode {
  final int _code;

  ThingSetFunctionCode(this._code);

  ThingSetFunctionCode.fromString(String str)
      : _code = int.parse(str, radix: 16);

  ThingSetFunctionCode.changed() : _code = 0x84;
  ThingSetFunctionCode.content() : _code = 0x85;
  ThingSetFunctionCode.badRequest() : _code = 0xA0;
  ThingSetFunctionCode.notFound() : _code = 0xA4;
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
  String path;
  String payload;

  ThingSetMessage(
      {required this.function, required this.path, required this.payload});

  String get relPath => getRelPath(path);

  @override
  String toString() {
    return '$function$path $payload';
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
      path: '',
      payload: matches[2]!,
    );
  }

  matches = RegExp(reportRegExp).firstMatch(str);
  if (matches != null && matches.groupCount == 2) {
    return ThingSetMessage(
      function: ThingSetFunctionCode(str.codeUnitAt(0)),
      path: matches[1]!,
      payload: matches[2]!,
    );
  }

  matches = RegExp(reqRegExp).firstMatch(str);
  if (matches != null && matches.groupCount == 3) {
    return ThingSetMessage(
      function: ThingSetFunctionCode(str.codeUnitAt(0)),
      path: matches[2]!,
      payload: matches[3]!,
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
