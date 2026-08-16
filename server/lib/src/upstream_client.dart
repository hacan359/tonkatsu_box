import 'dart:io';

class UpstreamResponse {
  const UpstreamResponse({
    required this.status,
    required this.contentType,
    required this.body,
  });

  final int status;
  final String? contentType;
  final List<int> body;
}

/// The proxy's one outbound seam, so tests can answer without a socket.
abstract class UpstreamClient {
  Future<UpstreamResponse> send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    List<int>? body,
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
  }) {
    return _send(method: method, url: url, headers: headers, body: body)
        .timeout(_deadline);
  }

  Future<UpstreamResponse> _send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    List<int>? body,
  }) async {
    final HttpClientRequest request = await _client.openUrl(method, url);
    headers.forEach(request.headers.set);
    if (body != null && body.isNotEmpty) {
      // Without an explicit length the request goes out chunked, which some
      // upstreams (ListenBrainz) answer with a bare 400.
      request.contentLength = body.length;
      request.add(body);
    }

    final HttpClientResponse response = await request.close();
    final List<int> bytes = <int>[
      await for (final List<int> chunk in response) ...chunk,
    ];

    return UpstreamResponse(
      status: response.statusCode,
      contentType: response.headers.contentType?.toString(),
      body: bytes,
    );
  }
}
