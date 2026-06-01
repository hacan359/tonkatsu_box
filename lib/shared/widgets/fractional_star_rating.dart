import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Star control for a personal rating (1.0–10.0, step 0.1). Inline, no popup.
///
/// Row of a leading clear cell (sets the rating to `null`) plus 10 stars;
/// tapping a star sets a whole integer 1–10. The −/+ buttons nudge the current
/// value by 0.1 and are disabled while the rating is unset (nothing to nudge —
/// tap a star first).
class FractionalStarRating extends StatefulWidget {
  const FractionalStarRating({
    required this.onChanged,
    this.value,
    this.starSize = 24.0,
    super.key,
  });

  final double? value;
  final double starSize;

  /// Emits `null` when the leading clear cell is hit.
  final ValueChanged<double?> onChanged;

  static const int starCount = 10;
  static const double minRating = 1.0;
  static const double maxRating = 10.0;
  static const double step = 0.1;
  static const double _gap = 3.0;

  static double _buttonWidth(double starSize) => starSize + _gap;

  /// Natural (unconstrained) width for a given [starSize]: clear cell, ten
  /// stars, and the two nudge buttons. Useful when the widget sits inside an
  /// `IntrinsicWidth` (e.g. a popup menu), which cannot measure the internal
  /// `LayoutBuilder`.
  static double naturalWidth(double starSize) =>
      (starSize + _gap) * (starCount + 1) + 2 * _buttonWidth(starSize);

  @override
  State<FractionalStarRating> createState() => _FractionalStarRatingState();
}

class _FractionalStarRatingState extends State<FractionalStarRating> {
  late double? _value = widget.value;

  @override
  void didUpdateWidget(FractionalStarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _value = widget.value;
    }
  }

  static double _roundToTenth(double v) => (v * 10).roundToDouble() / 10;

  void _emit(double? v) {
    setState(() => _value = v);
    widget.onChanged(v);
  }

  void _handleTap(double localX, double cellWidth) {
    if (cellWidth <= 0) return;
    final int index = (localX / cellWidth).floor();
    if (index <= 0) {
      _emit(null);
      return;
    }
    _emit(index.clamp(1, FractionalStarRating.starCount).toDouble());
  }

  void _nudge(double delta) {
    final double? current = _value;
    if (current == null) return;
    final double next = _roundToTenth(
      (current + delta).clamp(
        FractionalStarRating.minRating,
        FractionalStarRating.maxRating,
      ),
    );
    if (next == current) return;
    _emit(next);
  }

  @override
  Widget build(BuildContext context) {
    const int starCount = FractionalStarRating.starCount;
    final double buttonWidth =
        FractionalStarRating._buttonWidth(widget.starSize);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double barNatural =
            (widget.starSize + FractionalStarRating._gap) * (starCount + 1);
        final double reserved = 2 * buttonWidth;
        // Shrink the star bar to the parent when it is too narrow, so the row
        // never overflows; the nudge buttons keep their natural size.
        final double barWidth = constraints.maxWidth.isFinite &&
                constraints.maxWidth - reserved < barNatural
            ? (constraints.maxWidth - reserved).clamp(0.0, barNatural)
            : barNatural;
        final double cellWidth = barWidth / (starCount + 1);
        final bool hasValue = _value != null;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails d) =>
                  _handleTap(d.localPosition.dx, cellWidth),
              child: SizedBox(
                width: barWidth,
                height: widget.starSize,
                child: Row(
                  children: <Widget>[
                    _Cell(
                      width: cellWidth,
                      child: _ClearCell(
                        size: widget.starSize,
                        active: _value == null,
                      ),
                    ),
                    for (int i = 1; i <= starCount; i++)
                      _Cell(
                        width: cellWidth,
                        child: _PartialStar(
                          fill: ((_value ?? 0) - (i - 1)).clamp(0.0, 1.0),
                          size: widget.starSize,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _NudgeButton(
              icon: Icons.remove,
              size: widget.starSize,
              onTap: hasValue ? () => _nudge(-FractionalStarRating.step) : null,
            ),
            _NudgeButton(
              icon: Icons.add,
              size: widget.starSize,
              onTap: hasValue ? () => _nudge(FractionalStarRating.step) : null,
            ),
          ],
        );
      },
    );
  }
}

/// Square tappable +/- button. Greyed out (and inert) when [onTap] is null.
class _NudgeButton extends StatelessWidget {
  const _NudgeButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FractionalStarRating._buttonWidth(size),
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            size: size * 0.8,
            color:
                onTap == null ? AppColors.textTertiary : AppColors.ratingStar,
          ),
        ),
      ),
    );
  }
}

/// Fixed-width cell that scales its icon down if the column gets narrow.
class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}

class _ClearCell extends StatelessWidget {
  const _ClearCell({required this.size, required this.active});

  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.do_not_disturb_alt,
      size: size,
      color: active ? AppColors.ratingStar : AppColors.textTertiary,
    );
  }
}

class _PartialStar extends StatelessWidget {
  const _PartialStar({required this.fill, required this.size});

  /// Fill fraction, 0.0–1.0.
  final double fill;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Icon(Icons.star_rounded, size: size, color: AppColors.textTertiary),
          if (fill > 0)
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: Icon(
                  Icons.star_rounded,
                  size: size,
                  color: AppColors.ratingStar,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
