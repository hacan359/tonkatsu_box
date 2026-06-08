import 'package:dio/dio.dart';

import '../../../shared/models/book.dart';
import 'openlibrary_http_client.dart';

/// `search.json` — full-text work search.
class OpenLibrarySearchApi {
  OpenLibrarySearchApi(this._client);

  final OpenLibraryHttpClient _client;

  // Fields the grid + quick-look sheet need — rating, subjects and page count
  // come back here too, so a card is rich without a per-work fetch.
  static const String _searchFields =
      'key,title,author_name,first_publish_year,cover_i,language,'
      'edition_count,ratings_average,ratings_count,subject,'
      'number_of_pages_median';

  // Scopes the text query to one search field. `q` is the catch-all
  // ("everything"); the rest restrict the match to that field.
  static const Set<String> _scopes = <String>{
    'q',
    'title',
    'author',
    'subject',
  };

  /// Search works. [scope] picks which field the text matches (`q` = anything,
  /// or `title` / `author` / `subject`). [language] is a MARC 3-letter code
  /// (`eng`, `rus`, …); [sort] is an OpenLibrary sort key (empty = relevance).
  Future<(List<Book>, bool hasMore, int totalPages)> search({
    required String query,
    String scope = 'q',
    int page = 1,
    int perPage = 20,
    String? language,
    String? sort,
  }) async {
    final String field = _scopes.contains(scope) ? scope : 'q';
    final Map<String, dynamic> qp = <String, dynamic>{
      field: query,
      'page': page,
      'limit': perPage,
      'fields': _searchFields,
      if (language != null && language.isNotEmpty) 'language': language,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    try {
      final Response<dynamic> resp =
          await _client.get('/search.json', queryParameters: qp);
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> docs =
          (data['docs'] as List<dynamic>?) ?? <dynamic>[];
      final List<Book> books = _parseDocs(docs);

      final int numFound = (data['numFound'] as num?)?.toInt() ?? books.length;
      final int totalPages = perPage > 0 ? (numFound / perPage).ceil() : 1;
      final bool hasMore = page * perPage < numFound;

      return (books, hasMore, totalPages < 1 ? 1 : totalPages);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search OpenLibrary');
    }
  }

  /// Parses `docs[]`, skipping any malformed entry so one bad record can't take
  /// down the whole page (a parse error is an `Error`, not an `Exception`).
  static List<Book> _parseDocs(List<dynamic> docs) {
    final List<Book> out = <Book>[];
    for (final Map<String, dynamic> doc
        in docs.whereType<Map<String, dynamic>>()) {
      try {
        out.add(Book.fromOpenLibrarySearchDoc(doc));
      } on Object {
        // Skip malformed doc.
      }
    }
    return out;
  }
}
