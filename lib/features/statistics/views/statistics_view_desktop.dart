import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../layout/stats_layout.dart';
import '../layout/stats_layout_desktop.dart';
import '../layout/stats_layout_scope.dart';
import '../models/library_stats.dart';
import '../widgets/stats_hero_desktop.dart';
import '../widgets/stats_months_ribbon_desktop.dart';
import '../widgets/stats_period_picker.dart';
import '../widgets/stats_types_section.dart';
import 'stats_sections.dart';

/// The wide page: full-bleed hero and sections spanning the content area,
/// their column counts growing with the window instead of the cards.
class StatisticsViewDesktop extends StatelessWidget {
  /// Creates the wide page.
  const StatisticsViewDesktop({
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

  static const StatsLayout _layout = kStatsLayoutDesktop;

  @override
  Widget build(BuildContext context) {
    return StatsLayoutScope(
      layout: _layout,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StatsHeroDesktop(
              stats: stats,
              periodPicker: StatsPeriodPicker(data: picker),
            ),
            for (final Widget section in _sections())
              Padding(
                // Not const: Dart cannot read fields off a const object
                // inside a const expression.
                padding: EdgeInsets.fromLTRB(
                  _layout.horizontalPadding,
                  0,
                  _layout.horizontalPadding,
                  _layout.sectionGap,
                ),
                child: section,
              ),
          ],
        ),
      ),
    );
  }

  /// Everything below the hero, in order, with the empty blocks left out.
  List<Widget> _sections() {
    return <Widget>[
      if (stats.hasTypeBreakdown) StatsTypesSection(stats: stats),
      if (stats.hasMonthActivity) StatsMonthsRibbonDesktop(stats: stats),
      ...statsSectionsAfterMonths(stats, titleLanguage),
    ];
  }
}
