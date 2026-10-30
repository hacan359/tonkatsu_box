import 'package:core/database/dao/game_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/game.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late GameDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: MigrationRegistry.all.last.version,
        onCreate: (Database d, int _) async {
          for (final Migration m in MigrationRegistry.all) {
            await m.migrate(d);
          }
        },
        onConfigure: (Database d) => d.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    dao = GameDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  const Game withCompanies = Game(
    id: 7,
    name: 'Chrono Trigger',
    developers: <String>['Square'],
    publishers: <String>['Square', 'Nintendo'],
  );

  group('GameDao company columns', () {
    test('keeps cached developers and publishers when the row has none',
        () async {
      await dao.upsertGame(withCompanies);

      await dao.upsertGame(const Game(id: 7, name: 'Chrono Trigger (old)'));

      final Game? stored = await dao.getGameById(7);
      expect(stored?.name, 'Chrono Trigger (old)');
      expect(stored?.developers, <String>['Square']);
      expect(stored?.publishers, <String>['Square', 'Nintendo']);
    });

    test('replaces companies when the row carries its own', () async {
      await dao.upsertGame(withCompanies);

      await dao.upsertGame(const Game(
        id: 7,
        name: 'Chrono Trigger',
        developers: <String>['Square Enix'],
        publishers: <String>['Square Enix'],
      ));

      final Game? stored = await dao.getGameById(7);
      expect(stored?.developers, <String>['Square Enix']);
      expect(stored?.publishers, <String>['Square Enix']);
    });

    test('batch upsert preserves companies the same way', () async {
      await dao.upsertGames(<Game>[withCompanies]);

      await dao.upsertGames(const <Game>[
        Game(id: 7, name: 'Chrono Trigger'),
        Game(id: 8, name: 'Secret of Mana', developers: <String>['Square']),
      ]);

      expect((await dao.getGameById(7))?.developers, <String>['Square']);
      expect((await dao.getGameById(8))?.developers, <String>['Square']);
      expect((await dao.getGameById(8))?.publishers, isNull);
    });

    test('a game never cached stores nulls, not an error', () async {
      await dao.upsertGame(const Game(id: 9, name: 'Unknown'));

      final Game? stored = await dao.getGameById(9);
      expect(stored?.developers, isNull);
      expect(stored?.publishers, isNull);
    });
  });
}
