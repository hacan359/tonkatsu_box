import '../../core/import/import_progress.dart';
import '../../l10n/app_localizations.dart';

extension ImportStageUi on ImportStage {
  String label(S l) => switch (this) {
        ImportStage.reading => l.importStageReading,
        ImportStage.fetchingGames => l.importStageFetchingGames,
        ImportStage.fetchingMovies => l.importStageFetchingMovies,
        ImportStage.fetchingTvShows => l.importStageFetchingTvShows,
        ImportStage.fetchingVisualNovels => l.importStageFetchingVisualNovels,
        ImportStage.fetchingManga => l.importStageFetchingManga,
        ImportStage.fetchingAnime => l.importStageFetchingAnime,
        ImportStage.fetchingBooks => l.importStageFetchingBooks,
        ImportStage.cachingMedia => l.importStageCachingMedia,
        ImportStage.creatingCollection => l.importStageCreatingCollection,
        ImportStage.resolvingTitles => l.importStageResolvingTitles,
        ImportStage.addingItems => l.importStageAddingItems,
        ImportStage.importingCanvas => l.importStageImportingCanvas,
        ImportStage.restoringMedia => l.importStageRestoringMedia,
        ImportStage.importingImages => l.importStageImportingImages,
        ImportStage.completed => l.importStageCompleted,
      };
}
