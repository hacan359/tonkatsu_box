// Экран управления базой данных и конфигурацией.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/config_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';

/// Экран управления базой данных.
///
/// Содержит экспорт/импорт конфигурации и сброс базы данных.
class DatabaseScreen extends ConsumerWidget {
  /// Создаёт [DatabaseScreen].
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return BreadcrumbScope(
      label: S.of(context).databaseTitle,
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildConfigSection(context, ref, compact),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              _buildDangerZoneSection(context, ref, compact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigSection(
    BuildContext context,
    WidgetRef ref,
    bool compact,
  ) {
    final S l10n = S.of(context);
    return SettingsSection(
      title: l10n.databaseConfiguration,
      icon: Icons.settings_backup_restore,
      subtitle: l10n.databaseConfigSubtitle,
      compact: compact,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
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
      ],
    );
  }

  Widget _buildDangerZoneSection(
    BuildContext context,
    WidgetRef ref,
    bool compact,
  ) {
    final S l10n = S.of(context);
    return SettingsSection(
      title: l10n.databaseDangerZone,
      icon: Icons.warning_amber,
      iconColor: AppColors.error,
      compact: compact,
      children: <Widget>[
        Text(
          l10n.databaseDangerZoneMessage,
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
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
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.databaseResetTitle),
        content: Text(l10n.databaseResetMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
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

      if (context.mounted) {
        context.showSnack(
          S.of(context).databaseReset,
          type: SnackType.success,
        );
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const NavigationShell(),
          ),
        );
      }
    }
  }
}
