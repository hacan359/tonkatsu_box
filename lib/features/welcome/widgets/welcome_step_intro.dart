// Шаг 1 Welcome Wizard — описание приложения.

import 'package:flutter/material.dart';

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
                  'Welcome to Tonkatsu Box',
                  style: AppTypography.h1.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Organize your collections of retro games,\n'
                  'movies, TV shows & anime',
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
            title: 'What you can do',
            child: Column(
              children: <Widget>[
                _featureRow(
                  icon: Icons.inventory_2_outlined,
                  text: 'Create collections by platform, genre, or any theme',
                  color: AppColors.gameAccent,
                ),
                _featureRow(
                  icon: Icons.search,
                  text: 'Search games, movies, TV shows & anime via APIs',
                  color: AppColors.brand,
                ),
                _featureRow(
                  icon: Icons.bar_chart,
                  text: 'Track progress, rate 1-10, add notes',
                  color: AppColors.tvShowAccent,
                ),
                _featureRow(
                  icon: Icons.palette_outlined,
                  text: 'Visual canvas boards with artwork',
                  color: AppColors.animationAccent,
                ),
                _featureRow(
                  icon: Icons.upload_outlined,
                  text: 'Export & import — share collections with friends',
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
                      'Works without API keys',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    _FeatureChip(label: 'Collections'),
                    _FeatureChip(label: 'Wishlist'),
                    _FeatureChip(label: 'Import .xcoll'),
                    _FeatureChip(label: 'Canvas boards'),
                    _FeatureChip(label: 'Ratings & notes'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'API keys are only needed for searching new games, '
                  'movies & TV shows. You can import collections and '
                  'work with them offline.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Media types
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _MediaChip(
                label: 'Games (IGDB)',
                color: AppColors.gameAccent,
              ),
              _MediaChip(
                label: 'Movies (TMDB)',
                color: AppColors.movieAccent,
              ),
              _MediaChip(
                label: 'TV Shows (TMDB)',
                color: AppColors.tvShowAccent,
              ),
              _MediaChip(
                label: 'Anime (TMDB)',
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
