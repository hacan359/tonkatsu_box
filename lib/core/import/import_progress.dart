/// Receives [ImportProgress] updates while an import runs.
typedef ImportProgressCallback = void Function(ImportProgress progress);

/// A snapshot of an import in flight: [stage], progress, running tallies,
/// and rate-limit back-off info when a source is waiting out a 429 window.
class ImportProgress {
  const ImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.message,
    this.currentItem,
    this.imported = 0,
    this.updated = 0,
    this.wishlisted = 0,
    this.retryWaitSeconds,
    this.retryAttempt,
    this.retryMaxAttempts,
  });

  final ImportStage stage;

  final int current;

  final int total;

  final String? message;

  /// Title of the item currently being processed (raw data, not localized).
  final String? currentItem;

  /// Running tallies for the source-import progress UIs.
  final int imported;
  final int updated;
  final int wishlisted;

  /// Rate-limit back-off info, set only while a source waits out a 429 window.
  final int? retryWaitSeconds;
  final int? retryAttempt;
  final int? retryMaxAttempts;

  double get progress => total > 0 ? current / total : 0;
}

/// Phases an import goes through. The descriptions are developer-facing
/// fallbacks — the UI maps stages to localized strings.
enum ImportStage {
  reading('Reading file...'),

  fetchingGames('Fetching game data...'),

  fetchingMovies('Fetching movie data...'),

  fetchingTvShows('Fetching TV show data...'),

  fetchingVisualNovels('Fetching visual novel data...'),

  fetchingManga('Fetching manga data...'),

  fetchingAnime('Fetching anime data...'),

  fetchingBooks('Fetching book data...'),

  cachingMedia('Caching media...'),

  creatingCollection('Creating collection...'),

  addingItems('Adding items...'),

  importingCanvas('Importing board...'),

  restoringMedia('Restoring media data...'),

  importingImages('Restoring images...'),

  completed('Import completed');

  const ImportStage(this.description);

  final String description;
}
