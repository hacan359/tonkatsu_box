// Fetch ALL games for a given IGDB platform into one .xcollx file.
//
// Usage:
//   dart tool/generate_all_snes.dart \
//     --igdb-client-id=<id> \
//     --igdb-client-secret=<secret> \
//     --output=<dir> \
//     [--platform=19]
//
// Platform IDs: SNES=19, PS1=7, NES=18, Genesis=29, N64=4, GameBoy=33
import 'dart:convert';
import 'dart:io';

final HttpClient _http = HttpClient()
  ..connectionTimeout = const Duration(seconds: 15)
  ..idleTimeout = const Duration(seconds: 15);

Future<dynamic> _postIgdb(
  Uri uri, {
  required String clientId,
  required String accessToken,
  required String body,
}) async {
  final HttpClientRequest request = await _http.postUrl(uri);
  request.headers.set('Client-ID', clientId);
  request.headers.set('Authorization', 'Bearer $accessToken');
  request.headers.contentType = ContentType('text', 'plain');
  request.write(body);
  final HttpClientResponse response =
      await request.close().timeout(const Duration(seconds: 30));
  final String responseBody = await response
      .transform(utf8.decoder)
      .join()
      .timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw HttpException('POST $uri -> ${response.statusCode}: $responseBody');
  }
  return jsonDecode(responseBody);
}

Future<String> _getToken(String clientId, String clientSecret) async {
  final HttpClientRequest request = await _http.postUrl(Uri.parse(
    'https://id.twitch.tv/oauth2/token'
    '?client_id=$clientId&client_secret=$clientSecret'
    '&grant_type=client_credentials',
  ));
  final HttpClientResponse response =
      await request.close().timeout(const Duration(seconds: 15));
  final String body = await response.transform(utf8.decoder).join();
  return (jsonDecode(body) as Map<String, dynamic>)['access_token'] as String;
}

Future<String?> _downloadImageBase64(String url) async {
  try {
    final HttpClientRequest request =
        await _http.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 10));
    final HttpClientResponse response =
        await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final List<int> bytes = <int>[];
    await for (final List<int> chunk in response) {
      bytes.addAll(chunk);
    }
    return base64Encode(bytes);
  } catch (_) {
    return null;
  }
}

String? _coverUrl(Map<String, dynamic> json) {
  if (json['cover'] != null) {
    final String? imageId =
        (json['cover'] as Map<String, dynamic>)['image_id'] as String?;
    if (imageId != null) {
      return 'https://images.igdb.com/igdb/image/upload/t_cover_small/$imageId.jpg';
    }
  }
  return null;
}

Map<String, dynamic> _gameToDb(Map<String, dynamic> json) {
  final String? coverUrl = _coverUrl(json);
  String? genres;
  if (json['genres'] != null) {
    genres = (json['genres'] as List<dynamic>)
        .map((dynamic g) => (g as Map<String, dynamic>)['name'] as String)
        .join('|');
  }
  String? platformIds;
  if (json['platforms'] != null) {
    platformIds = (json['platforms'] as List<dynamic>)
        .map((dynamic p) => p.toString())
        .join(',');
  }
  final int cachedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return <String, dynamic>{
    'id': json['id'],
    'name': json['name'],
    'summary': json['summary'],
    'cover_url': coverUrl,
    'release_date': json['first_release_date'],
    'rating': (json['rating'] as num?)?.toDouble(),
    'rating_count': json['rating_count'],
    'genres': genres,
    'platform_ids': platformIds,
    'cached_at': cachedAt,
  };
}

String? _getArg(List<String> args, String name) {
  for (final String arg in args) {
    if (arg.startsWith('--$name=')) {
      return arg.substring('--$name='.length);
    }
  }
  return Platform.environment[name.replaceAll('-', '_').toUpperCase()];
}

Future<void> main(List<String> args) async {
  final String? clientId =
      _getArg(args, 'igdb-client-id') ?? _getArg(args, 'igdb_client_id');
  final String? clientSecret =
      _getArg(args, 'igdb-client-secret') ?? _getArg(args, 'igdb_client_secret');
  final String? outputDir =
      _getArg(args, 'output') ?? _getArg(args, 'output_dir');
  final int platformId =
      int.tryParse(_getArg(args, 'platform') ?? '') ?? 19; // default: SNES

  if (clientId == null || clientSecret == null || outputDir == null) {
    stderr.write(
      'Usage:\n'
      '  dart tool/generate_all_snes.dart \\\n'
      '    --igdb-client-id=<id> \\\n'
      '    --igdb-client-secret=<secret> \\\n'
      '    --output=<dir> \\\n'
      '    [--platform=19]\n'
      '\n'
      'Or set env vars: IGDB_CLIENT_ID, IGDB_CLIENT_SECRET, OUTPUT_DIR\n'
      '\n'
      'Platform IDs: SNES=19, PS1=7, NES=18, Genesis=29, N64=4, GameBoy=33\n',
    );
    exit(1);
  }

  final String outputPath = '$outputDir/all_platform_${platformId}_games.xcollx';

  stdout.write('Getting IGDB token...\n');
  final String token = await _getToken(clientId, clientSecret);
  stdout.write('OK\n\n');

  // Fetch ALL SNES games with pagination (max 500 per request).
  final List<Map<String, dynamic>> allGames = <Map<String, dynamic>>[];
  int offset = 0;

  while (true) {
    stdout.write('Fetching games offset=$offset...\n');
    final String body =
        'fields id, name, summary, rating, rating_count, '
        'first_release_date, cover.image_id, genres.name, platforms, url; '
        'where platforms = ($platformId); '
        'sort id asc; '
        'limit 500; '
        'offset $offset;';

    final dynamic result = await _postIgdb(
      Uri.parse('https://api.igdb.com/v4/games'),
      clientId: clientId,
      accessToken: token,
      body: body,
    );
    final List<dynamic> games = result as List<dynamic>;
    stdout.write('  Got ${games.length} games\n');

    if (games.isEmpty) break;
    allGames.addAll(games.cast<Map<String, dynamic>>());
    offset += 500;

    // IGDB rate limit.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  stdout.write('\nTotal: ${allGames.length} SNES games\n');

  // Build items + media (without images first to check size).
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> mediaGames = <Map<String, dynamic>>[];

  for (final Map<String, dynamic> game in allGames) {
    items.add(<String, dynamic>{
      'media_type': 'game',
      'external_id': game['id'],
      'platform_id': platformId,
      if (game['url'] != null) 'comment': game['url'] as String,
    });
    mediaGames.add(_gameToDb(game));
  }

  // Download all covers.
  final Map<String, String> urlMap = <String, String>{};
  for (final Map<String, dynamic> game in allGames) {
    final String? url = _coverUrl(game);
    if (url != null) {
      urlMap['game_covers/${game['id']}'] = url;
    }
  }
  stdout.write('Downloading ${urlMap.length} covers (5 parallel)...\n');

  final Map<String, String> images = <String, String>{};
  final List<MapEntry<String, String>> entries = urlMap.entries.toList();
  int failed = 0;

  for (int i = 0; i < entries.length; i += 5) {
    final int end = (i + 5).clamp(0, entries.length);
    final List<MapEntry<String, String>> chunk = entries.sublist(i, end);

    final List<String?> bases = await Future.wait(
      chunk.map((MapEntry<String, String> e) => _downloadImageBase64(e.value)),
    );

    for (int j = 0; j < chunk.length; j++) {
      if (bases[j] != null) {
        images[chunk[j].key] = bases[j]!;
      } else {
        failed++;
      }
    }

    if (i % 50 == 0 && i > 0) {
      stdout.write('  ${images.length} downloaded, $failed failed '
          '(${i + chunk.length}/${entries.length})\n');
    }
  }

  stdout.write('Downloaded ${images.length} covers ($failed failed)\n\n');

  // Build xcollx.
  final Map<String, dynamic> xcollx = <String, dynamic>{
    'version': 2,
    'format': 'full',
    'name': 'All Platform $platformId Games',
    'author': 'Tonkatsu Box',
    'created': DateTime.now().toUtc().toIso8601String(),
    'description': 'Complete platform $platformId library — ${allGames.length} games from IGDB',
    'items': items,
    'images': images,
    'media': <String, dynamic>{'games': mediaGames},
  };

  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final String jsonString = encoder.convert(xcollx);
  File(outputPath).writeAsStringSync(jsonString);

  final int sizeMb = jsonString.length ~/ (1024 * 1024);
  final int sizeKb = jsonString.length ~/ 1024;
  stdout.write('SAVED: ${outputPath.split('/').last.split('\\').last}\n');
  stdout.write('  Games: ${allGames.length}\n');
  stdout.write('  Covers: ${images.length}\n');
  stdout.write('  Size: $sizeKb KB ($sizeMb MB)\n');

  _http.close();
}
