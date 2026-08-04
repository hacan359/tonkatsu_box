import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/recommendations/providers/recommendations_provider.dart';

import '../../helpers/test_helpers.dart';

void main() {
  RecommendedItem itemFor(Object media, MediaType mediaType) => RecommendedItem(
        tasteId: 'taste:1',
        media: media,
        mediaType: mediaType,
        tmdbId: 1,
        title: 'Dune',
        posterUrl: null,
        year: null,
        apiRating: null,
        score: 1,
        predictedRating: null,
      );

  group('RecommendedItem', () {
    group('externalUrl', () {
      test('should take the url from the underlying movie', () {
        final RecommendedItem item = itemFor(
          createTestMovie(externalUrl: 'https://example.org/movie/42'),
          MediaType.movie,
        );

        expect(item.externalUrl, 'https://example.org/movie/42');
      });

      test('should take the url from the underlying tv show', () {
        final RecommendedItem item = itemFor(
          createTestTvShow(externalUrl: 'https://example.org/tv/7'),
          MediaType.tvShow,
        );

        expect(item.externalUrl, 'https://example.org/tv/7');
      });

      test('should be null when the underlying movie has no url', () {
        expect(itemFor(createTestMovie(), MediaType.movie).externalUrl, isNull);
      });

      test('should be null when media is neither a movie nor a tv show', () {
        expect(itemFor(Object(), MediaType.movie).externalUrl, isNull);
      });
    });
  });
}
