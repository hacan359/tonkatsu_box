import 'package:dio/dio.dart';

import '../../../shared/models/mangadex_tag.dart';
import 'mangadex_http_client.dart';

/// MangaDex tag catalog (`/manga/tag`). Tags are grouped into
/// genre / theme / format / content; the genre filter uses the genre group.
class MangaDexTagsApi {
  MangaDexTagsApi(this._client);

  final MangaDexHttpClient _client;

  Future<List<MangaDexTag>> fetchTags() async {
    try {
      final Response<dynamic> resp = await _client.get('manga/tag');
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<MangaDexTag> tags = <MangaDexTag>[];
      for (final Map<String, dynamic> row
          in rows.whereType<Map<String, dynamic>>()) {
        try {
          tags.add(MangaDexTag.fromJson(row));
        } on Object {
          // Skip a malformed tag rather than failing the whole catalog.
        }
      }
      return tags;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load MangaDex tags');
    }
  }
}
