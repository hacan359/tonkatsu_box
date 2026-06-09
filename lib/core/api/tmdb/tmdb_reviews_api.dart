import 'package:dio/dio.dart';

import '../../../shared/models/tmdb_review.dart';
import 'tmdb_http_client.dart';

/// Movie / TV reviews. Always queried in en-US — non-English reviews are
/// sparse on TMDB.
class TmdbReviewsApi {
  TmdbReviewsApi(this._client);

  final TmdbHttpClient _client;

  Future<List<TmdbReview>> getMovieReviews(int tmdbId, {int page = 1}) {
    return _fetchReviews('/movie/$tmdbId/reviews', page: page);
  }

  Future<List<TmdbReview>> getTvReviews(int tmdbId, {int page = 1}) {
    return _fetchReviews('/tv/$tmdbId/reviews', page: page);
  }

  Future<List<TmdbReview>> _fetchReviews(String path, {int page = 1}) async {
    _client.ensureApiKey();

    try {
      final Response<dynamic> response = await _client.get(
        path,
        queryParameters: <String, dynamic>{'page': page},
        language: 'en-US',
      );

      final List<Map<String, dynamic>> items = _client.extractResults(
        response,
        'Failed to fetch reviews from $path',
      );
      return items.map(TmdbReview.fromJson).toList();
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to fetch reviews');
    }
  }
}
