import 'package:dio/dio.dart';

import '../../../shared/models/manga.dart';
import 'mangadex_http_client.dart';

/// Manga search / detail on MangaDex (`/manga`).
///
/// MangaDex ids are UUIDs; [Manga.fromMangaDex] folds them into the numeric
/// id contract (FNV-1a hash) and keeps the UUID in `externalUrl`, so
/// [getByUuid] is the id-recovering entry point used by refresh.
class MangaDexMangaApi {
  MangaDexMangaApi(this._client);

  final MangaDexHttpClient _client;

  static const List<String> _defaultContentRatings = <String>[
    'safe',
    'suggestive',
  ];

  /// Repeated bracketed keys (`includes[]=cover_art&includes[]=author`) — the
  /// PHP-array style MangaDex expects. The keys already carry `[]`, so
  /// [ListFormat.multi] repeats them verbatim (multiCompatible would append a
  /// second `[]`).
  static final Options _arrayOptions =
      Options(listFormat: ListFormat.multi);

  static const List<String> _includes = <String>[
    'cover_art',
    'author',
    'artist',
  ];

  /// Search / browse manga. Chapter / volume counts need a separate
  /// `/aggregate` call per title, so they stay null here and are filled by
  /// [getByUuid] on demand.
  ///
  /// [order] is a `{field: 'asc'|'desc'}` map (e.g. `{'followedCount': 'desc'}`)
  /// passed straight through as `order[field]=dir`. [includedTags] are tag
  /// UUIDs combined with AND.
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

  /// Full manga by UUID. Chapter / volume counts come from the manga object's
  /// `lastChapter` / `lastVolume` (the series totals, parsed in
  /// [Manga.fromMangaDex]) — NOT from `/aggregate`, which only reflects the
  /// English-translated chapters uploaded to MangaDex and badly undercounts
  /// long series (Naruto → a handful instead of 700).
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
