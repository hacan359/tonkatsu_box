import 'package:core/database/dao/mood_grid_dao.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/mood_grid.dart';
import 'package:core/models/mood_grid_cell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../services/mood_grid_caption.dart';
import '../widgets/mood_grid_cell_media.dart';
import 'mood_grids_provider.dart';

class MoodGridDetailState {
  const MoodGridDetailState({
    required this.grid,
    required this.cells,
    required this.mediaByPosition,
  });

  final MoodGrid grid;
  final List<MoodGridCell> cells;

  /// Resolved cell media keyed by cell position. Cells with no item map to
  /// [MoodGridCellMedia.empty] so callers can index without null checks.
  final Map<int, MoodGridCellMedia> mediaByPosition;

  MoodGridDetailState copyWith({
    MoodGrid? grid,
    List<MoodGridCell>? cells,
    Map<int, MoodGridCellMedia>? mediaByPosition,
  }) {
    return MoodGridDetailState(
      grid: grid ?? this.grid,
      cells: cells ?? this.cells,
      mediaByPosition: mediaByPosition ?? this.mediaByPosition,
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
  late DatabaseService _db;

  @override
  Future<MoodGridDetailState> build(int arg) async {
    _dao = ref.watch(moodGridDaoProvider);
    _db = ref.watch(databaseServiceProvider);
    final MoodGrid? grid = await _dao.getMoodGridById(arg);
    if (grid == null) {
      throw StateError('Mood grid $arg not found');
    }
    final List<MoodGridCell> cells = await _dao.getCells(arg);
    final Map<int, MoodGridCellMedia> media =
        await resolveMoodGridCellMediaBatch(_db, cells);
    return MoodGridDetailState(
      grid: grid,
      cells: cells,
      mediaByPosition: media,
    );
  }

  Future<MoodGridCellMedia> _resolveOne(MoodGridCell cell) async {
    final Map<int, MoodGridCellMedia> resolved =
        await resolveMoodGridCellMediaBatch(_db, <MoodGridCell>[cell]);
    return resolved[cell.position] ?? MoodGridCellMedia.empty;
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

  Future<void> setCaptionTemplate(String? template) {
    return _setTemplate(
      template,
      _dao.setCaptionTemplate,
      (MoodGrid g, String? t) => g.copyWith(
        captionTemplate: t,
        clearCaptionTemplate: t == null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setCellLabelTemplate(String? template) {
    return _setTemplate(
      template,
      _dao.setCellLabelTemplate,
      (MoodGrid g, String? t) => g.copyWith(
        cellLabelTemplate: t,
        clearCellLabelTemplate: t == null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _setTemplate(
    String? template,
    Future<void> Function(int id, String? template) persist,
    MoodGrid Function(MoodGrid grid, String? template) apply,
  ) async {
    final String? normalised =
        (template == null || template.isEmpty) ? null : template;
    await persist(arg, normalised);
    final MoodGridDetailState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<MoodGridDetailState>(
      current.copyWith(grid: apply(current.grid, normalised)),
    );
  }

  Future<void> setCellLabel(int cellId, String? label) async {
    await _dao.setCellLabel(cellId, label);
    _replaceCell(cellId, (MoodGridCell c) =>
        c.copyWith(label: label, clearLabel: label == null));
  }

  Future<void> setCellItem({
    required int cellId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
  }) async {
    await _dao.setCellItem(
      cellId: cellId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      source: source,
    );
    final MoodGridCellMedia? media = await _replaceCellAndMedia(
      cellId,
      (MoodGridCell c) => c.copyWith(
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
        source: source,
      ),
    );
    if (media != null) {
      await _autoFillLabel(cellId, media);
    }
  }

  /// Fills the cell label from the grid's `cellLabelTemplate`. Fires only
  /// when an item is picked and only if the label is still empty.
  Future<void> _autoFillLabel(int cellId, MoodGridCellMedia media) async {
    final MoodGridDetailState? current = state.valueOrNull;
    if (current == null) return;
    final String template = current.grid.cellLabelTemplate ?? '';
    if (template.trim().isEmpty) return;

    MoodGridCell? cell;
    for (final MoodGridCell c in current.cells) {
      if (c.id == cellId) {
        cell = c;
        break;
      }
    }
    if (cell == null) return;
    if ((cell.label ?? '').isNotEmpty) return;

    final String label = renderRowCaption(template, media);
    if (label.isEmpty) return;
    await setCellLabel(cellId, label);
  }

  Future<void> clearCellItem(int cellId) async {
    await _dao.clearCellItem(cellId);
    await _replaceCellAndMedia(
      cellId,
      (MoodGridCell c) => c.copyWith(clearItem: true),
    );
  }

  Future<void> resize({required int newRows, required int newCols}) async {
    await _dao.resizeMoodGrid(arg, newRows: newRows, newCols: newCols);
    final MoodGrid? grid = await _dao.getMoodGridById(arg);
    if (grid == null) return;
    final List<MoodGridCell> cells = await _dao.getCells(arg);
    final Map<int, MoodGridCellMedia> media =
        await resolveMoodGridCellMediaBatch(_db, cells);
    state = AsyncData<MoodGridDetailState>(
      MoodGridDetailState(
        grid: grid,
        cells: cells,
        mediaByPosition: media,
      ),
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

  Future<MoodGridCellMedia?> _replaceCellAndMedia(
    int cellId,
    MoodGridCell Function(MoodGridCell) update,
  ) async {
    final MoodGridDetailState? current = state.valueOrNull;
    if (current == null) return null;
    MoodGridCell? updated;
    final List<MoodGridCell> next = current.cells.map((MoodGridCell c) {
      if (c.id != cellId) return c;
      updated = update(c);
      return updated!;
    }).toList();
    if (updated == null) return null;
    final MoodGridCellMedia media = await _resolveOne(updated!);
    final Map<int, MoodGridCellMedia> nextMedia =
        Map<int, MoodGridCellMedia>.of(current.mediaByPosition);
    nextMedia[updated!.position] = media;
    state = AsyncData<MoodGridDetailState>(
      current.copyWith(cells: next, mediaByPosition: nextMedia),
    );
    return media;
  }
}
