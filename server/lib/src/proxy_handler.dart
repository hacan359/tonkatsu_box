import 'dart:convert';
import 'dart:io';

import 'package:core/api/proxy_targets.dart';
import 'package:shelf/shelf.dart';

import 'api_credentials.dart';
import 'upstream_client.dart';

/// Browsers strip `User-Agent`, and AniList answers 403 without one.
const String kProxyUserAgent =
    'TonkatsuBox/selfhost (+https://github.com/hacan359/tonkatsu_box)';

/// Everything else — auth, host, agent — is the server's, so a crafted request
/// cannot borrow our keys for a target of its own.
const Set<String> _forwardedRequestHeaders = <String>{
  HttpHeaders.contentTypeHeader,
  HttpHeaders.acceptHeader,
};

class _CachedToken {
  const _CachedToken(this.value, this.expiresAt);

  final String value;
  final DateTime expiresAt;

  bool isValidAt(DateTime now) => now.isBefore(expiresAt);
}

/// `/proxy/<slug>/<path>` — the browser's only way out to an external API. Not
/// an open relay: an unknown slug is a 404 before anything is sent.
class ApiProxy {
  ApiProxy({
    required this.credentials,
    this.dataDir,
    UpstreamClient? upstream,
    DateTime Function()? clock,
  })  : _upstream = upstream ?? HttpUpstreamClient(),
        _now = clock ?? DateTime.now;

  /// Where an uploaded keys.json is written; null keeps uploads in memory.
  final String? dataDir;

  ApiCredentials credentials;

  final UpstreamClient _upstream;
  final DateTime Function() _now;

  _CachedToken? _igdbToken;

  /// Replaces the live set so a key starts working without a restart, and
  /// drops the IGDB token in case its credentials just changed.
  Map<String, String> applyCredentials(Map<String, String> updates) {
    credentials = credentials.merge(updates);
    _igdbToken = null;
    final String? dir = dataDir;
    if (dir != null) credentials.saveTo(dir);
    return credentials.values;
  }

  Handler get handler => (Request request) async {
        // url is relative to the app root, so segment 0 is the `/proxy` prefix.
        final List<String> segments = request.url.pathSegments;
        if (segments.length < 2) {
          return _error(HttpStatus.notFound, 'No upstream in the path');
        }

        final ProxyTarget? target = proxyTargetForSlug(segments[1]);
        if (target == null) {
          return _error(
            HttpStatus.notFound,
            'Unknown upstream "${segments[1]}"',
          );
        }

        final Map<String, List<String>> query = <String, List<String>>{
          ...request.requestedUri.queryParametersAll,
        };
        final Map<String, String> headers = <String, String>{
          for (final MapEntry<String, String> e in request.headers.entries)
            if (_forwardedRequestHeaders.contains(e.key.toLowerCase()))
              e.key: e.value,
          HttpHeaders.userAgentHeader: kProxyUserAgent,
        };
        List<int> body = await _collect(request);

        try {
          body = await _authorize(
            target: target,
            path: segments.skip(2).join('/'),
            headers: headers,
            query: query,
            body: body,
          );
        } on ProxyCredentialException catch (e) {
          return _error(HttpStatus.serviceUnavailable, e.message);
        }

        final Uri url = Uri(
          scheme: 'https',
          host: target.host,
          pathSegments: segments.skip(2),
          queryParameters: query.isEmpty ? null : query,
        );

        try {
          final UpstreamResponse response = await _upstream.send(
            method: request.method,
            url: url,
            headers: headers,
            body: body,
          );
          return Response(
            response.status,
            body: response.body,
            headers: <String, String>{
              if (response.contentType != null)
                HttpHeaders.contentTypeHeader: response.contentType!,
            },
          );
        } on Object catch (e) {
          return _error(HttpStatus.badGateway, '${target.slug}: $e');
        }
      };

  /// Attaches the real credentials; returns the body because TheTVDB's login
  /// carries its key there. Exhaustive so a new upstream must decide.
  Future<List<int>> _authorize({
    required ProxyTarget target,
    required String path,
    required Map<String, String> headers,
    required Map<String, List<String>> query,
    required List<int> body,
  }) async {
    switch (target) {
      case ProxyTarget.tmdb:
        query['api_key'] = <String>[_require(CredentialNames.tmdb, target)];
      case ProxyTarget.igdb:
        headers['Client-ID'] = _require(CredentialNames.igdbClientId, target);
        headers[HttpHeaders.authorizationHeader] = 'Bearer ${await _igdb()}';
      case ProxyTarget.steamgriddb:
        headers[HttpHeaders.authorizationHeader] =
            'Bearer ${_require(CredentialNames.steamGridDb, target)}';
      case ProxyTarget.hardcover:
        headers[HttpHeaders.authorizationHeader] =
            'Bearer ${_require(CredentialNames.hardcover, target)}';
      case ProxyTarget.comicvine:
        query['api_key'] = <String>[
          _require(CredentialNames.comicVine, target),
        ];
      case ProxyTarget.googlebooks:
        // Optional everywhere: a key only raises the quota.
        final String? key = credentials[CredentialNames.googleBooks];
        if (key != null) query['key'] = <String>[key];
      case ProxyTarget.ra:
        query['z'] = <String>[_require(CredentialNames.raUsername, target)];
        query['y'] = <String>[_require(CredentialNames.ra, target)];
      case ProxyTarget.simkl:
        headers['simkl-api-key'] =
            _require(CredentialNames.simklClientId, target);
      case ProxyTarget.tvdb:
        if (path.endsWith('login')) {
          return utf8.encode(jsonEncode(<String, Object?>{
            'apikey': _require(CredentialNames.tvdb, target),
          }));
        }
      // Keyless: the proxy is still the only way there from a browser.
      case ProxyTarget.anilist:
      case ProxyTarget.fantlab:
      case ProxyTarget.kitsu:
      case ProxyTarget.mangabaka:
      case ProxyTarget.mangadex:
      case ProxyTarget.openlibrary:
      case ProxyTarget.steam:
      case ProxyTarget.tvmaze:
      case ProxyTarget.vndb:
      // Four separate credentials, not wired yet — see server/README.md.
      case ProxyTarget.screenscraper:
        break;
    }
    return body;
  }

  Future<String> _igdb() async {
    final DateTime now = _now();
    final _CachedToken? cached = _igdbToken;
    if (cached != null && cached.isValidAt(now)) return cached.value;

    final UpstreamResponse response = await _upstream.send(
      method: 'POST',
      url: Uri.https('id.twitch.tv', '/oauth2/token', <String, String>{
        'client_id': _require(CredentialNames.igdbClientId, ProxyTarget.igdb),
        'client_secret':
            _require(CredentialNames.igdbClientSecret, ProxyTarget.igdb),
        'grant_type': 'client_credentials',
      }),
      headers: <String, String>{HttpHeaders.userAgentHeader: kProxyUserAgent},
    );
    if (response.status != HttpStatus.ok) {
      throw ProxyCredentialException(
        'Twitch refused the IGDB credentials (${response.status})',
      );
    }

    final Object? decoded = jsonDecode(utf8.decode(response.body));
    if (decoded is! Map<String, Object?>) {
      throw const ProxyCredentialException('Twitch returned no token');
    }
    final Object? token = decoded['access_token'];
    if (token is! String) {
      throw const ProxyCredentialException('Twitch returned no token');
    }

    final Object? expiresIn = decoded['expires_in'];
    // A minute of slack so a token cannot expire between the check and the use.
    final int seconds = expiresIn is int ? expiresIn : 3600;
    _igdbToken = _CachedToken(token, now.add(Duration(seconds: seconds - 60)));
    return token;
  }

  String _require(String name, ProxyTarget target) {
    final String? value = credentials[name];
    if (value == null) {
      throw ProxyCredentialException(
        'No "$name" configured for ${target.slug}',
      );
    }
    return value;
  }
}

/// A key the upstream needs is missing — the server's problem, not the
/// caller's, so it answers 503 rather than a 4xx.
class ProxyCredentialException implements Exception {
  const ProxyCredentialException(this.message);

  final String message;

  @override
  String toString() => 'ProxyCredentialException: $message';
}

Future<List<int>> _collect(Request request) async => <int>[
      await for (final List<int> chunk in request.read()) ...chunk,
    ];

Response _error(int status, String message) => Response(
      status,
      body: jsonEncode(<String, Object?>{
        'ok': false,
        'error': <String, String>{'kind': 'proxy', 'message': message},
      }),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );
