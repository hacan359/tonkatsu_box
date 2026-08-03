import 'package:core/models/data_source.dart';
import 'package:test/test.dart';

void main() {
  group('DataSource', () {
    group('key', () {
      test('should be lowercase and unique for every source', () {
        final Set<String> keys =
            DataSource.values.map((DataSource s) => s.key).toSet();
        expect(keys.length, DataSource.values.length);
        for (final String key in keys) {
          expect(key, key.toLowerCase());
        }
      });
    });

    group('label', () {
      test('should be non-empty and unique for every source', () {
        final Set<String> labels =
            DataSource.values.map((DataSource s) => s.label).toSet();
        expect(labels.length, DataSource.values.length);
        expect(labels.every((String l) => l.isNotEmpty), isTrue);
      });
    });

    group('brandName', () {
      test('should fall back to label when no override is set', () {
        expect(DataSource.tmdb.brandName, DataSource.tmdb.label);
        expect(DataSource.kitsu.brandName, DataSource.kitsu.label);
      });

      test('should use the override when the badge is an abbreviation', () {
        expect(DataSource.steamGridDb.label, isNot('SteamGridDB'));
        expect(DataSource.steamGridDb.brandName, 'SteamGridDB');
      });

      test('should be non-empty for every source', () {
        for (final DataSource s in DataSource.values) {
          expect(s.brandName, isNotEmpty, reason: s.name);
        }
      });
    });

    group('tryFromName', () {
      test('should resolve every known name', () {
        for (final DataSource s in DataSource.values) {
          expect(DataSource.tryFromName(s.name), s);
        }
      });

      test('should return null for null and unknown names', () {
        expect(DataSource.tryFromName(null), isNull);
        expect(DataSource.tryFromName('MANGA'), isNull);
        expect(DataSource.tryFromName(''), isNull);
      });
    });
  });
}