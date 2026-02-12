// Большая карточка коллекции с градиентным фоном.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/collection_repository.dart';
import '../../features/collections/providers/collections_provider.dart';
import '../../shared/models/collection.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Большая карточка коллекции для верхней секции HomeScreen.
///
/// Отображает коллекцию с градиентным фоном по типу,
/// иконкой, названием, статистикой и прогресс-баром.
class HeroCollectionCard extends ConsumerWidget {
  /// Создаёт [HeroCollectionCard].
  const HeroCollectionCard({
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

  /// Возвращает цвет акцента по типу коллекции.
  static Color accentForType(CollectionType type) {
    switch (type) {
      case CollectionType.own:
        return AppColors.gameAccent;
      case CollectionType.imported:
        return AppColors.movieAccent;
      case CollectionType.fork:
        return AppColors.tvShowAccent;
    }
  }

  /// Возвращает иконку по типу коллекции.
  static IconData iconForType(CollectionType type) {
    switch (type) {
      case CollectionType.own:
        return Icons.folder;
      case CollectionType.imported:
        return Icons.download;
      case CollectionType.fork:
        return Icons.fork_right;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = accentForType(collection.type);
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(collection.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  accent.withAlpha(40),
                  AppColors.surface,
                ],
              ),
              border: Border.all(color: accent.withAlpha(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Иконка + название
                Row(
                  children: <Widget>[
                    Icon(
                      iconForType(collection.type),
                      color: accent,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        collection.name,
                        style: AppTypography.h2.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Статистика
                statsAsync.when(
                  data: (CollectionStats stats) =>
                      _buildStats(stats, accent),
                  loading: () => _buildLoadingStats(),
                  error: (Object error, StackTrace stack) =>
                      _buildErrorStats(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(CollectionStats stats, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Текст статистики
        Text(
          _buildStatsText(stats),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        // Прогресс-бар
        if (collection.type != CollectionType.imported && stats.total > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: stats.completionPercent / 100,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
      ],
    );
  }

  String _buildStatsText(CollectionStats stats) {
    final String items =
        '${stats.total} item${stats.total != 1 ? 's' : ''}';
    if (collection.type == CollectionType.imported) {
      return items;
    }
    return '$items · ${stats.completionPercentFormatted} completed';
  }

  Widget _buildLoadingStats() {
    return SizedBox(
      height: 14,
      width: 120,
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
}
