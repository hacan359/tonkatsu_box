import 'package:core/models/collection_import.dart';
import 'package:core/models/import_source_kind.dart';
import 'package:test/test.dart';

void main() {
  group('CollectionImport', () {
    final DateTime runAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    CollectionImport build({
      Map<String, Object?> options = const <String, Object?>{},
    }) => CollectionImport(
      collectionId: 7,
      source: ImportSourceKind.aniList,
      options: options,
      lastRunAt: runAt,
    );

    group('toDb / fromDb', () {
      test('round-trips every field with second precision', () {
        final CollectionImport original = build(
          options: <String, Object?>{
            CollectionImportOption.mode: 'overwrite',
            CollectionImportOption.includeAnime: true,
            CollectionImportOption.platformId: 12,
          },
        );
        final CollectionImport restored = CollectionImport.fromDb(
          original.toDb(),
        );

        expect(restored.collectionId, 7);
        expect(restored.source, ImportSourceKind.aniList);
        expect(restored.options, original.options);
        expect(restored.lastRunAt, runAt);
      });

      test('throws on a source key this build does not know', () {
        final Map<String, dynamic> row = build().toDb()..['source'] = 'nope';
        expect(() => CollectionImport.fromDb(row), throwsArgumentError);
      });

      test('falls back to empty options on broken or missing JSON', () {
        final Map<String, dynamic> row = build().toDb();
        expect(
          CollectionImport.fromDb(row..['options'] = '{bad').options,
          isEmpty,
        );
        expect(
          CollectionImport.fromDb(row..['options'] = '[1,2]').options,
          isEmpty,
        );
        expect(
          CollectionImport.fromDb(row..['options'] = null).options,
          isEmpty,
        );
        expect(CollectionImport.fromDb(row..['options'] = '').options, isEmpty);
      });
    });

    group('typed accessors', () {
      final CollectionImport record = build(
        options: <String, Object?>{
          CollectionImportOption.isWishlist: true,
          CollectionImportOption.status: 'completed',
          CollectionImportOption.platformId: 3,
          CollectionImportOption.mode: 42,
        },
      );

      test('flag returns the stored bool or the fallback', () {
        expect(
          record.flag(CollectionImportOption.isWishlist, orElse: false),
          isTrue,
        );
        expect(
          record.flag(CollectionImportOption.importNotes, orElse: true),
          isTrue,
        );
        expect(
          record.flag(CollectionImportOption.status, orElse: false),
          isFalse,
        );
      });

      test('text returns the stored string or null on a type mismatch', () {
        expect(record.text(CollectionImportOption.status), 'completed');
        expect(record.text(CollectionImportOption.mode), isNull);
        expect(record.text(CollectionImportOption.addToWishlist), isNull);
      });

      test('integer returns the stored int or null on a type mismatch', () {
        expect(record.integer(CollectionImportOption.platformId), 3);
        expect(record.integer(CollectionImportOption.status), isNull);
      });
    });

    test('copyWith replaces only the given fields', () {
      final CollectionImport copy = build().copyWith(
        source: ImportSourceKind.steam,
        options: <String, Object?>{CollectionImportOption.mode: 'newOnly'},
      );
      expect(copy.collectionId, 7);
      expect(copy.source, ImportSourceKind.steam);
      expect(copy.options, <String, Object?>{'mode': 'newOnly'});
      expect(copy.lastRunAt, runAt);
    });
  });
}
