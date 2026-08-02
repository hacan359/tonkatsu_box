import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/constants/item_status_ui.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../layout/stats_layout_scope.dart';
import 'stats_poster.dart';

/// Locale-aware thousands-separated number format for the stats sections.
NumberFormat statsNumberFormat(BuildContext context) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString());

/// Derived views over a status-count map shared by every breakdown card.
extension StatusCountsX on Map<ItemStatus, int> {
  /// Non-zero segments ordered like the status pickers.
  List<MapEntry<ItemStatus, int>> get sortedSegments => entries
      .where((MapEntry<ItemStatus, int> e) => e.value > 0)
      .toList()
    ..sort((MapEntry<ItemStatus, int> a, MapEntry<ItemStatus, int> b) =>
        a.key.statusSortPriority.compareTo(b.key.statusSortPriority));

  /// Completed share of all counted items, rounded to whole percent.
  int get completedPercent {
    final int total = values.fold(0, (int sum, int c) => sum + c);
    if (total == 0) return 0;
    return ((this[ItemStatus.completed] ?? 0) * 100 / total).round();
  }
}

/// The standard stats surface card; [highlightColor] marks the leading card
/// of a group. Inner padding comes from the page's layout spec.
class StatsCard extends StatelessWidget {
  /// Creates the card shell.
  const StatsCard({required this.child, this.highlightColor, super.key});

  /// Card contents.
  final Widget child;

  /// Accent border color; null keeps the regular hairline.
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: StatsLayoutScope.of(context).cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: highlightColor?.withAlpha(110) ?? AppColors.surfaceBorder,
          width: highlightColor != null ? 1 : 0.5,
        ),
      ),
      child: child,
    );
  }
}

/// A 4px bar split into per-status segments; a plain track when empty.
class StatusSplitBar extends StatelessWidget {
  /// Creates the bar over a status-count map.
  const StatusSplitBar({required this.counts, super.key});

  /// Status counts to visualise.
  final Map<ItemStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<ItemStatus, int>> segments = counts.sortedSegments;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: segments.isEmpty
            ? const ColoredBox(color: AppColors.surfaceLight)
            : Row(
                children: <Widget>[
                  for (final MapEntry<ItemStatus, int> entry in segments)
                    Expanded(
                      flex: entry.value,
                      child: ColoredBox(color: entry.key.color),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Exactly three equal cover slots filling the card width; missing covers
/// leave an empty slot so the present ones keep a uniform size.
class StatsTopCoversRow extends StatelessWidget {
  /// Creates the cover row.
  const StatsTopCoversRow({
    required this.itemIds,
    required this.coversById,
    super.key,
  });

  /// Row ids of the covers to show, best first.
  final List<int> itemIds;

  /// Hydrated items keyed by row id.
  final Map<int, CollectionItem> coversById;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int slot = 0; slot < 3; slot++) ...<Widget>[
          if (slot > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: slot < itemIds.length
                ? StatsPoster(item: coversById[itemIds[slot]])
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

/// A colored legend dot with a label and an optional count.
class StatsLegendDot extends StatelessWidget {
  /// Creates the legend entry.
  const StatsLegendDot({
    required this.color,
    required this.label,
    this.count,
    super.key,
  });

  /// Dot color.
  final Color color;

  /// Legend label.
  final String label;

  /// Optional count rendered in [color] after the label.
  final String? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          label,
          style:
              AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        if (count != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Text(
            count!,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
