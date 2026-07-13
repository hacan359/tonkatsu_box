import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/book.dart';
import '../services/api_key_initializer.dart';
import 'hardcover/hardcover_graphql_client.dart';
import 'hardcover/hardcover_queries.dart';
import 'hardcover/hardcover_search_api.dart';
import 'hardcover/hardcover_types.dart';
import 'hardcover/hardcover_user_library_api.dart';

export 'hardcover/hardcover_types.dart';

/// Wires [HardcoverApi] with the user's personal token. Hardcover has no
/// built-in key — without a token the API rejects every request, so the
/// client throws [HardcoverAuthException] until one is entered in Credentials.
final Provider<HardcoverApi> hardcoverApiProvider =
    Provider<HardcoverApi>((Ref ref) {
  final HardcoverApi api = HardcoverApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  final String? key = keys.hardcoverApiKey;
  if (key != null && key.isNotEmpty) {
    api.setApiKey(key);
  }
  return api;
});

/// Hardcover (`api.hardcover.app/v1/graphql`) facade backing the book search
/// source and the library import. See `hardcover/` for the layer breakdown.
class HardcoverApi {
  HardcoverApi({Dio? dio}) : _client = HardcoverGraphQLClient(dio: dio) {
    _search = HardcoverSearchApi(_client);
    _library = HardcoverUserLibraryApi(_client);
  }

  final HardcoverGraphQLClient _client;
  late final HardcoverSearchApi _search;
  late final HardcoverUserLibraryApi _library;

  static const int searchPageSize = HardcoverSearchApi.pageSize;

  void setApiKey(String apiKey) => _client.setToken(apiKey);

  void clearApiKey() => _client.clearToken();

  bool get hasApiKey => _client.hasToken;

  Future<(List<Book> books, bool hasMore)> searchBooks(
    String query, {
    int page = 1,
    String? sort,
  }) =>
      _search.searchBooks(query, page: page, sort: sort);

  Future<Book?> getBook(String nativeId) => _search.getBook(nativeId);

  Future<List<HardcoverEdition>> getEditions(String bookNativeId) =>
      _search.getEditions(bookNativeId);

  Future<HardcoverEdition?> getEdition(int editionId) =>
      _search.getEdition(editionId);

  Future<int> countUserBooks(String username) =>
      _library.countUserBooks(username);

  Future<List<HardcoverUserBookEntry>> fetchUserBooks({
    required String username,
    void Function(int fetched, int total)? onProgress,
  }) =>
      _library.fetchUserBooks(username: username, onProgress: onProgress);

  /// Lightweight token check for the Credentials "test" button. Sends the
  /// given token explicitly; `me` returns the owner as a one-element list.
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final Map<String, dynamic> body = await _client.post(
        query: HardcoverQueries.me,
        variables: const <String, dynamic>{},
        errorContext: 'Hardcover token check failed',
        tokenOverride: apiKey,
      );
      final Map<String, dynamic>? data =
          body['data'] as Map<String, dynamic>?;
      final Object? me = data?['me'];
      return me is List<dynamic> &&
          me.isNotEmpty &&
          (me.first as Map<String, dynamic>)['id'] != null;
    } on HardcoverApiException {
      return false;
    }
  }

  void dispose() => _client.dispose();
}
