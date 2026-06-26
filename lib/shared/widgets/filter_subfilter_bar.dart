import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'scrollable_row_with_arrows.dart';

/// Row height passed to [ScrollableRowWithArrows] for arrow positioning.
const double _kSubfilterRowHeight = 34;

/// One subfilter chip in a [SubfilterBar].
class SubfilterChipData {
  const SubfilterChipData({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// Media-type accent the chip is tinted with.
  final Color accent;

  final bool selected;
  final VoidCallback onTap;
}

/// Single horizontal row of media-type subfilter chips — game platforms, manga
/// formats, anime formats.
///
/// Each [groups] entry is one media type's chips, tinted with that type's
/// accent and split from the next group by a divider, so when several types
/// are active their subfilters share one scrolling row instead of stacking.
/// Empty groups are dropped; renders nothing when all are empty.
class SubfilterBar extends StatefulWidget {
  const SubfilterBar({required this.groups, super.key});

  final List<List<SubfilterChipData>> groups;

  @override
  State<SubfilterBar> createState() => _SubfilterBarState();
}

class _SubfilterBarState extends State<SubfilterBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<List<SubfilterChipData>> active = widget.groups
        .where((List<SubfilterChipData> g) => g.isNotEmpty)
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();

    // Highlight the whole strip when any subfilter is on, tinted with the first
    // selected chip's media accent (any one of them when several types are on).
    final Color? highlight = _selectedAccent(active);

    final List<Widget> children = <Widget>[];
    for (int g = 0; g < active.length; g++) {
      if (g > 0) {
        children.add(
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            width: 1,
            height: 16,
            color: AppColors.surfaceBorder,
          ),
        );
      }
      for (int i = 0; i < active[g].length; i++) {
        if (i > 0) children.add(const SizedBox(width: AppSpacing.sm));
        children.add(FilterTabChip(data: active[g][i]));
      }
    }

    return Padding(
      // Vertical only — the highlight band runs full width (edge to edge), so
      // the horizontal inset lives inside it (below) instead.
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      // Full-bleed band with no border or radius so the highlight reads as one
      // even row with no seams; the inner padding keeps the chips inset. Geometry
      // is constant, so the strip never jumps when the highlight toggles — only
      // the color animates in.
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: highlight?.withAlpha(38) ?? Colors.transparent,
        ),
        // Desktop scrolling, all three ways: hover arrows, mouse wheel, and
        // click-drag (ScrollableRowWithArrows bundles them). Touch swipe on mobile.
        child: ScrollableRowWithArrows(
          controller: _scrollController,
          height: _kSubfilterRowHeight,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(children: children),
          ),
        ),
      ),
    );
  }

  /// Accent of the first selected chip, or null when nothing is selected.
  Color? _selectedAccent(List<List<SubfilterChipData>> groups) {
    for (final List<SubfilterChipData> group in groups) {
      for (final SubfilterChipData chip in group) {
        if (chip.selected) return chip.accent;
      }
    }
    return null;
  }
}

/// Flat underline-tab chip: the label is tinted with its media-type accent
/// (muted when unselected) and gains a 2px accent underline when selected.
class FilterTabChip extends StatelessWidget {
  const FilterTabChip({required this.data, super.key});

  final SubfilterChipData data;

  /// Label alpha when the chip is not selected.
  static const int _inactiveAlpha = 130;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: data.selected ? data.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            data.label,
            style: AppTypography.caption.copyWith(
              color: data.selected
                  ? data.accent
                  : data.accent.withAlpha(_inactiveAlpha),
              fontWeight: data.selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
