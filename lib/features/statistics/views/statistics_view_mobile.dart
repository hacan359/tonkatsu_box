import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../layout/stats_layout.dart';
import '../layout/stats_layout_mobile.dart';
import '../layout/stats_layout_scope.dart';
import '../models/library_stats.dart';
import '../widgets/stats_hero_mobile.dart';
import '../widgets/stats_months_ribbon_mobile.dart';
import '../widgets/stats_period_picker.dart';
import '../widgets/stats_types_section.dart';
import 'stats_sections.dart';

/// The phone page: same sections in the same order as the wide one, tighter,
/// with the activity ribbon bleeding to the screen edges.
class StatisticsViewMobile extends StatelessWidget {
  /// Creates the phone page.
  const StatisticsViewMobile({
    required this.stats,
    required this.titleLanguage,
    required this.picker,
    super.key,
  });

  /// The payload to render.
  final LibraryStats stats;

  /// AniList/Kitsu title language for display names.
  final String titleLanguage;

  /// The period dropdown and share button, assembled by the screen and
  /// placed in the hero across from the headline number.
  final StatsPeriodPickerData picker;

  static const StatsLayout _layout = kStatsLayoutMobile;

  @override
  Widget build(BuildContext context) {
    return StatsLayoutScope(
      layout: _layout,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StatsHeroMobile(
              stats: stats,
              periodPicker: StatsPeriodPicker(data: picker),
            ),
            if (stats.hasTypeBreakdown)
              _inset(StatsTypesSection(stats: stats)),
            // Full-bleed: the ribbon applies the page inset to its own header
            // and list padding so a swipe runs to the screen edge.
            if (stats.hasMonthActivity)
              Padding(
                padding: EdgeInsets.only(bottom: _layout.sectionGap),
                child: StatsMonthsRibbonMobile(
                  stats: stats,
                  edgeInset: _layout.horizontalPadding,
                ),
              ),
            for (final Widget section
                in statsSectionsAfterMonths(stats, titleLanguage))
              _inset(section),
          ],
        ),
      ),
    );
  }

  /// Wraps a section in the page inset and the gap that follows it.
  Widget _inset(Widget section) {
    return Padding(
      // Not const: Dart cannot read fields off a const object inside a const
      // expression.
      padding: EdgeInsets.fromLTRB(
        _layout.horizontalPadding,
        0,
        _layout.horizontalPadding,
        _layout.sectionGap,
      ),
      child: section,
    );
  }

}
