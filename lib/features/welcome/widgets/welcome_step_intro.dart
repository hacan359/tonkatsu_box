import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'welcome_card.dart';
import 'welcome_chip.dart';
import 'welcome_hero.dart';
import 'welcome_reveal.dart';

/// Welcome — app intro, feature highlights and media types.
class WelcomeStepIntro extends StatelessWidget {
  const WelcomeStepIntro({super.key});

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
          WelcomeReveal(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: WelcomeHero(
                asset: AppAssets.logo,
                title: l.welcomeTitle,
                subtitle: l.welcomeSubtitle,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          WelcomeReveal(
            index: 1,
            child: WelcomeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.welcomeWhatYouCanDo,
                    style: AppTypography.h3.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FeatureRow(
                    icon: Icons.inventory_2_outlined,
                    text: l.welcomeFeatureCollections,
                    color: AppColors.gameAccent,
                  ),
                  _FeatureRow(
                    icon: Icons.search,
                    text: l.welcomeFeatureSearch,
                    color: AppColors.brand,
                  ),
                  _FeatureRow(
                    icon: Icons.bar_chart,
                    text: l.welcomeFeatureTracking,
                    color: AppColors.tvShowAccent,
                  ),
                  _FeatureRow(
                    icon: Icons.palette_outlined,
                    text: l.welcomeFeatureBoards,
                    color: AppColors.animationAccent,
                  ),
                  _FeatureRow(
                    icon: Icons.upload_outlined,
                    text: l.welcomeFeatureExport,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          WelcomeReveal(
            index: 2,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: <Widget>[
                WelcomeChip(
                  label: l.welcomeChipGames,
                  color: AppColors.gameAccent,
                ),
                WelcomeChip(
                  label: l.welcomeChipMovies,
                  color: AppColors.movieAccent,
                ),
                WelcomeChip(
                  label: l.welcomeChipTvShows,
                  color: AppColors.tvShowAccent,
                ),
                WelcomeChip(
                  label: l.welcomeChipAnime,
                  color: AppColors.animeAccent,
                ),
                WelcomeChip(
                  label: l.welcomeChipVisualNovels,
                  color: AppColors.visualNovelAccent,
                ),
                WelcomeChip(
                  label: l.welcomeChipManga,
                  color: AppColors.mangaAccent,
                ),
                WelcomeChip(
                  label: l.welcomeChipBooks,
                  color: AppColors.bookAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
