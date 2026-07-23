import 'package:dio/dio.dart';

import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import 'tvmaze_http_client.dart';

/// TV series search / detail on TVmaze (`/search/shows`, `/shows/{id}`).
class TvMazeShowApi {
  TvMazeShowApi(this._client);

  final TvMazeHttpClient _client;

  /// Searches series by title.
  Future<List<TvShow>> searchShows(String query) async {
    try {
      final Response<dynamic> resp = await _client.get(
        'search/shows',
        queryParameters: <String, dynamic>{'q': query},
      );
      final List<dynamic> rows =
          (resp.data as List<dynamic>?) ?? <dynamic>[];
      final List<TvShow> shows = <TvShow>[];
      for (final dynamic row in rows) {
        if (row is Map<String, dynamic>) {
          final Object? show = row['show'];
          if (show is Map<String, dynamic>) {
            shows.add(TvShow.fromTvMaze(show));
          }
        }
      }
      return shows;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search TVmaze');
    }
  }

  /// Full show with embedded seasons.
  Future<TvShow?> getShow(int showId) async {
    try {
      final Response<dynamic> resp = await _client.get(
        'shows/$showId',
        queryParameters: <String, dynamic>{
          'embed[]': <String>['seasons'],
        },
      );
      final Object? data = resp.data;
      if (data is! Map<String, dynamic>) return null;
      return TvShow.fromTvMaze(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load TVmaze show');
    }
  }

  Future<List<TvSeason>> getSeasons(int showId) async {
    try {
      final Response<dynamic> resp = await _client.get('shows/$showId/seasons');
      final List<dynamic> rows =
          (resp.data as List<dynamic>?) ?? <dynamic>[];
      return <TvSeason>[
        for (final dynamic row in rows)
          if (row is Map<String, dynamic>)
            TvSeason.fromTvMaze(row, showId: showId),
      ];
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load TVmaze seasons');
    }
  }

  /// All episodes of a show in one flat list (specials included).
  Future<List<TvEpisode>> getAllEpisodes(int showId) async {
    try {
      final Response<dynamic> resp = await _client.get(
        'shows/$showId/episodes',
        queryParameters: <String, dynamic>{'specials': 1},
      );
      final List<dynamic> rows =
          (resp.data as List<dynamic>?) ?? <dynamic>[];
      final List<TvEpisode> episodes = <TvEpisode>[];
      for (final dynamic row in rows) {
        if (row is Map<String, dynamic>) {
          final TvEpisode? ep = TvEpisode.tryFromTvMaze(row, showId: showId);
          if (ep != null) episodes.add(ep);
        }
      }
      return episodes;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load TVmaze episodes');
    }
  }
}
