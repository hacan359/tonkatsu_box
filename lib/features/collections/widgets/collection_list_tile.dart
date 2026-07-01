import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/collections_provider.dart';
import '../providers/rich_collections_provider.dart';

class CollectionListTile extends ConsumerWidget {
  const CollectionListTile({
    required this.collection,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    super.key,
  });

  final Collection collection;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  /// Called with the tap position in global coordinates (for showMenu).
  final void Function(Offset globalPosition)? onSecondaryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(collection.id));
    final bool richEnabled = ref.watch(richCollectionsEnabledProvider);
    final bool showDescription = richEnabled &&
        collection.description != null &&
        collection.description!.isNotEmpty;

    final Widget subtitle = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        statsAsync.when(
          data: (CollectionStats s) => Text(
            S.of(context).collectionTileStats(
                  s.total,
                  s.completionPercentFormatted,
                ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          loading: () => const SizedBox(height: 14),
          error: (Object error, StackTrace stack) => Text(
            S.of(context).collectionTileError,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ),
        if (showDescription)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              collection.description!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap != null
          ? (TapUpDetails details) =>
              onSecondaryTap!(details.globalPosition)
          : null,
      child: ListTile(
        leading:
            const Icon(Icons.folder_rounded, color: AppColors.textSecondary),
        title: Text(
          collection.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.h3,
        ),
        subtitle: subtitle,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class UncategorizedListTile extends StatelessWidget {
  const UncategorizedListTile({
    required this.count,
    this.onTap,
    super.key,
  });

  final int count;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return ListTile(
      isThreeLine: true,
      leading: const Icon(Icons.inbox_rounded, color: AppColors.brand),
      title: Text(
        l.collectionsUncategorized,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.h3,
      ),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.collectionsUncategorizedItems(count),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l.uncategorizedDeprecationBadge,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
