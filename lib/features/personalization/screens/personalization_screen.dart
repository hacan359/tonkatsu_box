import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../../genre_cloud/screens/genre_cloud_screen.dart';
import '../../recommendations/screens/recommendations_screen.dart';
import '../../statistics/screens/statistics_screen.dart';

/// Which personalization view is showing.
enum _PersonalizationView { stats, cloud, recommendations }

/// Container that switches between the genre cloud and recommendations.
class PersonalizationScreen extends StatefulWidget {
  /// Creates a [PersonalizationScreen].
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  _PersonalizationView _view = _PersonalizationView.stats;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Material(
      color: AppColors.background,
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
              ),
            ),
            // Scrollable: three localized labels outgrow narrow phones.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedPill<_PersonalizationView>(
                selected: _view,
                onChanged: (_PersonalizationView v) =>
                    setState(() => _view = v),
                options: <SegmentedPillOption<_PersonalizationView>>[
                  SegmentedPillOption<_PersonalizationView>(
                    value: _PersonalizationView.stats,
                    label: l.statsTabTitle,
                  ),
                  SegmentedPillOption<_PersonalizationView>(
                    value: _PersonalizationView.cloud,
                    label: l.personalizationTabCloud,
                  ),
                  SegmentedPillOption<_PersonalizationView>(
                    value: _PersonalizationView.recommendations,
                    label: l.recommendationsTitle,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (_view) {
              _PersonalizationView.stats => const StatisticsScreen(),
              _PersonalizationView.cloud =>
                const GenreCloudScreen(showTitle: false),
              _PersonalizationView.recommendations =>
                const RecommendationsScreen(),
            },
          ),
        ],
      ),
    );
  }
}
