// Экран управления базой данных и конфигурацией.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/config_service.dart';
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

/// Экран управления базой данных.
///
/// Содержит экспорт/импорт конфигурации и сброс базы данных.
class DatabaseScreen extends ConsumerWidget {
  /// Создаёт [DatabaseScreen].
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BreadcrumbScope(
      label: 'Database',
      child: Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildConfigSection(context, ref),
            const SizedBox(height: AppSpacing.lg),
            _buildDangerZoneSection(context, ref),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildConfigSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.settings_backup_restore,
                    color: AppColors.brand),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Configuration',
                    style: AppTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Export or import your API keys and settings.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget exportButton = OutlinedButton.icon(
                  onPressed: () => _exportConfig(context, ref),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Export Config'),
                );
                final Widget importButton = OutlinedButton.icon(
                  onPressed: () => _importConfig(context, ref),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Import Config'),
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
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.warning_amber, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Danger Zone',
                  style: AppTypography.h3.copyWith(color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Clears all collections, games, movies, TV shows and board data. '
              'Settings and API keys will be preserved.',
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
                label: const Text('Reset Database'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportConfig(BuildContext context, WidgetRef ref) async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final ConfigResult result = await notifier.exportConfig();

    if (!context.mounted) return;

    if (result.success) {
      context.showAppSnackBar('Config exported to ${result.filePath}');
    } else if (result.error != null) {
      context.showAppSnackBar(result.error!, isError: true);
    }
  }

  Future<void> _importConfig(BuildContext context, WidgetRef ref) async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final ConfigResult result = await notifier.importConfig();

    if (!context.mounted) return;

    if (result.success) {
      context.showAppSnackBar('Config imported successfully');
    } else if (result.error != null) {
      context.showAppSnackBar(result.error!, isError: true);
    }
  }

  Future<void> _resetDatabase(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: const Text('Reset Database?'),
        content: const Text(
          'This will permanently delete all your collections, games, '
          'movies, TV shows, episode progress, and board data.\n\n'
          'Your API keys and settings will be preserved.\n\n'
          'This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Reset'),
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
        context.showAppSnackBar('Database has been reset');
        // Заменяем NavigationShell целиком, чтобы сбросить стеки
        // навигации всех табов (а не только текущего Settings).
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const NavigationShell(),
          ),
        );
      }
    }
  }
}
