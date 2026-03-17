import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/universal_import_result.dart';

import '../../helpers/builders.dart';

void main() {
  group('UniversalImportResult', () {
    group('totalImported', () {
      test('returns 0 for empty map', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
        );
        expect(result.totalImported, 0);
      });

      test('sums values across media types', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.game: 5,
            MediaType.movie: 3,
            MediaType.tvShow: 2,
          },
        );
        expect(result.totalImported, 10);
      });

      test('handles single type', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Steam',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.game: 42,
          },
        );
        expect(result.totalImported, 42);
      });
    });

    group('totalWishlisted', () {
      test('returns 0 for empty map', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
        );
        expect(result.totalWishlisted, 0);
      });

      test('sums wishlist values', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
          wishlistedByType: <MediaType, int>{
            MediaType.movie: 2,
            MediaType.tvShow: 1,
          },
        );
        expect(result.totalWishlisted, 3);
      });
    });

    group('totalUpdated', () {
      test('returns 0 for empty map', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
        );
        expect(result.totalUpdated, 0);
      });

      test('sums updated values', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
          updatedByType: <MediaType, int>{
            MediaType.game: 7,
          },
        );
        expect(result.totalUpdated, 7);
      });
    });

    group('hasWishlistItems', () {
      test('returns false when no wishlist items', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
        );
        expect(result.hasWishlistItems, false);
      });

      test('returns true when wishlist items exist', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
          wishlistedByType: <MediaType, int>{
            MediaType.game: 1,
          },
        );
        expect(result.hasWishlistItems, true);
      });
    });

    group('effectiveCollectionId', () {
      test('returns collection.id when collection exists', () {
        final Collection collection = createTestCollection(id: 42);
        final UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
          collection: collection,
          collectionId: 99,
        );
        expect(result.effectiveCollectionId, 42);
      });

      test('returns collectionId when collection is null', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
          collectionId: 99,
        );
        expect(result.effectiveCollectionId, 99);
      });

      test('returns null when both are null', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
        );
        expect(result.effectiveCollectionId, null);
      });
    });

    group('failure constructor', () {
      test('sets correct defaults', () {
        const UniversalImportResult result = UniversalImportResult.failure(
          sourceName: 'Steam',
          error: 'Connection failed',
        );
        expect(result.success, false);
        expect(result.fatalError, 'Connection failed');
        expect(result.sourceName, 'Steam');
        expect(result.totalImported, 0);
        expect(result.totalWishlisted, 0);
        expect(result.totalUpdated, 0);
        expect(result.skipped, 0);
        expect(result.collection, null);
        expect(result.collectionId, null);
      });
    });

    group('untypedImported and untypedUpdated', () {
      test('untypedImported adds to totalImported', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Xcoll',
          success: true,
          untypedImported: 15,
        );
        expect(result.totalImported, 15);
      });

      test('untypedUpdated adds to totalUpdated', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Xcoll',
          success: true,
          untypedUpdated: 3,
        );
        expect(result.totalUpdated, 3);
      });

      test('combines typed and untyped', () {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.game: 5,
          },
          untypedImported: 10,
        );
        expect(result.totalImported, 15);
      });
    });

    group('success result with all fields', () {
      test('stores all fields correctly', () {
        final Collection collection = createTestCollection(id: 1);
        final UniversalImportResult result = UniversalImportResult(
          sourceName: 'Trakt',
          success: true,
          collection: collection,
          importedByType: const <MediaType, int>{
            MediaType.movie: 10,
            MediaType.tvShow: 5,
            MediaType.animation: 3,
          },
          wishlistedByType: const <MediaType, int>{
            MediaType.movie: 2,
          },
          updatedByType: const <MediaType, int>{
            MediaType.tvShow: 1,
          },
          skipped: 4,
          errors: const <String>['Error 1', 'Error 2'],
        );

        expect(result.sourceName, 'Trakt');
        expect(result.success, true);
        expect(result.collection, collection);
        expect(result.totalImported, 18);
        expect(result.totalWishlisted, 2);
        expect(result.totalUpdated, 1);
        expect(result.hasWishlistItems, true);
        expect(result.skipped, 4);
        expect(result.errors, hasLength(2));
        expect(result.fatalError, null);
      });
    });
  });
}
