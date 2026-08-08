import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:dio/dio.dart';

import 'tvdb_http_client.dart';

/// `/series` — detail, seasons, episodes and genre-filtered browse.
class TvdbSeriesApi {
  TvdbSeriesApi(this._client);

  final TvdbHttpClient _client;

  /// Episodes come 500 per page; long-running shows need several.
  static const int _maxEpisodePages = 20;

  /// The episode tracker asks for the show and then its seasons, and both live
  /// in the same extended record — without this the endpoint is hit twice.
  int? _extendedId;
  Map<String, dynamic>? _extended;

  Future<TvShow?> getSeries(int id, {required String locale}) async {
    try {
      final Map<String, dynamic>? data = await _loadExtended(id);
      if (data == null) return null;
      return TvShow.fromTvdb(data, locale: locale);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load TheTVDB series');
    }
  }

  Future<Map<String, dynamic>?> _loadExtended(int id) async {
    if (_extendedId == id && _extended != null) return _extended;
    final Response<dynamic> response = await _client.get(
      'series/$id/extended',
      queryParameters: <String, dynamic>{
        'meta': 'translations',
        'short': true,
      },
    );
    _extended = _client.dataObject(response);
    _extendedId = _extended == null ? null : id;
    return _extended;
  }

  /// Seasons live inside the extended record, filtered to the aired order —
  /// DVD and absolute orders are alternative numberings of the same episodes.
  Future<List<TvSeason>> getSeasons(int id) async {
    try {
      final Map<String, dynamic>? data = await _loadExtended(id);
      final Object? seasons = data?['seasons'];
      if (seasons is! List<dynamic>) return const <TvSeason>[];

      final int defaultType = (data?['defaultSeasonType'] as int?) ?? 1;
      final List<TvSeason> result = <TvSeason>[
        for (final dynamic s in seasons)
          if (s is Map<String, dynamic> &&
              (s['type'] as Map<String, dynamic>?)?['id'] == defaultType)
            TvSeason.fromTvdb(s, showId: id),
      ]..sort((TvSeason a, TvSeason b) =>
          a.seasonNumber.compareTo(b.seasonNumber));
      return result;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load TheTVDB seasons');
    }
  }

  Future<List<TvEpisode>> getAllEpisodes(int id) async {
    final List<TvEpisode> episodes = <TvEpisode>[];
    try {
      for (int page = 0; page < _maxEpisodePages; page++) {
        final Response<dynamic> response = await _client.get(
          'series/$id/episodes/default',
          queryParameters: <String, dynamic>{'page': page},
        );
        final Map<String, dynamic>? data = _client.dataObject(response);
        final Object? raw = data?['episodes'];
        if (raw is! List<dynamic>) break;

        for (final dynamic e in raw) {
          if (e is! Map<String, dynamic>) continue;
          final TvEpisode? episode = TvEpisode.tryFromTvdb(e, showId: id);
          if (episode != null) episodes.add(episode);
        }

        final Object? links = (response.data as Map<String, dynamic>?)?['links'];
        final Object? next =
            links is Map<String, dynamic> ? links['next'] : null;
        if (next == null) break;
      }
      return episodes;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const <TvEpisode>[];
      throw _client.handleDioException(e, 'Failed to load TheTVDB episodes');
    }
  }

  Future<List<TvShow>> browse({
    required String locale,
    int? genreId,
    int? year,
    int? statusId,
    String sort = 'score',
    int page = 0,
  }) async {
    try {
      final Response<dynamic> response = await _client.get(
        'series/filter',
        queryParameters: <String, dynamic>{
          'lang': 'eng',
          'sort': sort.isEmpty ? 'score' : sort,
          'page': page,
          'genre': ?genreId,
          'year': ?year,
          'status': ?statusId,
        },
      );
      return _client
          .dataList(response)
          .map((Map<String, dynamic> j) => TvShow.fromTvdb(j, locale: locale))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to browse TheTVDB series');
    }
  }

  /// One flat list shared by movies and series, unlike TMDB's two catalogs.
  Future<List<({int id, String name})>> getGenres() async {
    try {
      final Response<dynamic> response = await _client.get('genres');
      return <({int id, String name})>[
        for (final Map<String, dynamic> g in _client.dataList(response))
          if (g['id'] is int && g['name'] is String)
            (id: g['id'] as int, name: g['name'] as String),
      ];
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load TheTVDB genres');
    }
  }
}
