import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/config_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../releases/providers/releases_provider.dart';
import '../../tier_lists/providers/mood_grids_provider.dart';
import '../../tier_lists/providers/tier_lists_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/lan_sync_screen.dart';
import '../widgets/backup_section.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';
import '../widgets/storage_location_section.dart';

class DatabaseContent extends ConsumerWidget {
  const DatabaseContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsGroup(
          title: l10n.databaseConfiguration,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                l10n.databaseConfigSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: LayoutBuilder(
                builder:
                    (BuildContext context, BoxConstraints constraints) {
                  final Widget exportButton = OutlinedButton.icon(
                    onPressed: () => _exportConfig(context, ref),
                    icon: const Icon(Icons.upload, size: 18),
                    label: Text(l10n.databaseExportConfig),
                  );
                  final Widget importButton = OutlinedButton.icon(
                    onPressed: () => _importConfig(context, ref),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.databaseImportConfig),
                  );
                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        exportButton,
                        const SizedBox(height: AppSpacing.sm),
                        importButton,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: exportButton),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: importButton),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        const StorageLocationSection(),
        const SizedBox(height: AppSpacing.md),

        SettingsGroup(
          title: l10n.lanSyncTitle,
          children: <Widget>[
            SettingsTile(
              title: l10n.lanSyncOpenTile,
              subtitle: l10n.lanSyncTileSubtitle,
              leadingIcon: Icons.devices,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const LanSyncScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        const BackupSection(),
        const SizedBox(height: AppSpacing.md),

        SettingsGroup(
          title: l10n.databaseDangerZone,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                l10n.databaseDangerZoneMessage,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _resetDatabase(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: Text(l10n.databaseResetDatabase),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportConfig(BuildContext context, WidgetRef ref) async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final ConfigResult result = await notifier.exportConfig();

    if (!context.mounted) return;

    if (result.success) {
      context.showSnack(
        S.of(context).databaseConfigExported(result.filePath ?? ''),
        type: SnackType.success,
      );
    } else if (result.error != null) {
      context.showSnack(result.error!, type: SnackType.error);
    }
  }

  Future<void> _importConfig(BuildContext context, WidgetRef ref) async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final ConfigResult result = await notifier.importConfig();

    if (!context.mounted) return;

    if (result.success) {
      context.showSnack(
        S.of(context).databaseConfigImported,
        type: SnackType.success,
      );
    } else if (result.error != null) {
      context.showSnack(result.error!, type: SnackType.error);
    }
  }

  Future<void> _resetDatabase(BuildContext context, WidgetRef ref) async {
    final S l10n = S.of(context);
    final bool confirm = await ConfirmDialog.show(
      context,
      title: l10n.databaseResetTitle,
      message: l10n.databaseResetMessage,
      confirmLabel: l10n.reset,
    );

    if (confirm && context.mounted) {
      final SettingsNotifier notifier =
          ref.read(settingsNotifierProvider.notifier);
      await notifier.flushDatabase();

      ref.invalidate(collectionsProvider);
      ref.invalidate(uncategorizedItemCountProvider);
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(collectedGameIdsProvider);
      ref.invalidate(collectedMovieIdsProvider);
      ref.invalidate(collectedTvShowIdsProvider);
      ref.invalidate(collectedAnimationIdsProvider);
      ref.invalidate(collectedVisualNovelIdsProvider);
      ref.invalidate(collectedMangaIdsProvider);
      ref.invalidate(wishlistProvider);
      ref.invalidate(tierListsProvider);
      ref.invalidate(moodGridsProvider);
      ref.invalidate(releasesProvider);

      if (context.mounted) {
        context.showSnack(
          S.of(context).databaseReset,
          type: SnackType.success,
        );
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const AppShell(),
          ),
        );
      }
    }
  }
}
