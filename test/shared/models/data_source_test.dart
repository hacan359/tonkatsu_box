import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

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
  });
}
