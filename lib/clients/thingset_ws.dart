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
  Future<void> connect() async {
    final wsChannel = WebSocketChannel.connect(Uri.parse(_baseUrl));
    _receiver = wsChannel.stream.asBroadcastStream();
    _sender = wsChannel.sink;
  }

  @override
  Future<ThingSetResponse> request(String msg) async {
    if (_sender != null) {
      await _mutex.acquire();
      _sender!.add(msg);
      try {
        await for (final value
            in _receiver!.timeout(const Duration(seconds: 3))) {
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
        return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
      }
      _mutex.release();
    }
    return ThingSetResponse(ThingSetStatusCode.serviceUnavailable(), '');
  }

  @override
  Future<void> disconnect() async {
    _sender?.close();
  }
}
