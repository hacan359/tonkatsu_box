import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/game.dart';
import 'package:core/models/image_type.dart';
import 'package:core/models/media_type.dart';
import 'package:core/testing/builders.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:test/test.dart';

void main() {
  const String apiCover = 'https://images.igdb.com/cover.jpg';
  const String link = 'https://example.com/mine.png';
  final String marker = CustomMedia.localCoverMarkerFor(1700000000000);

  CollectionItem game({String? overrideCoverUrl}) => createTestCollectionItem(
        mediaType: MediaType.game,
        externalId: 42,
        game: const Game(id: 42, name: 'G', coverUrl: apiCover),
        overrideCoverUrl: overrideCoverUrl,
      );

  group('CollectionItem', () {
    group('cover getters', () {
      test('should show the API cover when there is no override', () {
        final CollectionItem item = game();

        expect(item.coverUrl, apiCover);
        expect(item.thumbnailUrl, apiCover);
        expect(item.imageType, ImageType.gameCover);
        expect(item.coverImageId, '42');
      });

      test('should show a link override from its own cache slot', () {
        final CollectionItem item = game(overrideCoverUrl: link);

        expect(item.coverUrl, link);
        expect(item.thumbnailUrl, link);
        expect(item.imageType, ImageType.coverOverride);
        expect(item.coverImageId, overrideCoverImageId(link));
      });

      test('should key an uploaded override by its token', () {
        final CollectionItem item = game(overrideCoverUrl: marker);

        expect(item.coverImageId, '1700000000000');
      });

      test('should keep the API cover reachable behind an override', () {
        final CollectionItem item = game(overrideCoverUrl: link);

        expect(item.cachedCoverUrl, apiCover);
        expect(item.cachedImageType, ImageType.gameCover);
        expect(item.cachedCoverImageId, '42');
      });
    });

    group('fromDb / toDb', () {
      test('should round-trip override_cover_url', () {
        final Map<String, dynamic> row = game(overrideCoverUrl: link).toDb();

        expect(row['override_cover_url'], link);
        expect(CollectionItem.fromDb(row).overrideCoverUrl, link);
      });
    });

    group('toExport', () {
      test('should leave the override out by default', () {
        final Map<String, dynamic> json =
            game(overrideCoverUrl: link).toExport(includeUserData: true);

        expect(json.containsKey('override_cover_url'), isFalse);
      });

      test('should include the override when asked', () {
        final Map<String, dynamic> json =
            game(overrideCoverUrl: link).toExport(includeCoverOverride: true);

        expect(json['override_cover_url'], link);
        expect(CollectionItem.fromExport(json).overrideCoverUrl, link);
      });

      test('should omit the key for an item without an override', () {
        final Map<String, dynamic> json =
            game().toExport(includeCoverOverride: true);

        expect(json.containsKey('override_cover_url'), isFalse);
      });
    });

    group('copyWith', () {
      test('should set, keep and clear the override', () {
        final CollectionItem withOverride =
            game().copyWith(overrideCoverUrl: link);
        expect(withOverride.overrideCoverUrl, link);

        expect(withOverride.copyWith(userComment: 'x').overrideCoverUrl, link);
        expect(
          withOverride.copyWith(clearOverrideCoverUrl: true).overrideCoverUrl,
          isNull,
        );
      });
    });
  });
}
