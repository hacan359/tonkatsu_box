import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/collections_provider.dart';

/// Плитка коллекции для отображения в списке.
class CollectionTile extends ConsumerWidget {
  /// Создаёт [CollectionTile].
  const CollectionTile({
    required this.collection,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// Коллекция для отображения.
  final Collection collection;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  /// Callback при долгом нажатии.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(collection.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: <Widget>[
                // Иконка типа
                _buildIcon(),
                const SizedBox(width: AppSpacing.md),

                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        collection.name,
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      statsAsync.when(
                        data: (CollectionStats stats) =>
                            _buildStatsRow(stats),
                        loading: () => _buildLoadingStats(),
                        error: (Object error, StackTrace stack) =>
                            _buildErrorStats(),
                      ),
                      if (collection.type != CollectionType.imported)
                        statsAsync.when(
                          data: (CollectionStats stats) =>
                              _buildProgressBar(stats),
                          loading: () => const SizedBox.shrink(),
                          error: (Object error, StackTrace stack) =>
                              const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),

                // Стрелка
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final IconData icon;
    final Color color;

    switch (collection.type) {
      case CollectionType.own:
        icon = Icons.folder;
        color = AppColors.gameAccent;
      case CollectionType.imported:
        icon = Icons.download;
        color = AppColors.movieAccent;
      case CollectionType.fork:
        icon = Icons.fork_right;
        color = AppColors.tvShowAccent;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildStatsRow(CollectionStats stats) {
    return Text(
      '${stats.total} item${stats.total != 1 ? 's' : ''}'
      '${collection.type != CollectionType.imported ? ' · ${stats.completionPercentFormatted} completed' : ''}',
      style: AppTypography.bodySmall,
    );
  }

  Widget _buildLoadingStats() {
    return SizedBox(
      height: 14,
      width: 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: const LinearProgressIndicator(
          backgroundColor: AppColors.surfaceLight,
        ),
      ),
    );
  }

  Widget _buildErrorStats() {
    return Text(
      'Error loading stats',
      style: AppTypography.caption.copyWith(color: AppColors.error),
    );
  }

  Widget _buildProgressBar(CollectionStats stats) {
    if (stats.total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: stats.completionPercent / 100,
          minHeight: 4,
          backgroundColor: AppColors.surfaceLight,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gameAccent),
        ),
      ),
    );
  }
}

/// Заголовок секции для группировки коллекций.
class CollectionSectionHeader extends StatelessWidget {
  /// Создаёт [CollectionSectionHeader].
  const CollectionSectionHeader({
    required this.title,
    this.count,
    super.key,
  });

  /// Заголовок секции.
  final String title;

  /// Количество элементов (опционально).
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Text(title, style: AppTypography.h3),
          if (count != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                count.toString(),
                style: AppTypography.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
