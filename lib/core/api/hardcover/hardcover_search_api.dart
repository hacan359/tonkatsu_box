import 'package:core/models/book.dart';

import 'hardcover_graphql_client.dart';
import 'hardcover_queries.dart';
import 'hardcover_types.dart';

class HardcoverSearchApi {
  HardcoverSearchApi(this._client);

  static const int pageSize = 25;

  /// Popular books rarely exceed a couple hundred editions, so one request
  /// covers the picker without paging.
  static const int editionsLimit = 200;

  final HardcoverGraphQLClient _client;

  /// [sort] is a Typesense `field:direction` pair (`users_count:desc`, …);
  /// null sorts by relevance.
  Future<(List<Book> books, bool hasMore)> searchBooks(
    String query, {
    int page = 1,
    String? sort,
  }) async {
    final Map<String, dynamic> body = await _client.post(
      query: HardcoverQueries.search,
      variables: <String, dynamic>{
        'query': query,
        'perPage': pageSize,
        'page': page,
        'sort': sort,
      },
      errorContext: 'Hardcover search failed',
    );
    final Map<String, dynamic> data =
        _client.ensureData(body, 'Hardcover search failed');

    final Map<String, dynamic>? results = _searchResults(data);
    if (results == null) return (const <Book>[], false);

    final List<Book> books = <Book>[];
    final Object? hits = results['hits'];
    if (hits is List<dynamic>) {
      for (final Map<String, dynamic> hit
          in hits.whereType<Map<String, dynamic>>()) {
        final Object? document = hit['document'];
        if (document is Map<String, dynamic>) {
          books.add(Book.fromHardcoverDocument(document));
        }
      }
    }

    final int found = (results['found'] as num?)?.toInt() ?? 0;
    final bool hasMore = books.length >= pageSize && page * pageSize < found;
    return (books, hasMore);
  }

  /// Full book by its numeric id (stored as [Book.nativeId]). Returns null
  /// when the book is missing.
  Future<Book?> getBook(String nativeId) async {
    final int? id = int.tryParse(nativeId);
    if (id == null) return null;

    final Map<String, dynamic> body = await _client.post(
      query: HardcoverQueries.bookById,
      variables: <String, dynamic>{'id': id},
      errorContext: 'Hardcover book fetch failed',
    );
    final Map<String, dynamic> data =
        _client.ensureData(body, 'Hardcover book fetch failed');

    final Object? book = data['books_by_pk'];
    if (book is! Map<String, dynamic>) return null;
    return Book.fromHardcoverBook(book);
  }

  /// Editions of a book, most-owned first.
  Future<List<HardcoverEdition>> getEditions(String bookNativeId) async {
    final int? bookId = int.tryParse(bookNativeId);
    if (bookId == null) return const <HardcoverEdition>[];

    final Map<String, dynamic> body = await _client.post(
      query: HardcoverQueries.editionsByBook,
      variables: <String, dynamic>{'bookId': bookId, 'limit': editionsLimit},
      errorContext: 'Hardcover editions fetch failed',
    );
    final Map<String, dynamic> data =
        _client.ensureData(body, 'Hardcover editions fetch failed');

    final Object? editions = data['editions'];
    if (editions is! List<dynamic>) return const <HardcoverEdition>[];
    return <HardcoverEdition>[
      for (final Map<String, dynamic> json
          in editions.whereType<Map<String, dynamic>>())
        HardcoverEdition.fromJson(json),
    ];
  }

  /// One edition by id; null when it no longer exists.
  Future<HardcoverEdition?> getEdition(int editionId) async {
    final Map<String, dynamic> body = await _client.post(
      query: HardcoverQueries.editionById,
      variables: <String, dynamic>{'id': editionId},
      errorContext: 'Hardcover edition fetch failed',
    );
    final Map<String, dynamic> data =
        _client.ensureData(body, 'Hardcover edition fetch failed');

    final Object? edition = data['editions_by_pk'];
    if (edition is! Map<String, dynamic>) return null;
    return HardcoverEdition.fromJson(edition);
  }

  static Map<String, dynamic>? _searchResults(Map<String, dynamic> data) {
    final Object? search = data['search'];
    if (search is! Map<String, dynamic>) return null;
    final Object? results = search['results'];
    return results is Map<String, dynamic> ? results : null;
  }
}
