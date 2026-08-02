import 'package:core/models/book.dart';
import 'package:dio/dio.dart';

import 'fantlab_http_client.dart';

/// `/search-works` — full-text work search. The endpoint takes only `q`, `page`
/// and `onlymatches`; there is no server-side type / year / language filter or
/// sort, so the page is returned by relevance ("weight") and non-book matches
/// (reviews, interviews, articles) are dropped here.
class FantlabSearchApi {
  FantlabSearchApi(this._client);

  final FantlabHttpClient _client;

  /// Server-fixed page size; Fantlab returns 25 matches per page and caps the
  /// reachable result set at 1000.
  static const int pageSize = 25;
  static const int _maxResults = 1000;

  /// `name_eng` work types that are not books and are filtered out of results.
  static const Set<String> _nonBookTypes = <String>{
    'review',
    'interview',
    'article',
  };

  /// Searches works. Returns the page of books plus pagination flags. When
  /// [workType] is set (a Fantlab `name_eng` such as `novel`), only matches of
  /// that type are kept — the API has no server-side type filter.
  Future<(List<Book>, bool hasMore, int totalPages)> searchWorks({
    required String query,
    int page = 1,
    String? workType,
  }) async {
    try {
      final Response<dynamic> resp = await _client.get(
        '/search-works',
        queryParameters: <String, dynamic>{
          'q': query,
          'page': page,
          'onlymatches': 1,
        },
      );

      final Object? body = FantlabHttpClient.decodeBody(resp.data);
      final List<dynamic> matches = _matchesOf(body);
      final List<Book> books = _parseMatches(matches, workType);

      final int totalFound = _totalFound(body, matches.length);
      final int capped = totalFound > _maxResults ? _maxResults : totalFound;
      final int totalPages = (capped / pageSize).ceil();
      final bool hasMore = page * pageSize < capped;

      return (books, hasMore, totalPages < 1 ? 1 : totalPages);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search Fantlab');
    }
  }

  /// `onlymatches=1` returns the bare `matches` array; the default shape nests
  /// it under a `matches` key. Both are handled.
  static List<dynamic> _matchesOf(Object? data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final Object? matches = data['matches'];
      if (matches is List<dynamic>) return matches;
    }
    return const <dynamic>[];
  }

  static int _totalFound(Object? data, int fallback) {
    if (data is Map<String, dynamic>) {
      final Object? found = data['total_found'] ?? data['total'];
      if (found is num) return found.toInt();
      if (found is String) return int.tryParse(found) ?? fallback;
    }
    return fallback;
  }

  /// Parses `matches[]`. With [workType] set, keeps only that `name_eng`;
  /// otherwise drops the non-book types. Skips any malformed entry so one bad
  /// record can't take down the whole page.
  static List<Book> _parseMatches(List<dynamic> matches, String? workType) {
    final bool filterByType = workType != null && workType.isNotEmpty;
    final List<Book> out = <Book>[];
    for (final Map<String, dynamic> match
        in matches.whereType<Map<String, dynamic>>()) {
      final String? type = match['name_eng'] as String?;
      if (filterByType) {
        if (type != workType) continue;
      } else if (type != null && _nonBookTypes.contains(type)) {
        continue;
      }
      try {
        out.add(Book.fromFantlabSearchMatch(match));
      } on Object {
        // Skip malformed match.
      }
    }
    return out;
  }
}
