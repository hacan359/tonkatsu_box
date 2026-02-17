// Единая вертикальная постерная карточка с вариантами размера.

import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../constants/media_type_theme.dart';
import '../models/item_status.dart';
import '../models/media_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'dual_rating_badge.dart';

/// Вариант отображения карточки.
enum CardVariant {
  /// Полноразмерная сетка (коллекция + поиск).
  grid,

  /// Компактная сетка (ландшафт Android).
  compact,

  /// Карточка на Board (цветная рамка типа, без hover).
  canvas,
}

/// Единая вертикальная постерная карточка медиа-элемента.
///
/// Заменяет [PosterCard], [CanvasGameCard] и [CanvasMediaCard].
/// Поведение определяется параметром [variant]:
/// - [CardVariant.grid] — hover-анимация, рейтинг, статус, title+subtitle
/// - [CardVariant.compact] — уменьшенная grid (ландшафт)
/// - [CardVariant.canvas] — Card с цветной рамкой, без анимации
class MediaPosterCard extends StatefulWidget {
  /// Создаёт [MediaPosterCard].
  const MediaPosterCard({
    required this.variant,
    required this.title,
    required this.imageUrl,
    required this.cacheImageType,
    required this.cacheImageId,
    this.userRating,
    this.apiRating,
    this.isInCollection = false,
    this.status,
    this.year,
    this.subtitle,
    this.mediaType,
    this.placeholderIcon,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// Вариант отображения.
  final CardVariant variant;

  /// Название элемента.
  final String title;

  /// URL изображения постера.
  final String imageUrl;

  /// Тип изображения для кэширования.
  final ImageType cacheImageType;

  /// ID изображения для кэширования.
  final String cacheImageId;

  /// Пользовательский рейтинг (1–10). Grid/compact only.
  final int? userRating;

  /// API рейтинг (0.0–10.0). Grid/compact only.
  final double? apiRating;

  /// Находится ли элемент в коллекции. Grid/compact only.
  final bool isInCollection;

  /// Статус элемента. Grid/compact only.
  final ItemStatus? status;

  /// Год выпуска. Grid/compact only.
  final int? year;

  /// Подзаголовок (жанр, платформа). Grid/compact only.
  final String? subtitle;

  /// Тип медиа — для цвета рамки и иконки placeholder (canvas).
  final MediaType? mediaType;

  /// Кастомная иконка placeholder. Fallback: [Icons.image_outlined].
  final IconData? placeholderIcon;

  /// Обработчик нажатия.
  final VoidCallback? onTap;

  /// Обработчик долгого нажатия.
  final VoidCallback? onLongPress;

  @override
  State<MediaPosterCard> createState() => _MediaPosterCardState();
}

class _MediaPosterCardState extends State<MediaPosterCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _hoverController;
  Animation<double>? _scaleAnimation;
  FocusNode? _focusNode;

  static const double _hoverScale = 1.04;

  bool get _isGridVariant =>
      widget.variant == CardVariant.grid ||
      widget.variant == CardVariant.compact;

  bool get _isCompact => widget.variant == CardVariant.compact;

  @override
  void initState() {
    super.initState();
    if (_isGridVariant) {
      _focusNode = FocusNode();
      _hoverController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      );
      _scaleAnimation = Tween<double>(begin: 1.0, end: _hoverScale).animate(
        CurvedAnimation(parent: _hoverController!, curve: Curves.easeOut),
      );
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _hoverController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.variant) {
      CardVariant.grid || CardVariant.compact => _buildGridVariant(),
      CardVariant.canvas => _buildCanvasVariant(context),
    };
  }

  // ---------------------------------------------------------------------------
  // Grid / Compact variant
  // ---------------------------------------------------------------------------

  Widget _buildGridVariant() {
    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (bool hasFocus) {
          if (hasFocus) {
            _hoverController?.forward();
          } else {
            _hoverController?.reverse();
          }
        },
        child: MouseRegion(
          onEnter: (_) => _hoverController?.forward(),
          onExit: (_) => _hoverController?.reverse(),
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedBuilder(
            animation: _hoverController!,
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(
                scale: _scaleAnimation!.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildGridPoster(),
                  SizedBox(height: _isCompact ? 2 : AppSpacing.xs),
                  _buildGridTitle(),
                  if (widget.year != null || widget.subtitle != null)
                    Padding(
                      padding: EdgeInsets.only(top: _isCompact ? 1 : 2),
                      child: _buildGridSubtitle(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridPoster() {
    final double borderRadius =
        _isCompact ? AppSpacing.radiusSm : AppSpacing.radiusMd;

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Постер
            _buildCachedImage(
              placeholder: _buildGridPlaceholder(),
            ),

            // Затемнение
            const Positioned.fill(
              child: ColoredBox(color: Color(0x30000000)),
            ),

            // Hover-рамка
            AnimatedBuilder(
              animation: _hoverController!,
              builder: (BuildContext context, Widget? child) {
                if (_hoverController!.value == 0) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.textPrimary.withAlpha(
                          (40 * _hoverController!.value).round(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                );
              },
            ),

            // Рейтинг badge (top-left)
            if (_hasAnyRating)
              Positioned(
                top: _isCompact ? 2 : AppSpacing.xs,
                left: _isCompact ? 2 : AppSpacing.xs,
                child: DualRatingBadge(
                  userRating: widget.userRating,
                  apiRating: widget.apiRating,
                  compact: _isCompact,
                ),
              ),

            // Отметка "в коллекции" (top-right)
            if (widget.isInCollection)
              Positioned(
                top: _isCompact ? 2 : AppSpacing.xs,
                right: _isCompact ? 2 : AppSpacing.xs,
                child: Container(
                  padding: EdgeInsets.all(_isCompact ? 2 : 4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: _isCompact ? 8 : 12,
                  ),
                ),
              ),

            // Статус-бейдж (bottom-left)
            if (widget.status != null &&
                widget.status != ItemStatus.notStarted)
              Positioned(
                bottom: _isCompact ? 2 : AppSpacing.xs,
                left: _isCompact ? 2 : AppSpacing.xs,
                child: Container(
                  padding: EdgeInsets.all(_isCompact ? 2 : 4),
                  decoration: BoxDecoration(
                    color: widget.status!.color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.status!.icon,
                    style: TextStyle(fontSize: _isCompact ? 7 : 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Icon(
          widget.placeholderIcon ?? Icons.image_outlined,
          color: AppColors.textTertiary,
          size: _isCompact ? 16 : 32,
        ),
      ),
    );
  }

  Widget _buildGridTitle() {
    return Text(
      widget.title,
      style: _isCompact
          ? AppTypography.posterTitle.copyWith(fontSize: 9)
          : AppTypography.posterTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGridSubtitle() {
    final List<String> parts = <String>[];
    if (widget.year != null) parts.add(widget.year.toString());
    if (widget.subtitle != null) parts.add(widget.subtitle!);

    return Text(
      parts.join(' \u00b7 '),
      style: _isCompact
          ? AppTypography.posterSubtitle.copyWith(fontSize: 7)
          : AppTypography.posterSubtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  bool get _hasAnyRating =>
      widget.userRating != null ||
      (widget.apiRating != null && widget.apiRating! > 0);

  // ---------------------------------------------------------------------------
  // Canvas variant
  // ---------------------------------------------------------------------------

  Widget _buildCanvasVariant(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color borderColor = widget.mediaType != null
        ? MediaTypeTheme.colorFor(widget.mediaType!)
        : AppColors.surfaceBorder;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Постер
            Expanded(
              child: _buildCachedImage(
                placeholder: _buildCanvasPlaceholder(colorScheme),
              ),
            ),

            // Название
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: colorScheme.surfaceContainerLow,
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        widget.placeholderIcon ?? Icons.image_outlined,
        size: 32,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Common
  // ---------------------------------------------------------------------------

  Widget _buildCachedImage({required Widget placeholder}) {
    if (widget.imageUrl.isEmpty) return placeholder;

    return CachedImage(
      imageType: widget.cacheImageType,
      imageId: widget.cacheImageId,
      remoteUrl: widget.imageUrl,
      fit: BoxFit.cover,
      placeholder: placeholder,
      errorWidget: placeholder,
    );
  }
}
