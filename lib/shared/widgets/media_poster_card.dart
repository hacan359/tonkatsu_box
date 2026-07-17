import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../../l10n/app_localizations.dart';
import '../constants/media_type_theme.dart';
import '../models/item_status.dart';
import '../models/media_type.dart';
import '../utils/item_card_progress.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'dual_rating_badge.dart';

enum CardVariant {
  /// Full-size grid (collection + search).
  grid,

  /// Compact grid (Android landscape).
  compact,

  /// Board card (typed colored border, no hover).
  canvas,
}

/// Vertical poster card for a media item.
///
/// Behavior is driven by [variant]:
/// - [CardVariant.grid] — hover animation, rating, status, title+subtitle
/// - [CardVariant.compact] — smaller grid (landscape)
/// - [CardVariant.canvas] — card with colored border, no animation
class MediaPosterCard extends StatefulWidget {
  const MediaPosterCard({
    required this.variant,
    required this.title,
    required this.imageUrl,
    required this.cacheImageType,
    required this.cacheImageId,
    this.userRating,
    this.apiRating,
    this.splitRatings = false,
    this.isInCollection = false,
    this.status,
    this.year,
    this.subtitle,
    this.mediaType,
    this.typeLabelOverride,
    this.placeholderIcon,
    this.platformLabel,
    this.platformColor,
    this.platformOverlayAsset,
    this.timeToBeatHours,
    this.progress,
    this.isFavorite = false,
    this.showFavorite = false,
    this.onToggleFavorite,
    this.enableHoverScale = true,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onOpenInCollection,
    this.onFocusChanged,
    this.tagName,
    this.tagColor,
    this.tagTextColor,
    this.tagMoreCount = 0,
    this.tagGlow = false,
    this.onTagTap,
    super.key,
  });

  final CardVariant variant;
  final String title;
  final String imageUrl;
  final ImageType cacheImageType;
  final String cacheImageId;

  /// Personal rating (1.0–10.0). Grid/compact only.
  final double? userRating;

  /// API rating (0.0–10.0). Grid/compact only.
  final double? apiRating;

  /// When true (collection), only the API rating goes to the banner's
  /// subtitle line — the personal rating stays in the top-left badge. When
  /// false (search), both ratings render in the subtitle line. Grid/compact
  /// only.
  final bool splitRatings;

  /// Grid/compact only.
  final bool isInCollection;

  /// Grid/compact only.
  final ItemStatus? status;

  /// Grid/compact only.
  final int? year;

  /// Genre / platform. Grid/compact only.
  final String? subtitle;

  /// Short platform name (SNES, GBA). Grid/compact only.
  final String? platformLabel;

  /// Platform family color (Sony=blue, Nintendo=red, ...).
  final Color? platformColor;

  /// Platform overlay asset (PNG 600×900); when set, drawn over the poster
  /// instead of a text badge.
  final String? platformOverlayAsset;

  /// Average time-to-beat in whole hours (IGDB). When set, a small clock
  /// badge is drawn over the poster. Grid/compact only; used on search cards.
  final int? timeToBeatHours;

  /// Progress pill next to the status dot (`12/24`) plus the bottom-edge
  /// bar when the fraction is known. Grid/compact only.
  final ItemCardProgress? progress;

  /// Whether this item is marked favorite. Grid/compact only; drives the
  /// heart toggle's filled/broken state.
  final bool isFavorite;

  /// Forces the heart to render as a static (non-tappable) indicator even when
  /// [onToggleFavorite] is null — e.g. during multi-select, so the heart stays
  /// visible while taps select the card. Grid/compact only.
  final bool showFavorite;

  /// Fired when the favorite heart is tapped. When null the heart isn't
  /// tappable (and is hidden unless [showFavorite] is set). Grid/compact only.
  final VoidCallback? onToggleFavorite;

  /// When false the hover zoom is suppressed — used for selected cards, whose
  /// fixed-size selection scrim would otherwise not track the scaled card.
  final bool enableHoverScale;

  /// Drives the border color and placeholder icon (canvas).
  final MediaType? mediaType;

  /// Replaces the [mediaType] caption in the subtitle row (e.g. a manga/anime
  /// format like "Manhwa" or "OVA"). When null, the media-type label is shown.
  /// The caption keeps the [mediaType] accent color either way.
  final String? typeLabelOverride;

  /// Fallback: [Icons.image_outlined].
  final IconData? placeholderIcon;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Right-click; carries the global position for showMenu.
  final void Function(Offset globalPosition)? onSecondaryTap;

  /// Only meaningful when isInCollection.
  final VoidCallback? onOpenInCollection;

  final ValueChanged<bool>? onFocusChanged;

  /// Tag (section) name. Grid/compact only.
  final String? tagName;

  /// Tag color (ARGB int). Grid/compact only.
  final int? tagColor;

  /// Explicit tag label color (ARGB int); `null` means white.
  final int? tagTextColor;

  /// How many more tags the item carries beyond the shown one ("+N").
  final int tagMoreCount;

  /// Glow the poster with the tag color.
  final bool tagGlow;

  /// Fired on tag-badge tap (to pick/change the tag).
  final void Function(Offset globalPosition)? onTagTap;

  @override
  State<MediaPosterCard> createState() => _MediaPosterCardState();
}

class _MediaPosterCardState extends State<MediaPosterCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _hoverController;
  Animation<double>? _scaleAnimation;
  FocusNode? _focusNode;

  static const double _hoverScale = 1.02;

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
        duration: AppDurations.fast,
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
                scale:
                    widget.enableHoverScale ? _scaleAnimation!.value : 1.0,
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
              child: _buildGridPoster(),
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

    final bool showFavoriteBadge =
        widget.onToggleFavorite != null || widget.showFavorite;
    final bool showStatusDot =
        widget.status != null && widget.status != ItemStatus.notStarted;
    final bool showPlatformBadge = widget.platformOverlayAsset == null &&
        widget.platformLabel != null &&
        widget.platformColor != null;

    final Color? glowColor = widget.tagGlow && widget.tagColor != null
        ? Color(widget.tagColor!)
        : null;

    return _TagGlowWrapper(
      color: glowColor,
      borderRadius: borderRadius,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
          children: <Widget>[
            _buildCachedImage(
              placeholder: _buildGridPlaceholder(),
            ),

            // Platform overlay sits above the poster, below the badges.
            if (widget.platformOverlayAsset != null &&
                !widget.isInCollection)
              Positioned.fill(
                child: Image.asset(
                  widget.platformOverlayAsset!,
                  fit: BoxFit.fill,
                ),
              ),

            // Scrim: ~25% at idle, fades to transparent on hover.
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

            // Top-left row: personal rating badge (split mode only — in
            // non-split mode both ratings render in the banner's subtitle
            // line) and the time-to-beat clock.
            if ((widget.splitRatings && widget.userRating != null) ||
                widget.timeToBeatHours != null)
              Positioned(
                top: _isCompact ? 2 : AppSpacing.xs,
                left: _isCompact ? 2 : AppSpacing.xs,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.splitRatings && widget.userRating != null)
                      DualRatingBadge(
                        userRating: widget.userRating,
                        compact: _isCompact,
                      ),
                    // Average time-to-beat — search game cards only.
                    if (widget.timeToBeatHours != null && !showStatusDot)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isCompact ? 3 : 5,
                          vertical: _isCompact ? 1 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(170),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.schedule,
                              size: _isCompact ? 8 : 11,
                              color: Colors.white,
                            ),
                            SizedBox(width: _isCompact ? 1 : 2),
                            Text(
                              S.of(context).runtimeHours(
                                  widget.timeToBeatHours!),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _isCompact ? 7 : 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Top-right row: the favorite heart (collection only) sits before
            // the in-collection button (search) or the platform text badge
            // (games), which are mutually exclusive.
            Positioned(
              top: _isCompact ? 2 : AppSpacing.xs,
              right: _isCompact ? 2 : AppSpacing.xs,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (showFavoriteBadge)
                    _FavoriteButton(
                      isFavorite: widget.isFavorite,
                      compact: _isCompact,
                      onTap: widget.onToggleFavorite,
                    ),
                  if (showFavoriteBadge &&
                      (widget.isInCollection || showPlatformBadge))
                    SizedBox(width: _isCompact ? 2 : 4),
                  if (widget.isInCollection)
                    widget.onOpenInCollection != null
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
                          )
                  // Platform text badge — fallback when there's no overlay.
                  else if (showPlatformBadge)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isCompact ? 3 : 5,
                        vertical: _isCompact ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.platformColor!.withAlpha(210),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXs),
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
                ],
              ),
            ),

            // Bottom banner: solid translucent panel with title, subtitle
            // line and the always-visible progress + tag row.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBanner(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Solid translucent panel pinned to the poster's bottom edge: title,
  /// subtitle line, then the always-visible progress + tag row and the
  /// progress bar. The panel darkens and the title expands on hover/focus.
  Widget _buildBottomBanner(BuildContext context) {
    final double hPad = _isCompact ? 4 : 6;
    final double vPad = _isCompact ? 3 : 5;
    final bool showStatusDot =
        widget.status != null && widget.status != ItemStatus.notStarted;
    final bool hasBottomRow = showStatusDot ||
        widget.progress != null ||
        widget.onTagTap != null ||
        widget.tagName != null;

    return AnimatedBuilder(
      animation: _hoverController!,
      builder: (BuildContext context, Widget? child) {
        final double t = _hoverController!.value;
        final bool expanded = t > 0.3;
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.6 + 0.25 * t),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AnimatedSize(
                      duration: AppDurations.fast,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        widget.title,
                        style: (_isCompact
                                ? AppTypography.posterTitle
                                    .copyWith(fontSize: 9)
                                : AppTypography.posterTitle)
                            .copyWith(height: 1.2),
                        maxLines: expanded ? 6 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildSubtitleRow(context),
                    if (hasBottomRow) ...<Widget>[
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          if (showStatusDot) ...<Widget>[
                            Container(
                              padding: EdgeInsets.all(_isCompact ? 2 : 3),
                              decoration: BoxDecoration(
                                color: widget.status!.color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.status!.materialIcon,
                                size: _isCompact ? 7 : 10,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: _isCompact ? 2 : 4),
                          ],
                          if (widget.progress != null)
                            Expanded(
                              child: Text(
                                widget.progress!.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _isCompact ? 7 : 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            const Spacer(),
                          if (widget.onTagTap != null ||
                              widget.tagName != null)
                            _TagBadge(
                              tagName: widget.tagName,
                              tagColor: widget.tagColor,
                              tagTextColor: widget.tagTextColor,
                              moreCount: widget.tagMoreCount,
                              compact: _isCompact,
                              onTap: widget.onTagTap,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.progress?.fraction != null)
                SizedBox(
                  height: _isCompact ? 2 : 3,
                  child: ColoredBox(
                    color: Colors.black.withAlpha(120),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.progress!.fraction,
                      child: ColoredBox(
                        color: widget.mediaType != null
                            ? MediaTypeTheme.colorFor(widget.mediaType!)
                            : AppColors.brand,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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

  /// Subtitle row: [rating ·] platform · year · MediaType (colored) · genre.
  Widget _buildSubtitleRow(BuildContext context) {
    final TextStyle baseStyle = _isCompact
        ? AppTypography.posterSubtitle.copyWith(fontSize: 7)
        : AppTypography.posterSubtitle;

    // Parts before the type: rating, platform, year.
    final List<String> before = <String>[];
    final bool hasApi = widget.apiRating != null && widget.apiRating! > 0;
    String? leadingRating;
    if (widget.splitRatings) {
      // Only the API rating goes here; the personal one stays in the badge.
      if (hasApi) {
        leadingRating = '★${widget.apiRating!.toStringAsFixed(1)}';
      }
    } else if (_hasAnyRating) {
      final bool hasUser = widget.userRating != null;
      if (hasUser && hasApi) {
        leadingRating =
            '★${widget.userRating!.toStringAsFixed(1)} / ${widget.apiRating!.toStringAsFixed(1)}';
      } else if (hasUser) {
        leadingRating = '★${widget.userRating!.toStringAsFixed(1)}';
      } else if (hasApi) {
        leadingRating = '★${widget.apiRating!.toStringAsFixed(1)}';
      }
    }
    if (widget.platformLabel != null && widget.platformColor == null) {
      before.add(widget.platformLabel!);
    }
    if (widget.year != null) before.add(widget.year.toString());
    final String beforeText = before.join(' \u00b7 ');

    // Part after the type: genre/subtitle.
    final String? afterText = widget.subtitle;

    const Color ratingColor = Color(0xFFFFD700); // gold

    if (widget.mediaType == null) {
      final List<String> all = <String>[...before];
      if (afterText != null) all.add(afterText);
      if (leadingRating == null) {
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
              text: leadingRating,
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

    final String typeLabel =
        widget.typeLabelOverride ?? widget.mediaType!.localizedLabel(S.of(context));
    final Color typeColor = MediaTypeTheme.colorFor(widget.mediaType!);

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (leadingRating != null)
            TextSpan(
              text: '$leadingRating \u00b7 ',
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _buildCachedImage(
                placeholder: _buildCanvasPlaceholder(colorScheme),
              ),
            ),

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

  /// Poster decode width in px (2x for HiDPI).
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

/// Wraps the poster with a colored border and a highlight running its edge.
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
      // The border repaints every frame; the boundary keeps that repaint from
      // re-rasterizing the whole card (poster image, badges) each tick.
      child: RepaintBoundary(child: widget.child),
    );
  }
}

/// Paints a colored border with a running bright highlight.
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

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.withAlpha(100);
    canvas.drawRRect(rrect, borderPaint);

    // Running highlight: a SweepGradient rotated by progress.
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

/// Tappable tag badge shown over the poster.
class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.tagName,
    required this.tagColor,
    required this.compact,
    this.tagTextColor,
    this.moreCount = 0,
    this.onTap,
  });

  final String? tagName;
  final int? tagColor;
  final int? tagTextColor;
  final int moreCount;
  final bool compact;
  final void Function(Offset globalPosition)? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = tagColor != null
        ? Color(tagColor!)
        : AppColors.textSecondary;
    final bool hasTag = tagName != null;
    final Color labelColor =
        tagTextColor != null ? Color(tagTextColor!) : Colors.white;
    final String label =
        moreCount > 0 ? '$tagName +$moreCount' : (tagName ?? '');

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
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: hasTag
          ? Text(
              label,
              style: TextStyle(
                color: labelColor,
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

/// Tappable favorite heart shown over the poster (top-right).
///
/// A solid colored circle with a white icon, matching the status /
/// in-collection badges: the favorite color when on, a dark scrim when off. A
/// red heart on a translucent scrim blended into colorful, warm-toned covers;
/// white on a solid fill stays legible over any poster, and the elevation
/// shadow separates the badge from the background.
///
/// The visible badge stays small, but the tap target is padded out to a finger-
/// friendly box (the bare icon is far under the ~40px touch guideline, so on a
/// phone it was easy to miss and open the card instead). The heart's own tap
/// recognizer wins over the card's open-tap, so a hit on the target toggles the
/// flag rather than opening the item.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.compact,
    this.onTap,
  });

  final bool isFavorite;
  final bool compact;

  /// When null the heart is a static indicator: taps fall through to the card
  /// (e.g. select it) instead of toggling the flag.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget badge = Material(
      color: isFavorite ? AppColors.favorite : Colors.black.withAlpha(160),
      shape: const CircleBorder(),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(compact ? 2 : 4),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.heart_broken,
          color: Colors.white,
          size: compact ? 10 : 13,
        ),
      ),
    );

    if (onTap == null) return badge;

    final double target = compact ? 28 : 32;
    return SizedBox(
      width: target,
      height: target,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Align(alignment: Alignment.topRight, child: badge),
        ),
      ),
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
