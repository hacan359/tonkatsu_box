// Personalization hub opened from the centre nav button: two views over the
// whole library — the genre cloud (a taste *picture*) and recommendations
// (taste *acted on*). The two are switched with a segmented pill (the same
// switcher style as the item-detail status row); it does not touch the app's
// primary navigation. An IndexedStack keeps both alive so the cloud's pan/zoom
// and the recs' fetched state survive a switch.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../../genre_cloud/screens/genre_cloud_screen.dart';
import '../../recommendations/screens/recommendations_screen.dart';

/// Which personalization view is showing.
enum _PersonalizationView { cloud, recommendations }

/// Container that switches between the genre cloud and recommendations.
class PersonalizationScreen extends StatefulWidget {
  /// Creates a [PersonalizationScreen].
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  _PersonalizationView _view = _PersonalizationView.cloud;

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
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedPill<_PersonalizationView>(
                selected: _view,
                onChanged: (_PersonalizationView v) =>
                    setState(() => _view = v),
                options: <SegmentedPillOption<_PersonalizationView>>[
                  SegmentedPillOption<_PersonalizationView>(
                    value: _PersonalizationView.cloud,
                    label: l.personalizationTabCloud,
                  ),
                  SegmentedPillOption<_PersonalizationView>(
                    value: _PersonalizationView.recommendations,
                    label: l.personalizationTabRecommendations,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _view.index,
              children: const <Widget>[
                GenreCloudScreen(showTitle: false),
                RecommendationsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
