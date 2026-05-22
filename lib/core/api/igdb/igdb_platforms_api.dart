import 'package:dio/dio.dart';

import '../../../shared/models/platform.dart';
import 'igdb_http_client.dart';
import 'igdb_types.dart';

class IgdbPlatformsApi {
  IgdbPlatformsApi(this._client);

  final IgdbHttpClient _client;

  Future<List<Platform>> fetchPlatforms() async {
    _client.ensureCredentials();

    try {
      final List<Platform> allPlatforms = <Platform>[];
      int offset = 0;
      const int limit = 500;

      while (true) {
        final Response<dynamic> response = await _client.post(
          '/platforms',
          data: 'fields id,name,abbreviation; limit $limit; offset $offset;',
        );

        if (response.statusCode != 200 || response.data == null) {
          throw IgdbApiException(
            'Failed to fetch platforms',
            statusCode: response.statusCode,
          );
        }

        final List<dynamic> data = response.data as List<dynamic>;
        if (data.isEmpty) break;

        final List<Platform> platforms = data
            .map((dynamic item) =>
                Platform.fromJson(item as Map<String, dynamic>))
            .toList();

        allPlatforms.addAll(platforms);

        if (data.length < limit) break;
        offset += limit;
      }

      return allPlatforms;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch platforms');
    }
  }

  Future<List<Platform>> fetchPlatformsByIds(List<int> ids) async {
    if (ids.isEmpty) return <Platform>[];
    _client.ensureCredentials();

    try {
      final String idList = ids.join(',');
      final Response<dynamic> response = await _client.post(
        '/platforms',
        data:
            'fields id,name,abbreviation; where id = ($idList); limit 500;',
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to fetch platforms by IDs',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) =>
              Platform.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch platforms by IDs');
    }
  }
}
