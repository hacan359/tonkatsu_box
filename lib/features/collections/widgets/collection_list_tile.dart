// Строка коллекции для list-вида на HomeScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/collections_provider.dart';

/// Строка коллекции для list-вида (без картинок).
class CollectionListTile extends ConsumerWidget {
  /// Создаёт [CollectionListTile].
  const CollectionListTile({
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

    return ListTile(
      leading: const Icon(Icons.folder_rounded, color: AppColors.textSecondary),
      title: Text(
        collection.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.h3,
      ),
      subtitle: statsAsync.when(
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
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// Строка uncategorized элементов для list-вида.
class UncategorizedListTile extends StatelessWidget {
  /// Создаёт [UncategorizedListTile].
  const UncategorizedListTile({
    required this.count,
    this.onTap,
    super.key,
  });

  /// Количество uncategorized элементов.
  final int count;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return ListTile(
      leading: const Icon(Icons.inbox_rounded, color: AppColors.brand),
      title: Text(
        l.collectionsUncategorized,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.h3,
      ),
      subtitle: Text(
        l.collectionsUncategorizedItems(count),
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }
}
