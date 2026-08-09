import 'dart:io';

import 'package:core/database/db_file.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/database/sqlite_health.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';
import 'package:tonkatsu_server/src/database_bootstrap.dart';

void main() {
  late Directory dataDir;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('tonkatsu_server_test');
  });

  tearDown(() {
    if (dataDir.existsSync()) dataDir.deleteSync(recursive: true);
  });

  String dbPath() => p.join(dataDir.path, kDatabaseFileName);

  /// Writes a database stopped at [version] by replaying only that prefix.
  Future<void> seedDatabaseAt(int version) async {
    final Database db = await databaseFactoryFfi.openDatabase(dbPath());
    for (final Migration migration in MigrationRegistry.all) {
      if (migration.version > version) break;
      await migration.migrate(db);
    }
    await db.execute('PRAGMA user_version = $version');
    await db.close();
  }

  group('bootstrapDatabase', () {
    test('should create a database at the latest version in an empty dir',
        () async {
      final DatabaseBootstrap result = await bootstrapDatabase(
        factory: databaseFactoryFfi,
        dataDir: dataDir.path,
      );
      addTearDown(result.db.close);

      expect(result.wasCreated, isTrue);
      expect(result.previousVersion, isNull);
      expect(result.snapshotPath, isNull);
      expect(result.schemaVersion, MigrationRegistry.latestVersion);
      expect(await readUserVersion(result.db), MigrationRegistry.latestVersion);
      expect(File(result.path).existsSync(), isTrue);
    });

    test('should create the data directory when it does not exist', () async {
      final String nested = p.join(dataDir.path, 'deep', 'nested');

      final DatabaseBootstrap result = await bootstrapDatabase(
        factory: databaseFactoryFfi,
        dataDir: nested,
      );
      addTearDown(result.db.close);

      expect(File(p.join(nested, kDatabaseFileName)).existsSync(), isTrue);
    });

    test('should reopen an up-to-date database without a snapshot', () async {
      final DatabaseBootstrap first = await bootstrapDatabase(
        factory: databaseFactoryFfi,
        dataDir: dataDir.path,
      );
      await first.db.close();

      final DatabaseBootstrap second = await bootstrapDatabase(
        factory: databaseFactoryFfi,
        dataDir: dataDir.path,
      );
      addTearDown(second.db.close);

      expect(second.wasCreated, isFalse);
      expect(second.previousVersion, MigrationRegistry.latestVersion);
      expect(second.snapshotPath, isNull);
      expect(Directory(p.join(dataDir.path, 'snapshots')).existsSync(), isFalse);
    });

    test('should snapshot before running pending migrations', () async {
      const int oldVersion = 1;
      await seedDatabaseAt(oldVersion);

      final DatabaseBootstrap result = await bootstrapDatabase(
        factory: databaseFactoryFfi,
        dataDir: dataDir.path,
      );
      addTearDown(result.db.close);

      expect(result.previousVersion, oldVersion);
      expect(result.schemaVersion, MigrationRegistry.latestVersion);
      expect(await readUserVersion(result.db), MigrationRegistry.latestVersion);

      final String? snapshot = result.snapshotPath;
      expect(snapshot, isNotNull);
      expect(File(snapshot!).existsSync(), isTrue);
      expect(p.basename(snapshot), contains('.v$oldVersion.'));
    });

    test('should keep the snapshot at the pre-migration version', () async {
      await seedDatabaseAt(1);

      final DatabaseBootstrap result = await bootstrapDatabase(
        factory: databaseFactoryFfi,
        dataDir: dataDir.path,
      );
      await result.db.close();

      final Database snapshot =
          await databaseFactoryFfi.openDatabase(result.snapshotPath!);
      addTearDown(snapshot.close);

      expect(await readUserVersion(snapshot), 1);
    });

    test('should treat a never-initialised file as a fresh database', () async {
      await databaseFactoryFfi.openDatabase(dbPath()).then((Database d) {
        return d.close();
      });

      final DatabaseBootstrap result = await bootstrapDatabase(
        factory: databaseFactoryFfi,
        dataDir: dataDir.path,
      );
      addTearDown(result.db.close);

      expect(result.wasCreated, isTrue);
      expect(result.snapshotPath, isNull);
      expect(await readUserVersion(result.db), MigrationRegistry.latestVersion);
    });

    test('should refuse a schema newer than this build', () async {
      await seedDatabaseAt(MigrationRegistry.latestVersion);
      final Database db = await databaseFactoryFfi.openDatabase(dbPath());
      await db.execute(
        'PRAGMA user_version = ${MigrationRegistry.latestVersion + 1}',
      );
      await db.close();

      expect(
        () => bootstrapDatabase(
          factory: databaseFactoryFfi,
          dataDir: dataDir.path,
        ),
        throwsA(isA<ServerBootstrapException>()),
      );
    });

    test('should refuse a file that is not a database', () async {
      File(dbPath()).writeAsStringSync('not a database, just some bytes');

      expect(
        () => bootstrapDatabase(
          factory: databaseFactoryFfi,
          dataDir: dataDir.path,
        ),
        throwsA(isA<ServerBootstrapException>()),
      );
    });
  });
}
