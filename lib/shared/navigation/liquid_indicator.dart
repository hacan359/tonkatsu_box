import 'package:flutter/material.dart';

import '../constants/media_type_theme.dart';
import '../theme/app_colors.dart';

/// Round blob that slides between nav items, squashing along the way and
/// settling back with an elastic bounce. Hidden while [selectedIndex] is -1.
class LiquidIndicator extends StatefulWidget {
  /// Creates a [LiquidIndicator].
  const LiquidIndicator({
    required this.selectedIndex,
    required this.itemExtent,
    required this.crossExtent,
    this.axis = Axis.vertical,
    this.size = 40,
    this.rainbow = false,
    super.key,
  });

  /// Active item index, or -1 when no menu item is active.
  final int selectedIndex;

  /// Extent of one cell along the main axis.
  final double itemExtent;

  /// Extent of the container across the main axis.
  final double crossExtent;

  /// Axis the blob travels along.
  final Axis axis;

  /// Diameter of the blob at rest.
  final double size;

  /// Fill with the media-type rainbow instead of flat brand. Marks the
  /// centre button, which opens the whole library rather than one section.
  final bool rainbow;

  @override
  State<LiquidIndicator> createState() => _LiquidIndicatorState();
}

class _LiquidIndicatorState extends State<LiquidIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _fromOffset;
  late double _toOffset;

  /// Fill the blob is sliding away from, cross-faded into the current one.
  late bool _fromRainbow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fromOffset = _offsetFor(widget.selectedIndex);
    _toOffset = _fromOffset;
    _fromRainbow = widget.rainbow;
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant LiquidIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex ||
        widget.axis != oldWidget.axis ||
        widget.itemExtent != oldWidget.itemExtent ||
        widget.crossExtent != oldWidget.crossExtent) {
      _fromOffset = _offsetFor(oldWidget.selectedIndex);
      _toOffset = _offsetFor(widget.selectedIndex);
      // Cross-faded over the same slide, so the fill does not snap halfway
      // between the centre button and a tab.
      _fromRainbow = oldWidget.rainbow;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _offsetFor(int index) {
    return widget.itemExtent * index + (widget.itemExtent - widget.size) / 2;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedIndex < 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final double posT = Curves.easeInOutCubic.transform(t);
        final double mainOffset = _fromOffset + (_toOffset - _fromOffset) * posT;
        final double crossOffset = (widget.crossExtent - widget.size) / 2;

        final double squashT;
        if (t < 0.6) {
          squashT = t / 0.6;
        } else {
          squashT = 1 - ((t - 0.6) / 0.4);
        }
        final double relaxed = Curves.easeOutBack.transform(
          1 - squashT.clamp(0.0, 1.0),
        );

        final double distance = (_toOffset - _fromOffset).abs();
        final double amplitude =
            (distance / widget.itemExtent).clamp(0.0, 3.0) * 0.42;

        final double scaleMain = 1 + amplitude * (1 - relaxed);
        final double scaleCross = 1 - amplitude * 0.5 * (1 - relaxed);

        final bool vertical = widget.axis == Axis.vertical;
        final double top = vertical ? mainOffset : crossOffset;
        final double left = vertical ? crossOffset : mainOffset;
        final double scaleX = vertical ? scaleCross : scaleMain;
        final double scaleY = vertical ? scaleMain : scaleCross;

        // 0 = plain brand, 1 = rainbow. Only moves while the blob slides.
        final double rainbowT = _fromRainbow == widget.rainbow
            ? (widget.rainbow ? 1.0 : 0.0)
            : (widget.rainbow ? posT : 1 - posT);

        return Positioned(
          top: top,
          left: left,
          width: widget.size,
          height: widget.size,
          child: Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            // Both fills are translucent, so painting them stacked at rest
            // would tint the rainbow orange.
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (rainbowT < 1)
                  Opacity(
                    opacity: 1 - rainbowT,
                    child: DecoratedBox(decoration: _brandBlob),
                  ),
                if (rainbowT > 0)
                  Opacity(
                    opacity: rainbowT,
                    child: DecoratedBox(decoration: _rainbowBlob),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fill opacity, shared by both variants.
const int _kBlobAlpha = 180;

/// Flat brand fill, used by the regular menu items.
final BoxDecoration _brandBlob = BoxDecoration(
  color: AppColors.brand.withAlpha(_kBlobAlpha),
  shape: BoxShape.circle,
  boxShadow: <BoxShadow>[
    BoxShadow(color: AppColors.brand.withAlpha(60), blurRadius: 12),
  ],
);

/// Media-type accents run around the circle.
final BoxDecoration _rainbowBlob = BoxDecoration(
  shape: BoxShape.circle,
  gradient: SweepGradient(
    colors: <Color>[
      for (final Color c in MediaTypeTheme.rainbowSweep)
        c.withAlpha(_kBlobAlpha),
    ],
  ),
  boxShadow: <BoxShadow>[
    BoxShadow(color: AppColors.brand.withAlpha(60), blurRadius: 12),
  ],
);
