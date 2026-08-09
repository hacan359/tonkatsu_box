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
  HttpUpstreamClient({Duration timeout = const Duration(seconds: 30)})
      : _client = HttpClient()..connectionTimeout = timeout;

  final HttpClient _client;

  @override
  Future<UpstreamResponse> send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    List<int>? body,
  }) async {
    final HttpClientRequest request = await _client.openUrl(method, url);
    headers.forEach(request.headers.set);
    if (body != null && body.isNotEmpty) request.add(body);

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
