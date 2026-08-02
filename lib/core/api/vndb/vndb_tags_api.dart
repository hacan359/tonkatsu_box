import 'package:core/models/visual_novel.dart';
import 'package:dio/dio.dart';

import 'vndb_http_client.dart';
import 'vndb_types.dart';

/// VNDB tag catalog (`/tag`).
class VndbTagsApi {
  VndbTagsApi(this._client);

  final VndbHttpClient _client;

  /// Fetches the top 100 content tags (VNDB category `cont`) sorted by usage
  /// count — these are what we surface as "genres" in the UI.
  Future<List<VndbTag>> fetchTags() async {
    try {
      final Response<dynamic> response = await _client.post(
        '/tag',
        data: <String, dynamic>{
          'filters': <dynamic>['category', '=', 'cont'],
          'fields': 'name',
          'results': 100,
          'sort': 'vn_count',
          'reverse': true,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to fetch tags',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results =
          data['results'] as List<dynamic>? ?? <dynamic>[];

      return results
          .map((dynamic item) =>
              VndbTag.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch tags');
    }
  }
}
