import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mutex/mutex.dart';

const respRegExp = r':([0-9A-F]*)[^\.]*\. (.*)';

class ThingSetStatusCode {
  final int _status;

  ThingSetStatusCode(this._status);

  ThingSetStatusCode.fromString(String str)
      : _status = int.parse(str, radix: 16);

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

  get type => _type;

  ThingSetClient(this._type);

  // Establish connection with the remote node
  Future<void> connect();
  // Send a ThingSet request and await response
  Future<ThingSetResponse> request(String msg);
  // Disconnect from the node
  Future<void> disconnect();
}

class WebSocketClient extends ThingSetClient {
  final String baseUrl;
  Stream? receiver;
  WebSocketSink? sender;
  final mutex = Mutex();

  WebSocketClient(this.baseUrl) : super('WebSocket');

  @override
  Future<void> connect() async {
    final wsChannel = WebSocketChannel.connect(Uri.parse(baseUrl));
    receiver = wsChannel.stream.asBroadcastStream();
    sender = wsChannel.sink;
  }

  @override
  Future<ThingSetResponse> request(String msg) async {
    if (sender != null) {
      await mutex.acquire();
      sender!.add(msg);
      await for (final value in receiver!.timeout(const Duration(seconds: 3))) {
        // ToDo: Check if receiver stream has to be cancelled here
        final matches = RegExp(respRegExp).firstMatch(value.toString());
        if (matches != null && matches.groupCount == 2) {
          final status = matches[1];
          final jsonData = matches[2]!;
          mutex.release();
          return ThingSetResponse(
              ThingSetStatusCode.fromString(status!), jsonData);
        }
      }
      mutex.release();
    }
    throw Exception('Client not connected');
  }

  @override
  Future<void> disconnect() async {
    sender?.close();
  }
}

class DummyClient extends ThingSetClient {
  DummyClient(super.type);

  @override
  Future<void> connect() async {
    throw Exception('Dummy client. Not possible to connect.');
  }

  @override
  Future<ThingSetResponse> request(String msg) async {
    throw Exception('Client not connected.');
  }

  @override
  Future<void> disconnect() async {
    throw Exception('Dummy client. Not possible to disconnect.');
  }
}
