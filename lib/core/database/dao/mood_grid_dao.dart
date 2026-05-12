import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/media_type.dart';
import '../../../shared/models/mood_grid.dart';
import '../../../shared/models/mood_grid_cell.dart';

/// Spec for a cell created at grid initialisation time (template / blank).
class MoodGridCellSpec {
  /// Creates a [MoodGridCellSpec].
  const MoodGridCellSpec({this.label});

  /// Optional category label (e.g. "Favorite Game"). `null` for blank cells.
  final String? label;
}

/// DAO for `mood_grids` and `mood_grid_cells`.
class MoodGridDao {
  /// Creates a DAO with a database accessor.
  const MoodGridDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Returns all grids ordered by creation date, newest first.
  Future<List<MoodGrid>> getAllMoodGrids() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'mood_grids',
      orderBy: 'created_at DESC',
    );
    return rows.map(MoodGrid.fromDb).toList();
  }

  /// Returns a grid by id, or null if missing.
  Future<MoodGrid?> getMoodGridById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'mood_grids',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MoodGrid.fromDb(rows.first);
  }

  /// Creates a grid plus `rows*cols` empty cells in one transaction.
  ///
  /// When [cellSpecs] is supplied, its labels are applied to the first
  /// `cellSpecs.length` cells in row-major order; remaining cells stay blank.
  Future<MoodGrid> createMoodGrid({
    required String name,
    int rows = 1,
    int cols = 5,
    List<MoodGridCellSpec> cellSpecs = const <MoodGridCellSpec>[],
  }) async {
    if (rows < 1 || cols < 1) {
      throw ArgumentError.value('${rows}x$cols', 'rows/cols', 'must be >= 1');
    }

    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int total = rows * cols;

    final int gridId = await db.transaction<int>((Transaction txn) async {
      final int id = await txn.insert(
        'mood_grids',
        <String, dynamic>{
          'name': name,
          'rows': rows,
          'cols': cols,
          'created_at': now,
          'updated_at': now,
        },
      );

      for (int position = 0; position < total; position++) {
        final String? label = position < cellSpecs.length
            ? cellSpecs[position].label
            : null;
        await txn.insert(
          'mood_grid_cells',
          <String, dynamic>{
            'grid_id': id,
            'position': position,
            'label': label,
          },
        );
      }

      return id;
    });

    return MoodGrid(
      id: gridId,
      name: name,
      rows: rows,
      cols: cols,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }

  /// Renames a grid and bumps `updated_at`.
  Future<void> renameMoodGrid(int id, String name) async {
    final Database db = await _getDatabase();
    await db.update(
      'mood_grids',
      <String, dynamic>{
        'name': name,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Deletes a grid; CASCADE drops all cells.
  Future<void> deleteMoodGrid(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'mood_grids',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Returns all cells of a grid ordered by position.
  Future<List<MoodGridCell>> getCells(int gridId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'mood_grid_cells',
      where: 'grid_id = ?',
      whereArgs: <Object?>[gridId],
      orderBy: 'position ASC',
    );
    return rows.map(MoodGridCell.fromDb).toList();
  }

  /// Resizes a grid to `newRows × newCols`.
  ///
  /// Growth: appends empty cells to the end of each row and/or new rows.
  /// Shrink: drops cells whose `position >= newRows * newCols`. Positions
  /// are remapped so the remaining cells keep their (row, col) coordinates
  /// even when `cols` shrinks — i.e. cell at old `(r, c)` with old `cols=5`
  /// moves to new position `r * newCols + c`. Cells that end up out of bounds
  /// (`c >= newCols` or `r >= newRows`) are deleted.
  Future<void> resizeMoodGrid(
    int id, {
    required int newRows,
    required int newCols,
  }) async {
    if (newRows < 1 || newCols < 1) {
      throw ArgumentError.value(
        '${newRows}x$newCols',
        'newRows/newCols',
        'must be >= 1',
      );
    }

    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.transaction((Transaction txn) async {
      final List<Map<String, dynamic>> gridRows = await txn.query(
        'mood_grids',
        where: 'id = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (gridRows.isEmpty) {
        throw StateError('Mood grid $id not found');
      }

      final int oldRows = gridRows.first['rows'] as int;
      final int oldCols = gridRows.first['cols'] as int;

      if (oldRows == newRows && oldCols == newCols) {
        return;
      }

      // Read all existing cells, normalise position to (row, col) under
      // the OLD column count, then write back at new positions under the
      // NEW column count.
      final List<Map<String, dynamic>> oldCells = await txn.query(
        'mood_grid_cells',
        where: 'grid_id = ?',
        whereArgs: <Object?>[id],
        orderBy: 'position ASC',
      );

      await txn.delete(
        'mood_grid_cells',
        where: 'grid_id = ?',
        whereArgs: <Object?>[id],
      );

      // Track which new positions are filled by existing cells; the rest
      // get blank inserts at the end.
      final Set<int> usedPositions = <int>{};

      for (final Map<String, dynamic> cell in oldCells) {
        final int pos = cell['position'] as int;
        final int row = pos ~/ oldCols;
        final int col = pos % oldCols;
        if (row >= newRows || col >= newCols) {
          continue; // out of new bounds — drop
        }
        final int newPos = row * newCols + col;
        usedPositions.add(newPos);
        await txn.insert(
          'mood_grid_cells',
          <String, dynamic>{
            'grid_id': id,
            'position': newPos,
            'label': cell['label'],
            'media_type': cell['media_type'],
            'external_id': cell['external_id'],
            'platform_id': cell['platform_id'],
          },
        );
      }

      // Fill missing slots with blanks.
      final int total = newRows * newCols;
      for (int p = 0; p < total; p++) {
        if (usedPositions.contains(p)) continue;
        await txn.insert(
          'mood_grid_cells',
          <String, dynamic>{
            'grid_id': id,
            'position': p,
            'label': null,
          },
        );
      }

      await txn.update(
        'mood_grids',
        <String, dynamic>{
          'rows': newRows,
          'cols': newCols,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    });
  }

  /// Sets the cell's category label. `null` clears it.
  Future<void> setCellLabel(int cellId, String? label) async {
    final Database db = await _getDatabase();
    await db.update(
      'mood_grid_cells',
      <String, dynamic>{'label': label},
      where: 'id = ?',
      whereArgs: <Object?>[cellId],
    );
    await _touchOwningGrid(db, cellId);
  }

  /// Assigns a media item to the cell.
  Future<void> setCellItem({
    required int cellId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
  }) async {
    final Database db = await _getDatabase();
    await db.update(
      'mood_grid_cells',
      <String, dynamic>{
        'media_type': mediaType.value,
        'external_id': externalId,
        'platform_id': platformId,
      },
      where: 'id = ?',
      whereArgs: <Object?>[cellId],
    );
    await _touchOwningGrid(db, cellId);
  }

  /// Removes the media item from the cell but keeps the label.
  Future<void> clearCellItem(int cellId) async {
    final Database db = await _getDatabase();
    await db.update(
      'mood_grid_cells',
      <String, dynamic>{
        'media_type': null,
        'external_id': null,
        'platform_id': null,
      },
      where: 'id = ?',
      whereArgs: <Object?>[cellId],
    );
    await _touchOwningGrid(db, cellId);
  }

  Future<void> _touchOwningGrid(Database db, int cellId) async {
    final List<Map<String, dynamic>> rows = await db.query(
      'mood_grid_cells',
      columns: <String>['grid_id'],
      where: 'id = ?',
      whereArgs: <Object?>[cellId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    await db.update(
      'mood_grids',
      <String, dynamic>{
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: <Object?>[rows.first['grid_id']],
    );
  }
}
