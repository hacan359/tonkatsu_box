import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/trakt_zip_import_service.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';

import '../../helpers/builders.dart';

void main() {
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
