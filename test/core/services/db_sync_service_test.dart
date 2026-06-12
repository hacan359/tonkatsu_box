import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_registry.dart';
import 'package:tonkatsu_box/core/services/db_sync_service.dart';
import 'package:tonkatsu_box/core/services/storage_root.dart';
import 'package:tonkatsu_box/shared/models/sync_manifest.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late String syncDir;
  late DatabaseService dbService;
  late DbSyncService sync;

  Future<SyncDeviceMeta> testMeta() async =>
      const SyncDeviceMeta(deviceName: 'TEST-DEVICE', appVersion: '9.9.9');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('db_sync_test');
    final String dataDir = p.join(tempDir.path, 'data');
    syncDir = p.join(tempDir.path, 'sync');
    await Directory(dataDir).create(recursive: true);
    await Directory(syncDir).create(recursive: true);

    StorageRoot.defaultPathProvider = () async => dataDir;
    SharedPreferences.setMockInitialValues(<String, Object>{});

    dbService = DatabaseService();
    sync = DbSyncService(database: dbService, metaProvider: testMeta);
  });

  tearDown(() async {
    await dbService.close();
    StorageRoot.defaultPathProvider = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> insertCollection(String name) async {
    final Database db = await dbService.database;
    await db.insert('collections', <String, Object?>{
      'name': name,
      'author': 'tester',
      'created_at': 1700000000,
    });
  }

  group('DbSyncService', () {
    group('sendSnapshot', () {
      test('writes a snapshot and a manifest', () async {
        await insertCollection('My games');

        final SyncManifest manifest =
            await sync.sendSnapshot(syncDir, profileName: 'default');

        expect(
          File(p.join(syncDir, DbSyncService.snapshotFileName)).existsSync(),
          isTrue,
        );
        expect(manifest.deviceName, 'TEST-DEVICE');
        expect(manifest.appVersion, '9.9.9');
        expect(manifest.schemaVersion, MigrationRegistry.latestVersion);
        expect(manifest.collections, 1);
        expect(manifest.items, 0);
        expect(manifest.profileName, 'default');

        final SyncManifest reread = SyncManifest.fromJsonString(
          File(p.join(syncDir, DbSyncService.manifestFileName))
              .readAsStringSync(),
        );
        expect(reread.deviceName, manifest.deviceName);
        expect(reread.schemaVersion, manifest.schemaVersion);
        expect(reread.collections, 1);
      });

      test('records the last-sent timestamp', () async {
        expect(await sync.lastSentAt(), isNull);

        await sync.sendSnapshot(syncDir);

        expect(await sync.lastSentAt(), isNotNull);
      });

      test('overwrites a previous snapshot', () async {
        await sync.sendSnapshot(syncDir);
        await insertCollection('Added later');

        final SyncManifest second = await sync.sendSnapshot(syncDir);

        expect(second.collections, 1);
        final SyncSnapshotInfo info = await sync.inspectSnapshot(syncDir);
        expect(info.manifest?.collections, 1);
      });
    });

    group('inspectSnapshot', () {
      test('reports a missing snapshot', () async {
        final SyncSnapshotInfo info = await sync.inspectSnapshot(syncDir);

        expect(info.exists, isFalse);
        expect(info.receivable, isFalse);
      });

      test('accepts a fresh snapshot', () async {
        await sync.sendSnapshot(syncDir);

        final SyncSnapshotInfo info = await sync.inspectSnapshot(syncDir);

        expect(info.exists, isTrue);
        expect(info.integrityOk, isTrue);
        expect(info.tooNew, isFalse);
        expect(info.receivable, isTrue);
        expect(info.schemaVersion, MigrationRegistry.latestVersion);
      });

      test('rejects a snapshot with a newer schema', () async {
        await sync.sendSnapshot(syncDir);
        final Database snapshot = await databaseFactory.openDatabase(
          p.join(syncDir, DbSyncService.snapshotFileName),
        );
        await snapshot.execute(
          'PRAGMA user_version = ${MigrationRegistry.latestVersion + 1}',
        );
        await snapshot.close();

        final SyncSnapshotInfo info = await sync.inspectSnapshot(syncDir);

        expect(info.tooNew, isTrue);
        expect(info.receivable, isFalse);
      });

      test('rejects a garbage file posing as a snapshot', () async {
        await File(p.join(syncDir, DbSyncService.snapshotFileName))
            .writeAsString('this is not a database');

        final SyncSnapshotInfo info = await sync.inspectSnapshot(syncDir);

        expect(info.exists, isTrue);
        expect(info.integrityOk, isFalse);
        expect(info.receivable, isFalse);
      });

      test('tolerates a missing manifest', () async {
        await sync.sendSnapshot(syncDir);
        await File(p.join(syncDir, DbSyncService.manifestFileName)).delete();

        final SyncSnapshotInfo info = await sync.inspectSnapshot(syncDir);

        expect(info.manifest, isNull);
        expect(info.receivable, isTrue);
      });
    });

    group('restoreBackup', () {
      test('backupTimestamp is null before any backup exists', () async {
        expect(await sync.backupTimestamp(), isNull);
      });

      test('swaps the live database with the backup, twice undoes itself',
          () async {
        await insertCollection('KEEP');
        await sync.sendSnapshot(syncDir);
        final Database db = await dbService.database;
        await db.delete('collections');
        await sync.receiveSnapshot(syncDir);
        // Live DB now holds KEEP (from the snapshot); .bak holds the
        // emptied state captured right before the receive.
        expect(await dbService.getCollectionCount(), 1);
        expect(await sync.backupTimestamp(), isNotNull);

        await sync.restoreBackup();
        expect(await dbService.getCollectionCount(), 0);

        await sync.restoreBackup();
        expect(await dbService.getCollectionCount(), 1);
      });

      test('throws when no backup exists', () async {
        expect(() => sync.restoreBackup(), throwsStateError);
      });

      test('refuses a corrupted backup', () async {
        final Database db = await dbService.database;
        await File('${db.path}.bak').writeAsString('garbage');

        expect(() => sync.restoreBackup(), throwsStateError);
        expect(await dbService.getCollectionCount(), 0);
      });

      test('refuses a backup with a newer schema', () async {
        final Database db = await dbService.database;
        final String bakPath = '${db.path}.bak';
        final Database bak = await databaseFactory.openDatabase(bakPath);
        await bak.execute(
          'PRAGMA user_version = ${MigrationRegistry.latestVersion + 1}',
        );
        await bak.close();

        expect(() => sync.restoreBackup(), throwsStateError);
      });
    });

    group('receiveSnapshot', () {
      test('replaces the live database and keeps a backup', () async {
        await insertCollection('From sender');
        await sync.sendSnapshot(syncDir);

        final Database db = await dbService.database;
        await db.delete('collections');
        expect(await dbService.getCollectionCount(), 0);
        final String dbPath = db.path;

        await sync.receiveSnapshot(syncDir);

        expect(File('$dbPath.bak').existsSync(), isTrue);
        expect(await dbService.getCollectionCount(), 1);
        expect(await sync.lastReceivedAt(), isNotNull);
      });

      test('throws on a snapshot with a newer schema', () async {
        await sync.sendSnapshot(syncDir);
        final Database snapshot = await databaseFactory.openDatabase(
          p.join(syncDir, DbSyncService.snapshotFileName),
        );
        await snapshot.execute(
          'PRAGMA user_version = ${MigrationRegistry.latestVersion + 1}',
        );
        await snapshot.close();

        expect(
          () => sync.receiveSnapshot(syncDir),
          throwsStateError,
        );
      });

      test('throws when no snapshot is present', () async {
        expect(
          () => sync.receiveSnapshot(syncDir),
          throwsStateError,
        );
      });
    });
  });
}
