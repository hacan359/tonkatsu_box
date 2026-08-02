import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/database/dao/global_tag_dao.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  const int collectionId = 1;
  const int customId = 5;
  const int itemId = 99;

  late MockCollectionRepository repo;
  late MockDatabaseService db;
  late MockCustomMediaDao customMediaDao;
  late MockCollectionDao collectionDao;
  late MockGlobalTagDao tagDao;
  late SharedPreferences prefs;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(const <TagSeed>[]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    repo = MockCollectionRepository();
    db = MockDatabaseService();
    customMediaDao = MockCustomMediaDao();
    collectionDao = MockCollectionDao();
    tagDao = MockGlobalTagDao();

    when(() => db.customMediaDao).thenReturn(customMediaDao);
    when(() => db.collectionDao).thenReturn(collectionDao);
    // gameRepositoryProvider (watched by the notifier) resolves gameDao
    // eagerly from the database service.
    when(() => db.gameDao).thenReturn(MockGameDao());
    when(() => customMediaDao.create(any())).thenAnswer((_) async => customId);
    when(() => collectionDao.updateItemUserComment(any(), any()))
        .thenAnswer((_) async {});
    when(() => tagDao.resolveOrCreateAll(any())).thenAnswer(
      (_) async => <String, int>{'backlog': 1, 'favorites': 2},
    );
    when(() => tagDao.setItemTags(any(), any())).thenAnswer((_) async {});

    when(() => repo.addItem(
          collectionId: any(named: 'collectionId'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
        )).thenAnswer((_) async => itemId);
    when(() => repo.getItemsWithData(collectionId))
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => repo.getAllItemsWithData())
        .thenAnswer((_) async => <CollectionItem>[]);
  });

  Future<CollectionItemsNotifier> notifier() async {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(repo),
        databaseServiceProvider.overrideWithValue(db),
        globalTagDaoProvider.overrideWithValue(tagDao),
        imageCacheServiceProvider.overrideWithValue(MockImageCacheService()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(c.dispose);
    c.read(collectionItemsNotifierProvider(collectionId));
    await Future<void>.delayed(Duration.zero);
    return c.read(collectionItemsNotifierProvider(collectionId).notifier);
  }

  CustomMedia media() => const CustomMedia(
        id: 0,
        title: 'My Card',
        displayType: MediaType.game,
      );

  group('addCustomItem personal fields', () {
    test('writes the user comment onto the created item', () async {
      final CollectionItemsNotifier n = await notifier();

      final bool ok =
          await n.addCustomItem(media(), userComment: 'loved it');

      expect(ok, isTrue);
      verify(() => collectionDao.updateItemUserComment(itemId, 'loved it'))
          .called(1);
    });

    test('resolves tags (creating missing ones) and assigns them', () async {
      final CollectionItemsNotifier n = await notifier();

      final bool ok = await n.addCustomItem(
        media(),
        tags: <String>['Backlog', 'Favorites'],
      );

      expect(ok, isTrue);
      final List<TagSeed> seeds =
          verify(() => tagDao.resolveOrCreateAll(captureAny()))
              .captured
              .single as List<TagSeed>;
      expect(
        seeds.map((TagSeed s) => s.name),
        <String>['Backlog', 'Favorites'],
      );
      verify(() => tagDao.setItemTags(itemId, <int>{1, 2})).called(1);
    });

    test('skips personal writes when nothing was provided', () async {
      final CollectionItemsNotifier n = await notifier();

      final bool ok = await n.addCustomItem(media());

      expect(ok, isTrue);
      verifyNever(() => collectionDao.updateItemUserComment(any(), any()));
      verifyNever(() => tagDao.resolveOrCreateAll(any()));
      verifyNever(() => tagDao.setItemTags(any(), any()));
    });
  });
}
