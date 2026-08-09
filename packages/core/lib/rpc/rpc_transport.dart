/// A DAO call that reached the server and came back as a failure.
///
/// [kind] is the stable tag from the wire (`database`, `notFound`, …); the
/// message is for logs and never parsed.
class RpcException implements Exception {
  const RpcException(this.kind, this.message);

  final String kind;
  final String message;

  @override
  String toString() => 'RpcException($kind): $message';
}

/// The one seam the generated stubs talk to.
///
/// Kept abstract so `core` stays free of an HTTP client: the app plugs in a Dio
/// implementation, tests plug in the dispatcher directly.
abstract class RpcTransport {
  Future<Object?> call(
    String dao,
    String method,
    Map<String, Object?> args,
  );
}
