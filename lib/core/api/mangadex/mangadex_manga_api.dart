import 'package:core/models/manga.dart';
import 'package:dio/dio.dart';

import 'mangadex_http_client.dart';
import 'mangadex_types.dart';

/// MangaDex ids are UUIDs; [Manga.fromMangaDex] hashes them into the numeric
/// id contract and keeps the UUID in `externalUrl` for [getByUuid] refresh.
class MangaDexMangaApi {
  MangaDexMangaApi(this._client);

  final MangaDexHttpClient _client;

  static const List<String> _defaultContentRatings = <String>[
    'safe',
    'suggestive',
  ];

  /// Keys already carry `[]` (the PHP-array style MangaDex expects), so
  /// [ListFormat.multi] repeats them verbatim; multiCompatible adds a 2nd `[]`.
  static final Options _arrayOptions =
      Options(listFormat: ListFormat.multi);

  static const List<String> _includes = <String>[
    'cover_art',
    'author',
    'artist',
  ];

  /// Chapter/volume counts need a separate `/aggregate` call per title, so
  /// they stay null here; [getByUuid] fills them on demand.
  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
    String? query,
    List<String>? statuses,
    List<String>? demographics,
    List<String>? contentRatings,
    List<String>? includedTags,
    Map<String, String>? order,
    int page = 1,
    int perPage = 20,
  }) async {
    final int offset = (page - 1) * perPage;
    final Map<String, dynamic> qp = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'title': query,
      'limit': perPage,
      'offset': offset,
      'includes[]': _includes,
      'contentRating[]': (contentRatings != null && contentRatings.isNotEmpty)
          ? contentRatings
          : _defaultContentRatings,
      if (statuses != null && statuses.isNotEmpty) 'status[]': statuses,
      if (demographics != null && demographics.isNotEmpty)
        'publicationDemographic[]': demographics,
      if (includedTags != null && includedTags.isNotEmpty) ...<String, dynamic>{
        'includedTags[]': includedTags,
        'includedTagsMode': 'AND',
      },
      if (order != null)
        for (final MapEntry<String, String> e in order.entries)
          'order[${e.key}]': e.value,
    };

    try {
      final Response<dynamic> resp = await _client.get(
        'manga',
        queryParameters: qp,
        options: _arrayOptions,
      );
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<Manga> mangas = _parseSeries(rows);

      final int total = (data['total'] as num?)?.toInt() ?? rows.length;
      final int limit = (data['limit'] as num?)?.toInt() ?? perPage;
      final bool hasMore = offset + rows.length < total;
      final int totalPages = limit > 0 ? (total / limit).ceil() : 1;

      return (mangas, hasMore, totalPages < 1 ? 1 : totalPages);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search MangaDex');
    }
  }

  /// Counts come from `lastChapter`/`lastVolume`, NOT `/aggregate` — that
  /// reflects only English uploads and badly undercounts long series.
  Future<Manga?> getByUuid(String uuid) async {
    try {
      final Response<dynamic> resp = await _client.get(
        'manga/$uuid',
        queryParameters: <String, dynamic>{'includes[]': _includes},
        options: _arrayOptions,
      );
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final Object? series = data['data'];
      if (series is! Map<String, dynamic>) return null;
      return _tryParseManga(series);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load manga from MangaDex');
    }
  }

  /// The recommendation endpoint returns only ids and scores, so top matches
  /// are hydrated in one batched `/manga?ids[]` call, kept in score order.
  Future<List<Manga>> getRecommendations(
    String seedUuid, {
    int limit = 20,
  }) async {
    try {
      final Response<dynamic> resp =
          await _client.get('manga/$seedUuid/recommendation');
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];

      // Insertion order == score order (endpoint sorts by score desc).
      final List<String> orderedUuids = <String>[];
      for (final Map<String, dynamic> row
          in rows.whereType<Map<String, dynamic>>()) {
        final String? uuid = _recommendedUuid(row, seedUuid);
        if (uuid == null || orderedUuids.contains(uuid)) continue;
        orderedUuids.add(uuid);
        if (orderedUuids.length >= limit) break;
      }
      if (orderedUuids.isEmpty) return <Manga>[];

      final Map<String, Manga> byUuid = <String, Manga>{
        for (final Manga m in await _hydrateByIds(orderedUuids))
          if (mangaDexUuidFromUrl(m.externalUrl) case final String u
              when u.isNotEmpty)
            u: m,
      };
      return <Manga>[
        for (final String uuid in orderedUuids)
          if (byUuid[uuid] case final Manga m) m,
      ];
    } on DioException catch (e) {
      throw _client.handleDioException(
        e,
        'Failed to load MangaDex recommendations',
      );
    }
  }

  /// Content ratings mirror the recommendation endpoint's default so nothing
  /// it surfaced is dropped on hydration.
  Future<List<Manga>> _hydrateByIds(List<String> uuids) async {
    final Response<dynamic> resp = await _client.get(
      'manga',
      queryParameters: <String, dynamic>{
        'ids[]': uuids,
        'limit': uuids.length,
        'includes[]': _includes,
        'contentRating[]': <String>['safe', 'suggestive', 'erotica'],
      },
      options: _arrayOptions,
    );
    final Map<String, dynamic> data =
        (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
    return _parseSeries((data['data'] as List<dynamic>?) ?? <dynamic>[]);
  }

  /// The recommended manga's UUID from a recommendation row: the `manga`
  /// relationship that is not the seed itself.
  static String? _recommendedUuid(Map<String, dynamic> row, String seedUuid) {
    final List<dynamic> rels =
        (row['relationships'] as List<dynamic>?) ?? <dynamic>[];
    for (final Map<String, dynamic> rel
        in rels.whereType<Map<String, dynamic>>()) {
      if (rel['type'] == 'manga') {
        final String? id = rel['id'] as String?;
        if (id != null && id != seedUuid) return id;
      }
    }
    return null;
  }

  static List<Manga> _parseSeries(List<dynamic> rows) {
    final List<Manga> out = <Manga>[];
    for (final Map<String, dynamic> row
        in rows.whereType<Map<String, dynamic>>()) {
      final Manga? manga = _tryParseManga(row);
      if (manga != null) out.add(manga);
    }
    return out;
  }

  static Manga? _tryParseManga(Map<String, dynamic> json) {
    try {
      return Manga.fromMangaDex(json);
    } on Object {
      return null;
    }
  }
}
