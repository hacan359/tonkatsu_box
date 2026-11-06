import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_panel.dart';

@immutable
class GlassTabOption<T> {
  const GlassTabOption({
    required this.value,
    required this.label,
    required this.icon,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  final T value;
  final String label;
  final IconData icon;

  /// Filled variant shown while active; defaults to [icon].
  final IconData selectedIcon;
}

/// Glass capsule of equal-width tabs. The active one is marked by a brand
/// pill that slides over, squashing along the way like the sidebar's blob.
class GlassTabBar<T> extends StatefulWidget {
  const GlassTabBar({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<GlassTabOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  State<GlassTabBar<T>> createState() => _GlassTabBarState<T>();
}

class _GlassTabBarState<T> extends State<GlassTabBar<T>>
    with SingleTickerProviderStateMixin {
  static const double _kHeight = 44;
  static const double _kInset = 4;

  late final AnimationController _controller;
  late int _from;
  late int _to;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy controller first touched in dispose() looks up
    // TickerMode on a deactivated element.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    );
    _from = _indexOf(widget.selected);
    _to = _from;
  }

  int _indexOf(T value) =>
      widget.options.indexWhere((GlassTabOption<T> o) => o.value == value);

  @override
  void didUpdateWidget(covariant GlassTabBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _from = _indexOf(oldWidget.selected);
      _to = _indexOf(widget.selected);
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kHeight,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double cellWidth =
              (constraints.maxWidth - _kInset * 2) / widget.options.length;
          return Container(
            padding: const EdgeInsets.all(_kInset),
            decoration: BoxDecoration(
              color: glassChipColor(),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            // Expand + stretch: a loose Row would take the text's height and
            // sit at the top, leaving the labels off the pill's centre.
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (_to >= 0)
                  _SlidingPill(
                    animation: _controller,
                    from: _from < 0 ? _to : _from,
                    to: _to,
                    cellWidth: cellWidth,
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final GlassTabOption<T> option in widget.options)
                      Expanded(
                        child: _TabCell<T>(
                          option: option,
                          active: option.value == widget.selected,
                          onTap: () => widget.onChanged(option.value),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SlidingPill extends StatelessWidget {
  const _SlidingPill({
    required this.animation,
    required this.from,
    required this.to,
    required this.cellWidth,
  });

  final Animation<double> animation;
  final int from;
  final int to;
  final double cellWidth;

  @override
  Widget build(BuildContext context) {
    // Hoisted: the getter allocates and the builder runs every frame.
    final BoxDecoration pill = _pillDecoration;
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        final double posT = Curves.easeInOutCubic.transform(t);
        final double left = cellWidth * (from + (to - from) * posT);

        // Stretches along the travel and relaxes back with a slight
        // overshoot, so it reads as liquid rather than a sliding box.
        final double squashT = t < 0.6 ? t / 0.6 : 1 - (t - 0.6) / 0.4;
        final double relaxed = Curves.easeOutBack.transform(
          1 - squashT.clamp(0.0, 1.0),
        );
        final double amplitude = (to - from).abs().clamp(0, 3) * 0.14;
        final double stretch = amplitude * (1 - relaxed);

        return Positioned(
          left: left,
          top: 0,
          bottom: 0,
          width: cellWidth,
          child: Transform.scale(
            scaleX: 1 + stretch,
            scaleY: 1 - stretch * 0.5,
            child: child,
          ),
        );
      },
      child: DecoratedBox(decoration: pill),
    );
  }
}

/// Getter, not `final`: must re-read the palette after a theme switch.
BoxDecoration get _pillDecoration => BoxDecoration(
  color: AppColors.brand.withAlpha(56),
  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  border: Border.all(color: AppColors.brand.withAlpha(90)),
  boxShadow: <BoxShadow>[
    BoxShadow(color: AppColors.brand.withAlpha(50), blurRadius: 12),
  ],
);

class _TabCell<T> extends StatelessWidget {
  const _TabCell({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final GlassTabOption<T> option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? AppColors.textPrimary : AppColors.textTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              active ? option.selectedIcon : option.icon,
              size: 16,
              color: fg,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
