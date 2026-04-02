// Карточка коллекции в стиле "iOS папка" для грида на HomeScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/cover_info.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../providers/collection_covers_provider.dart';
import '../providers/collections_provider.dart';

/// Карточка коллекции в стиле "iOS папка".
///
/// Сверху — квадратная область с мозаикой 3+3 (скруглённые углы 16).
/// Снизу — название и количество элементов по центру.
/// Фон прозрачный, без бордеров.
class CollectionCard extends ConsumerStatefulWidget {
  /// Создаёт [CollectionCard].
  const CollectionCard({
    required this.collection,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onFocusChanged,
    super.key,
  });

  /// Коллекция для отображения.
  final Collection collection;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  /// Callback при долгом нажатии.
  final VoidCallback? onLongPress;

  /// Callback при правом клике (координаты для showMenu).
  final void Function(Offset globalPosition)? onSecondaryTap;

  /// Callback при изменении фокуса (для трекинга клавиатурного выделения).
  final ValueChanged<bool>? onFocusChanged;

  /// Радиус скругления квадрата мозаики.
  static const double mosaicRadius = 16;

  /// Радиус скругления каждой ячейки мозаики.
  static const double _cellRadius = 8;

  /// Padding внутри квадрата мозаики.
  static const double _mosaicPadding = 14;

  /// Gap между ячейками мозаики.
  static const double _cellGap = 10;

  /// Непрозрачность затемнения в обычном состоянии.
  static const double _dimOpacity = 0.25;

  @override
  ConsumerState<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends ConsumerState<CollectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _dimAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    // От затемнённого (dimOpacity) к прозрачному (0)
    _dimAnimation = Tween<double>(
      begin: CollectionCard._dimOpacity,
      end: 0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(widget.collection.id));
    final AsyncValue<List<CoverInfo>> coversAsync =
        ref.watch(collectionCoversProvider(widget.collection.id));

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (BuildContext context, Widget? animatedChild) {
        return Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(CollectionCard.mosaicRadius + 2),
            border: _focusNode.hasFocus
                ? Border.all(color: AppColors.brand, width: 2)
                : null,
          ),
          child: animatedChild,
        );
      },
      child: InkWell(
        focusNode: _focusNode,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTapUp: widget.onSecondaryTap != null
            ? (TapUpDetails details) =>
                widget.onSecondaryTap!(details.globalPosition)
            : null,
        onFocusChange: (bool hasFocus) {
          if (hasFocus) {
            _hoverController.forward();
            widget.onFocusChanged?.call(true);
          } else {
            _hoverController.reverse();
            widget.onFocusChanged?.call(false);
          }
        },
        onHover: (bool hovering) {
          if (hovering) {
            _hoverController.forward();
          } else if (!_focusNode.hasFocus) {
            _hoverController.reverse();
          }
        },
        borderRadius: BorderRadius.circular(CollectionCard.mosaicRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Мозаика обложек + затемнение
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(CollectionCard.mosaicRadius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Padding(
                        padding:
                            const EdgeInsets.all(CollectionCard._mosaicPadding),
                        child: _CoverMosaic(
                          covers: coversAsync,
                          totalCount: statsAsync.valueOrNull?.total ?? 0,
                        ),
                      ),
                      // Затемнение поверх мозаики
                      AnimatedBuilder(
                        animation: _dimAnimation,
                        builder: (BuildContext context, Widget? child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(
                                (_dimAnimation.value * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(
                                CollectionCard.mosaicRadius,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Название
              Text(
                widget.collection.name,
                style: AppTypography.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              // Статистика
              statsAsync.when(
                data: (CollectionStats s) => Text(
                  S.of(context).collectionTileStats(
                        s.total,
                        s.completionPercentFormatted,
                      ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const SizedBox(height: 14),
                error: (Object error, StackTrace stack) => Text(
                  S.of(context).collectionTileError,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Мозаика обложек 3+3
// =============================================================================

class _CoverMosaic extends StatelessWidget {
  const _CoverMosaic({required this.covers, required this.totalCount});

  final AsyncValue<List<CoverInfo>> covers;
  final int totalCount;

  static final BorderRadius _cellBorderRadius =
      BorderRadius.circular(CollectionCard._cellRadius);
  static final BoxDecoration _emptyCellDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        AppColors.surface,
        AppColors.surfaceLight,
      ],
    ),
    borderRadius: _cellBorderRadius,
  );

  @override
  Widget build(BuildContext context) {
    return covers.when(
      data: (List<CoverInfo> data) => _buildGrid(data),
      loading: () => const SizedBox.expand(),
      error: (Object error, StackTrace stack) => _buildEmpty(),
    );
  }

  /// Сетка 3+3: верхний ряд 3 постера, нижний 3 (последний — счётчик).
  Widget _buildGrid(List<CoverInfo> data) {
    if (data.isEmpty) return _buildEmpty();

    final int remaining = totalCount - 6;

    return Column(
      children: <Widget>[
        // Верхний ряд — 3 постера
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: _poster(data, 0)),
              const SizedBox(width: CollectionCard._cellGap),
              Expanded(child: _poster(data, 1)),
              const SizedBox(width: CollectionCard._cellGap),
              Expanded(child: _poster(data, 2)),
            ],
          ),
        ),
        const SizedBox(height: CollectionCard._cellGap),
        // Нижний ряд — 3 постера (последний может быть счётчиком)
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: _poster(data, 3)),
              const SizedBox(width: CollectionCard._cellGap),
              Expanded(child: _poster(data, 4)),
              const SizedBox(width: CollectionCard._cellGap),
              Expanded(
                child: remaining > 0
                    ? _counterCell(remaining)
                    : _poster(data, 5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _poster(List<CoverInfo> data, int index) {
    if (index >= data.length) {
      return _emptyCell();
    }
    return _CoverImage(cover: data[index]);
  }

  Widget _counterCell(int count) {
    if (count <= 0) return _emptyCell();
    return Container(
      decoration: _emptyCellDecoration,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: AppTypography.h3.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _emptyCell() {
    return Container(decoration: _emptyCellDecoration);
  }

  Widget _buildEmpty() {
    return Center(
      child: Icon(
        Icons.folder_rounded,
        color: AppColors.textTertiary.withAlpha(120),
        size: 36,
      ),
    );
  }
}

// =============================================================================
// Обложка-изображение с сохранением пропорций
// =============================================================================

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.cover});

  final CoverInfo cover;

  static final BorderRadius _borderRadius =
      BorderRadius.circular(CollectionCard._cellRadius);
  static const Widget _emptyPlaceholder = SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    if (cover.thumbnailUrl == null) {
      return const SizedBox.expand();
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: _borderRadius,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedImage(
        imageType: _imageTypeFor(cover.mediaType, cover.platformId),
        imageId: cover.externalId.toString(),
        remoteUrl: cover.thumbnailUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 200,
        placeholder: _emptyPlaceholder,
        errorWidget: _emptyPlaceholder,
      ),
    );
  }

  static ImageType _imageTypeFor(MediaType mediaType, int? platformId) {
    switch (mediaType) {
      case MediaType.game:
        return ImageType.gameCover;
      case MediaType.movie:
        return ImageType.moviePoster;
      case MediaType.tvShow:
        return ImageType.tvShowPoster;
      case MediaType.animation:
        if (platformId == AnimationSource.tvShow) {
          return ImageType.tvShowPoster;
        }
        return ImageType.moviePoster;
      case MediaType.visualNovel:
        return ImageType.vnCover;
      case MediaType.manga:
        return ImageType.mangaCover;
      case MediaType.custom:
        return ImageType.customCover;
    }
  }
}

// =============================================================================
// Карточка Uncategorized
// =============================================================================

/// Карточка для uncategorized элементов в стиле "iOS папка".
///
/// Вместо мозаики — иконка inbox на фоне surfaceLight.
class UncategorizedCard extends StatelessWidget {
  /// Создаёт [UncategorizedCard].
  const UncategorizedCard({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CollectionCard.mosaicRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Фон с иконкой
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius:
                    BorderRadius.circular(CollectionCard.mosaicRadius),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Center(
                child: Icon(
                  Icons.inbox_rounded,
                  color: AppColors.brand,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Название
          Text(
            l.collectionsUncategorized,
            style: AppTypography.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // Количество
          Text(
            l.collectionsUncategorizedItems(count),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
