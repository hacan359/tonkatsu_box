// Standalone CLI script to generate 10 demo .xcollx collection files.
//
// Usage:
//   dart tool/generate_demo_collections.dart \
//     --igdb-client-id=<id> \
//     --igdb-client-secret=<secret> \
//     --tmdb-key=<key> \
//     --output=<dir>
//
// No Flutter dependencies — uses only dart:io and dart:convert.

import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const int _kPlatformSnes = 19;
const int _kPlatformPs1 = 7;
const int _kPlatformNes = 18;
const int _kPlatformGenesis = 29;
const int _kPlatformN64 = 4;
const int _kPlatformGameBoy = 33;
const int _kTmdbAnimationGenreId = 16;

enum CollectionType {
  igdbPlatform,
  tmdbTopMovies,
  tmdbTopTvShows,
  tmdbAnimeMovies,
  tmdbAnimeSeries,
}

class CollectionSpec {
  const CollectionSpec({
    required this.name,
    required this.description,
    required this.fileName,
    required this.type,
    this.platformId,
    this.genreId,
  });

  final String name;
  final String description;
  final String fileName;
  final CollectionType type;
  final int? platformId;
  final int? genreId;
}

const List<CollectionSpec> collections = <CollectionSpec>[
  CollectionSpec(
    name: 'Top SNES Games',
    description: 'Top 50 highest rated Super Nintendo games of all time',
    fileName: 'top_snes_games',
    type: CollectionType.igdbPlatform,
    platformId: _kPlatformSnes,
  ),
  CollectionSpec(
    name: 'Top PS1 Games',
    description: 'Top 50 highest rated PlayStation 1 games of all time',
    fileName: 'top_ps1_games',
    type: CollectionType.igdbPlatform,
    platformId: _kPlatformPs1,
  ),
  CollectionSpec(
    name: 'Top NES Games',
    description: 'Top 50 highest rated Nintendo Entertainment System games',
    fileName: 'top_nes_games',
    type: CollectionType.igdbPlatform,
    platformId: _kPlatformNes,
  ),
  CollectionSpec(
    name: 'Top Sega Genesis Games',
    description: 'Top 50 highest rated Sega Genesis / Mega Drive games',
    fileName: 'top_genesis_games',
    type: CollectionType.igdbPlatform,
    platformId: _kPlatformGenesis,
  ),
  CollectionSpec(
    name: 'Top N64 Games',
    description: 'Top 50 highest rated Nintendo 64 games of all time',
    fileName: 'top_n64_games',
    type: CollectionType.igdbPlatform,
    platformId: _kPlatformN64,
  ),
  CollectionSpec(
    name: 'Top Game Boy Games',
    description: 'Top 50 highest rated Game Boy games of all time',
    fileName: 'top_gameboy_games',
    type: CollectionType.igdbPlatform,
    platformId: _kPlatformGameBoy,
  ),
  CollectionSpec(
    name: 'Top Rated Movies',
    description: 'Top 50 highest rated movies of all time (TMDB)',
    fileName: 'top_rated_movies',
    type: CollectionType.tmdbTopMovies,
  ),
  CollectionSpec(
    name: 'Top Rated TV Shows',
    description: 'Top 50 highest rated TV shows of all time (TMDB)',
    fileName: 'top_rated_tv_shows',
    type: CollectionType.tmdbTopTvShows,
  ),
  CollectionSpec(
    name: 'Best Anime Series',
    description: 'Top 50 highest rated anime TV series (TMDB)',
    fileName: 'best_anime_series',
    type: CollectionType.tmdbAnimeSeries,
    genreId: _kTmdbAnimationGenreId,
  ),
  CollectionSpec(
    name: 'Best Anime Movies',
    description: 'Top 50 highest rated anime movies (TMDB)',
    fileName: 'best_anime_movies',
    type: CollectionType.tmdbAnimeMovies,
    genreId: _kTmdbAnimationGenreId,
  ),
];

// ---------------------------------------------------------------------------
// HTTP helpers
// ---------------------------------------------------------------------------

final HttpClient _http = HttpClient()
  ..connectionTimeout = const Duration(seconds: 15)
  ..idleTimeout = const Duration(seconds: 15);

Future<dynamic> _getJson(Uri uri, {Map<String, String>? headers}) async {
  final HttpClientRequest request = await _http.getUrl(uri);
  headers?.forEach((String k, String v) => request.headers.set(k, v));
  final HttpClientResponse response =
      await request.close().timeout(const Duration(seconds: 30));
  final String body =
      await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw HttpException(
      'GET $uri → ${response.statusCode}: $body',
      uri: uri,
    );
  }
  return jsonDecode(body);
}

Future<dynamic> _postJson(
  Uri uri, {
  Map<String, String>? headers,
  String? body,
}) async {
  final HttpClientRequest request = await _http.postUrl(uri);
  headers?.forEach((String k, String v) => request.headers.set(k, v));
  if (body != null) {
    request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
    request.write(body);
  }
  final HttpClientResponse response = await request.close();
  final String responseBody = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw HttpException(
      'POST $uri → ${response.statusCode}: $responseBody',
      uri: uri,
    );
  }
  return jsonDecode(responseBody);
}

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
  final HttpClientResponse response = await request.close();
  final String responseBody = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw HttpException(
      'POST $uri → ${response.statusCode}: $responseBody',
      uri: uri,
    );
  }
  return jsonDecode(responseBody);
}

Future<String?> _downloadImageBase64(String url) async {
  try {
    final HttpClientRequest request = await _http.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
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

// ---------------------------------------------------------------------------
// IGDB
// ---------------------------------------------------------------------------

Future<String> _getIgdbToken(String clientId, String clientSecret) async {
  final Uri uri = Uri.parse(
    'https://id.twitch.tv/oauth2/token'
    '?client_id=$clientId'
    '&client_secret=$clientSecret'
    '&grant_type=client_credentials',
  );
  final dynamic result = await _postJson(uri);
  return (result as Map<String, dynamic>)['access_token'] as String;
}

Future<List<Map<String, dynamic>>> _fetchIgdbGames({
  required String clientId,
  required String accessToken,
  required int platformId,
  int limit = 50,
}) async {
  final String body = 'fields id, name, summary, rating, rating_count, '
      'first_release_date, cover.image_id, genres.name, platforms, url; '
      'where platforms = ($platformId) '
      '& rating_count >= 20 & rating != null; '
      'sort rating desc; '
      'limit $limit;';

  final dynamic result = await _postIgdb(
    Uri.parse('https://api.igdb.com/v4/games'),
    clientId: clientId,
    accessToken: accessToken,
    body: body,
  );
  return (result as List<dynamic>).cast<Map<String, dynamic>>();
}

Map<String, dynamic> _gameToDb(Map<String, dynamic> json) {
  // Cover URL
  String? coverUrl;
  if (json['cover'] != null) {
    final String? imageId =
        (json['cover'] as Map<String, dynamic>)['image_id'] as String?;
    if (imageId != null) {
      coverUrl =
          'https://images.igdb.com/igdb/image/upload/t_cover_big/$imageId.jpg';
    }
  }

  // Genres — pipe-separated
  String? genres;
  if (json['genres'] != null) {
    genres = (json['genres'] as List<dynamic>)
        .map((dynamic g) => (g as Map<String, dynamic>)['name'] as String)
        .join('|');
  }

  // Platforms — comma-separated
  String? platformIds;
  if (json['platforms'] != null) {
    platformIds = (json['platforms'] as List<dynamic>)
        .map((dynamic p) => p.toString())
        .join(',');
  }

  // Release date — unix timestamp
  int? releaseDate;
  if (json['first_release_date'] != null) {
    releaseDate = json['first_release_date'] as int;
  }

  final int cachedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  return <String, dynamic>{
    'id': json['id'],
    'name': json['name'],
    'summary': json['summary'],
    'cover_url': coverUrl,
    'release_date': releaseDate,
    'rating': (json['rating'] as num?)?.toDouble(),
    'rating_count': json['rating_count'],
    'genres': genres,
    'platform_ids': platformIds,
    'external_url': json['url'] as String?,
    'cached_at': cachedAt,
  };
}

String? _gameCoverUrl(Map<String, dynamic> json) {
  if (json['cover'] != null) {
    final String? imageId =
        (json['cover'] as Map<String, dynamic>)['image_id'] as String?;
    if (imageId != null) {
      return 'https://images.igdb.com/igdb/image/upload/t_cover_big/$imageId.jpg';
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// TMDB
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>> _fetchTmdbMoviesTopRated(
  String apiKey, {
  int pages = 3,
}) async {
  final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
  for (int page = 1; page <= pages && all.length < 50; page++) {
    final dynamic result = await _getJson(
      Uri.parse(
        'https://api.themoviedb.org/3/movie/top_rated'
        '?api_key=$apiKey&page=$page&language=en-US',
      ),
    );
    final List<dynamic> results =
        (result as Map<String, dynamic>)['results'] as List<dynamic>;
    all.addAll(results.cast<Map<String, dynamic>>());
  }
  return all.take(50).toList();
}

Future<List<Map<String, dynamic>>> _fetchTmdbTvShowsTopRated(
  String apiKey, {
  int pages = 3,
}) async {
  final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
  for (int page = 1; page <= pages && all.length < 50; page++) {
    final dynamic result = await _getJson(
      Uri.parse(
        'https://api.themoviedb.org/3/tv/top_rated'
        '?api_key=$apiKey&page=$page&language=en-US',
      ),
    );
    final List<dynamic> results =
        (result as Map<String, dynamic>)['results'] as List<dynamic>;
    all.addAll(results.cast<Map<String, dynamic>>());
  }
  return all.take(50).toList();
}

Future<List<Map<String, dynamic>>> _fetchTmdbDiscover(
  String apiKey, {
  required String mediaType, // 'movie' or 'tv'
  int? genreId,
  int voteCountGte = 100,
  String sortBy = 'vote_average.desc',
  int pages = 3,
}) async {
  final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
  for (int page = 1; page <= pages && all.length < 50; page++) {
    final StringBuffer url = StringBuffer(
      'https://api.themoviedb.org/3/discover/$mediaType'
      '?api_key=$apiKey&page=$page&language=en-US&sort_by=$sortBy'
      '&vote_count.gte=$voteCountGte',
    );
    if (genreId != null) {
      url.write('&with_genres=$genreId');
    }
    final dynamic result = await _getJson(Uri.parse(url.toString()));
    final List<dynamic> results =
        (result as Map<String, dynamic>)['results'] as List<dynamic>;
    all.addAll(results.cast<Map<String, dynamic>>());
  }
  return all.take(50).toList();
}

Map<String, dynamic> _movieToDb(Map<String, dynamic> json) {
  String? posterUrl;
  final String? posterPath = json['poster_path'] as String?;
  if (posterPath != null) {
    posterUrl = 'https://image.tmdb.org/t/p/w342$posterPath';
  }

  String? backdropUrl;
  final String? backdropPath = json['backdrop_path'] as String?;
  if (backdropPath != null) {
    backdropUrl = 'https://image.tmdb.org/t/p/w780$backdropPath';
  }

  int? releaseYear;
  final String? releaseDate = json['release_date'] as String?;
  if (releaseDate != null && releaseDate.length >= 4) {
    releaseYear = int.tryParse(releaseDate.substring(0, 4));
  }

  // genre_ids from discover/top_rated results
  List<String>? genres;
  if (json['genre_ids'] != null) {
    genres = (json['genre_ids'] as List<dynamic>)
        .map((dynamic id) => id.toString())
        .toList();
  }

  final int cachedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final int tmdbId = json['id'] as int;

  return <String, dynamic>{
    'tmdb_id': tmdbId,
    'title': json['title'],
    'original_title': json['original_title'],
    'poster_url': posterUrl,
    'backdrop_url': backdropUrl,
    'overview': json['overview'],
    'genres': genres != null ? jsonEncode(genres) : null,
    'release_year': releaseYear,
    'rating': (json['vote_average'] as num?)?.toDouble(),
    'runtime': json['runtime'],
    'external_url': 'https://www.themoviedb.org/movie/$tmdbId',
    'cached_at': cachedAt,
  };
}

Map<String, dynamic> _tvShowToDb(Map<String, dynamic> json) {
  String? posterUrl;
  final String? posterPath = json['poster_path'] as String?;
  if (posterPath != null) {
    posterUrl = 'https://image.tmdb.org/t/p/w342$posterPath';
  }

  String? backdropUrl;
  final String? backdropPath = json['backdrop_path'] as String?;
  if (backdropPath != null) {
    backdropUrl = 'https://image.tmdb.org/t/p/w780$backdropPath';
  }

  int? firstAirYear;
  final String? firstAirDate = json['first_air_date'] as String?;
  if (firstAirDate != null && firstAirDate.length >= 4) {
    firstAirYear = int.tryParse(firstAirDate.substring(0, 4));
  }

  List<String>? genres;
  if (json['genre_ids'] != null) {
    genres = (json['genre_ids'] as List<dynamic>)
        .map((dynamic id) => id.toString())
        .toList();
  }

  final int cachedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final int tmdbId = json['id'] as int;

  return <String, dynamic>{
    'tmdb_id': tmdbId,
    'title': json['name'] ?? json['title'],
    'original_title': json['original_name'] ?? json['original_title'],
    'poster_url': posterUrl,
    'backdrop_url': backdropUrl,
    'overview': json['overview'],
    'genres': genres != null ? jsonEncode(genres) : null,
    'first_air_year': firstAirYear,
    'total_seasons': json['number_of_seasons'],
    'total_episodes': json['number_of_episodes'],
    'rating': (json['vote_average'] as num?)?.toDouble(),
    'status': json['status'],
    'external_url': 'https://www.themoviedb.org/tv/$tmdbId',
    'cached_at': cachedAt,
  };
}

String? _tmdbPosterUrl(Map<String, dynamic> json) {
  final String? posterPath = json['poster_path'] as String?;
  if (posterPath != null) {
    return 'https://image.tmdb.org/t/p/w342$posterPath';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Image download (chunked, 5 parallel)
// ---------------------------------------------------------------------------

Future<Map<String, String>> _downloadImages({
  required Map<String, String> urlMap, // key → url
}) async {
  final Map<String, String> result = <String, String>{};
  final List<MapEntry<String, String>> entries = urlMap.entries.toList();

  for (int i = 0; i < entries.length; i += 5) {
    final int end = (i + 5).clamp(0, entries.length);
    final List<MapEntry<String, String>> chunk = entries.sublist(i, end);

    final List<String?> bases = await Future.wait(
      chunk.map((MapEntry<String, String> e) => _downloadImageBase64(e.value)),
    );

    for (int j = 0; j < chunk.length; j++) {
      if (bases[j] != null) {
        result[chunk[j].key] = bases[j]!;
      }
    }

    if (i > 0 && i % 20 == 0) {
      stdout.write('  ...${result.length} images downloaded\n');
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// XcollFile builder
// ---------------------------------------------------------------------------

Map<String, dynamic> _buildXcollx({
  required String name,
  required String description,
  required List<Map<String, dynamic>> items,
  required Map<String, String> images,
  required Map<String, dynamic> media,
}) {
  return <String, dynamic>{
    'version': 2,
    'format': 'full',
    'name': name,
    'author': 'Tonkatsu Box',
    'created': DateTime.now().toUtc().toIso8601String(),
    'description': description,
    'items': items,
    'images': images,
    'media': media,
  };
}

// ---------------------------------------------------------------------------
// Collection generators
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _generateGameCollection({
  required CollectionSpec spec,
  required String clientId,
  required String accessToken,
}) async {
  stdout.write('  Fetching top games for platform ${spec.platformId}...\n');

  final List<Map<String, dynamic>> games = await _fetchIgdbGames(
    clientId: clientId,
    accessToken: accessToken,
    platformId: spec.platformId!,
  );
  stdout.write('  Got ${games.length} games\n');

  // Rate limit.
  await Future<void>.delayed(const Duration(milliseconds: 300));

  // Build items + media.
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> mediaGames = <Map<String, dynamic>>[];

  for (final Map<String, dynamic> game in games) {
    items.add(<String, dynamic>{
      'media_type': 'game',
      'external_id': game['id'],
      'platform_id': spec.platformId,
    });
    mediaGames.add(_gameToDb(game));
  }

  // Download covers.
  final Map<String, String> urlMap = <String, String>{};
  for (final Map<String, dynamic> game in games) {
    final String? url = _gameCoverUrl(game);
    if (url != null) {
      urlMap['game_covers/${game['id']}'] = url;
    }
  }
  stdout.write('  Downloading ${urlMap.length} covers...\n');
  final Map<String, String> images = await _downloadImages(urlMap: urlMap);
  stdout.write('  Downloaded ${images.length} covers\n');

  return _buildXcollx(
    name: spec.name,
    description: spec.description,
    items: items,
    images: images,
    media: <String, dynamic>{'games': mediaGames},
  );
}

Future<Map<String, dynamic>> _generateMovieCollection({
  required CollectionSpec spec,
  required String tmdbKey,
  required String mediaType, // 'movie' or 'animation'
}) async {
  List<Map<String, dynamic>> movies;

  if (spec.type == CollectionType.tmdbTopMovies) {
    stdout.write('  Fetching top rated movies...\n');
    movies = await _fetchTmdbMoviesTopRated(tmdbKey);
  } else {
    stdout.write('  Fetching anime movies (discover)...\n');
    movies = await _fetchTmdbDiscover(
      tmdbKey,
      mediaType: 'movie',
      genreId: spec.genreId,
      voteCountGte: 100,
      sortBy: 'vote_average.desc',
    );
  }
  stdout.write('  Got ${movies.length} movies\n');

  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> mediaMovies = <Map<String, dynamic>>[];

  for (final Map<String, dynamic> m in movies) {
    items.add(<String, dynamic>{
      'media_type': mediaType,
      'external_id': m['id'],
    });
    mediaMovies.add(_movieToDb(m));
  }

  // Download posters.
  final Map<String, String> urlMap = <String, String>{};
  for (final Map<String, dynamic> m in movies) {
    final String? url = _tmdbPosterUrl(m);
    if (url != null) {
      urlMap['movie_posters/${m['id']}'] = url;
    }
  }
  stdout.write('  Downloading ${urlMap.length} posters...\n');
  final Map<String, String> images = await _downloadImages(urlMap: urlMap);
  stdout.write('  Downloaded ${images.length} posters\n');

  return _buildXcollx(
    name: spec.name,
    description: spec.description,
    items: items,
    images: images,
    media: <String, dynamic>{'movies': mediaMovies},
  );
}

Future<Map<String, dynamic>> _generateTvShowCollection({
  required CollectionSpec spec,
  required String tmdbKey,
  required String mediaType, // 'tv_show' or 'animation'
}) async {
  List<Map<String, dynamic>> shows;

  if (spec.type == CollectionType.tmdbTopTvShows) {
    stdout.write('  Fetching top rated TV shows...\n');
    shows = await _fetchTmdbTvShowsTopRated(tmdbKey);
  } else {
    stdout.write('  Fetching anime series (discover)...\n');
    shows = await _fetchTmdbDiscover(
      tmdbKey,
      mediaType: 'tv',
      genreId: spec.genreId,
      voteCountGte: 100,
      sortBy: 'vote_average.desc',
    );
  }
  stdout.write('  Got ${shows.length} TV shows\n');

  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> mediaTvShows = <Map<String, dynamic>>[];

  for (final Map<String, dynamic> s in shows) {
    items.add(<String, dynamic>{
      'media_type': mediaType,
      'external_id': s['id'],
    });
    mediaTvShows.add(_tvShowToDb(s));
  }

  // Download posters.
  final Map<String, String> urlMap = <String, String>{};
  for (final Map<String, dynamic> s in shows) {
    final String? url = _tmdbPosterUrl(s);
    if (url != null) {
      urlMap['tv_show_posters/${s['id']}'] = url;
    }
  }
  stdout.write('  Downloading ${urlMap.length} posters...\n');
  final Map<String, String> images = await _downloadImages(urlMap: urlMap);
  stdout.write('  Downloaded ${images.length} posters\n');

  return _buildXcollx(
    name: spec.name,
    description: spec.description,
    items: items,
    images: images,
    media: <String, dynamic>{'tv_shows': mediaTvShows},
  );
}

// ---------------------------------------------------------------------------
// CLI args parser
// ---------------------------------------------------------------------------

String? _getArg(List<String> args, String name) {
  for (final String arg in args) {
    if (arg.startsWith('--$name=')) {
      return arg.substring('--$name='.length);
    }
  }
  return Platform.environment[name.replaceAll('-', '_').toUpperCase()];
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final String? igdbClientId =
      _getArg(args, 'igdb-client-id') ?? _getArg(args, 'igdb_client_id');
  final String? igdbClientSecret =
      _getArg(args, 'igdb-client-secret') ?? _getArg(args, 'igdb_client_secret');
  final String? tmdbKey =
      _getArg(args, 'tmdb-key') ?? _getArg(args, 'tmdb_key');
  final String? outputDir =
      _getArg(args, 'output') ?? _getArg(args, 'output_dir');

  if (igdbClientId == null ||
      igdbClientSecret == null ||
      tmdbKey == null ||
      outputDir == null) {
    stderr.write(
      'Usage:\n'
      '  dart tool/generate_demo_collections.dart \\\n'
      '    --igdb-client-id=<id> \\\n'
      '    --igdb-client-secret=<secret> \\\n'
      '    --tmdb-key=<bearer_token> \\\n'
      '    --output=<dir>\n'
      '\n'
      'Or set env vars: IGDB_CLIENT_ID, IGDB_CLIENT_SECRET, TMDB_KEY, OUTPUT_DIR\n',
    );
    exit(1);
  }

  // Ensure output dir exists.
  final Directory dir = Directory(outputDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    stdout.write('Created output directory: $outputDir\n');
  }

  stdout.write('=== Demo Collections Generator ===\n');
  stdout.write('Output: $outputDir\n\n');

  // Get IGDB access token.
  stdout.write('Authenticating with IGDB (Twitch)...\n');
  final String igdbToken = await _getIgdbToken(igdbClientId, igdbClientSecret);
  stdout.write('Got IGDB access token.\n\n');

  int successCount = 0;

  for (int i = 0; i < collections.length; i++) {
    final CollectionSpec spec = collections[i];
    stdout.write('--- [${i + 1}/${collections.length}] ${spec.name} ---\n');

    try {
      late Map<String, dynamic> xcollx;

      switch (spec.type) {
        case CollectionType.igdbPlatform:
          xcollx = await _generateGameCollection(
            spec: spec,
            clientId: igdbClientId,
            accessToken: igdbToken,
          );
          break;
        case CollectionType.tmdbTopMovies:
          xcollx = await _generateMovieCollection(
            spec: spec,
            tmdbKey: tmdbKey,
            mediaType: 'movie',
          );
          break;
        case CollectionType.tmdbAnimeMovies:
          xcollx = await _generateMovieCollection(
            spec: spec,
            tmdbKey: tmdbKey,
            mediaType: 'animation',
          );
          break;
        case CollectionType.tmdbTopTvShows:
          xcollx = await _generateTvShowCollection(
            spec: spec,
            tmdbKey: tmdbKey,
            mediaType: 'tv_show',
          );
          break;
        case CollectionType.tmdbAnimeSeries:
          xcollx = await _generateTvShowCollection(
            spec: spec,
            tmdbKey: tmdbKey,
            mediaType: 'animation',
          );
          break;
      }

      // Write file.
      final String filePath = '$outputDir/${spec.fileName}.xcollx';
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String jsonString = encoder.convert(xcollx);
      File(filePath).writeAsStringSync(jsonString);

      final int sizeKb = jsonString.length ~/ 1024;
      stdout.write('  SAVED: ${spec.fileName}.xcollx ($sizeKb KB)\n\n');
      successCount++;
    } catch (e) {
      stderr.write('  ERROR: $e\n\n');
    }
  }

  stdout.write('===================================\n');
  stdout.write('Done! $successCount/${collections.length} files generated.\n');

  _http.close();
}
