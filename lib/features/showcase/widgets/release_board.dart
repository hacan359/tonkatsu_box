import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/showcase_item.dart';
import '../utils/release_labels.dart';
import '../utils/release_schedule.dart';
import 'release_card.dart';

/// A widest card the grid still splits into columns; a desktop pane gets
/// two or three, a phone one.
const double releaseBoardMaxCardWidth = 460;

/// Cards shown before "Show all": two desktop rows, so eight boards do not
/// turn the section into an endless page.
const int releaseBoardCollapsedCount = 6;

/// One feed as a schedule: soonest first, optionally bucketed by day.
class ReleaseBoard extends StatefulWidget {
  const ReleaseBoard({
    required this.title,
    required this.items,
    required this.onTap,
    this.icon,
    this.isOwned,
    this.allowsDayGrouping = false,
    super.key,
  });

  final String title;
  final List<ShowcaseItem> items;
  final void Function(ShowcaseItem item) onTap;
  final IconData? icon;
  final bool Function(ShowcaseItem item)? isOwned;
  final bool allowsDayGrouping;

  @override
  State<ReleaseBoard> createState() => _ReleaseBoardState();
}

class _ReleaseBoardState extends State<ReleaseBoard> {
  bool _expanded = false;
  bool _byDay = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final S l = S.of(context);
    final List<ShowcaseItem> sorted = sortByNextDate(widget.items);
    // The per-day view is the schedule itself; hiding later days behind
    // "Show all" would defeat it.
    final bool collapsible =
        !_byDay && sorted.length > releaseBoardCollapsedCount;
    final List<ShowcaseItem> visible = collapsible && !_expanded
        ? sorted.take(releaseBoardCollapsedCount).toList()
        : sorted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShowcaseRowTitle(
          title: widget.title,
          icon: widget.icon,
          trailing: widget.allowsDayGrouping ? _viewToggle(l) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_byDay)
          for (final ReleaseDayGroup group in groupByDay(visible)) ...<Widget>[
            _DayTitle(group: group),
            _grid(group.items),
          ]
        else
          _grid(visible),
        if (collapsible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  // The theme's infinite minimumSize would break inside a Row.
                  style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? l.showLess : l.showcaseShowAll(sorted.length),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _viewToggle(S l) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: <ButtonSegment<bool>>[
        ButtonSegment<bool>(
          value: false,
          icon: const Icon(Icons.view_list_outlined, size: 16),
          tooltip: l.showcaseViewList,
        ),
        ButtonSegment<bool>(
          value: true,
          icon: const Icon(Icons.calendar_view_day_outlined, size: 16),
          tooltip: l.showcaseViewByDay,
        ),
      ],
      selected: <bool>{_byDay},
      onSelectionChanged: (Set<bool> selection) =>
          setState(() => _byDay = selection.first),
    );
  }

  Widget _grid(List<ShowcaseItem> items) {
    return ReleaseGrid(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final ShowcaseItem item = items[index];
        return ReleaseCard(
          key: ValueKey<String>('${item.source.name}_${item.externalId}'),
          item: item,
          isOwned: widget.isOwned?.call(item) ?? false,
          onTap: () => widget.onTap(item),
        );
      },
    );
  }
}

/// Non-scrolling grid of fixed-height cards, shared with the shimmer so
/// the skeleton takes the same footprint as the data.
class ReleaseGrid extends StatelessWidget {
  const ReleaseGrid({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final double height = ReleaseCard.height(
      compact: isCompactScreen(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: releaseBoardMaxCardWidth,
        mainAxisExtent: height,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class _DayTitle extends StatelessWidget {
  const _DayTitle({required this.group});

  final ReleaseDayGroup group;

  @override
  Widget build(BuildContext context) {
    final DateTime? day = group.day;
    final String text = day == null
        ? S.of(context).showcaseDateTba
        : releaseDayTitle(day, Localizations.localeOf(context).toString());
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ShowcaseRowTitle extends StatelessWidget {
  const ShowcaseRowTitle({
    required this.title,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing case final Widget trailing) trailing,
        ],
      ),
    );
  }
}
