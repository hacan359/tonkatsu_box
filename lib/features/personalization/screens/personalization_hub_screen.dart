import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../likes/screens/likes_screen.dart';
import '../../recommendations/screens/recommendations_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../widgets/hub_likes_preview.dart';
import '../widgets/hub_recommendations_preview.dart';
import '../widgets/hub_section_card.dart';
import '../widgets/hub_stats_preview.dart';
import '../widgets/personalization_sub_screen.dart';

/// Landing page of the hub: one card per section with a live preview.
class PersonalizationHubScreen extends StatelessWidget {
  const PersonalizationHubScreen({super.key});

  static const double _wideBreakpoint = 800;
  static const double _maxContentWidth = 920;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final bool wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    return Material(
      color: AppColors.background,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: wide ? _maxContentWidth : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? AppSpacing.lg : AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.md,
                ),
                child: Text(l.personalizationTitle, style: AppTypography.h2),
              ),
              HubSectionCard(
                icon: Icons.insights_outlined,
                title: l.statsTabTitle,
                hint: l.personalizationStatsHint,
                preview: const HubStatsPreview(),
                onTap: () => pushPersonalizationSection(
                  context,
                  title: l.statsTabTitle,
                  child: const StatisticsScreen(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              HubSectionCard(
                icon: Icons.auto_awesome_outlined,
                title: l.recommendationsTitle,
                hint: l.personalizationRecommendationsHint,
                preview: const HubRecommendationsPreview(),
                onTap: () => pushPersonalizationSection(
                  context,
                  title: l.recommendationsTitle,
                  child: const RecommendationsScreen(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              HubSectionCard(
                icon: Icons.favorite_border,
                title: l.likesTitle,
                hint: l.personalizationLikesHint,
                preview: const HubLikesPreview(),
                onTap: () => pushPersonalizationSection(
                  context,
                  title: l.likesTitle,
                  child: const LikesScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
