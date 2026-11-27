import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../providers/episode_tracker_provider.dart';

/// Whether moving [items] to [status] should also stamp (`completed`) or
/// erase (`notStarted`) their episode marks; null when the user backed out.
Future<bool?> askEpisodeSync(
  BuildContext context,
  T Function<T>(ProviderListenable<T> provider) read,
  Iterable<CollectionItem?> items,
  ItemStatus status,
) async {
  final bool completing = status == ItemStatus.completed;
  if (!completing && status != ItemStatus.notStarted) return true;

  bool undecided = false;
  for (final CollectionItem? item in items) {
    if (item == null || !item.usesEpisodeTracker) continue;
    final bool wasCompleted = item.status == ItemStatus.completed;
    // Only a completed title loses its marks on the way back to not started.
    if (completing == wasCompleted) continue;
    final EpisodeTrackerNotifier tracker = read(
      episodeTrackerNotifierProvider((
        collectionId: item.collectionId,
        showId: item.externalId,
        source: item.dataSource,
      )).notifier,
    );
    // An unknown total cannot prove the title is fully watched.
    undecided = completing
        ? await tracker.unwatchedEpisodeCount() != 0
        : await tracker.hasWatchedEpisodes();
    if (undecided) break;
  }
  if (!undecided) return true;
  if (!context.mounted) return null;

  final S l = S.of(context);
  return showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => GlassAlertDialog(
      scrollable: true,
      title: Text(completing ? l.completeEpisodesTitle : l.clearEpisodesTitle),
      content: Text(completing ? l.completeEpisodesBody : l.clearEpisodesBody),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            completing ? l.completeEpisodesKeep : l.clearEpisodesKeep,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            completing ? l.completeEpisodesMarkRest : l.clearEpisodesRemove,
          ),
        ),
      ],
    ),
  );
}
