import 'package:web_socket_channel/web_socket_channel.dart';

// This class mainly handles routing of request/response messages and pub/sub
// messages, so that the application has a simple interface to request data.
abstract class ThingSetClient {
  final String _type;

  get type => _type;

  ThingSetClient(this._type);

  // Establish connection with the remote node
  Future<void> connect();
  // Send a ThingSet request and await response
  Future<String> request(String msg);
  // Disconnect from the node
  Future<void> disconnect();
}

class WebSocketClient extends ThingSetClient {
  final String baseUrl;
  WebSocketChannel? channel;

  WebSocketClient(this.baseUrl) : super('WebSocket');

  @override
  Future<void> connect() async {
    channel = WebSocketChannel.connect(Uri.parse(baseUrl));
  }

  @override
  Future<String> request(String msg) async {
    if (channel != null) {
      channel!.sink.add(msg);
      await for (final value
          in channel!.stream.timeout(const Duration(seconds: 3))) {
        return value.toString();
      }
    }
    throw Exception('Client not connected');
  }

  @override
  Future<void> disconnect() async {
    channel?.sink.close();
  }
}

class DummyClient extends ThingSetClient {
  DummyClient(super.type);

  @override
  Future<void> connect() async {
    throw Exception('Dummy client. Not possible to connect.');
  }

  @override
  Future<String> request(String msg) async {
    throw Exception('Client not connected.');
  }

  @override
  Future<void> disconnect() async {
    throw Exception('Dummy client. Not possible to disconnect.');
  }
}
