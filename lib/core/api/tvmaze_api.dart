import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tvmaze/tvmaze_http_client.dart';
import 'tvmaze/tvmaze_show_api.dart';
export 'tvmaze/tvmaze_types.dart';

/// TVmaze API facade (`https://api.tvmaze.com`, keyless). TV series only.
class TvMazeApi {
  TvMazeApi({Dio? dio}) : _client = TvMazeHttpClient(dio: dio) {
    _shows = TvMazeShowApi(_client);
  }

  final TvMazeHttpClient _client;
  late final TvMazeShowApi _shows;

  Future<List<TvShow>> searchShows(String query) =>
      _shows.searchShows(query);

  Future<TvShow?> getShow(int showId) => _shows.getShow(showId);

  Future<List<TvSeason>> getSeasons(int showId) => _shows.getSeasons(showId);

  Future<List<TvEpisode>> getAllEpisodes(int showId) =>
      _shows.getAllEpisodes(showId);

  void dispose() => _client.dispose();
}

final Provider<TvMazeApi> tvMazeApiProvider =
    Provider<TvMazeApi>((Ref ref) => TvMazeApi());
