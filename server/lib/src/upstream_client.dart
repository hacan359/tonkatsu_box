import 'dart:io';
import 'dart:typed_data';

class UpstreamResponse {
  const UpstreamResponse({
    required this.status,
    required this.contentType,
    required this.body,
    this.location,
  });

  final int status;
  final String? contentType;
  final List<int> body;

  /// The `Location` header, only seen when redirects were not followed.
  final String? location;

  bool get isRedirect => status >= 300 && status < 400 && location != null;
}

/// Refused rather than buffered whole: a rogue upstream must not OOM the box.
/// Covers are hundreds of KB, API payloads single MB.
const int kUpstreamMaxBodyBytes = 20 * 1024 * 1024;

/// The proxy's one outbound seam, so tests can answer without a socket.
abstract class UpstreamClient {
  /// [followRedirects] off hands each hop back to the caller, which is how the
  /// image cache checks every redirect target against its host allowlist.
  Future<UpstreamResponse> send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    List<int>? body,
    bool followRedirects = true,
  });
}

class HttpUpstreamClient implements UpstreamClient {
  HttpUpstreamClient({Duration deadline = const Duration(seconds: 15)})
      : _deadline = deadline,
        _client = HttpClient()..connectionTimeout = deadline;

  /// connectionTimeout alone lets an accepted-but-silent upstream hold the line
  /// for minutes, pinning one of the browser's six connections.
  final Duration _deadline;

  final HttpClient _client;

  @override
  Future<UpstreamResponse> send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    List<int>? body,
    bool followRedirects = true,
  }) {
    return _send(
      method: method,
      url: url,
      headers: headers,
      body: body,
      followRedirects: followRedirects,
    ).timeout(_deadline);
  }

  Future<UpstreamResponse> _send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    List<int>? body,
    required bool followRedirects,
  }) async {
    final HttpClientRequest request = await _client.openUrl(method, url);
    request.followRedirects = followRedirects;
    headers.forEach(request.headers.set);
    // Without an explicit length the request goes out chunked — even when the
    // body is empty — which some upstreams (ListenBrainz) answer with a 400.
    final bool methodTakesBody = method != 'GET' && method != 'HEAD';
    if (body != null && (body.isNotEmpty || methodTakesBody)) {
      request.contentLength = body.length;
      if (body.isNotEmpty) request.add(body);
    }

    final HttpClientResponse response = await request.close();
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in response) {
      builder.add(chunk);
      if (builder.length > kUpstreamMaxBodyBytes) {
        throw const UpstreamBodyTooLarge();
      }
    }
    final List<int> bytes = builder.takeBytes();

    return UpstreamResponse(
      status: response.statusCode,
      contentType: response.headers.contentType?.toString(),
      body: bytes,
      location: response.headers.value(HttpHeaders.locationHeader),
    );
  }
}

/// The request has already gone upstream, so the proxy answers 502 like any
/// other failed hop.
class UpstreamBodyTooLarge implements Exception {
  const UpstreamBodyTooLarge();

  @override
  String toString() =>
      'Upstream response exceeded $kUpstreamMaxBodyBytes bytes';
}
