import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collection.dart';
import '../providers/collections_provider.dart';

/// Плитка коллекции для отображения в списке.
class CollectionTile extends ConsumerWidget {
  /// Создаёт [CollectionTile].
  const CollectionTile({
    required this.collection,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    super.key,
  });

  /// Коллекция для отображения.
  final Collection collection;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  /// Callback при долгом нажатии.
  final VoidCallback? onLongPress;

  /// Callback при удалении.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(collection.id));
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              // Иконка типа
              _buildIcon(colorScheme),
              const SizedBox(width: 16),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Название
                    Text(
                      collection.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Статистика
                    statsAsync.when(
                      data: (CollectionStats stats) =>
                          _buildStatsRow(stats, theme, colorScheme),
                      loading: () => _buildLoadingStats(colorScheme),
                      error: (Object error, StackTrace stack) =>
                          _buildErrorStats(colorScheme),
                    ),

                    // Прогресс-бар (только для своих и форков)
                    if (collection.type != CollectionType.imported)
                      statsAsync.when(
                        data: (CollectionStats stats) =>
                            _buildProgressBar(stats, colorScheme),
                        loading: () => const SizedBox.shrink(),
                        error: (Object error, StackTrace stack) =>
                            const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),

              // Иконка удаления
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),

              // Стрелка
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    final IconData icon;
    final Color color;

    switch (collection.type) {
      case CollectionType.own:
        icon = Icons.folder;
        color = colorScheme.primary;
      case CollectionType.imported:
        icon = Icons.download;
        color = colorScheme.secondary;
      case CollectionType.fork:
        icon = Icons.fork_right;
        color = colorScheme.tertiary;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildStatsRow(
    CollectionStats stats,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Text(
      '${stats.total} game${stats.total != 1 ? 's' : ''}'
      '${collection.type != CollectionType.imported ? ' • ${stats.completionPercentFormatted} completed' : ''}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLoadingStats(ColorScheme colorScheme) {
    return SizedBox(
      height: 14,
      width: 100,
      child: LinearProgressIndicator(
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildErrorStats(ColorScheme colorScheme) {
    return Text(
      'Error loading stats',
      style: TextStyle(
        color: colorScheme.error,
        fontSize: 12,
      ),
    );
  }

  Widget _buildProgressBar(CollectionStats stats, ColorScheme colorScheme) {
    if (stats.total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: stats.completionPercent / 100,
          minHeight: 4,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (count != null) ...<Widget>[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
