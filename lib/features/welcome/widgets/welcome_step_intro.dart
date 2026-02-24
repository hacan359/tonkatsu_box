// Шаг 1 Welcome Wizard — описание приложения.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 1: Welcome — описание приложения и возможностей.
class WelcomeStepIntro extends StatelessWidget {
  /// Создаёт [WelcomeStepIntro].
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
          // Hero
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Column(
              children: <Widget>[
                Image.asset(AppAssets.logo, width: 80, height: 80),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.welcomeTitle,
                  style: AppTypography.h1.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  l.welcomeSubtitle,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // What you can do
          _buildCard(
            title: l.welcomeWhatYouCanDo,
            child: Column(
              children: <Widget>[
                _featureRow(
                  icon: Icons.inventory_2_outlined,
                  text: l.welcomeFeatureCollections,
                  color: AppColors.gameAccent,
                ),
                _featureRow(
                  icon: Icons.search,
                  text: l.welcomeFeatureSearch,
                  color: AppColors.brand,
                ),
                _featureRow(
                  icon: Icons.bar_chart,
                  text: l.welcomeFeatureTracking,
                  color: AppColors.tvShowAccent,
                ),
                _featureRow(
                  icon: Icons.palette_outlined,
                  text: l.welcomeFeatureBoards,
                  color: AppColors.animationAccent,
                ),
                _featureRow(
                  icon: Icons.upload_outlined,
                  text: l.welcomeFeatureExport,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Works without keys
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(12),
              border: Border.all(color: AppColors.success.withAlpha(40)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.welcomeWorksWithoutKeys,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    _FeatureChip(label: l.welcomeChipCollections),
                    _FeatureChip(label: l.welcomeChipWishlist),
                    _FeatureChip(label: l.welcomeChipImport),
                    _FeatureChip(label: l.welcomeChipCanvas),
                    _FeatureChip(label: l.welcomeChipRatings),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.welcomeApiKeysHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Media types
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _MediaChip(
                label: l.welcomeChipGames,
                color: AppColors.gameAccent,
              ),
              _MediaChip(
                label: l.welcomeChipMovies,
                color: AppColors.movieAccent,
              ),
              _MediaChip(
                label: l.welcomeChipTvShows,
                color: AppColors.tvShowAccent,
              ),
              _MediaChip(
                label: l.welcomeChipAnime,
                color: AppColors.animationAccent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
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
            style: AppTypography.h3.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
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

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        border: Border.all(color: AppColors.success.withAlpha(30)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.success,
        ),
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  const _MediaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(30)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
