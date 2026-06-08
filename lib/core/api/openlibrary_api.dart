import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/book.dart';
import 'openlibrary/openlibrary_http_client.dart';
import 'openlibrary/openlibrary_search_api.dart';
import 'openlibrary/openlibrary_works_api.dart';

export 'openlibrary/openlibrary_types.dart';

/// OpenLibrary REST facade. See `openlibrary/README.md` for the layer
/// breakdown.
class OpenLibraryApi {
  OpenLibraryApi({Dio? dio}) : _client = OpenLibraryHttpClient(dio: dio) {
    _search = OpenLibrarySearchApi(_client);
    _works = OpenLibraryWorksApi(_client);
  }

  final OpenLibraryHttpClient _client;
  late final OpenLibrarySearchApi _search;
  late final OpenLibraryWorksApi _works;

  /// Search works. [scope] picks the search field (`q` / `title` / `author` /
  /// `subject`), [language] is a MARC 3-letter code, [sort] an OpenLibrary sort
  /// key.
  Future<(List<Book>, bool hasMore, int totalPages)> search({
    required String query,
    String scope = 'q',
    int page = 1,
    int perPage = 20,
    String? language,
    String? sort,
  }) =>
      _search.search(
        query: query,
        scope: scope,
        page: page,
        perPage: perPage,
        language: language,
        sort: sort,
      );

  /// Full work by OLID (`OL27448W`), enriched with ratings and author names.
  Future<Book?> getWork(String olid) => _works.getWork(olid);

  void dispose() => _client.dispose();
}

final Provider<OpenLibraryApi> openLibraryApiProvider =
    Provider<OpenLibraryApi>((Ref ref) => OpenLibraryApi());
