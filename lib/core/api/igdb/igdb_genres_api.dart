import 'package:dio/dio.dart';

import 'igdb_http_client.dart';
import 'igdb_types.dart';

class IgdbGenresApi {
  IgdbGenresApi(this._client);

  final IgdbHttpClient _client;

  Future<List<Map<String, dynamic>>> fetchGenres() async {
    _client.ensureCredentials();

    try {
      final Response<dynamic> response = await _client.post(
        '/genres',
        data: 'fields id,name; limit 50; sort name asc;',
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to fetch genres',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => item as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch genres');
    }
  }
}
