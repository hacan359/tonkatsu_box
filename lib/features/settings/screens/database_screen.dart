// Экран управления базой данных и конфигурацией.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/config_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/breadcrumb_app_bar.dart';
import '../../collections/providers/collections_provider.dart';
import '../providers/settings_provider.dart';

/// Экран управления базой данных.
///
/// Содержит экспорт/импорт конфигурации и сброс базы данных.
class DatabaseScreen extends ConsumerWidget {
  /// Создаёт [DatabaseScreen].
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BreadcrumbAppBar(
        crumbs: <BreadcrumbItem>[
          BreadcrumbItem(
            label: 'Settings',
            onTap: () => Navigator.of(context).pop(),
          ),
          const BreadcrumbItem(label: 'Database'),
        ],
      ),
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
                    color: AppColors.gameAccent),
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
                      const SizedBox(height: 12),
                      importButton,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: exportButton),
                    const SizedBox(width: 12),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Config exported to ${result.filePath}'),
          backgroundColor: AppColors.gameAccent,
        ),
      );
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _importConfig(BuildContext context, WidgetRef ref) async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final ConfigResult result = await notifier.importConfig();

    if (!context.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Config imported successfully'),
          backgroundColor: AppColors.gameAccent,
        ),
      );
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppColors.error,
        ),
      );
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database has been reset'),
            backgroundColor: AppColors.gameAccent,
          ),
        );
        Navigator.of(context)
            .popUntil((Route<dynamic> route) => route.isFirst);
      }
    }
  }
}
