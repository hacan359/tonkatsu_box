import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/services/backup_service.dart';
import 'package:xerabora/core/services/import_service.dart';
import 'package:xerabora/core/services/xcoll_file.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BackupManifest.fromJson', () {
    test('parses a full manifest', () {
      final BackupManifest m = BackupManifest.fromJson(<String, dynamic>{
        'version': 2,
        'created': '2025-02-02T12:00:00Z',
        'collections_count': 3,
        'items_count': 42,
        'wishlist_count': 5,
        'includes_config': true,
        'profile_name': 'Main',
        'app_version': '1.2.3',
      });

      expect(m.version, 2);
      expect(m.collectionsCount, 3);
      expect(m.itemsCount, 42);
      expect(m.wishlistCount, 5);
      expect(m.includesConfig, isTrue);
      expect(m.profileName, 'Main');
      expect(m.appVersion, '1.2.3');
    });

    test('applies defaults for missing fields', () {
      final BackupManifest m = BackupManifest.fromJson(<String, dynamic>{
        'created': '2025-02-02T12:00:00Z',
      });

      expect(m.version, 1);
      expect(m.collectionsCount, 0);
      expect(m.itemsCount, 0);
      expect(m.wishlistCount, 0);
      expect(m.includesConfig, isFalse);
      expect(m.profileName, isNull);
    });
  });

  group('BackupService restore', () {
    late MockDatabaseService database;
    late MockDatabase rawDb;
    late MockExportService exportService;
    late MockImportService importService;
    late MockConfigService configService;
    late MockCollectionRepository collectionRepo;
    late MockWishlistRepository wishlistRepo;
    late Directory tmp;
    int seq = 0;

    setUpAll(() {
      registerAllFallbacks();
      registerFallbackValue(
        XcollFile(version: 3, name: 'x', author: 'x', created: DateTime(2025)),
      );
    });

    setUp(() {
      database = MockDatabaseService();
      rawDb = MockDatabase();
      exportService = MockExportService();
      importService = MockImportService();
      configService = MockConfigService();
      collectionRepo = MockCollectionRepository();
      wishlistRepo = MockWishlistRepository();
      tmp = Directory.systemTemp.createTempSync('backup_test');

      // WAL checkpoint at the end of restore.
      when(() => database.database).thenAnswer((_) async => rawDb);
      when(() => rawDb.execute(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    BackupService makeService() => BackupService(
          database: database,
          exportService: exportService,
          importService: importService,
          configService: configService,
          collectionRepo: collectionRepo,
          wishlistRepo: wishlistRepo,
        );

    String writeZip(Map<String, String> files) {
      final Archive archive = Archive();
      files.forEach((String name, String content) {
        final List<int> b = utf8.encode(content);
        archive.addFile(ArchiveFile(name, b.length, b));
      });
      final List<int> zip = ZipEncoder().encode(archive);
      final File f = File('${tmp.path}/backup_${seq++}.zip')
        ..writeAsBytesSync(zip);
      return f.path;
    }

    const String collectionXcoll =
        '{"version":3,"format":"full","name":"My Coll","author":"me",'
        '"created":"2025-01-01T00:00:00Z","items":[]}';

    const String manifestJson = '{"version":3,"created":"2025-02-02T12:00:00Z",'
        '"collections_count":1,"items_count":3,"wishlist_count":2,'
        '"includes_config":true}';

    const String wishlistJson = '['
        '{"text":"Dup Game","created_at":1700000000},'
        '{"text":"New Game","media_type_hint":"game","note":"n",'
        '"created_at":1700000000,"tag":"t"}'
        ']';

    void stubImportOk() {
      when(() => importService.importFromXcoll(any())).thenAnswer(
        (_) async => ImportResult.success(createTestCollection(), 3),
      );
    }

    void stubWishlist() {
      when(() => wishlistRepo.findUnresolved('Dup Game'))
          .thenAnswer((_) async => createTestWishlistItem(text: 'Dup Game'));
      when(() => wishlistRepo.findUnresolved('New Game'))
          .thenAnswer((_) async => null);
      when(() => wishlistRepo.add(
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            note: any(named: 'note'),
            tag: any(named: 'tag'),
          )).thenAnswer((_) async => createTestWishlistItem(text: 'New Game'));
    }

    test('readManifest returns the parsed manifest from a ZIP', () async {
      final String path = writeZip(<String, String>{'manifest.json': manifestJson});

      final BackupManifest? m = await makeService().readManifest(path);

      expect(m, isNotNull);
      expect(m!.collectionsCount, 1);
      expect(m.itemsCount, 3);
      expect(m.includesConfig, isTrue);
    });

    test('readManifest returns null when manifest is absent', () async {
      final String path =
          writeZip(<String, String>{'collections/001_a.xcollx': collectionXcoll});

      expect(await makeService().readManifest(path), isNull);
    });

    test('readManifest returns null for a non-ZIP file', () async {
      final File f = File('${tmp.path}/not-a-zip.zip')
        ..writeAsBytesSync(<int>[1, 2, 3, 4, 5]);

      expect(await makeService().readManifest(f.path), isNull);
    });

    test('restores collections and dedups wishlist, skips settings by default',
        () async {
      stubImportOk();
      stubWishlist();
      final String path = writeZip(<String, String>{
        'manifest.json': manifestJson,
        'collections/001_my-coll.xcollx': collectionXcoll,
        'wishlist.json': wishlistJson,
        'config.json': '{"theme":"dark"}',
      });

      final RestoreResult r = await makeService().restoreFromBackup(zipPath: path);

      expect(r.success, isTrue);
      expect(r.collectionsRestored, 1);
      expect(r.itemsRestored, 3);
      expect(r.wishlistRestored, 1); // "Dup Game" skipped, "New Game" added
      expect(r.settingsRestored, isFalse);

      verify(() => importService.importFromXcoll(any())).called(1);
      verify(() => wishlistRepo.add(
            text: 'New Game',
            mediaTypeHint: any(named: 'mediaTypeHint'),
            note: any(named: 'note'),
            tag: any(named: 'tag'),
          )).called(1);
      verifyNever(() => configService.applySettings(any()));
    });

    test('applies settings only when restoreSettings is true', () async {
      stubImportOk();
      stubWishlist();
      when(() => configService.applySettings(any())).thenAnswer((_) async => 2);
      final String path = writeZip(<String, String>{
        'manifest.json': manifestJson,
        'collections/001_my-coll.xcollx': collectionXcoll,
        'config.json': '{"theme":"dark"}',
      });

      final RestoreResult r = await makeService()
          .restoreFromBackup(zipPath: path, restoreSettings: true);

      expect(r.settingsRestored, isTrue);
      verify(() => configService.applySettings(any())).called(1);
    });

    test('does not touch wishlist when restoreWishlist is false', () async {
      stubImportOk();
      final String path = writeZip(<String, String>{
        'manifest.json': manifestJson,
        'wishlist.json': wishlistJson,
      });

      final RestoreResult r = await makeService()
          .restoreFromBackup(zipPath: path, restoreWishlist: false);

      expect(r.wishlistRestored, 0);
      verifyNever(() => wishlistRepo.findUnresolved(any()));
      verifyNever(() => wishlistRepo.add(
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            note: any(named: 'note'),
            tag: any(named: 'tag'),
          ));
    });

    test('returns failure when the backup file cannot be read', () async {
      final RestoreResult r = await makeService()
          .restoreFromBackup(zipPath: '${tmp.path}/does-not-exist.zip');

      expect(r.success, isFalse);
    });

    test('a failed collection import does not abort the whole restore',
        () async {
      when(() => importService.importFromXcoll(any()))
          .thenAnswer((_) async => const ImportResult.failure('boom'));
      final String path = writeZip(<String, String>{
        'manifest.json': manifestJson,
        'collections/001_my-coll.xcollx': collectionXcoll,
      });

      final RestoreResult r = await makeService().restoreFromBackup(zipPath: path);

      expect(r.success, isTrue);
      expect(r.collectionsRestored, 0); // import failed → not counted
      expect(r.itemsRestored, 0);
    });
  });
}
