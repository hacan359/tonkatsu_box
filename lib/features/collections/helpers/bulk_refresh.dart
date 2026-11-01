import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/import/import_progress.dart';
import 'item_refresh.dart';

/// Set from the dialog's Stop button; the loop checks it between items, so
/// the item in flight always finishes and stays updated.
class BulkRefreshCancellation {
  bool _requested = false;

  bool get requested => _requested;

  void request() => _requested = true;
}

class BulkRefreshProblem {
  const BulkRefreshProblem({required this.title, required this.kind, this.error});

  final String title;
  final RefreshOutcomeKind kind;
  final String? error;
}

class BulkRefreshResult {
  const BulkRefreshResult({
    required this.updated,
    required this.notFound,
    required this.failed,
    required this.skipped,
    required this.problems,
    required this.cancelled,
  });

  final int updated;
  final int notFound;
  final int failed;
  final int skipped;
  final List<BulkRefreshProblem> problems;
  final bool cancelled;
}

ImportStage _stageFor(MediaType type) => switch (type) {
      MediaType.game => ImportStage.fetchingGames,
      MediaType.movie => ImportStage.fetchingMovies,
      MediaType.tvShow || MediaType.animation => ImportStage.fetchingTvShows,
      MediaType.anime => ImportStage.fetchingAnime,
      MediaType.manga => ImportStage.fetchingManga,
      MediaType.visualNovel => ImportStage.fetchingVisualNovels,
      MediaType.book => ImportStage.fetchingBooks,
      MediaType.audio => ImportStage.fetchingAudio,
      // Never asked: custom cards fail canRefreshFromSource.
      MediaType.custom => ImportStage.completed,
    };

/// One item at a time, a failure never stops the rest. Sequential on purpose:
/// one source dominates a selection and its rate limiter would queue anyway.
Future<BulkRefreshResult> runBulkRefresh(
  WidgetRef ref,
  List<CollectionItem> items, {
  required ImportProgressCallback onProgress,
  BulkRefreshCancellation? cancellation,
}) async {
  final List<CollectionItem> eligible =
      items.where(canRefreshFromSource).toList();
  int skipped = items.length - eligible.length;
  int updated = 0;
  int notFound = 0;
  int failed = 0;
  int done = 0;
  final List<BulkRefreshProblem> problems = <BulkRefreshProblem>[];

  void report(ImportStage stage, String? currentItem) {
    onProgress(ImportProgress(
      stage: stage,
      current: done,
      total: eligible.length,
      currentItem: currentItem,
      updated: updated,
      notFound: notFound,
      failed: failed,
      skipped: skipped,
    ));
  }

  // Skipped rows are counted before the first request so the user sees
  // them even if the very first lookup is slow.
  if (eligible.isNotEmpty) report(_stageFor(eligible.first.mediaType), null);

  for (final CollectionItem item in eligible) {
    if (cancellation?.requested ?? false) break;
    report(_stageFor(item.mediaType), item.itemName);
    final RefreshOutcome outcome =
        await refreshItemFromSource(ref, item, bulk: true);
    done++;
    switch (outcome.kind) {
      case RefreshOutcomeKind.success:
        updated++;
      case RefreshOutcomeKind.notFound:
        notFound++;
        problems.add(
          BulkRefreshProblem(title: item.itemName, kind: outcome.kind),
        );
      case RefreshOutcomeKind.unsupported:
        skipped++;
      case RefreshOutcomeKind.failed:
        failed++;
        problems.add(BulkRefreshProblem(
          title: item.itemName,
          kind: outcome.kind,
          error: outcome.error,
        ));
    }
  }

  report(ImportStage.completed, null);
  return BulkRefreshResult(
    updated: updated,
    notFound: notFound,
    failed: failed,
    skipped: skipped,
    problems: problems,
    cancelled: cancellation?.requested ?? false,
  );
}
