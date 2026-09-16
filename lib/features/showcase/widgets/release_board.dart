import 'dart:math' as math;

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

/// Below this a card has no room left for its text column, so the grid drops
/// a column rather than squeeze one. A phone always lands on a single card.
const double releaseBoardMinCardWidth = 380;

/// Cards shown before "Show all": two desktop rows, so eight boards do not
/// turn the section into an endless page.
const int releaseBoardCollapsedCount = 6;

/// One feed as a schedule: soonest first, optionally bucketed by date.
class ReleaseBoard extends StatefulWidget {
  const ReleaseBoard({
    required this.title,
    required this.items,
    required this.onTap,
    this.icon,
    this.isOwned,
    this.defaultGrouping = ReleaseGrouping.list,
    super.key,
  });

  final String title;
  final List<ShowcaseItem> items;
  final void Function(ShowcaseItem item) onTap;
  final IconData? icon;
  final bool Function(ShowcaseItem item)? isOwned;

  /// The bucketing the row opens on; [ReleaseGrouping.list] also means the
  /// row has no schedule worth bucketing and hides the switch.
  final ReleaseGrouping defaultGrouping;

  @override
  State<ReleaseBoard> createState() => _ReleaseBoardState();
}

class _ReleaseBoardState extends State<ReleaseBoard> {
  bool _expanded = false;
  late ReleaseGrouping _grouping = widget.defaultGrouping;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final S l = S.of(context);
    final List<ShowcaseItem> sorted = sortByNextDate(widget.items);
    // A bucketed view is the schedule itself; hiding later buckets behind
    // "Show all" would defeat it.
    final bool collapsible = _grouping == ReleaseGrouping.list &&
        sorted.length > releaseBoardCollapsedCount;
    final List<ShowcaseItem> visible = collapsible && !_expanded
        ? sorted.take(releaseBoardCollapsedCount).toList()
        : sorted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShowcaseRowTitle(title: widget.title, icon: widget.icon),
        if (widget.defaultGrouping != ReleaseGrouping.list) _groupingBar(l),
        const SizedBox(height: AppSpacing.sm),
        if (_grouping != ReleaseGrouping.list)
          for (final ReleaseGroup group
              in groupReleases(visible, _grouping)) ...<Widget>[
            _GroupTitle(group: group, grouping: _grouping),
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

  /// Its own row: four segments plus a title do not fit a phone's width.
  Widget _groupingBar(S l) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: SegmentedButton<ReleaseGrouping>(
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: <ButtonSegment<ReleaseGrouping>>[
            ButtonSegment<ReleaseGrouping>(
              value: ReleaseGrouping.list,
              icon: const Icon(Icons.view_list_outlined, size: 16),
              tooltip: l.showcaseViewList,
            ),
            ButtonSegment<ReleaseGrouping>(
              value: ReleaseGrouping.weekday,
              icon: const Icon(Icons.calendar_view_week_outlined, size: 16),
              tooltip: l.showcaseViewByWeekday,
            ),
            ButtonSegment<ReleaseGrouping>(
              value: ReleaseGrouping.day,
              icon: const Icon(Icons.calendar_view_day_outlined, size: 16),
              tooltip: l.showcaseViewByDay,
            ),
            ButtonSegment<ReleaseGrouping>(
              value: ReleaseGrouping.week,
              icon: const Icon(Icons.date_range_outlined, size: 16),
              tooltip: l.showcaseViewByWeek,
            ),
          ],
          selected: <ReleaseGrouping>{_grouping},
          onSelectionChanged: (Set<ReleaseGrouping> selection) =>
              setState(() => _grouping = selection.first),
        ),
      ),
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
    // The pane, not the window: a desktop grid sits beside the side menu.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnsFor(constraints.maxWidth),
            mainAxisExtent: height,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }

  /// Columns that fit [availableWidth] at [releaseBoardMinCardWidth] apiece,
  /// never fewer than one however narrow the pane gets.
  static int columnsFor(double availableWidth) {
    final double grid = availableWidth - AppSpacing.md * 2;
    final int columns = (grid + AppSpacing.sm) ~/
        (releaseBoardMinCardWidth + AppSpacing.sm);
    return math.max(1, columns);
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.group, required this.grouping});

  final ReleaseGroup group;
  final ReleaseGrouping grouping;

  @override
  Widget build(BuildContext context) {
    final DateTime? date = group.date;
    final String text = date == null
        ? S.of(context).showcaseDateTba
        : releaseGroupTitle(
            date,
            grouping,
            Localizations.localeOf(context).toString(),
          );
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
  const ShowcaseRowTitle({required this.title, this.icon, super.key});

  final String title;
  final IconData? icon;

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
        ],
      ),
    );
  }
}
