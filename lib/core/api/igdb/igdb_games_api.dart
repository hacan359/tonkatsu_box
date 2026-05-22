import 'package:dio/dio.dart';

import '../../../shared/models/game.dart';
import 'igdb_http_client.dart';
import 'igdb_types.dart';

class IgdbGamesApi {
  IgdbGamesApi(this._client);

  final IgdbHttpClient _client;

  static const String _gameFields = '''
    fields id, name, summary, rating, rating_count, first_release_date,
           cover.image_id, artworks.image_id, genres.name, platforms, url;
  ''';

  /// IGDB multiquery cap: 10 sub-queries per request.
  static const int maxMultiQueryBatch = 10;

  static const int _multiSearchLimit = 20;

  /// IGDB `external_game_source` value for Steam.
  static const int _steamSource = 1;

  Future<List<Game>> searchGames({
    required String query,
    List<int>? genreIds,
    List<int>? platformIds,
    List<int>? gameModeIds,
    int? minRating,
    int? year,
    (int, int)? decade,
    int limit = 20,
    int offset = 0,
  }) async {
    _client.ensureCredentials();

    if (query.trim().isEmpty) {
      return <Game>[];
    }

    try {
      final String escapedQuery = query.replaceAll('"', '\\"');

      // IGDB query order: fields -> where -> search -> limit.
      final StringBuffer body = StringBuffer(_gameFields);

      // IGDB: `field = (a,b)` is ANY-of (OR match).
      final List<String> conditions = <String>[];
      if (platformIds != null && platformIds.isNotEmpty) {
        conditions.add('platforms = (${platformIds.join(",")})');
      }
      if (genreIds != null && genreIds.isNotEmpty) {
        conditions.add('genres = (${genreIds.join(",")})');
      }
      if (gameModeIds != null && gameModeIds.isNotEmpty) {
        conditions.add('game_modes = (${gameModeIds.join(",")})');
      }
      if (minRating != null) {
        conditions.add('rating >= $minRating');
      }
      if (year != null) {
        final int start =
            DateTime(year).millisecondsSinceEpoch ~/ 1000;
        final int end =
            DateTime(year + 1).millisecondsSinceEpoch ~/ 1000;
        conditions.add(
          'first_release_date >= $start & first_release_date < $end',
        );
      } else if (decade != null) {
        final int start =
            DateTime(decade.$1).millisecondsSinceEpoch ~/ 1000;
        final int end =
            DateTime(decade.$2 + 1).millisecondsSinceEpoch ~/ 1000;
        conditions.add(
          'first_release_date >= $start & first_release_date < $end',
        );
      }
      if (conditions.isNotEmpty) {
        body.write(' where ${conditions.join(" & ")};');
      }

      body.write(' search "$escapedQuery"; limit $limit;');
      if (offset > 0) {
        body.write(' offset $offset;');
      }

      final Response<dynamic> response = await _client.post(
        '/games',
        data: body.toString(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to search games',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search games');
    }
  }

  Future<Map<int, List<Game>>> multiSearchGamesByName(
    List<({String name, int? platformId})> queries,
  ) async {
    if (queries.isEmpty) return <int, List<Game>>{};
    _client.ensureCredentials();

    const String fields =
        'fields id,name,summary,rating,rating_count,first_release_date,'
        'cover.image_id,genres.name,platforms,url;';

    try {
      final StringBuffer body = StringBuffer();
      for (int i = 0; i < queries.length; i++) {
        final String escaped = queries[i]
            .name
            .replaceAll('"', '\\"')
            .replaceAll('*', '');
        final String platformFilter = queries[i].platformId != null
            ? ' & platforms = (${queries[i].platformId})'
            : '';
        body.writeln(
          'query games "q_$i" { $fields '
          'where name ~ *"$escaped"*$platformFilter; '
          'limit $_multiSearchLimit; };',
        );
      }

      final Response<dynamic> response = await _client.post(
        '/multiquery',
        data: body.toString(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to multi-search games',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> results = response.data as List<dynamic>;
      final Map<int, List<Game>> mapped = <int, List<Game>>{};

      for (final dynamic entry in results) {
        final Map<String, dynamic> item = entry as Map<String, dynamic>;
        final String name = item['name'] as String;
        final int? index = int.tryParse(name.replaceFirst('q_', ''));
        if (index == null) continue;

        final List<dynamic> resultList =
            (item['result'] as List<dynamic>?) ?? <dynamic>[];
        mapped[index] = resultList
            .map((dynamic g) => Game.fromJson(g as Map<String, dynamic>))
            .toList();
      }

      for (int i = 0; i < queries.length; i++) {
        mapped.putIfAbsent(i, () => <Game>[]);
      }

      return mapped;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to multi-search games');
    }
  }

  Future<Map<String, Game>> lookupSteamGames(
    List<String> steamAppIds,
  ) async {
    if (steamAppIds.isEmpty) return <String, Game>{};
    _client.ensureCredentials();

    try {
      // Step 1: Steam appId -> IGDB game id via external_games.
      final Map<String, int> uidToGameId = <String, int>{};

      for (int offset = 0; offset < steamAppIds.length; offset += 500) {
        final List<String> batch = steamAppIds.sublist(
          offset,
          offset + 500 > steamAppIds.length
              ? steamAppIds.length
              : offset + 500,
        );
        final String uidList = batch.map((String id) => '"$id"').join(',');

        final Response<dynamic> response = await _client.post(
          '/external_games',
          data: 'fields game,uid; '
              'where external_game_source = $_steamSource '
              '& uid = ($uidList); '
              'limit 500;',
        );

        if (response.statusCode != 200 || response.data == null) {
          throw IgdbApiException(
            'Failed to lookup Steam games',
            statusCode: response.statusCode,
          );
        }

        final List<dynamic> data = response.data as List<dynamic>;
        for (final dynamic item in data) {
          final Map<String, dynamic> map = item as Map<String, dynamic>;
          final String uid = map['uid'] as String;
          final int gameId = map['game'] as int;
          uidToGameId[uid] = gameId;
        }
      }

      if (uidToGameId.isEmpty) return <String, Game>{};

      // Step 2: fetch full game data by IGDB id (deduped).
      final List<Game> games =
          await getGamesByIds(uidToGameId.values.toSet().toList());

      final Map<int, Game> gamesById = <int, Game>{
        for (final Game game in games) game.id: game,
      };

      final Map<String, Game> result = <String, Game>{};
      for (final MapEntry<String, int> entry in uidToGameId.entries) {
        final Game? game = gamesById[entry.value];
        if (game != null) {
          result[entry.key] = game;
        }
      }

      return result;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to lookup Steam games');
    }
  }

  Future<Game?> getGameById(int gameId) async {
    _client.ensureCredentials();

    try {
      final Response<dynamic> response = await _client.post(
        '/games',
        data: '$_gameFields where id = $gameId;',
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to fetch game',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      if (data.isEmpty) return null;

      return Game.fromJson(data.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch game');
    }
  }

  Future<List<Game>> getGamesByIds(List<int> gameIds) async {
    _client.ensureCredentials();

    if (gameIds.isEmpty) {
      return <Game>[];
    }

    try {
      // IGDB caps a single request at 500 records.
      final List<Game> allGames = <Game>[];

      for (int i = 0; i < gameIds.length; i += 500) {
        final List<int> batch = gameIds.sublist(
          i,
          i + 500 > gameIds.length ? gameIds.length : i + 500,
        );

        final String idsString = batch.join(',');

        final Response<dynamic> response = await _client.post(
          '/games',
          data: '$_gameFields where id = ($idsString); limit 500;',
        );

        if (response.statusCode != 200 || response.data == null) {
          throw IgdbApiException(
            'Failed to fetch games',
            statusCode: response.statusCode,
          );
        }

        final List<dynamic> data = response.data as List<dynamic>;
        final List<Game> games = data
            .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
            .toList();

        allGames.addAll(games);
      }

      return allGames;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch games');
    }
  }

  Future<List<Game>> getTopGamesByPlatform({
    required int platformId,
    int minRatingCount = 20,
    int limit = 50,
  }) async {
    _client.ensureCredentials();

    try {
      final StringBuffer body = StringBuffer(_gameFields);
      body.write(
        ' where platforms = ($platformId)'
        ' & rating_count >= $minRatingCount'
        ' & rating != null;',
      );
      body.write(' sort rating desc;');
      body.write(' limit $limit;');

      final Response<dynamic> response = await _client.post(
        '/games',
        data: body.toString(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to fetch top games',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch top games');
    }
  }

  Future<List<Game>> browseGames({
    List<int>? genreIds,
    List<int>? platformIds,
    List<int>? gameModeIds,
    int? minRating,
    int? year,
    (int, int)? decade,
    String sortBy = 'rating desc',
    int limit = 20,
    int offset = 0,
    int minRatingCount = 10,
  }) async {
    _client.ensureCredentials();

    try {
      final StringBuffer where =
          StringBuffer('where rating_count > $minRatingCount');

      if (genreIds != null && genreIds.isNotEmpty) {
        where.write(' & genres = (${genreIds.join(",")})');
      }
      if (platformIds != null && platformIds.isNotEmpty) {
        where.write(' & platforms = (${platformIds.join(",")})');
      }
      if (gameModeIds != null && gameModeIds.isNotEmpty) {
        where.write(' & game_modes = (${gameModeIds.join(",")})');
      }
      if (minRating != null) {
        where.write(' & rating >= $minRating');
      }
      if (year != null) {
        final int start =
            DateTime(year).millisecondsSinceEpoch ~/ 1000;
        final int end =
            DateTime(year + 1).millisecondsSinceEpoch ~/ 1000;
        where.write(
          ' & first_release_date >= $start & first_release_date < $end',
        );
      } else if (decade != null) {
        final int start =
            DateTime(decade.$1).millisecondsSinceEpoch ~/ 1000;
        final int end =
            DateTime(decade.$2 + 1).millisecondsSinceEpoch ~/ 1000;
        where.write(
          ' & first_release_date >= $start & first_release_date < $end',
        );
      }

      final StringBuffer body = StringBuffer(_gameFields);
      body.write(' $where;');
      body.write(' sort $sortBy;');
      body.write(' limit $limit;');
      if (offset > 0) {
        body.write(' offset $offset;');
      }

      final Response<dynamic> response = await _client.post(
        '/games',
        data: body.toString(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to browse games',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to browse games');
    }
  }
}
