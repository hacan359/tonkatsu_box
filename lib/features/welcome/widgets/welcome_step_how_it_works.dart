// Шаг 3 Welcome Wizard — структура приложения и Quick Start.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 3: How it works — структура приложения, Quick Start, экспорт.
class WelcomeStepHowItWorks extends StatelessWidget {
  /// Создаёт [WelcomeStepHowItWorks].
  const WelcomeStepHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.menu_book,
                  size: 36,
                  color: AppColors.brand,
                ),
                const SizedBox(height: 8),
                Text(
                  l.welcomeHowTitle,
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // App structure
          _buildCard(
            title: l.welcomeHowAppStructure,
            child: Column(
              children: <Widget>[
                _tabRow(
                  icon: Icons.home,
                  tab: l.navMain,
                  desc: l.welcomeHowMainDesc,
                  showDivider: false,
                ),
                _tabRow(
                  icon: Icons.collections_bookmark,
                  tab: l.navCollections,
                  desc: l.welcomeHowCollectionsDesc,
                ),
                _tabRow(
                  icon: Icons.bookmark,
                  tab: l.navWishlist,
                  desc: l.welcomeHowWishlistDesc,
                ),
                _tabRow(
                  icon: Icons.search,
                  tab: l.navSearch,
                  desc: l.welcomeHowSearchDesc,
                ),
                _tabRow(
                  icon: Icons.settings,
                  tab: l.navSettings,
                  desc: l.welcomeHowSettingsDesc,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Quick Start
          _buildCard(
            title: l.welcomeHowQuickStart,
            child: Column(
              children: <Widget>[
                _QuickStartStep(
                  number: 1,
                  text: l.welcomeHowStep1,
                ),
                _QuickStartStep(
                  number: 2,
                  text: l.welcomeHowStep2,
                ),
                _QuickStartStep(
                  number: 3,
                  text: l.welcomeHowStep3,
                ),
                _QuickStartStep(
                  number: 4,
                  text: l.welcomeHowStep4,
                ),
                _QuickStartStep(
                  number: 5,
                  text: l.welcomeHowStep5,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Sharing
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.tvShowAccent.withAlpha(12),
              border: Border.all(color: AppColors.tvShowAccent.withAlpha(30)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.upload,
                      size: 16,
                      color: AppColors.tvShowAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.welcomeHowSharing,
                      style: AppTypography.h3.copyWith(
                        fontSize: 13,
                        color: AppColors.tvShowAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: <InlineSpan>[
                      TextSpan(text: l.welcomeHowSharingDesc1),
                      _codeSpan('.xcoll'),
                      TextSpan(text: l.welcomeHowSharingDesc2),
                      _codeSpan('.xcollx'),
                      TextSpan(text: l.welcomeHowSharingDesc3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.h3.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _tabRow({
    required IconData icon,
    required String tab,
    required String desc,
    bool showDivider = true,
  }) {
    return Column(
      children: <Widget>[
        if (showDivider)
          Divider(height: 1, color: AppColors.surfaceBorder.withAlpha(100)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      tab,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      desc,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static InlineSpan _codeSpan(String text) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _QuickStartStep extends StatelessWidget {
  const _QuickStartStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.brand.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
