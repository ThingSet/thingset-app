// Copyright (c) Libre Solar Technologies GmbH
// SPDX-License-Identifier: GPL-3.0-only

const reqRegExp = r'([?=+\-!])([^ ]*) *(.*)';
const respRegExp = r':([0-9A-F]*)[^ ]* ?(.*)';

class ThingSetStatusCode {
  final int _status;

  ThingSetStatusCode(this._status);

  ThingSetStatusCode.fromString(String str)
      : _status = int.parse(str, radix: 16);

  ThingSetStatusCode.serviceUnavailable() : _status = 0xC3;
  ThingSetStatusCode.content() : _status = 0x85;

  int asInt() => _status;

  String asString() => _status.toRadixString(16).padLeft(2, '0').toUpperCase();

  bool isCreated() => _status == 0x81;
  bool isDeleted() => _status == 0x82;
  bool isValid() => _status == 0x83;
  bool isChanged() => _status == 0x84;
  bool isContent() => _status == 0x85;
}

class ThingSetResponse {
  final ThingSetStatusCode status;
  final String data;

  ThingSetResponse(this.status, this.data);
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
      final chunks = absPath.split('/');
      if (chunks.length > 1) {
        // remove nodeId in chunks[1]
        String relPath = chunks.length > 2 ? chunks.sublist(2).join('/') : '';
        return '$type$relPath $data';
      }
    }
    return null;
  }

  // Establish connection with the remote node
  Future<void> connect();
  // Send a ThingSet request and await response
  Future<ThingSetResponse> request(String msg);
  // Disconnect from the node
  Future<void> disconnect();
}
