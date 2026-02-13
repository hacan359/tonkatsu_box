// Большая карточка коллекции с обложками.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/image_cache_service.dart';
import '../../data/repositories/collection_repository.dart';
import '../../features/collections/providers/collections_provider.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/media_type.dart';
import '../navigation/navigation_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';

/// Стиль отображения карточки коллекции.
enum HeroCardStyle {
  /// Мозаика 2×2 слева + информация справа.
  mosaic,

  /// Обложки на фон карточки + текст поверх с градиентом.
  backdrop,
}

/// Большая карточка коллекции для верхней секции HomeScreen.
///
/// Два стиля отображения:
/// - [HeroCardStyle.mosaic]: мозаика 2×2 слева, текст справа (desktop)
/// - [HeroCardStyle.backdrop]: обложки на фоне, текст поверх с градиентом (mobile)
///
/// Если [style] не задан, выбирается автоматически по ширине экрана:
/// `< navigationBreakpoint` → backdrop, иначе → mosaic.
class HeroCollectionCard extends ConsumerWidget {
  /// Создаёт [HeroCollectionCard].
  const HeroCollectionCard({
    required this.collection,
    this.style,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// Коллекция для отображения.
  final Collection collection;

  /// Стиль карточки. Если `null` — определяется по ширине экрана.
  final HeroCardStyle? style;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  /// Callback при долгом нажатии.
  final VoidCallback? onLongPress;

  /// Количество обложек в мозаике.
  static const int _mosaicCount = 3;

  /// Размер мозаики.
  static const double _mosaicSize = 64;

  /// Максимум обложек на фоне backdrop.
  static const int _backdropMaxCovers = 4;

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

  /// Возвращает [ImageType] для кэширования по типу медиа.
  static ImageType _imageTypeFor(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.game:
        return ImageType.gameCover;
      case MediaType.movie:
        return ImageType.moviePoster;
      case MediaType.tvShow:
        return ImageType.tvShowPoster;
      case MediaType.animation:
        return ImageType.moviePoster;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = accentForType(collection.type);
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(collection.id));
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(collection.id));

    // Авто-определение стиля по ширине экрана.
    final HeroCardStyle effectiveStyle = style ??
        (MediaQuery.sizeOf(context).width < navigationBreakpoint
            ? HeroCardStyle.backdrop
            : HeroCardStyle.mosaic);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: switch (effectiveStyle) {
            HeroCardStyle.mosaic =>
              _buildMosaicLayout(accent, statsAsync, itemsAsync),
            HeroCardStyle.backdrop =>
              _buildBackdropLayout(accent, statsAsync, itemsAsync),
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Backdrop layout: обложки на фон, текст поверх
  // ---------------------------------------------------------------------------

  Widget _buildBackdropLayout(
    Color accent,
    AsyncValue<CollectionStats> statsAsync,
    AsyncValue<List<CollectionItem>> itemsAsync,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: SizedBox(
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Фон: обложки или градиент
            itemsAsync.when(
              data: (List<CollectionItem> items) =>
                  _buildBackdropCovers(items, accent),
              loading: () => Container(color: AppColors.surface),
              error: (Object error, StackTrace stack) =>
                  _buildBackdropFallback(accent),
            ),

            // Тёмный градиент снизу для читаемости текста
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.black.withAlpha(80),
                      Colors.black.withAlpha(200),
                    ],
                  ),
                ),
              ),
            ),

            // Акцентная линия сверху
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: ColoredBox(color: accent),
            ),

            // Контент
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Иконка типа + название
                  Row(
                    children: <Widget>[
                      Icon(
                        iconForType(collection.type),
                        color: accent,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          collection.name,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                          ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBackdropCovers(List<CollectionItem> items, Color accent) {
    final List<CollectionItem> withCovers = items
        .where((CollectionItem item) => item.thumbnailUrl != null)
        .take(_backdropMaxCovers)
        .toList();

    if (withCovers.isEmpty) {
      return _buildBackdropFallback(accent);
    }

    return Row(
      children: <Widget>[
        for (final CollectionItem item in withCovers)
          Expanded(
            child: CachedImage(
              imageType: _imageTypeFor(item.mediaType),
              imageId: item.externalId.toString(),
              remoteUrl: item.thumbnailUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 200,
              memCacheHeight: 240,
              placeholder: Container(color: AppColors.surfaceLight),
              errorWidget: Container(color: AppColors.surfaceLight),
            ),
          ),
      ],
    );
  }

  Widget _buildBackdropFallback(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withAlpha(40),
            AppColors.surface,
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mosaic layout: мозаика 2×2 слева + информация справа
  // ---------------------------------------------------------------------------

  Widget _buildMosaicLayout(
    Color accent,
    AsyncValue<CollectionStats> statsAsync,
    AsyncValue<List<CollectionItem>> itemsAsync,
  ) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Row(
        children: <Widget>[
          _buildMosaic(itemsAsync, accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  collection.name,
                  style: AppTypography.h2.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
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
        ],
      ),
    );
  }

  Widget _buildMosaic(
    AsyncValue<List<CollectionItem>> itemsAsync,
    Color accent,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        width: _mosaicSize,
        height: _mosaicSize,
        child: itemsAsync.when(
          data: (List<CollectionItem> items) =>
              _buildMosaicGrid(items, accent),
          loading: () => Container(color: AppColors.surfaceLight),
          error: (Object error, StackTrace stack) =>
              _buildFallbackIcon(accent),
        ),
      ),
    );
  }

  Widget _buildMosaicGrid(List<CollectionItem> items, Color accent) {
    final List<CollectionItem> withCovers = items
        .where((CollectionItem item) => item.thumbnailUrl != null)
        .toList();

    if (withCovers.isEmpty) {
      return _buildFallbackIcon(accent);
    }

    final int totalItems = items.length;
    final int remaining = totalItems - _mosaicCount;
    const double cellSize = _mosaicSize / 2;
    const double gap = 2;

    return Container(
      color: AppColors.surfaceLight,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: <Widget>[
          for (int i = 0; i < _mosaicCount && i < withCovers.length; i++)
            SizedBox(
              width: cellSize - gap / 2,
              height: cellSize - gap / 2,
              child: CachedImage(
                imageType: _imageTypeFor(withCovers[i].mediaType),
                imageId: withCovers[i].externalId.toString(),
                remoteUrl: withCovers[i].thumbnailUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 80,
                memCacheHeight: 80,
                placeholder: Container(color: AppColors.surfaceLight),
                errorWidget: Container(color: AppColors.surfaceLight),
              ),
            ),
          if (withCovers.length >= _mosaicCount && remaining > 0)
            Container(
              width: cellSize - gap / 2,
              height: cellSize - gap / 2,
              color: AppColors.surface,
              alignment: Alignment.center,
              child: Text(
                '+$remaining',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (withCovers.length > _mosaicCount)
            SizedBox(
              width: cellSize - gap / 2,
              height: cellSize - gap / 2,
              child: CachedImage(
                imageType: _imageTypeFor(withCovers[_mosaicCount].mediaType),
                imageId: withCovers[_mosaicCount].externalId.toString(),
                remoteUrl: withCovers[_mosaicCount].thumbnailUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 80,
                memCacheHeight: 80,
                placeholder: Container(color: AppColors.surfaceLight),
                errorWidget: Container(color: AppColors.surfaceLight),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(Color accent) {
    return Container(
      color: accent.withAlpha(25),
      child: Center(
        child: Icon(
          iconForType(collection.type),
          color: accent,
          size: 32,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Общие виджеты
  // ---------------------------------------------------------------------------

  Widget _buildStats(CollectionStats stats, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _buildStatsText(stats),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (collection.type != CollectionType.imported && stats.total > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: stats.completionPercent / 100,
                minHeight: 4,
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
