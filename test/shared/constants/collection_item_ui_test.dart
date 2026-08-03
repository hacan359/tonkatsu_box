import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/l10n/app_localizations_ru.dart';
import 'package:tonkatsu_box/shared/constants/collection_item_ui.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('CollectionItemUi', () {
    group('cardSubcategoryLabel', () {
      final S l = SRu();

      test('null for a game without a platform', () {
        expect(
          createTestCollectionItem(mediaType: MediaType.game).cardSubcategoryLabel(l),
          isNull,
        );
      });

      test('movie/TV label for animation', () {
        expect(
          createTestCollectionItem(
              mediaType: MediaType.animation,
              platformId: AnimationSource.tvShow,
            ).cardSubcategoryLabel(l),
          l.mediaTypeTvShow,
        );
        expect(
          createTestCollectionItem(
              mediaType: MediaType.animation,
              platformId: AnimationSource.movie,
            ).cardSubcategoryLabel(l),
          l.mediaTypeMovie,
        );
      });

      test('null for other media types', () {
        expect(
          createTestCollectionItem(mediaType: MediaType.movie).cardSubcategoryLabel(l),
          isNull,
        );
      });
    });
  });
}
