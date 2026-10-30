import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/custom_item/custom_item_data.dart';

void main() {
  const CustomMedia card = CustomMedia(
    id: 5,
    title: 'Old',
    displayType: MediaType.game,
    altTitle: 'Alt',
    description: 'Text',
    coverUrl: 'https://x/c.png',
    year: 2001,
    genres: 'RPG',
    authors: <String>['Ann'],
    platformName: 'PC',
    externalUrl: 'https://x',
  );

  group('CustomItemData', () {
    group('applyTo', () {
      test('should clear every text field the user emptied', () {
        const CustomItemData data =
            CustomItemData(title: 'Old', mediaType: MediaType.game);

        final CustomMedia updated =
            data.applyTo(card, coverUrl: card.coverUrl);

        expect(updated.altTitle, isNull);
        expect(updated.description, isNull);
        expect(updated.genres, isNull);
        expect(updated.authors, isNull);
        expect(updated.externalUrl, isNull);
        expect(updated.platformName, isNull);
      });

      test('should keep fields that came back unchanged', () {
        const CustomItemData data = CustomItemData(
          title: 'Old',
          mediaType: MediaType.game,
          altTitle: 'Alt',
          description: 'Text',
          year: 2001,
          genres: 'RPG',
          authors: <String>['Ann'],
          platform: 'PC',
          externalUrl: 'https://x',
        );

        final CustomMedia updated =
            data.applyTo(card, coverUrl: card.coverUrl);

        // An edit stamps a fresh cached_at; every other column must match.
        expect(
          updated.toDb()..remove('cached_at'),
          card.toDb()..remove('cached_at'),
        );
      });

      test('should replace a field with its new value', () {
        const CustomItemData data = CustomItemData(
          title: 'New',
          mediaType: MediaType.game,
          description: 'Fresh',
        );

        final CustomMedia updated = data.applyTo(card, coverUrl: null);

        expect(updated.title, 'New');
        expect(updated.description, 'Fresh');
        expect(
          const CustomItemData(
            title: 'New',
            mediaType: MediaType.game,
            authors: <String>['Bob'],
          ).applyTo(card, coverUrl: null).authors,
          <String>['Bob'],
        );
        expect(updated.coverUrl, card.coverUrl);
        expect(updated.year, card.year);
      });

      test('should drop the display type when the card goes back to custom',
          () {
        const CustomItemData data =
            CustomItemData(title: 'Old', mediaType: MediaType.custom);

        expect(data.applyTo(card, coverUrl: null).displayType, isNull);
      });

      test('should set the display type of a typed card', () {
        const CustomItemData data =
            CustomItemData(title: 'Old', mediaType: MediaType.movie);

        expect(data.applyTo(card, coverUrl: null).displayType, MediaType.movie);
      });
    });

    group('toNewCustomMedia', () {
      test('should carry the authors onto the new card', () {
        const CustomItemData data = CustomItemData(
          title: 'New',
          mediaType: MediaType.custom,
          authors: <String>['Ann'],
        );

        expect(data.toNewCustomMedia().authors, <String>['Ann']);
      });
    });
  });
}
