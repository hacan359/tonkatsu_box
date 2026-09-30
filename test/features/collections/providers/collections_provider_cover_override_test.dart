import 'dart:typed_data';

import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  const int collectionId = 1;
  const String link = 'https://example.com/mine.png';
  const String otherLink = 'https://example.com/other.png';
  late MockCollectionRepository repo;
  late MockImageCacheService cache;
  late SharedPreferences prefs;

  setUpAll(registerAllFallbacks);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    repo = MockCollectionRepository();
    cache = MockImageCacheService();

    when(() => repo.setItemOverrideCoverUrl(any(), any()))
        .thenAnswer((_) async {});
    when(() => repo.countItemsWithOverrideCover(any()))
        .thenAnswer((_) async => 0);
    when(() => repo.updateItemActivityDates(
          any(),
          startedAt: any(named: 'startedAt'),
          completedAt: any(named: 'completedAt'),
          lastActivityAt: any(named: 'lastActivityAt'),
          clearStartedAt: any(named: 'clearStartedAt'),
          clearCompletedAt: any(named: 'clearCompletedAt'),
        )).thenAnswer((_) async {});
    when(() => repo.getAllItemsWithData())
        .thenAnswer((_) async => <CollectionItem>[]);

    when(() => cache.saveImageBytes(any(), any(), any()))
        .thenAnswer((_) async => true);
    when(() => cache.downloadImage(
          type: any(named: 'type'),
          imageId: any(named: 'imageId'),
          remoteUrl: any(named: 'remoteUrl'),
        )).thenAnswer((_) async => true);
    when(() => cache.deleteImage(any(), any())).thenAnswer((_) async {});
    when(() => cache.evictDecodedImage(any(), any())).thenAnswer((_) async {});
  });

  Future<CollectionItemsNotifier> loaded(CollectionItem item) async {
    when(() => repo.getItemsWithData(collectionId))
        .thenAnswer((_) async => <CollectionItem>[item]);
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(repo),
        sharedPreferencesProvider.overrideWithValue(prefs),
        imageCacheServiceProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(c.dispose);
    c.read(collectionItemsNotifierProvider(collectionId));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return c.read(collectionItemsNotifierProvider(collectionId).notifier);
  }

  CollectionItem game({String? overrideCoverUrl}) => createTestCollectionItem(
        id: 7,
        mediaType: MediaType.game,
        externalId: 42,
        game: createTestGame(id: 42),
        overrideCoverUrl: overrideCoverUrl,
      );

  String? overrideOf(CollectionItemsNotifier n) => n.state.valueOrNull
      ?.firstWhere((CollectionItem i) => i.id == 7)
      .overrideCoverUrl;

  group('CollectionItemsNotifier', () {
    group('setCoverOverride', () {
      test('should store uploaded bytes under a fresh token', () async {
        final CollectionItemsNotifier n = await loaded(game());

        final bool ok =
            await n.setCoverOverride(7, bytes: Uint8List.fromList(<int>[1]));

        expect(ok, isTrue);
        final String marker = overrideOf(n)!;
        expect(marker, startsWith('local://cover/'));
        verify(() => cache.saveImageBytes(
              ImageType.coverOverride,
              overrideCoverImageId(marker),
              any(),
            )).called(1);
        verify(() => repo.setItemOverrideCoverUrl(7, marker)).called(1);
      });

      test('should not touch the item when the file cannot be saved',
          () async {
        when(() => cache.saveImageBytes(any(), any(), any()))
            .thenAnswer((_) async => false);
        final CollectionItemsNotifier n = await loaded(game());

        final bool ok =
            await n.setCoverOverride(7, bytes: Uint8List.fromList(<int>[1]));

        expect(ok, isFalse);
        expect(overrideOf(n), isNull);
        verifyNever(() => repo.setItemOverrideCoverUrl(any(), any()));
      });

      test('should store a link and prefetch it into the override slot',
          () async {
        final CollectionItemsNotifier n = await loaded(game());

        await n.setCoverOverride(7, url: '  $link  ');

        expect(overrideOf(n), link);
        verify(() => repo.setItemOverrideCoverUrl(7, link)).called(1);
        verify(() => cache.downloadImage(
              type: ImageType.coverOverride,
              imageId: overrideCoverImageId(link),
              remoteUrl: link,
            )).called(1);
      });

      test('should delete the replaced file once no item shows it', () async {
        final CollectionItemsNotifier n =
            await loaded(game(overrideCoverUrl: link));

        await n.setCoverOverride(7, url: otherLink);

        verify(() => cache.deleteImage(
              ImageType.coverOverride,
              overrideCoverImageId(link),
            )).called(1);
      });

      test('should keep the replaced file while another item shows it',
          () async {
        when(() => repo.countItemsWithOverrideCover(link))
            .thenAnswer((_) async => 1);
        final CollectionItemsNotifier n =
            await loaded(game(overrideCoverUrl: link));

        await n.setCoverOverride(7, url: otherLink);

        verifyNever(() => cache.deleteImage(any(), any()));
      });

      test('should reset to the API cover when given nothing', () async {
        final CollectionItemsNotifier n =
            await loaded(game(overrideCoverUrl: link));

        await n.setCoverOverride(7);

        expect(overrideOf(n), isNull);
        verify(() => repo.setItemOverrideCoverUrl(7, null)).called(1);
        verify(() => cache.deleteImage(
              ImageType.coverOverride,
              overrideCoverImageId(link),
            )).called(1);
      });

      test('should do nothing when the link is unchanged', () async {
        final CollectionItemsNotifier n =
            await loaded(game(overrideCoverUrl: link));

        final bool ok = await n.setCoverOverride(7, url: link);

        expect(ok, isTrue);
        verifyNever(() => repo.setItemOverrideCoverUrl(any(), any()));
        verifyNever(() => cache.deleteImage(any(), any()));
      });
    });
  });
}
