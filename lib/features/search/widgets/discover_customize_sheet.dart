import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/discover_provider.dart';

/// Shows only sections available for the current [mediaType]; sizing comes
/// from the `constraints` the caller passes to [showModalBottomSheet].
class DiscoverCustomizeSheet extends ConsumerWidget {
  const DiscoverCustomizeSheet({required this.mediaType, super.key});

  final MediaType mediaType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final DiscoverSettings settings = ref.watch(discoverSettingsProvider);
    final DiscoverSettingsNotifier notifier =
        ref.read(discoverSettingsProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withAlpha(102),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
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

                ..._buildAvailableSections(
                  context: context,
                  l: l,
                  notifier: notifier,
                  settings: settings,
                ),

                const SizedBox(height: AppSpacing.lg),

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

        // Buttons stay pinned below the scrollable content.
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
        discoverSectionsPerMediaType[mediaType] ?? <DiscoverSectionId>{};

    return <Widget>[
      for (final DiscoverSectionId section in available)
        _buildSectionToggle(
          context: context,
          notifier: notifier,
          section: section,
          label: section.localizedLabel(l),
          icon: section.icon,
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
