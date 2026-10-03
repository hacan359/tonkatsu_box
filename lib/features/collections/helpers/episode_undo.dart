import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/collections_provider.dart';
import '../providers/episode_tracker_provider.dart';

// Long enough to notice a slip; the default 750ms snack is gone before that.
const Duration _undoWindow = Duration(seconds: 5);

/// The undo lives only as long as the snack: leaving the screen drops it.
void showUndoSnack(
  BuildContext context,
  String message,
  Future<void> Function() onUndo,
) {
  context.showSnack(
    message,
    duration: _undoWindow,
    countdown: true,
    action: SnackBarAction(
      label: S.of(context).undo,
      textColor: AppColors.brand,
      onPressed: () => unawaited(onUndo()),
    ),
  );
}

/// Offers to put back marks an unmark just removed; a no-op after a mark.
void offerWatchedUndo(
  BuildContext context,
  EpisodeTrackerNotifier tracker,
  WatchedMarks removed,
  String message,
) {
  if (removed.isEmpty || !context.mounted) return;
  showUndoSnack(context, message, () => tracker.restoreWatched(removed));
}

/// Offers to undo a status change that left `completed` and wiped the marks.
void offerStatusEpisodesUndo(
  BuildContext context,
  CollectionItemsNotifier notifier,
  ClearedEpisodeMarks? cleared,
) {
  if (cleared == null || !context.mounted) return;
  showUndoSnack(
    context,
    S.of(context).episodesClearedSnack,
    () => notifier.restoreCompleted(cleared),
  );
}
