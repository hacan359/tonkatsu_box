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

    group('cardTitle', () {
      test('should prefix the artist for a music item', () {
        final String title = createTestCollectionItem(
          mediaType: MediaType.music,
          album: createTestAlbum(
            title: 'The Dark Side of the Moon',
            artists: <String>['Pink Floyd'],
          ),
        ).cardTitle('The Dark Side of the Moon');

        expect(title, 'Pink Floyd — The Dark Side of the Moon');
      });

      test('should keep the plain name when the album has no artists', () {
        final String title = createTestCollectionItem(
          mediaType: MediaType.music,
          album: createTestAlbum(title: 'Nameless', artists: const <String>[]),
        ).cardTitle('Nameless');

        expect(title, 'Nameless');
      });

      test('should keep the plain name when the album is not joined', () {
        expect(
          createTestCollectionItem(mediaType: MediaType.music).cardTitle('X'),
          'X',
        );
      });

      test('should not prefix a custom rename', () {
        final String title = createTestCollectionItem(
          mediaType: MediaType.music,
          overrideName: 'My favourite',
          album: createTestAlbum(artists: <String>['Pink Floyd']),
        ).cardTitle('My favourite');

        expect(title, 'My favourite');
      });

      test('should keep other media types untouched', () {
        expect(
          createTestCollectionItem(mediaType: MediaType.game).cardTitle('Doom'),
          'Doom',
        );
      });
    });
  });
}
