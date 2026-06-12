// Final wizard step: a short intro to the interactive menu tour. Both actions
// close the wizard; [onStart] also kicks off the coachmark that plays over the
// real navigation in [AppShell], while [onSkip] just finishes.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import 'welcome_hero.dart';

/// Intro page for the menu tour shown as the last wizard step.
class WelcomeStepMenuTour extends StatelessWidget {
  /// Creates a [WelcomeStepMenuTour].
  const WelcomeStepMenuTour({
    required this.onStart,
    required this.onSkip,
    super.key,
  });

  /// Finishes the wizard and starts the menu tour over the real app.
  final VoidCallback onStart;

  /// Finishes the wizard without the tour.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.lg),
          WelcomeHero(
            icon: Icons.explore_outlined,
            title: l.welcomeTourTitle,
            subtitle: l.welcomeTourSubtitle,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.black,
              // The theme makes FilledButtons full-width; pin a content min so
              // this one sizes to its label.
              minimumSize: const Size(0, AppSpacing.buttonHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l.welcomeTourStart,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.rocket_launch, size: 18),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
            ),
            child: Text(
              l.welcomeReadySkip,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
