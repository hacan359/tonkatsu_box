import 'package:dio/dio.dart';

import '../../../shared/models/book.dart';
import 'openlibrary_http_client.dart';

/// `/works/{OLID}.json` plus the calls that enrich a work: `/ratings.json` and
/// `/authors/{OLID}.json`.
class OpenLibraryWorksApi {
  OpenLibraryWorksApi(this._client);

  final OpenLibraryHttpClient _client;

  // Cap author lookups so a work with a huge author list can't fan out into
  // dozens of requests.
  static const int _maxAuthorLookups = 5;

  /// Full work by OLID (`OL27448W`), enriched with ratings and resolved author
  /// names. Returns null on 404.
  Future<Book?> getWork(String olid) async {
    try {
      final Response<dynamic> workResp =
          await _client.get('/works/$olid.json');
      final Object? work = workResp.data;
      if (work is! Map<String, dynamic>) return null;

      final List<Object?> enrich = await Future.wait(<Future<Object?>>[
        _getRatings(olid),
        _resolveAuthorNames(work['authors']),
      ]);

      return Book.fromOpenLibraryWork(
        work,
        ratings: enrich[0] as Map<String, dynamic>?,
        authorNames: (enrich[1] as List<String>?) ?? const <String>[],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load work from OpenLibrary');
    }
  }

  Future<Map<String, dynamic>?> _getRatings(String olid) async {
    try {
      final Response<dynamic> resp =
          await _client.get('/works/$olid/ratings.json');
      return resp.data as Map<String, dynamic>?;
    } on DioException {
      // Ratings are optional — a missing/failed ratings call must not sink the
      // whole work load.
      return null;
    }
  }

  /// Resolves `work.authors[].author.key` (`/authors/OL26320A`) to names via
  /// parallel `/authors/{OLID}.json` lookups, capped at [_maxAuthorLookups].
  Future<List<String>> _resolveAuthorNames(Object? authors) async {
    if (authors is! List<dynamic>) return const <String>[];
    final List<String> keys = <String>[];
    for (final Object? entry in authors) {
      if (entry is! Map<String, dynamic>) continue;
      final Object? author = entry['author'];
      if (author is Map<String, dynamic>) {
        final String? key = author['key'] as String?;
        if (key != null) keys.add(key);
      }
      if (keys.length >= _maxAuthorLookups) break;
    }
    if (keys.isEmpty) return const <String>[];

    final List<String?> names = await Future.wait(keys.map(_getAuthorName));
    return names.whereType<String>().toList();
  }

  Future<String?> _getAuthorName(String key) async {
    try {
      final Response<dynamic> resp = await _client.get('$key.json');
      final Map<String, dynamic>? data = resp.data as Map<String, dynamic>?;
      return data?['name'] as String?;
    } on DioException {
      return null;
    }
  }
}
