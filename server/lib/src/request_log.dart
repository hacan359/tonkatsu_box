import 'package:shelf/shelf.dart';

/// Query-parameter names redacted from the request log — the same set the
/// app uses for error details, plus the proxy-injected upstream credentials.
const Set<String> _redactKeys = <String>{
  'y', // RetroAchievements api key
  'z', // RetroAchievements username
  'api_key',
  'apikey',
  'key',
  'token',
  'access_token',
  'client_secret',
  'authorization',
  'devid',
  'devpassword',
  'ssid',
  'sspassword',
};

/// `/path?api_key=***&query=fox` — what the log may say about a request.
String redactedTarget(Uri uri) {
  if (uri.queryParameters.isEmpty) {
    return uri.path.isEmpty ? '/' : '/${uri.path}';
  }
  final StringBuffer query = StringBuffer();
  bool first = true;
  for (final MapEntry<String, String> e in uri.queryParameters.entries) {
    if (!first) query.write('&');
    first = false;
    final String value = _redactKeys.contains(e.key.toLowerCase())
        ? '***'
        : Uri.encodeQueryComponent(e.value);
    query.write('${Uri.encodeQueryComponent(e.key)}=$value');
  }
  return '/${uri.path}?$query';
}

/// shelf's logRequests, minus the secrets: it prints the raw query string,
/// which for the proxy routes carries real API keys.
Middleware sanitizedLogRequests() {
  return (Handler inner) {
    return (Request request) async {
      final Stopwatch watch = Stopwatch()..start();
      final String target = redactedTarget(request.url);
      try {
        final Response response = await inner(request);
        // ignore: avoid_print — the container log IS the server's output.
        print('${DateTime.now().toIso8601String()} ${watch.elapsed} '
            '${request.method.padRight(7)} [${response.statusCode}] $target');
        return response;
      } catch (error) {
        // ignore: avoid_print
        print('${DateTime.now().toIso8601String()} ${watch.elapsed} '
            '${request.method.padRight(7)} [ERROR] $target: $error');
        rethrow;
      }
    };
  };
}
