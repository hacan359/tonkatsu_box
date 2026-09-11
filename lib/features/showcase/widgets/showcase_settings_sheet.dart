import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/showcase_settings_provider.dart';
import 'showcase_group_title.dart';

/// Sizing comes from the `constraints` the caller passes to
/// [showModalBottomSheet].
class ShowcaseSettingsSheet extends ConsumerWidget {
  const ShowcaseSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      constraints: BoxConstraints(
        maxWidth: screenSize.width,
        maxHeight: screenSize.height * 0.85,
      ),
      builder: (BuildContext _) => const ShowcaseSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final ShowcaseSettings settings = ref.watch(showcaseSettingsProvider);
    final ShowcaseSettingsNotifier notifier =
        ref.read(showcaseSettingsProvider.notifier);

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
                  l.showcaseSettingsTitle,
                  style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.showcaseSettingsHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final ShowcaseGroup group in ShowcaseGroup.values) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      showcaseGroupLabel(l, group),
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final ShowcaseRowId row in ShowcaseRowId.inGroup(group))
                    SwitchListTile(
                      key: ValueKey<String>('showcase_row_${row.key}'),
                      title: Row(
                        children: <Widget>[
                          Icon(row.icon, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(row.localizedLabel(l))),
                        ],
                      ),
                      value: settings.isEnabled(row),
                      onChanged: (_) => notifier.toggleRow(row),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l.showcaseAlreadyInCollection,
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                RadioGroup<bool>(
                  groupValue: settings.hideOwned,
                  onChanged: (bool? value) {
                    if (value != null) notifier.setHideOwned(value: value);
                  },
                  child: Column(
                    children: <Widget>[
                      RadioListTile<bool>(
                        title: Text(l.showcaseShowWithBadge),
                        value: false,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      RadioListTile<bool>(
                        title: Text(l.showcaseHideCompletely),
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
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextButton(
                style: TextButton.styleFrom(minimumSize: Size.zero),
                onPressed: () => notifier.resetToDefault(),
                child: Text(l.showcaseResetDefault),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: Size.zero),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.done),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
