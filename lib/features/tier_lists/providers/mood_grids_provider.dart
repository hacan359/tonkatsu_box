import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/mood_grid_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/mood_grid.dart';

/// Default preset id used by the create dialog and elsewhere.
enum MoodGridPreset { aboutMeTonkatsuBox, blank }

/// Default labels for the «About Me: Tonkatsu Box» preset.
List<MoodGridCellSpec> aboutMeTonkatsuBoxCells() {
  return const <MoodGridCellSpec>[
    MoodGridCellSpec(label: 'Favorite Game'),
    MoodGridCellSpec(label: 'Favorite Movie'),
    MoodGridCellSpec(label: 'Favorite TV Show'),
    MoodGridCellSpec(label: 'Favorite Anime'),
    MoodGridCellSpec(label: 'Favorite Manga'),
  ];
}

/// Default title used when the user does not type one.
const String kDefaultMoodGridTitle = 'About Me: Tonkatsu Box';

final AsyncNotifierProvider<MoodGridsNotifier, List<MoodGrid>>
    moodGridsProvider =
    AsyncNotifierProvider<MoodGridsNotifier, List<MoodGrid>>(
  MoodGridsNotifier.new,
);

class MoodGridsNotifier extends AsyncNotifier<List<MoodGrid>> {
  late MoodGridDao _dao;

  @override
  Future<List<MoodGrid>> build() async {
    _dao = ref.watch(moodGridDaoProvider);
    return _dao.getAllMoodGrids();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<MoodGrid>>();
    state = await AsyncValue.guard(() => _dao.getAllMoodGrids());
  }

  /// Creates a grid from a preset.
  Future<MoodGrid> create({
    required String name,
    required MoodGridPreset preset,
    int rows = 1,
    int cols = 5,
  }) async {
    final List<MoodGridCellSpec> cellSpecs;
    final int actualRows;
    final int actualCols;

    switch (preset) {
      case MoodGridPreset.aboutMeTonkatsuBox:
        cellSpecs = aboutMeTonkatsuBoxCells();
        actualRows = 1;
        actualCols = 5;
      case MoodGridPreset.blank:
        cellSpecs = const <MoodGridCellSpec>[];
        actualRows = rows;
        actualCols = cols;
    }

    final MoodGrid grid = await _dao.createMoodGrid(
      name: name,
      rows: actualRows,
      cols: actualCols,
      cellSpecs: cellSpecs,
    );

    final List<MoodGrid> current = state.valueOrNull ?? <MoodGrid>[];
    state = AsyncData<List<MoodGrid>>(<MoodGrid>[grid, ...current]);

    return grid;
  }

  Future<void> rename(int id, String name) async {
    await _dao.renameMoodGrid(id, name);
    final List<MoodGrid> current = state.valueOrNull ?? <MoodGrid>[];
    state = AsyncData<List<MoodGrid>>(
      current.map((MoodGrid g) =>
          g.id == id ? g.copyWith(name: name, updatedAt: DateTime.now()) : g).toList(),
    );
  }

  Future<void> delete(int id) async {
    await _dao.deleteMoodGrid(id);
    final List<MoodGrid> current = state.valueOrNull ?? <MoodGrid>[];
    state = AsyncData<List<MoodGrid>>(
      current.where((MoodGrid g) => g.id != id).toList(),
    );
  }
}
