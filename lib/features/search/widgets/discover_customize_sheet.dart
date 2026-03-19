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
/// Показывает только секции, доступные для текущего [sourceId].
/// Constraints (ширина и высота) задаются вызывающим кодом через
/// параметр `constraints` в [showModalBottomSheet].
class DiscoverCustomizeSheet extends ConsumerWidget {
  /// Создаёт [DiscoverCustomizeSheet].
  const DiscoverCustomizeSheet({required this.sourceId, super.key});

  /// ID текущего источника (movies, tv, anime).
  final String sourceId;

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

                // Секции — только доступные для текущей вкладки
                ..._buildAvailableSections(
                  context: context,
                  l: l,
                  notifier: notifier,
                  settings: settings,
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

  List<Widget> _buildAvailableSections({
    required BuildContext context,
    required S l,
    required DiscoverSettingsNotifier notifier,
    required DiscoverSettings settings,
  }) {
    final Set<DiscoverSectionId> available =
        discoverSectionsPerSource[sourceId] ?? <DiscoverSectionId>{};

    final Map<DiscoverSectionId, ({String label, IconData icon})> sectionMeta =
        <DiscoverSectionId, ({String label, IconData icon})>{
      DiscoverSectionId.trending: (
        label: l.discoverTrending,
        icon: Icons.local_fire_department,
      ),
      DiscoverSectionId.topRatedMovies: (
        label: l.discoverTopRatedMovies,
        icon: Icons.star,
      ),
      DiscoverSectionId.upcoming: (
        label: l.discoverUpcoming,
        icon: Icons.upcoming,
      ),
      DiscoverSectionId.popularTvShows: (
        label: l.discoverPopularTvShows,
        icon: Icons.tv,
      ),
      DiscoverSectionId.topRatedTvShows: (
        label: l.discoverTopRatedTvShows,
        icon: Icons.star_border,
      ),
      DiscoverSectionId.anime: (
        label: l.discoverAnime,
        icon: Icons.animation,
      ),
    };

    return <Widget>[
      for (final DiscoverSectionId section in available)
        if (sectionMeta.containsKey(section))
          _buildSectionToggle(
            context: context,
            notifier: notifier,
            section: section,
            label: sectionMeta[section]!.label,
            icon: sectionMeta[section]!.icon,
            isEnabled: settings.enabledSections.contains(section),
          ),
    ];
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
