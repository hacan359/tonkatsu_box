// Шаг 3 Welcome Wizard — структура приложения и Quick Start.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 3: How it works — структура приложения, Quick Start, экспорт.
class WelcomeStepHowItWorks extends StatelessWidget {
  /// Создаёт [WelcomeStepHowItWorks].
  const WelcomeStepHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          // Header
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.menu_book,
                  size: 36,
                  color: AppColors.brand,
                ),
                SizedBox(height: 8),
                Text(
                  'How it works',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // App structure
          _buildCard(
            title: 'App structure',
            child: Column(
              children: <Widget>[
                _tabRow(
                  icon: Icons.home,
                  tab: 'Main',
                  desc: 'All items from all collections in one view. '
                      'Filter by type, sort by rating.',
                  showDivider: false,
                ),
                _tabRow(
                  icon: Icons.collections_bookmark,
                  tab: 'Collections',
                  desc: 'Your collections. Create, organize, manage. '
                      'Grid or list view per collection.',
                ),
                _tabRow(
                  icon: Icons.bookmark,
                  tab: 'Wishlist',
                  desc: 'Quick list of items to check out later. '
                      'No API needed.',
                ),
                _tabRow(
                  icon: Icons.search,
                  tab: 'Search',
                  desc: 'Find games, movies & TV shows via API. '
                      'Add to any collection.',
                ),
                _tabRow(
                  icon: Icons.settings,
                  tab: 'Settings',
                  desc: 'API keys, cache, database export/import, '
                      'debug tools.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Quick Start
          _buildCard(
            title: 'Quick Start',
            child: const Column(
              children: <Widget>[
                _QuickStartStep(
                  number: 1,
                  text: 'Go to Settings → Credentials, enter API keys',
                ),
                _QuickStartStep(
                  number: 2,
                  text: 'Click Verify Connection, wait for platforms sync',
                ),
                _QuickStartStep(
                  number: 3,
                  text: 'Go to Collections → + New Collection',
                ),
                _QuickStartStep(
                  number: 4,
                  text: 'Name it, then Add Items → Search → Add',
                ),
                _QuickStartStep(
                  number: 5,
                  text: "Rate, track progress, add notes — you're set!",
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
                      'Sharing',
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
                      const TextSpan(text: 'Export collections as '),
                      _codeSpan('.xcoll'),
                      const TextSpan(text: ' (light, metadata only) or '),
                      _codeSpan('.xcollx'),
                      const TextSpan(
                        text: ' (full, with images & canvas — works offline). '
                            'Import from friends — no API needed!',
                      ),
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
