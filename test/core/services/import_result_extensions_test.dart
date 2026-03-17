import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/steam_import_service.dart';
import 'package:xerabora/core/services/trakt_zip_import_service.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/universal_import_result.dart';

import '../../helpers/builders.dart';

void main() {
  group('SteamImportResult.toUniversal()', () {
    test('converts successful result', () {
      const SteamImportResult steamResult = SteamImportResult(
        imported: 10,
        wishlisted: 3,
        updated: 2,
        total: 15,
        collectionId: 42,
      );
      final UniversalImportResult result = steamResult.toUniversal();

      expect(result.sourceName, 'Steam');
      expect(result.success, true);
      expect(result.totalImported, 10);
      expect(result.totalWishlisted, 3);
      expect(result.totalUpdated, 2);
      expect(result.collectionId, 42);
      expect(result.importedByType[MediaType.game], 10);
      expect(result.wishlistedByType[MediaType.game], 3);
      expect(result.updatedByType[MediaType.game], 2);
    });

    test('passes collection when provided', () {
      const SteamImportResult steamResult = SteamImportResult(
        imported: 5,
        wishlisted: 0,
        updated: 0,
        total: 5,
        collectionId: 1,
      );
      final Collection collection = createTestCollection(id: 1);
      final UniversalImportResult result =
          steamResult.toUniversal(collection: collection);

      expect(result.collection, collection);
      expect(result.effectiveCollectionId, 1);
    });

    test('skips zero counts in maps', () {
      const SteamImportResult steamResult = SteamImportResult(
        imported: 5,
        wishlisted: 0,
        updated: 0,
        total: 5,
        collectionId: 1,
      );
      final UniversalImportResult result = steamResult.toUniversal();

      expect(result.importedByType.containsKey(MediaType.game), true);
      expect(result.wishlistedByType.containsKey(MediaType.game), false);
      expect(result.updatedByType.containsKey(MediaType.game), false);
    });
  });

  group('TraktImportResult.toUniversal()', () {
    test('converts successful result with per-type data', () {
      final TraktImportResult traktResult = TraktImportResult.success(
        collection: createTestCollection(id: 7),
        itemsImported: 8,
        itemsSkipped: 2,
        itemsUpdated: 1,
        wishlistItemsAdded: 3,
        importedByType: const <MediaType, int>{
          MediaType.movie: 5,
          MediaType.tvShow: 3,
        },
        wishlistedByType: const <MediaType, int>{
          MediaType.movie: 2,
          MediaType.tvShow: 1,
        },
        updatedByType: const <MediaType, int>{
          MediaType.tvShow: 1,
        },
      );
      final UniversalImportResult result = traktResult.toUniversal();

      expect(result.sourceName, 'Trakt');
      expect(result.success, true);
      expect(result.totalImported, 8);
      expect(result.totalWishlisted, 3);
      expect(result.totalUpdated, 1);
      expect(result.skipped, 2);
      expect(result.collection?.id, 7);
    });

    test('converts failure result', () {
      const TraktImportResult traktResult =
          TraktImportResult.failure('TMDB error');
      final UniversalImportResult result = traktResult.toUniversal();

      expect(result.success, false);
      expect(result.fatalError, 'TMDB error');
      expect(result.sourceName, 'Trakt');
    });
  });
}
