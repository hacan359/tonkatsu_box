/// A DAO call that reached the server and came back a failure. [kind] is the
/// stable wire tag; the message is for logs and never parsed.
class RpcException implements Exception {
  const RpcException(this.kind, this.message);

  final String kind;
  final String message;

  @override
  String toString() => 'RpcException($kind): $message';
}

/// The one seam the generated stubs talk to; abstract so `core` needs no HTTP
/// client — the app plugs in Dio, tests plug in the dispatcher.
abstract class RpcTransport {
  Future<Object?> call(
    String dao,
    String method,
    Map<String, Object?> args,
  );
}
