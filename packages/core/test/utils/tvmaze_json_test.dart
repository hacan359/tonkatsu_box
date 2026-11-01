import 'package:core/utils/tvmaze_json.dart';
import 'package:test/test.dart';

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

  group('tvMazeCreators', () {
    test('reads Creator crew', () {
      expect(
        tvMazeCreators(<String, dynamic>{
          '_embedded': <String, dynamic>{
            'crew': <dynamic>[
              <String, dynamic>{
                'type': 'Creator',
                'person': <String, dynamic>{'name': 'C'},
              },
              <String, dynamic>{
                'type': 'Executive Producer',
                'person': <String, dynamic>{'name': 'P'},
              },
            ],
          },
        }),
        <String>['C'],
      );
    });

    test('never stands the network in for a creator', () {
      expect(
        tvMazeCreators(<String, dynamic>{
          'network': <String, dynamic>{'name': 'CBS'},
          '_embedded': <String, dynamic>{'crew': <dynamic>[]},
        }),
        isNull,
      );
      expect(tvMazeCreators(<String, dynamic>{}), isNull);
    });
  });

  group('tvMazeNetworks', () {
    test('reads the network and the web channel', () {
      expect(
        tvMazeNetworks(<String, dynamic>{
          'network': <String, dynamic>{'name': 'CBS'},
          'webChannel': <String, dynamic>{'name': 'Paramount+'},
        }),
        <String>['CBS', 'Paramount+'],
      );
      expect(
        tvMazeNetworks(<String, dynamic>{
          'network': null,
          'webChannel': <String, dynamic>{'name': 'Netflix'},
        }),
        <String>['Netflix'],
      );
    });

    test('is null with neither', () {
      expect(tvMazeNetworks(<String, dynamic>{}), isNull);
    });
  });
}
