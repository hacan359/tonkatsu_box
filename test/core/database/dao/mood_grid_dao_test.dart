import 'package:core/database/dao/mood_grid_dao.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/mood_grid.dart';
import 'package:core/models/mood_grid_cell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Runs against a real in-memory SQLite: resize is transactional and remaps
// positions, which mocks cannot meaningfully cover.
void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  late Database db;
  late MoodGridDao dao;

  setUp(() async {
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
    await db.execute('''
      CREATE TABLE mood_grids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rows INTEGER NOT NULL DEFAULT 1,
        cols INTEGER NOT NULL DEFAULT 5,
        caption_template TEXT,
        cell_label_template TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE mood_grid_cells (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grid_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        label TEXT,
        media_type TEXT,
        external_id INTEGER,
        platform_id INTEGER,
        source TEXT,
        FOREIGN KEY (grid_id) REFERENCES mood_grids(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_mood_grid_cell_pos
      ON mood_grid_cells(grid_id, position)
    ''');
    dao = MoodGridDao(() async => db);
  });

  tearDown(() async => db.close());

  Future<MoodGridCell> cellAt(int gridId, int position) async {
    final List<MoodGridCell> cells = await dao.getCells(gridId);
    return cells.firstWhere((MoodGridCell c) => c.position == position);
  }

  group('MoodGridDao', () {
    group('createMoodGrid', () {
      test('creates grid with rows*cols blank cells', () async {
        final MoodGrid grid =
            await dao.createMoodGrid(name: 'G', rows: 2, cols: 3);

        final List<MoodGridCell> cells = await dao.getCells(grid.id);
        expect(cells, hasLength(6));
        expect(cells.every((MoodGridCell c) => c.isEmpty), isTrue);
        expect(
          cells.map((MoodGridCell c) => c.position),
          List<int>.generate(6, (int i) => i),
        );
      });

      test('applies cell specs to leading cells', () async {
        final MoodGrid grid = await dao.createMoodGrid(
          name: 'G',
          cols: 3,
          cellSpecs: const <MoodGridCellSpec>[
            MoodGridCellSpec(label: 'A'),
            MoodGridCellSpec(label: 'B'),
          ],
        );

        final List<MoodGridCell> cells = await dao.getCells(grid.id);
        expect(cells[0].label, 'A');
        expect(cells[1].label, 'B');
        expect(cells[2].label, isNull);
      });

      test('rejects non-positive dimensions', () async {
        expect(
          () => dao.createMoodGrid(name: 'G', rows: 0),
          throwsArgumentError,
        );
      });
    });

    group('templates', () {
      test('setCaptionTemplate and setCellLabelTemplate round-trip', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'G');

        await dao.setCaptionTemplate(grid.id, '{{name}} ({{year}})');
        await dao.setCellLabelTemplate(grid.id, '{{name}}');

        final MoodGrid? loaded = await dao.getMoodGridById(grid.id);
        expect(loaded?.captionTemplate, '{{name}} ({{year}})');
        expect(loaded?.cellLabelTemplate, '{{name}}');
      });

      test('empty template clears to null', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'G');
        await dao.setCellLabelTemplate(grid.id, '{{name}}');

        await dao.setCellLabelTemplate(grid.id, '');

        final MoodGrid? loaded = await dao.getMoodGridById(grid.id);
        expect(loaded?.cellLabelTemplate, isNull);
      });
    });

    group('cell items', () {
      test('setCellItem stores the full reference including source', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'G');
        final MoodGridCell cell = await cellAt(grid.id, 0);

        await dao.setCellItem(
          cellId: cell.id,
          mediaType: MediaType.manga,
          externalId: 42,
          source: DataSource.mangabaka,
        );

        final MoodGridCell updated = await cellAt(grid.id, 0);
        expect(updated.mediaType, MediaType.manga);
        expect(updated.externalId, 42);
        expect(updated.source, DataSource.mangabaka);
      });

      test('clearCellItem keeps the label', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'G');
        final MoodGridCell cell = await cellAt(grid.id, 0);
        await dao.setCellLabel(cell.id, 'Keep me');
        await dao.setCellItem(
          cellId: cell.id,
          mediaType: MediaType.game,
          externalId: 7,
        );

        await dao.clearCellItem(cell.id);

        final MoodGridCell updated = await cellAt(grid.id, 0);
        expect(updated.isEmpty, isTrue);
        expect(updated.label, 'Keep me');
      });
    });

    group('resizeMoodGrid', () {
      test('growth appends blank cells and keeps coordinates', () async {
        final MoodGrid grid =
            await dao.createMoodGrid(name: 'G', rows: 1, cols: 2);
        final MoodGridCell first = await cellAt(grid.id, 0);
        await dao.setCellItem(
          cellId: first.id,
          mediaType: MediaType.game,
          externalId: 7,
        );

        await dao.resizeMoodGrid(grid.id, newRows: 2, newCols: 3);

        final MoodGrid? loaded = await dao.getMoodGridById(grid.id);
        expect(loaded?.rows, 2);
        expect(loaded?.cols, 3);
        final List<MoodGridCell> cells = await dao.getCells(grid.id);
        expect(cells, hasLength(6));
        // Old (0,0) stays at position 0 under the new column count.
        expect(cells[0].externalId, 7);
        expect(cells.skip(1).every((MoodGridCell c) => c.isEmpty), isTrue);
      });

      test('column shrink remaps positions to keep (row, col)', () async {
        final MoodGrid grid =
            await dao.createMoodGrid(name: 'G', rows: 2, cols: 3);
        // Fill (1, 1): old position = 1*3+1 = 4.
        final MoodGridCell target = await cellAt(grid.id, 4);
        await dao.setCellItem(
          cellId: target.id,
          mediaType: MediaType.movie,
          externalId: 99,
        );

        await dao.resizeMoodGrid(grid.id, newRows: 2, newCols: 2);

        // New position of (1, 1) = 1*2+1 = 3.
        final MoodGridCell moved = await cellAt(grid.id, 3);
        expect(moved.externalId, 99);
        expect(await dao.getCells(grid.id), hasLength(4));
      });

      test('shrink drops out-of-bounds cells', () async {
        final MoodGrid grid =
            await dao.createMoodGrid(name: 'G', rows: 1, cols: 3);
        final MoodGridCell last = await cellAt(grid.id, 2);
        await dao.setCellItem(
          cellId: last.id,
          mediaType: MediaType.game,
          externalId: 5,
        );

        await dao.resizeMoodGrid(grid.id, newRows: 1, newCols: 2);

        final List<MoodGridCell> cells = await dao.getCells(grid.id);
        expect(cells, hasLength(2));
        expect(cells.every((MoodGridCell c) => c.isEmpty), isTrue);
      });

      test('preserves label and source across resize', () async {
        final MoodGrid grid =
            await dao.createMoodGrid(name: 'G', rows: 1, cols: 2);
        final MoodGridCell cell = await cellAt(grid.id, 1);
        await dao.setCellLabel(cell.id, 'Best manga');
        await dao.setCellItem(
          cellId: cell.id,
          mediaType: MediaType.manga,
          externalId: 42,
          source: DataSource.mangabaka,
        );

        await dao.resizeMoodGrid(grid.id, newRows: 2, newCols: 2);

        final MoodGridCell kept = await cellAt(grid.id, 1);
        expect(kept.label, 'Best manga');
        expect(kept.mediaType, MediaType.manga);
        expect(kept.externalId, 42);
        expect(kept.source, DataSource.mangabaka);
      });
    });

    group('resizeMoodGrid edge cases', () {
      test('rejects non-positive dimensions', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'G');

        expect(
          () => dao.resizeMoodGrid(grid.id, newRows: 0, newCols: 5),
          throwsArgumentError,
        );
        expect(
          () => dao.resizeMoodGrid(grid.id, newRows: 1, newCols: 0),
          throwsArgumentError,
        );
      });

      test('throws when the grid does not exist', () async {
        expect(
          () => dao.resizeMoodGrid(404, newRows: 2, newCols: 2),
          throwsStateError,
        );
      });

      test('leaves cells untouched when the size is unchanged', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'G', cols: 3);
        await dao.setCellItem(
          cellId: (await cellAt(grid.id, 0)).id,
          mediaType: MediaType.game,
          externalId: 42,
        );

        await dao.resizeMoodGrid(grid.id, newRows: 1, newCols: 3);

        final List<MoodGridCell> cells = await dao.getCells(grid.id);
        expect(cells, hasLength(3));
        expect(cells.first.externalId, 42);
      });
    });

    group('deleteMoodGrid', () {
      test('cascade removes cells', () async {
        // FK enforcement is opt-in per connection in SQLite.
        await db.execute('PRAGMA foreign_keys = ON');
        final MoodGrid grid = await dao.createMoodGrid(name: 'G');

        await dao.deleteMoodGrid(grid.id);

        expect(await dao.getMoodGridById(grid.id), isNull);
        expect(await dao.getCells(grid.id), isEmpty);
      });

      test('leaves other grids alone', () async {
        final MoodGrid kept = await dao.createMoodGrid(name: 'Keep');
        final MoodGrid dropped = await dao.createMoodGrid(name: 'Drop');

        await dao.deleteMoodGrid(dropped.id);

        expect(await dao.getMoodGridById(kept.id), isNotNull);
      });
    });

    group('getAllMoodGrids', () {
      test('returns empty when none exist', () async {
        expect(await dao.getAllMoodGrids(), isEmpty);
      });

      test('returns every grid with its dimensions', () async {
        await dao.createMoodGrid(name: 'A', rows: 2, cols: 3);
        await dao.createMoodGrid(name: 'B');

        final List<MoodGrid> all = await dao.getAllMoodGrids();

        expect(all, hasLength(2));
        expect(
          all.map((MoodGrid g) => g.name).toSet(),
          <String>{'A', 'B'},
        );
        final MoodGrid a = all.firstWhere((MoodGrid g) => g.name == 'A');
        expect(a.rows, 2);
        expect(a.cols, 3);
      });
    });

    group('getMoodGridById', () {
      test('returns null for an unknown id', () async {
        expect(await dao.getMoodGridById(404), isNull);
      });
    });

    group('renameMoodGrid', () {
      test('changes the name', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'Before');

        await dao.renameMoodGrid(grid.id, 'After');

        expect((await dao.getMoodGridById(grid.id))?.name, 'After');
      });

      test('keeps the cells untouched', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'G', cols: 3);

        await dao.renameMoodGrid(grid.id, 'Renamed');

        expect(await dao.getCells(grid.id), hasLength(3));
      });

      test('is a no-op for an unknown id', () async {
        final MoodGrid grid = await dao.createMoodGrid(name: 'Keep');

        await dao.renameMoodGrid(grid.id + 1000, 'Ghost');

        expect((await dao.getMoodGridById(grid.id))?.name, 'Keep');
      });
    });
  });
}
