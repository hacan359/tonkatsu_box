import 'package:core/models/media_type.dart';
import 'package:core/models/mood_grid.dart';
import 'package:core/models/mood_grid_cell.dart';
import 'package:core/models/movie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/mood_grids/providers/mood_grid_detail_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  const int gridId = 1;
  const int cellId = 10;

  late MockMoodGridDao mockDao;
  late MockDatabaseService mockDb;
  late MockMovieDao mockMovieDao;
  late ProviderContainer container;

  MoodGrid createGrid({String? cellLabelTemplate}) {
    return MoodGrid(
      id: gridId,
      name: 'G',
      rows: 1,
      cols: 1,
      cellLabelTemplate: cellLabelTemplate,
      createdAt: testDate,
      updatedAt: testDate,
    );
  }

  void stubGrid(MoodGrid grid, {String? cellLabel}) {
    when(() => mockDao.getMoodGridById(gridId)).thenAnswer((_) async => grid);
    when(() => mockDao.getCells(gridId)).thenAnswer(
      (_) async => <MoodGridCell>[
        MoodGridCell(id: cellId, gridId: gridId, position: 0, label: cellLabel),
      ],
    );
  }

  setUp(() {
    mockDao = MockMoodGridDao();
    mockDb = MockDatabaseService();
    mockMovieDao = MockMovieDao();

    when(() => mockDb.movieDao).thenReturn(mockMovieDao);
    when(() => mockMovieDao.getMoviesByTmdbIds(any())).thenAnswer(
      (_) async => const <Movie>[
        Movie(tmdbId: 99, title: 'Heat', releaseYear: 1995),
      ],
    );
    when(
      () => mockDao.setCellItem(
        cellId: any(named: 'cellId'),
        mediaType: any(named: 'mediaType'),
        externalId: any(named: 'externalId'),
        platformId: any(named: 'platformId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockDao.setCellLabel(any(), any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: <Override>[
        moodGridDaoProvider.overrideWithValue(mockDao),
        databaseServiceProvider.overrideWithValue(mockDb),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<MoodGridDetailState> load() =>
      container.read(moodGridDetailProvider(gridId).future);

  group('MoodGridDetailNotifier.setCellItem', () {
    test('auto-fills an empty label from cellLabelTemplate', () async {
      stubGrid(createGrid(cellLabelTemplate: '{{name}} ({{year}})'));
      await load();

      await container
          .read(moodGridDetailProvider(gridId).notifier)
          .setCellItem(
            cellId: cellId,
            mediaType: MediaType.movie,
            externalId: 99,
          );

      verify(() => mockDao.setCellLabel(cellId, 'Heat (1995)')).called(1);
      final MoodGridDetailState state = await load();
      expect(state.cells.single.label, 'Heat (1995)');
    });

    test('does not touch a non-empty label', () async {
      stubGrid(
        createGrid(cellLabelTemplate: '{{name}}'),
        cellLabel: 'My pick',
      );
      await load();

      await container
          .read(moodGridDetailProvider(gridId).notifier)
          .setCellItem(
            cellId: cellId,
            mediaType: MediaType.movie,
            externalId: 99,
          );

      verifyNever(() => mockDao.setCellLabel(any(), any()));
      final MoodGridDetailState state = await load();
      expect(state.cells.single.label, 'My pick');
    });

    test('does nothing without a template', () async {
      stubGrid(createGrid());
      await load();

      await container
          .read(moodGridDetailProvider(gridId).notifier)
          .setCellItem(
            cellId: cellId,
            mediaType: MediaType.movie,
            externalId: 99,
          );

      verifyNever(() => mockDao.setCellLabel(any(), any()));
    });

    test('skips auto-fill when the template renders to empty', () async {
      stubGrid(createGrid(cellLabelTemplate: '{{genre}}'));
      when(() => mockMovieDao.getMoviesByTmdbIds(any())).thenAnswer(
        (_) async => const <Movie>[Movie(tmdbId: 99, title: 'Heat')],
      );
      await load();

      await container
          .read(moodGridDetailProvider(gridId).notifier)
          .setCellItem(
            cellId: cellId,
            mediaType: MediaType.movie,
            externalId: 99,
          );

      verifyNever(() => mockDao.setCellLabel(any(), any()));
    });
  });

  group('MoodGridDetailNotifier.setCellLabelTemplate', () {
    test('persists and updates state', () async {
      stubGrid(createGrid());
      when(() => mockDao.setCellLabelTemplate(gridId, any()))
          .thenAnswer((_) async {});
      await load();

      await container
          .read(moodGridDetailProvider(gridId).notifier)
          .setCellLabelTemplate('{{name}}');

      verify(() => mockDao.setCellLabelTemplate(gridId, '{{name}}')).called(1);
      final MoodGridDetailState state = await load();
      expect(state.grid.cellLabelTemplate, '{{name}}');
    });

    test('clears with an empty string', () async {
      stubGrid(createGrid(cellLabelTemplate: '{{name}}'));
      when(() => mockDao.setCellLabelTemplate(gridId, any()))
          .thenAnswer((_) async {});
      await load();

      await container
          .read(moodGridDetailProvider(gridId).notifier)
          .setCellLabelTemplate('');

      verify(() => mockDao.setCellLabelTemplate(gridId, null)).called(1);
      final MoodGridDetailState state = await load();
      expect(state.grid.cellLabelTemplate, isNull);
    });
  });
}
