import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/mood_grid_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/mood_grid.dart';
import '../../../shared/models/mood_grid_cell.dart';
import 'mood_grids_provider.dart';

class MoodGridDetailState {
  const MoodGridDetailState({required this.grid, required this.cells});

  final MoodGrid grid;
  final List<MoodGridCell> cells;

  MoodGridDetailState copyWith({
    MoodGrid? grid,
    List<MoodGridCell>? cells,
  }) {
    return MoodGridDetailState(
      grid: grid ?? this.grid,
      cells: cells ?? this.cells,
    );
  }
}

final AsyncNotifierProviderFamily<MoodGridDetailNotifier, MoodGridDetailState,
        int> moodGridDetailProvider =
    AsyncNotifierProvider.family<MoodGridDetailNotifier, MoodGridDetailState,
        int>(
  MoodGridDetailNotifier.new,
);

class MoodGridDetailNotifier
    extends FamilyAsyncNotifier<MoodGridDetailState, int> {
  late MoodGridDao _dao;

  @override
  Future<MoodGridDetailState> build(int arg) async {
    _dao = ref.watch(moodGridDaoProvider);
    final MoodGrid? grid = await _dao.getMoodGridById(arg);
    if (grid == null) {
      throw StateError('Mood grid $arg not found');
    }
    final List<MoodGridCell> cells = await _dao.getCells(arg);
    return MoodGridDetailState(grid: grid, cells: cells);
  }

  Future<void> rename(String name) async {
    await _dao.renameMoodGrid(arg, name);
    final MoodGridDetailState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<MoodGridDetailState>(
      current.copyWith(
        grid: current.grid.copyWith(name: name, updatedAt: DateTime.now()),
      ),
    );
    ref.invalidate(moodGridsProvider);
  }

  Future<void> setCellLabel(int cellId, String? label) async {
    await _dao.setCellLabel(cellId, label);
    _replaceCell(cellId, (MoodGridCell c) =>
        c.copyWith(label: label, clearLabel: label == null));
    ref.invalidate(moodGridsProvider);
  }

  Future<void> setCellItem({
    required int cellId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
  }) async {
    await _dao.setCellItem(
      cellId: cellId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
    );
    _replaceCell(
      cellId,
      (MoodGridCell c) => c.copyWith(
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
      ),
    );
    ref.invalidate(moodGridsProvider);
  }

  Future<void> clearCellItem(int cellId) async {
    await _dao.clearCellItem(cellId);
    _replaceCell(cellId, (MoodGridCell c) => c.copyWith(clearItem: true));
    ref.invalidate(moodGridsProvider);
  }

  Future<void> resize({required int newRows, required int newCols}) async {
    await _dao.resizeMoodGrid(arg, newRows: newRows, newCols: newCols);
    final MoodGrid? grid = await _dao.getMoodGridById(arg);
    if (grid == null) return;
    final List<MoodGridCell> cells = await _dao.getCells(arg);
    state = AsyncData<MoodGridDetailState>(
      MoodGridDetailState(grid: grid, cells: cells),
    );
    ref.invalidate(moodGridsProvider);
  }

  void _replaceCell(int cellId, MoodGridCell Function(MoodGridCell) update) {
    final MoodGridDetailState? current = state.valueOrNull;
    if (current == null) return;
    final List<MoodGridCell> next = current.cells.map((MoodGridCell c) {
      if (c.id != cellId) return c;
      return update(c);
    }).toList();
    state = AsyncData<MoodGridDetailState>(current.copyWith(cells: next));
  }
}
