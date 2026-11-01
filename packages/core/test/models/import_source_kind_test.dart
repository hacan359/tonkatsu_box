import 'package:core/models/import_source_kind.dart';
import 'package:test/test.dart';

void main() {
  group('ImportSourceKind', () {
    group('tryFromKey', () {
      test('resolves every member by its own key', () {
        for (final ImportSourceKind kind in ImportSourceKind.values) {
          expect(ImportSourceKind.tryFromKey(kind.key), kind);
        }
      });

      test('returns null for an unknown or null key', () {
        expect(ImportSourceKind.tryFromKey('letterboxd'), isNull);
        expect(ImportSourceKind.tryFromKey(null), isNull);
      });
    });

    test('keys are unique', () {
      final Set<String> keys = <String>{
        for (final ImportSourceKind kind in ImportSourceKind.values) kind.key,
      };
      expect(keys, hasLength(ImportSourceKind.values.length));
    });
  });
}
