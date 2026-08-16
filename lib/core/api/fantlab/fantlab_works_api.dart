import 'package:core/models/book.dart';
import 'package:dio/dio.dart';

import 'fantlab_editions.dart';
import 'fantlab_http_client.dart';

/// `/work/{id}/extended` (a superset of `/work/{id}`) and `/work/{id}/similars`.
class FantlabWorksApi {
  FantlabWorksApi(this._client);

  final FantlabHttpClient _client;

  /// Full work from `/work/{id}/extended` — it carries the base fields plus
  /// classificatory/awards/editions, so one call is enough. Null on 404.
  Future<Book?> getWork(String id) async {
    try {
      final Response<dynamic> resp = await _client.get('/work/$id/extended');
      final Object? work = FantlabHttpClient.decodeBody(resp.data);
      if (work is! Map<String, dynamic>) return null;
      // A 200 with an error payload (`{"error": …}`) and no work id is "missing".
      if (work['work_id'] == null) return null;
      return Book.fromFantlabWork(work);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load work from Fantlab');
    }
  }

  /// Editions of work [id], grouped by block; covers live at
  /// `/images/editions/big|small/{edition_id}`. Empty on 404 / no editions.
  Future<List<FantlabEditionBlock>> getEditions(String id) async {
    try {
      final Response<dynamic> resp = await _client.get('/work/$id/extended');
      final Object? work = FantlabHttpClient.decodeBody(resp.data);
      if (work is! Map<String, dynamic>) return const <FantlabEditionBlock>[];
      return parseFantlabEditionBlocks(work['editions_blocks']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const <FantlabEditionBlock>[];
      throw _client.handleDioException(
        e,
        'Failed to load editions from Fantlab',
      );
    }
  }

  /// Similar works for [id] (`/work/{id}/similars`, a top-level array). Returns
  /// an empty list when there are none or the call fails softly (404).
  Future<List<Book>> getSimilars(String id) async {
    try {
      final Response<dynamic> resp = await _client.get('/work/$id/similars');
      final Object? data = FantlabHttpClient.decodeBody(resp.data);
      if (data is! List<dynamic>) return const <Book>[];
      final List<Book> out = <Book>[];
      for (final Map<String, dynamic> entry
          in data.whereType<Map<String, dynamic>>()) {
        try {
          out.add(Book.fromFantlabSimilar(entry));
        } on Object {
          // Skip malformed entry.
        }
      }
      return out;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const <Book>[];
      throw _client.handleDioException(
        e,
        'Failed to load similar works from Fantlab',
      );
    }
  }
}
