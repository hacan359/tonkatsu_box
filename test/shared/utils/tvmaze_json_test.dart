import 'package:core/utils/tvmaze_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tvMazeImageUrl', () {
    test('prefers original over medium', () {
      expect(
        tvMazeImageUrl(<String, dynamic>{
          'medium': 'm.jpg',
          'original': 'o.jpg',
        }),
        'o.jpg',
      );
    });

    test('falls back to medium when original is absent', () {
      expect(tvMazeImageUrl(<String, dynamic>{'medium': 'm.jpg'}), 'm.jpg');
    });

    test('returns null when not a map or null', () {
      expect(tvMazeImageUrl(null), isNull);
      expect(tvMazeImageUrl('nope'), isNull);
    });
  });

  group('tvMazeRating', () {
    test('reads average as double', () {
      expect(tvMazeRating(<String, dynamic>{'average': 8.2}), 8.2);
    });

    test('coerces int average to double', () {
      expect(tvMazeRating(<String, dynamic>{'average': 8}), 8.0);
    });

    test('returns null when average or object is missing', () {
      expect(tvMazeRating(<String, dynamic>{'average': null}), isNull);
      expect(tvMazeRating(null), isNull);
    });
  });
}
