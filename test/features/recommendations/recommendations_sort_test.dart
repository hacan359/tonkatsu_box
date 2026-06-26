import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/recommendations/providers/recommendations_provider.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

RecommendedItem _item(
  String title, {
  double? api,
  double? predicted,
  double score = 0.5,
}) =>
    RecommendedItem(
      tasteId: 'movie:$title',
      media: Object(),
      mediaType: MediaType.movie,
      tmdbId: 1,
      title: title,
      posterUrl: null,
      year: null,
      apiRating: api,
      score: score,
      predictedRating: predicted,
    );

List<String> _sorted(List<RecommendedItem> items) {
  final List<RecommendedItem> copy = items.toList()..sort(byRatingDesc);
  return copy.map((RecommendedItem i) => i.title).toList();
}

void main() {
  group('byRatingDesc', () {
    test('orders by TMDB rating, highest first', () {
      expect(
        _sorted(<RecommendedItem>[
          _item('a', api: 5),
          _item('b', api: 9),
          _item('c', api: 7),
        ]),
        <String>['b', 'c', 'a'],
      );
    });

    test('breaks a TMDB-rating tie by predicted personal rating', () {
      expect(
        _sorted(<RecommendedItem>[
          _item('low', api: 8, predicted: 6),
          _item('high', api: 8, predicted: 9),
        ]),
        <String>['high', 'low'],
      );
    });

    test('breaks remaining ties by engine match score', () {
      expect(
        _sorted(<RecommendedItem>[
          _item('weak', api: 8, predicted: 7, score: 0.2),
          _item('strong', api: 8, predicted: 7, score: 0.9),
        ]),
        <String>['strong', 'weak'],
      );
    });

    test('sorts items without a TMDB rating after rated ones', () {
      expect(
        _sorted(<RecommendedItem>[
          _item('unrated', api: null),
          _item('rated', api: 5),
        ]),
        <String>['rated', 'unrated'],
      );
    });

    test('falls back through predicted rating when TMDB rating is absent', () {
      expect(
        _sorted(<RecommendedItem>[
          _item('none', api: null, predicted: null),
          _item('hasApi', api: 3),
          _item('hasPredicted', api: null, predicted: 8),
        ]),
        <String>['hasApi', 'hasPredicted', 'none'],
      );
    });
  });
}
