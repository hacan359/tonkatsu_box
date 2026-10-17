import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/helpers/custom_duplicate.dart';

import '../../../helpers/builders.dart';

void main() {
  group('customDraftFromItem', () {
    test('should carry movie directors as authors', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.movie,
        movie: createTestMovie(title: 'Alien')
            .copyWith(directors: <String>['Ridley Scott']),
      );

      expect(
        customDraftFromItem(item, title: 'Alien').authors,
        <String>['Ridley Scott'],
      );
    });

    test('should carry game developers but not publishers', () {
      final CollectionItem item = createTestCollectionItem(
        game: createTestGame().copyWith(
          developers: <String>['Team Cherry'],
          publishers: <String>['Fangamer'],
        ),
      );

      expect(
        customDraftFromItem(item, title: 'HK').authors,
        <String>['Team Cherry'],
      );
    });

    test('should carry book authors', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.book,
        book: createTestBook(authors: <String>['Frank Herbert']),
      );

      expect(
        customDraftFromItem(item, title: 'Dune').authors,
        <String>['Frank Herbert'],
      );
    });

    test('should keep a custom card\'s own authors', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.custom,
        customMedia: const CustomMedia(
          id: 1,
          title: 'Zine',
          authors: <String>['Ann'],
        ),
      );

      expect(customDraftFromItem(item, title: 'Zine').authors, <String>['Ann']);
    });

    test('should leave authors null when the item has no creators', () {
      final CollectionItem item = createTestCollectionItem(game: createTestGame());

      expect(customDraftFromItem(item, title: 'G').authors, isNull);
    });
  });
}
