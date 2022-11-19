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
  // List all connected nodes
  List<String> listNodes();
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

  @override
  List<String> listNodes() {
    return ["ABCD1234", "XYZ12345"];
  }
}
