import 'package:core/models/audio_item.dart';
import 'package:core/models/audio_track.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_key_initializer.dart';
import 'podcast_index/podcast_index_http_client.dart';

export 'podcast_index/podcast_index_http_client.dart'
    show PodcastIndexApiException;

/// User keys first, the build-time pair as fallback; without either, requests
/// throw until keys are entered in Credentials.
final Provider<PodcastIndexApi> podcastIndexApiProvider =
    Provider<PodcastIndexApi>((Ref ref) {
  final PodcastIndexApi api = PodcastIndexApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  final String? key = keys.podcastIndexApiKey;
  final String? secret = keys.podcastIndexApiSecret;
  if (key != null && key.isNotEmpty && secret != null && secret.isNotEmpty) {
    api.setCredentials(key, secret);
  }
  ref.onDispose(api.dispose);
  return api;
});

/// Search has no pagination and clamps `max` to 60; `/episodes/byfeedid` caps
/// at the newest 1000, and `fulltext` lifts the 100-word description cut.
class PodcastIndexApi {
  PodcastIndexApi({Dio? dio, DateTime Function()? now})
      : _client = PodcastIndexHttpClient(dio: dio, now: now);

  final PodcastIndexHttpClient _client;

  /// The documented ceiling of `/episodes/byfeedid`.
  static const int maxEpisodesPerFetch = 1000;

  /// Search clamps `max` to 60 server-side; ask for the whole window.
  static const int searchLimit = 60;

  void setCredentials(String key, String secret) =>
      _client.setCredentials(key, secret);

  void clearCredentials() => _client.clearCredentials();

  bool get hasCredentials => _client.hasCredentials;

  /// Relevance-ranked feed search — a single page (no pagination upstream).
  Future<List<AudioItem>> search(String term, {int max = searchLimit}) async {
    try {
      final Response<dynamic> response = await _client.get(
        'search/byterm',
        queryParameters: <String, dynamic>{
          'q': term,
          'max': max,
          'fulltext': '',
        },
      );
      return _feedList(response.data);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Podcast search failed');
    }
  }

  /// Full feed record for the detail sheet / enrich.
  Future<AudioItem?> getPodcast(int feedId) async {
    try {
      final Response<dynamic> response = await _client.get(
        'podcasts/byfeedid',
        queryParameters: <String, dynamic>{'id': feedId, 'fulltext': ''},
      );
      final Object? data = response.data;
      final Object? feed =
          data is Map<String, dynamic> ? data['feed'] : null;
      // A missing feed comes back as an empty list, not a map.
      if (feed is! Map<String, dynamic> || feed['id'] == null) return null;
      return AudioItem.fromPodcastIndexFeed(feed);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load podcast');
    }
  }

  /// Newest episodes (≤1000). Pass [since] (unix seconds) to fetch only what
  /// was published after the cached watermark.
  Future<List<AudioTrack>> getEpisodes(
    int feedId, {
    int? since,
    int max = maxEpisodesPerFetch,
  }) async {
    try {
      final Response<dynamic> response = await _client.get(
        'episodes/byfeedid',
        queryParameters: <String, dynamic>{
          'id': feedId,
          'max': max,
          'since': ?since,
          'fulltext': '',
        },
      );
      final Object? data = response.data;
      final Object? items =
          data is Map<String, dynamic> ? data['items'] : null;
      if (items is! List<dynamic>) return const <AudioTrack>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> e) =>
              AudioTrack.fromPodcastIndexEpisode(e, audioId: feedId))
          .where((AudioTrack t) => t.position != 0)
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load episodes');
    }
  }

  /// Trending feeds — the browse/discover source. [lang] is a comma-separated
  /// language list (`en`, `ru`); [category] a category name or id.
  Future<List<AudioItem>> getTrending({
    int max = 40,
    String? lang,
    String? category,
  }) async {
    try {
      final Response<dynamic> response = await _client.get(
        'podcasts/trending',
        queryParameters: <String, dynamic>{
          'max': max,
          if (lang != null && lang.isNotEmpty) 'lang': lang,
          if (category != null && category.isNotEmpty) 'cat': category,
        },
      );
      return _feedList(response.data);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load trending podcasts');
    }
  }

  /// True when the current pair signs a request the API accepts.
  Future<bool> validateCredentials() async {
    try {
      await getTrending(max: 1);
      return true;
    } on PodcastIndexApiException {
      return false;
    }
  }

  static List<AudioItem> _feedList(Object? data) {
    final Object? feeds = data is Map<String, dynamic> ? data['feeds'] : null;
    if (feeds is! List<dynamic>) return const <AudioItem>[];
    return feeds
        .whereType<Map<String, dynamic>>()
        .map(AudioItem.fromPodcastIndexFeed)
        .where((AudioItem p) => p.id != 0)
        .toList();
  }

  void dispose() => _client.dispose();
}
