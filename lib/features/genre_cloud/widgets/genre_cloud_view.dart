// On-screen preference cloud: lays out and paints facet words.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../facet_value.dart';
import '../genre_cloud_layout.dart';

/// Base text style for a cloud word.
TextStyle genreWordStyle(double fontSize, Color color) => TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1,
      color: color,
    );

/// Builds the rich span for a cloud word: the label plus an optional smaller,
/// dimmed count suffix. Used by both measurement and painting so the laid-out
/// footprint matches what is drawn. [labelShadows] is paint-only.
TextSpan genreWordSpan(
  FacetValue word,
  double fontSize,
  Color color, {
  required bool showCount,
  List<Shadow>? labelShadows,
}) {
  return TextSpan(
    text: word.label,
    style: genreWordStyle(fontSize, color).copyWith(shadows: labelShadows),
    children: showCount
        ? <InlineSpan>[
            TextSpan(
              text: '  ${word.count}',
              style: genreWordStyle(
                math.max(8, fontSize * 0.38),
                color.withAlpha(140),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ]
        : null,
  );
}

/// Measures a cloud word (label + optional count) at [fontSize].
Size measureGenreWord(
  FacetValue word,
  double fontSize, {
  required bool showCount,
}) {
  final TextPainter painter = TextPainter(
    text: genreWordSpan(
      word,
      fontSize,
      const Color(0xFFFFFFFF),
      showCount: showCount,
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return Size(painter.width, painter.height);
}

/// Paints a preference cloud. Word size scales with frequency rank; colour
/// follows the dominant media type. Which facets and media types appear is
/// controlled by the legend (callers filter [words] upstream).
///
/// When [interactive] (the default) the cloud is laid out on a canvas grown to
/// fit every word and wrapped in an [InteractiveViewer], so on small screens the
/// user pans and pinch-zooms to reach words instead of losing them to the hidden
/// counter. The offscreen export view sets it false to render a fixed,
/// fully-visible poster.
class GenreCloudView extends StatefulWidget {
  /// Creates a [GenreCloudView].
  const GenreCloudView({
    required this.words,
    this.minFontSize = 14,
    this.maxFontSize = 64,
    this.showCount = true,
    this.interactive = true,
    this.resetTooltip,
    this.hiddenLabel,
    super.key,
  });

  /// Facet values to render.
  final List<FacetValue> words;

  /// Smallest font size used for the rarest tier.
  final double minFontSize;

  /// Largest font size for the most frequent tier (auto-fit may shrink it).
  final double maxFontSize;

  /// Whether to draw the item count next to each word.
  final bool showCount;

  /// Whether to grow the canvas to fit every word and allow pan/zoom.
  final bool interactive;

  /// Tooltip for the recenter button (shown only while the view is panned or
  /// zoomed away from the default). Omit to hide the tooltip.
  final String? resetTooltip;

  /// Builds the caption shown when some words could not be placed.
  final String Function(int hidden)? hiddenLabel;

  @override
  State<GenreCloudView> createState() => _GenreCloudViewState();
}

class _GenreCloudViewState extends State<GenreCloudView> {
  /// Max canvas growth passes before giving up (then [hidden] carries the rest).
  static const int _maxGrowthPasses = 4;

  final TransformationController _controller = TransformationController();

  // Cached layout: the placement is expensive, so recompute only when the words
  // or the viewport actually change, not on every unrelated rebuild.
  GenreCloudLayout? _layout;
  List<FacetValue>? _laidOutWords;
  Size? _laidOutViewport;

  // Canvas the view is currently centred for; re-centre only when it changes so
  // the user's own panning survives rebuilds.
  Size? _centeredFor;

  // The default (centred, unzoomed) transform the recenter button restores.
  Matrix4? _homeTransform;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isHome(Matrix4 transform) =>
      _homeTransform == null || transform == _homeTransform;

  void _resetView() {
    final Matrix4? home = _homeTransform;
    if (home != null) _controller.value = home;
  }

  GenreCloudLayout _compute(Size canvas) => layoutGenreCloud(
        words: widget.words,
        canvasSize: canvas,
        measure: (FacetValue word, double fontSize) =>
            measureGenreWord(word, fontSize, showCount: widget.showCount),
        minFontSize: widget.minFontSize,
        maxFontSize: widget.maxFontSize,
      );

  GenreCloudLayout _resolveLayout(Size viewport) {
    if (!widget.interactive) return _compute(viewport);

    if (_layout != null &&
        _laidOutViewport == viewport &&
        _laidOutWords != null &&
        listEquals(_laidOutWords, widget.words)) {
      return _layout!;
    }

    Size canvas = viewport;
    GenreCloudLayout layout = _compute(canvas);
    // Grow the canvas (keeping fonts readable) until everything fits, so the
    // pan/zoom can reach every word.
    int pass = 0;
    while (layout.hidden > 0 && pass < _maxGrowthPasses) {
      canvas = Size(canvas.width * 1.4, canvas.height * 1.4);
      layout = _compute(canvas);
      pass++;
    }

    _layout = layout;
    _laidOutWords = List<FacetValue>.of(widget.words);
    _laidOutViewport = viewport;
    return layout;
  }

  void _maybeRecenter(Size viewport, Size canvas) {
    final double dx = (viewport.width - canvas.width) / 2;
    final double dy = (viewport.height - canvas.height) / 2;
    final Matrix4 home = Matrix4.translationValues(dx, dy, 0);
    _homeTransform = home;
    if (_centeredFor == canvas) return;
    _centeredFor = canvas;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.value = home;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final GenreCloudLayout layout = _resolveLayout(viewport);

        final Widget content;
        if (widget.interactive) {
          _maybeRecenter(viewport, layout.size);
          content = InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            minScale: 0.4,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(64),
            child: CustomPaint(
              size: layout.size,
              painter: _GenreCloudPainter(layout, showCount: widget.showCount),
            ),
          );
        } else {
          content = CustomPaint(
            painter: _GenreCloudPainter(layout, showCount: widget.showCount),
          );
        }

        return Stack(
          children: <Widget>[
            Positioned.fill(child: content),
            if (widget.interactive)
              Positioned(
                left: 8,
                bottom: 8,
                child: ValueListenableBuilder<Matrix4>(
                  valueListenable: _controller,
                  builder: (BuildContext context, Matrix4 value, Widget? _) {
                    if (_isHome(value)) return const SizedBox.shrink();
                    return _RecenterButton(
                      onTap: _resetView,
                      tooltip: widget.resetTooltip,
                    );
                  },
                ),
              ),
            if (layout.hidden > 0 && widget.hiddenLabel != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: Text(
                  widget.hiddenLabel!(layout.hidden),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF707070),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Small circular button that restores the cloud to its default centred view.
class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget button = Material(
      color: AppColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.filter_center_focus,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
    final String? message = tooltip;
    if (message == null) return button;
    return Tooltip(message: message, child: button);
  }
}

class _GenreCloudPainter extends CustomPainter {
  _GenreCloudPainter(this.layout, {required this.showCount});

  final GenreCloudLayout layout;
  final bool showCount;

  @override
  void paint(Canvas canvas, Size size) {
    for (final PlacedWord placed in layout.placed) {
      final FacetValue word = placed.word;
      final Color color = MediaTypeTheme.colorFor(word.type);
      final TextPainter painter = TextPainter(
        text: genreWordSpan(
          word,
          placed.fontSize,
          color,
          showCount: showCount,
          labelShadows: <Shadow>[
            Shadow(color: color.withAlpha(70), blurRadius: 14),
          ],
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      canvas.save();
      canvas.translate(placed.center.dx, placed.center.dy);
      if (placed.rotated) {
        canvas.rotate(-math.pi / 2);
      }
      painter.paint(
        canvas,
        Offset(-painter.width / 2, -painter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GenreCloudPainter oldDelegate) =>
      !identical(oldDelegate.layout, layout) ||
      oldDelegate.showCount != showCount;
}
