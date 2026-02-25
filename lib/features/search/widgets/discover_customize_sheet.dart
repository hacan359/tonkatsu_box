// Bottom sheet для настройки секций Discover.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/discover_provider.dart';

/// Bottom sheet для настройки секций Discover.
///
/// Constraints (ширина и высота) задаются вызывающим кодом через
/// параметр `constraints` в [showModalBottomSheet].
class DiscoverCustomizeSheet extends ConsumerWidget {
  /// Создаёт [DiscoverCustomizeSheet].
  const DiscoverCustomizeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final DiscoverSettings settings = ref.watch(discoverSettingsProvider);
    final DiscoverSettingsNotifier notifier =
        ref.read(discoverSettingsProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Скроллируемый контент
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Ручка
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withAlpha(102),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  l.discoverCustomizeTitle,
                  style:
                      AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.discoverCustomizeHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Секции
                _buildSectionToggle(
                  context: context,
                  notifier: notifier,
                  section: DiscoverSectionId.trending,
                  label: l.discoverTrending,
                  icon: Icons.local_fire_department,
                  isEnabled: settings.enabledSections
                      .contains(DiscoverSectionId.trending),
                ),
                _buildSectionToggle(
                  context: context,
                  notifier: notifier,
                  section: DiscoverSectionId.topRatedMovies,
                  label: l.discoverTopRatedMovies,
                  icon: Icons.star,
                  isEnabled: settings.enabledSections
                      .contains(DiscoverSectionId.topRatedMovies),
                ),
                _buildSectionToggle(
                  context: context,
                  notifier: notifier,
                  section: DiscoverSectionId.popularTvShows,
                  label: l.discoverPopularTvShows,
                  icon: Icons.tv,
                  isEnabled: settings.enabledSections
                      .contains(DiscoverSectionId.popularTvShows),
                ),
                _buildSectionToggle(
                  context: context,
                  notifier: notifier,
                  section: DiscoverSectionId.upcoming,
                  label: l.discoverUpcoming,
                  icon: Icons.upcoming,
                  isEnabled: settings.enabledSections
                      .contains(DiscoverSectionId.upcoming),
                ),
                _buildSectionToggle(
                  context: context,
                  notifier: notifier,
                  section: DiscoverSectionId.anime,
                  label: l.discoverAnime,
                  icon: Icons.animation,
                  isEnabled: settings.enabledSections
                      .contains(DiscoverSectionId.anime),
                ),
                _buildSectionToggle(
                  context: context,
                  notifier: notifier,
                  section: DiscoverSectionId.topRatedTvShows,
                  label: l.discoverTopRatedTvShows,
                  icon: Icons.star_border,
                  isEnabled: settings.enabledSections
                      .contains(DiscoverSectionId.topRatedTvShows),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Режим отображения уже добавленных
                Text(
                  l.discoverAlreadyInCollection,
                  style:
                      AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                RadioGroup<bool>(
                  groupValue: settings.hideOwned,
                  onChanged: (bool? value) {
                    if (value != null) {
                      notifier.setHideOwned(value: value);
                    }
                  },
                  child: Column(
                    children: <Widget>[
                      RadioListTile<bool>(
                        title: Text(l.discoverShowWithBadge),
                        value: false,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      RadioListTile<bool>(
                        title: Text(l.discoverHideCompletely),
                        value: true,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Кнопки — фиксированы внизу
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                ),
                onPressed: () => notifier.resetToDefault(),
                child: Text(l.discoverResetDefault),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.done),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionToggle({
    required BuildContext context,
    required DiscoverSettingsNotifier notifier,
    required DiscoverSectionId section,
    required String label,
    required IconData icon,
    required bool isEnabled,
  }) {
    return SwitchListTile(
      title: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
        ],
      ),
      value: isEnabled,
      onChanged: (_) => notifier.toggleSection(section),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
