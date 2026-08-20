import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/flat_tab_bar.dart';
import '../../genre_cloud/screens/genre_cloud_screen.dart';
import '../../recommendations/screens/recommendations_screen.dart';
import '../../statistics/screens/statistics_screen.dart';

/// Which personalization view is showing.
enum _PersonalizationView { stats, cloud, recommendations }

/// Container that switches between the genre cloud and recommendations.
class PersonalizationScreen extends StatefulWidget {
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
          // No wrapper padding and no container of its own: the blocks start
          // at one screen edge and end at the other.
          FlatTabBar<_PersonalizationView>(
            selected: _view,
            onChanged: (_PersonalizationView v) => setState(() => _view = v),
            options: <FlatTabOption<_PersonalizationView>>[
              FlatTabOption<_PersonalizationView>(
                value: _PersonalizationView.stats,
                label: l.statsTabTitle,
              ),
              FlatTabOption<_PersonalizationView>(
                value: _PersonalizationView.cloud,
                label: l.personalizationTabCloud,
              ),
              FlatTabOption<_PersonalizationView>(
                value: _PersonalizationView.recommendations,
                label: l.recommendationsTitle,
              ),
            ],
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
