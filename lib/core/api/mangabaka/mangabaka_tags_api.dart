import 'package:core/models/mangabaka_tag.dart';
import 'package:dio/dio.dart';

import 'mangabaka_http_client.dart';

/// MangaBaka tag catalog (`/tags`).
class MangaBakaTagsApi {
  MangaBakaTagsApi(this._client);

  final MangaBakaHttpClient _client;

  /// Full tag catalog (`/v1/tags`, ~2700 entries).
  Future<List<MangaBakaTag>> fetchTagCatalog() async {
    try {
      final Response<dynamic> resp = await _client.get('tags');
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<MangaBakaTag> tags = <MangaBakaTag>[];
      for (final Map<String, dynamic> row
          in rows.whereType<Map<String, dynamic>>()) {
        try {
          tags.add(MangaBakaTag.fromJson(row));
        } on Object {
          // Skip a malformed tag entry rather than failing the whole catalog.
        }
      }
      return tags;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load MangaBaka tags');
    }
  }
}
