import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'chip_tile.dart';
import 'glass_panel.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'horizontal_mouse_scroll.dart';

const double kMediaTypeTileSize = 40;

/// Headroom above a tile for the count badge that overhangs it.
const double _badgeRoom = 6;

/// Horizontal strip of filter tiles under the glass: wheel and drag both
/// scroll it, because on a narrow window it is longer than the panel.
class MediaTypeIconStrip extends StatefulWidget {
  const MediaTypeIconStrip({required this.children, super.key});

  final List<Widget> children;

  @override
  State<MediaTypeIconStrip> createState() => _MediaTypeIconStripState();
}

class _MediaTypeIconStripState extends State<MediaTypeIconStrip> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Six extra points keep the count badge clear of the clip edge.
    return SizedBox(
      height: kMediaTypeTileSize + 6,
      child: HorizontalMouseScroll(
        controller: _controller,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: PointerDeviceKind.values.toSet(),
            scrollbars: false,
          ),
          child: ListView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}

/// One filter in the strip: a tinted tile, filled when selected, with the
/// count riding on its top-right corner and the label in the tooltip.
class MediaTypeIconTile extends StatelessWidget {
  const MediaTypeIconTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.count = 0,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected
        ? accent
        : glassChipColor(tint: accent, tintAlpha: 80);
    final Color fg = selected ? AppColors.background : accent.withAlpha(230);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs, top: _badgeRoom),
      child: Tooltip(
        message: count > 0 ? '$label ($count)' : label,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            ChipTile(
              color: bg,
              onTap: onTap,
              width: kMediaTypeTileSize,
              height: kMediaTypeTileSize,
              padding: EdgeInsets.zero,
              child: Icon(icon, size: 20, color: fg),
            ),
            if (count > 0)
              Positioned(
                top: -6,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withAlpha(230),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: accent.withAlpha(160)),
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A neutral tile for a trigger that is not a media type: sort, the tag
/// sheet, anything that opens a menu.
class StripActionTile extends StatelessWidget {
  const StripActionTile({
    required this.icon,
    this.active = false,
    this.child,
    super.key,
  });

  final IconData icon;
  final bool active;

  /// Replaces the icon when set; the tile stays the same size.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Color bg = active ? AppColors.brand : glassChipColor();
    final Color fg = active ? AppColors.onBrand : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs, top: _badgeRoom),
      child: ChipTile(
        color: bg,
        width: kMediaTypeTileSize,
        height: kMediaTypeTileSize,
        padding: EdgeInsets.zero,
        child: child ?? Icon(icon, size: 18, color: fg),
      ),
    );
  }
}
