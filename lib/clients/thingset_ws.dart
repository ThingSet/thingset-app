import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mutex/mutex.dart';

import 'thingset.dart';

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
      try {
        await for (final value
            in receiver!.timeout(const Duration(seconds: 3))) {
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
      } catch (error) {
        return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
      }
      mutex.release();
    }
    return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
  }

  @override
  Future<void> disconnect() async {
    sender?.close();
  }
}
