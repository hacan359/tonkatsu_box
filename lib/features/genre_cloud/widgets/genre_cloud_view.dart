import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/logo_loader.dart';
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

/// Shared by measurement and painting so the laid-out footprint matches what
/// is drawn; [labelShadows] is paint-only.
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
      AppColors.textPrimary,
      showCount: showCount,
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final Size size = Size(painter.width, painter.height);
  // Free the native paragraph now; layout passes measure thousands of words.
  painter.dispose();
  return size;
}

/// When [interactive], the canvas grows to fit every word inside an
/// [InteractiveViewer]; the offscreen export view sets it false.
class GenreCloudView extends StatefulWidget {
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

  // Deferred (post-frame) layout bookkeeping; see _scheduleLayout.
  bool _layoutPending = false;

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

  /// Measurement memo shared by every pass of one layout run: auto-fit and
  /// growth passes re-ask for the same (word, fontSize) pairs many times over.
  MeasureWord _memoizedMeasure() {
    final Map<String, Size> cache = <String, Size>{};
    final bool showCount = widget.showCount;
    return (FacetValue word, double fontSize) => cache.putIfAbsent(
          '${word.label}|${word.count}|$fontSize',
          () => measureGenreWord(word, fontSize, showCount: showCount),
        );
  }

  GenreCloudLayout _compute(Size canvas) => layoutGenreCloud(
        words: widget.words,
        canvasSize: canvas,
        measure: _memoizedMeasure(),
        minFontSize: widget.minFontSize,
        maxFontSize: widget.maxFontSize,
      );

  Future<GenreCloudLayout> _computeAsync(
    Size canvas,
    List<FacetValue> words,
    MeasureWord measure,
  ) =>
      layoutGenreCloudAsync(
        words: words,
        canvasSize: canvas,
        measure: measure,
        minFontSize: widget.minFontSize,
        maxFontSize: widget.maxFontSize,
      );

  /// The cached layout when it still matches the current words + viewport.
  GenreCloudLayout? _cachedLayout(Size viewport) {
    if (_layout != null &&
        _laidOutViewport == viewport &&
        _laidOutWords != null &&
        listEquals(_laidOutWords, widget.words)) {
      return _layout;
    }
    return null;
  }

  Future<GenreCloudLayout> _computeWithGrowth(
    Size viewport,
    List<FacetValue> words,
  ) async {
    Size canvas = viewport;
    final MeasureWord measure = _memoizedMeasure();
    GenreCloudLayout layout = await _computeAsync(canvas, words, measure);
    // Grow the canvas (keeping fonts readable) until everything fits, so the
    // pan/zoom can reach every word.
    int pass = 0;
    while (layout.hidden > 0 && pass < _maxGrowthPasses) {
      canvas = Size(canvas.width * 1.4, canvas.height * 1.4);
      layout = await _computeAsync(canvas, words, measure);
      pass++;
    }
    return layout;
  }

  /// Defers the expensive placement past the current frame and runs it
  /// cooperatively, so the loading indicator keeps animating.
  void _scheduleLayout(Size viewport) {
    if (_layoutPending) return;
    _layoutPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runLayout(viewport);
    });
  }

  Future<void> _runLayout(Size viewport) async {
    try {
      if (!mounted) return;
      // Snapshot the inputs: if words change mid-computation the next build's
      // cache check misses and a fresh pass is scheduled.
      final List<FacetValue> words = List<FacetValue>.of(widget.words);
      final GenreCloudLayout layout = await _computeWithGrowth(viewport, words);
      if (!mounted) return;
      setState(() {
        _layout = layout;
        _laidOutWords = words;
        _laidOutViewport = viewport;
      });
    } finally {
      _layoutPending = false;
    }
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

        final GenreCloudLayout layout;
        if (widget.interactive) {
          // Deferred so the screen opens with a spinner, not a frozen frame;
          // export views compute synchronously (captured right after the frame).
          final GenreCloudLayout? cached = _cachedLayout(viewport);
          if (cached == null) {
            _scheduleLayout(viewport);
            return const Center(child: LogoLoader());
          }
          layout = cached;
        } else {
          layout = _compute(viewport);
        }

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
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
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
      shape: CircleBorder(
        side: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
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
