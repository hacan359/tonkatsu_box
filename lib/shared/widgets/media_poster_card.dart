// Единая вертикальная постерная карточка с вариантами размера.

import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../../l10n/app_localizations.dart';
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
    this.platformLabel,
    this.platformColor,
    this.platformOverlayAsset,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onOpenInCollection,
    this.onFocusChanged,
    this.tagName,
    this.tagColor,
    this.tagGlow = false,
    this.onTagTap,
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

  /// Краткое название платформы (SNES, GBA). Grid/compact only.
  final String? platformLabel;

  /// Цвет семейства платформы (Sony=синий, Nintendo=красный и т.д.).
  final Color? platformColor;

  /// Путь к ассету оверлея платформы (PNG 600×900).
  ///
  /// Если задан, рисуется поверх постера вместо текстового бейджа.
  final String? platformOverlayAsset;

  /// Тип медиа — для цвета рамки и иконки placeholder (canvas).
  final MediaType? mediaType;

  /// Кастомная иконка placeholder. Fallback: [Icons.image_outlined].
  final IconData? placeholderIcon;

  /// Обработчик нажатия.
  final VoidCallback? onTap;

  /// Обработчик долгого нажатия.
  final VoidCallback? onLongPress;

  /// Обработчик правого клика (координаты для showMenu).
  final void Function(Offset globalPosition)? onSecondaryTap;

  /// Обработчик "Открыть в коллекции" (только если isInCollection).
  final VoidCallback? onOpenInCollection;

  /// Callback при изменении фокуса (для трекинга клавиатурного выделения).
  final ValueChanged<bool>? onFocusChanged;

  /// Название тега (секции) элемента. Grid/compact only.
  final String? tagName;

  /// Цвет тега (ARGB int). Grid/compact only.
  final int? tagColor;

  /// Включить свечение постера цветом тега.
  final bool tagGlow;

  /// Callback при тапе на тег-бейдж (для выбора/смены тега).
  final void Function(Offset globalPosition)? onTagTap;

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
          widget.onFocusChanged?.call(hasFocus);
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
              onSecondaryTapUp: widget.onSecondaryTap != null
                  ? (TapUpDetails details) =>
                      widget.onSecondaryTap!(details.globalPosition)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildGridPoster(),
                  // Текстовый блок — фиксированная высота для ровной сетки.
                  Tooltip(
                    message: widget.title,
                    waitDuration: const Duration(milliseconds: 500),
                    child: SizedBox(
                      height: _isCompact ? 38 : 52,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: _isCompact ? 2 : AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                widget.title,
                                style: _isCompact
                                    ? AppTypography.posterTitle
                                        .copyWith(fontSize: 9)
                                    : AppTypography.posterTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildSubtitleRow(context),
                          ],
                        ),
                      ),
                    ),
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
    final bool hasOverlay =
        widget.platformOverlayAsset != null && !widget.isInCollection;
    final double borderRadius =
        hasOverlay ? 0 : (_isCompact ? AppSpacing.radiusSm : AppSpacing.radiusMd);

    final Color? glowColor = widget.tagGlow && widget.tagColor != null
        ? Color(widget.tagColor!)
        : null;

    return Expanded(
      child: _TagGlowWrapper(
        color: glowColor,
        borderRadius: borderRadius,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
          children: <Widget>[
            // Постер
            _buildCachedImage(
              placeholder: _buildGridPlaceholder(),
            ),

            // Оверлей платформы (сразу поверх постера, под бейджами)
            if (widget.platformOverlayAsset != null &&
                !widget.isInCollection)
              Positioned.fill(
                child: Image.asset(
                  widget.platformOverlayAsset!,
                  fit: BoxFit.fill,
                ),
              ),

            // Затемнение: idle ~25%, hover → прозрачный.
            AnimatedBuilder(
              animation: _hoverController!,
              builder: (BuildContext context, Widget? child) {
                final int alpha =
                    (0x40 * (1.0 - _hoverController!.value)).round();
                return Positioned.fill(
                  child: ColoredBox(
                    color: Color.fromARGB(alpha, 0, 0, 0),
                  ),
                );
              },
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

            // Рейтинг badge (top-left, скрыт при оверлее — выносится в subtitle)
            if (_hasAnyRating && !hasOverlay)
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
                child: widget.onOpenInCollection != null
                    ? _InCollectionButton(
                        compact: _isCompact,
                        onTap: widget.onOpenInCollection!,
                      )
                    : Container(
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

            // Платформа-бейдж (top-right, fallback когда нет оверлея)
            if (widget.platformOverlayAsset == null &&
                widget.platformLabel != null &&
                widget.platformColor != null &&
                !widget.isInCollection)
              Positioned(
                top: _isCompact ? 2 : AppSpacing.xs,
                right: _isCompact ? 2 : AppSpacing.xs,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isCompact ? 3 : 5,
                    vertical: _isCompact ? 1 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.platformColor!.withAlpha(210),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    widget.platformLabel!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _isCompact ? 7 : 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
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
                  child: Icon(
                    widget.status!.materialIcon,
                    size: _isCompact ? 8 : 12,
                    color: Colors.white,
                  ),
                ),
              ),

            // Тег-бейдж (bottom-right) — кликабельный для выбора тега
            if (widget.onTagTap != null || widget.tagName != null)
              Positioned(
                bottom: _isCompact ? 2 : AppSpacing.xs,
                right: _isCompact ? 2 : AppSpacing.xs,
                child: _TagBadge(
                  tagName: widget.tagName,
                  tagColor: widget.tagColor,
                  compact: _isCompact,
                  onTap: widget.onTagTap,
                ),
              ),
          ],
        ),
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

  /// Subtitle row: [rating ·] platform · year · MediaType (цветной) · genre.
  Widget _buildSubtitleRow(BuildContext context) {
    final bool hasOverlay =
        widget.platformOverlayAsset != null && !widget.isInCollection;
    final TextStyle baseStyle = _isCompact
        ? AppTypography.posterSubtitle.copyWith(fontSize: 7)
        : AppTypography.posterSubtitle;

    // Части до типа: rating (если оверлей), platform, year.
    final List<String> before = <String>[];
    String? overlayRating;
    if (hasOverlay && _hasAnyRating) {
      final bool hasUser = widget.userRating != null;
      final bool hasApi =
          widget.apiRating != null && widget.apiRating! > 0;
      if (hasUser && hasApi) {
        overlayRating =
            '★${widget.userRating} / ${widget.apiRating!.toStringAsFixed(1)}';
      } else if (hasUser) {
        overlayRating = '★${widget.userRating}';
      } else if (hasApi) {
        overlayRating = '★${widget.apiRating!.toStringAsFixed(1)}';
      }
    }
    if (widget.platformLabel != null && widget.platformColor == null) {
      before.add(widget.platformLabel!);
    }
    if (widget.year != null) before.add(widget.year.toString());
    final String beforeText = before.join(' \u00b7 ');

    // Часть после типа: genre/subtitle.
    final String? afterText = widget.subtitle;

    const Color ratingColor = Color(0xFFFFD700); // gold

    if (widget.mediaType == null) {
      final List<String> all = <String>[...before];
      if (afterText != null) all.add(afterText);
      if (overlayRating == null) {
        return Text(
          all.join(' \u00b7 '),
          style: baseStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      return Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: overlayRating,
              style: baseStyle.copyWith(color: ratingColor),
            ),
            if (all.isNotEmpty)
              TextSpan(text: ' \u00b7 ${all.join(' \u00b7 ')}', style: baseStyle),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final String typeLabel = widget.mediaType!.localizedLabel(S.of(context));
    final Color typeColor = MediaTypeTheme.colorFor(widget.mediaType!);

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (overlayRating != null)
            TextSpan(
              text: '$overlayRating \u00b7 ',
              style: baseStyle.copyWith(color: ratingColor),
            ),
          if (beforeText.isNotEmpty)
            TextSpan(text: '$beforeText \u00b7 ', style: baseStyle),
          TextSpan(
            text: typeLabel,
            style: baseStyle.copyWith(color: typeColor),
          ),
          if (afterText != null)
            TextSpan(text: ' \u00b7 $afterText', style: baseStyle),
        ],
      ),
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

  /// Ширина декодирования постера в пикселях (2x для HiDPI).
  static const int _posterDecodeWidth = 300;

  Widget _buildCachedImage({required Widget placeholder}) {
    if (widget.imageUrl.isEmpty) return placeholder;

    return CachedImage(
      imageType: widget.cacheImageType,
      imageId: widget.cacheImageId,
      remoteUrl: widget.imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: _posterDecodeWidth,
      placeholder: placeholder,
      errorWidget: placeholder,
    );
  }
}

/// Обёртка постера с цветной рамкой и бегущим бликом по периметру.
class _TagGlowWrapper extends StatefulWidget {
  const _TagGlowWrapper({
    required this.borderRadius,
    required this.child,
    this.color,
  });

  final Color? color;
  final double borderRadius;
  final Widget child;

  @override
  State<_TagGlowWrapper> createState() => _TagGlowWrapperState();
}

class _TagGlowWrapperState extends State<_TagGlowWrapper>
    with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(_TagGlowWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.color != null) != (oldWidget.color != null)) {
      _syncController();
    }
  }

  void _syncController() {
    if (widget.color != null && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat();
    } else if (widget.color == null && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.color == null) return widget.child;

    return AnimatedBuilder(
      animation: _controller!,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          foregroundPainter: _GlowBorderPainter(
            color: widget.color!,
            borderRadius: widget.borderRadius,
            progress: _controller!.value,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Рисует цветную рамку с бегущим ярким бликом.
class _GlowBorderPainter extends CustomPainter {
  _GlowBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.progress,
  });

  final Color color;
  final double borderRadius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // Базовая рамка.
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.withAlpha(100);
    canvas.drawRRect(rrect, borderPaint);

    // Бегущий блик — SweepGradient, вращающийся по progress.
    final double angle = progress * 2 * 3.14159265;
    final Paint highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = SweepGradient(
        startAngle: angle,
        endAngle: angle + 1.0,
        colors: <Color>[
          color.withAlpha(0),
          color.withAlpha(220),
          color.withAlpha(0),
        ],
        stops: const <double>[0.0, 0.5, 1.0],
        tileMode: TileMode.decal,
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect, highlightPaint);
  }

  @override
  bool shouldRepaint(_GlowBorderPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color;
}

/// Кнопка "Открыть в коллекции" поверх постера.
class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.tagName,
    required this.tagColor,
    required this.compact,
    this.onTap,
  });

  final String? tagName;
  final int? tagColor;
  final bool compact;
  final void Function(Offset globalPosition)? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = tagColor != null
        ? Color(tagColor!)
        : AppColors.textSecondary;
    final bool hasTag = tagName != null;

    final Widget badge = Container(
      constraints: BoxConstraints(
        maxWidth: compact ? 50 : 70,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 5,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: hasTag
            ? accentColor.withAlpha(200)
            : AppColors.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(4),
      ),
      child: hasTag
          ? Text(
              tagName!,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 7 : 9,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Icon(
              Icons.label_outline,
              size: compact ? 10 : 14,
              color: AppColors.textTertiary,
            ),
    );

    if (onTap == null) return badge;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) {
        onTap!(details.globalPosition);
      },
      child: badge,
    );
  }
}

class _InCollectionButton extends StatelessWidget {
  const _InCollectionButton({
    required this.compact,
    required this.onTap,
  });

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.success,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 2 : 4),
          child: Icon(
            Icons.open_in_new,
            color: Colors.white,
            size: compact ? 8 : 12,
          ),
        ),
      ),
    );
  }
}
