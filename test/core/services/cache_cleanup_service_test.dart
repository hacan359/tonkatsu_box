import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/cache_cleanup_service.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late Directory cacheDir;
  late ImageCacheService cache;
  late MockCollectionRepository repo;
  late CacheCleanupService cleanup;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    cacheDir = await Directory.systemTemp.createTemp('cache_cleanup_test');
    cache = ImageCacheService();
    await cache.setCachePath(cacheDir.path);
    repo = MockCollectionRepository();
    cleanup = CacheCleanupService(repo, cache);
  });

  tearDown(() async {
    if (cacheDir.existsSync()) await cacheDir.delete(recursive: true);
  });

  Future<File> writeCacheFile(
    ImageType type,
    String id, {
    String ext = 'png',
  }) async {
    final String dirPath = await cache.getCachePath(type);
    await Directory(dirPath).create(recursive: true);
    final File file = File(p.join(dirPath, '$id.$ext'));
    await file.writeAsBytes(Uint8List.fromList(<int>[1, 2, 3, 4]));
    return file;
  }

  void stubItems(List<CollectionItem> items) {
    when(() => repo.getAllItemsWithData())
        .thenAnswer((_) async => items);
  }

  group('CacheCleanupService.removeOrphans', () {
    test('keeps covers for media in a collection and deletes the rest',
        () async {
      stubItems(<CollectionItem>[
        createTestCollectionItem(
          mediaType: MediaType.game,
          externalId: 100,
          game: createTestGame(id: 100),
        ),
        createTestCollectionItem(
          mediaType: MediaType.movie,
          externalId: 200,
          movie: createTestMovie(tmdbId: 200),
        ),
      ]);

      final File keptGame = await writeCacheFile(ImageType.gameCover, '100');
      final File keptMovie =
          await writeCacheFile(ImageType.moviePoster, '200');
      final File orphanGame = await writeCacheFile(ImageType.gameCover, '999');
      final File orphanMovie =
          await writeCacheFile(ImageType.moviePoster, '888');

      final CacheCleanupResult result = await cleanup.removeOrphans();

      expect(result.deletedCount, 2);
      expect(result.freedBytes, 8, reason: '2 deleted files of 4 bytes each');
      expect(keptGame.existsSync(), isTrue);
      expect(keptMovie.existsSync(), isTrue);
      expect(orphanGame.existsSync(), isFalse);
      expect(orphanMovie.existsSync(), isFalse);
    });

    test('never touches custom covers or canvas board images', () async {
      stubItems(<CollectionItem>[]);

      final File custom = await writeCacheFile(ImageType.customCover, '5');
      final File canvas =
          await writeCacheFile(ImageType.canvasImage, 'deadbeef');
      final File gameOrphan = await writeCacheFile(ImageType.gameCover, '1');

      final CacheCleanupResult result = await cleanup.removeOrphans();

      expect(result.deletedCount, 1);
      expect(custom.existsSync(), isTrue, reason: 'custom covers untouched');
      expect(canvas.existsSync(), isTrue, reason: 'canvas images untouched');
      expect(gameOrphan.existsSync(), isFalse);
    });

    test('deletes every cleanable cover when no collection holds the media',
        () async {
      // After deleting a collection: collection_items rows are gone, but the
      // cache rows and downloaded covers remain — all of them are orphans now.
      stubItems(<CollectionItem>[]);

      final File game = await writeCacheFile(ImageType.gameCover, '1');
      final File book =
          await writeCacheFile(ImageType.bookCover, 'openLibrary_2');

      final CacheCleanupResult result = await cleanup.removeOrphans();

      expect(result.deletedCount, 2);
      expect(game.existsSync(), isFalse);
      expect(book.existsSync(), isFalse);
    });
  });

  group('ImageCacheService.removeOrphans', () {
    test('leaves non-png files and folders absent from the keep map alone',
        () async {
      final File png = await writeCacheFile(ImageType.gameCover, 'orphan');
      final File txt =
          await writeCacheFile(ImageType.gameCover, 'note', ext: 'txt');
      final File untracked =
          await writeCacheFile(ImageType.moviePoster, 'orphan');

      // Only the gameCover folder is scanned; moviePoster is absent.
      final CacheCleanupResult result = await cache.removeOrphans(
        <ImageType, Set<String>>{ImageType.gameCover: <String>{}},
      );

      expect(result.deletedCount, 1);
      expect(png.existsSync(), isFalse, reason: 'orphan png removed');
      expect(txt.existsSync(), isTrue, reason: 'non-png left alone');
      expect(untracked.existsSync(), isTrue,
          reason: 'folder not in keep map left alone');
    });
  });
}
