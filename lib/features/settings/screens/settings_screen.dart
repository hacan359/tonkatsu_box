// Экран-хаб настроек приложения.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_strings.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../providers/settings_provider.dart';
import 'cache_screen.dart';
import 'credentials_screen.dart';
import 'database_screen.dart';
import 'debug_hub_screen.dart';

/// Хаб настроек приложения.
///
/// Содержит ссылки на подразделы: Credentials, Cache, Database, Debug.
class SettingsScreen extends ConsumerWidget {
  /// Создаёт [SettingsScreen].
  const SettingsScreen({super.key});

  Future<void> _editAuthorName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final TextEditingController controller =
        TextEditingController(text: currentName == AppStrings.defaultAuthor ? '' : currentName);

    try {
      final String? result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Author name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: AppStrings.defaultAuthor,
              helperText: 'Used as default author for new collections',
            ),
            onSubmitted: (String value) => Navigator.of(context).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result != null) {
        await ref
            .read(settingsNotifierProvider.notifier)
            .setDefaultAuthor(result);
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Author name'),
              subtitle: Text(settings.authorName),
              trailing: const Icon(Icons.edit),
              onTap: () => _editAuthorName(context, ref, settings.authorName),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Credentials'),
                  subtitle: const Text('IGDB, SteamGridDB, TMDB API keys'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const CredentialsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cached),
                  title: const Text('Cache'),
                  subtitle: const Text('Image cache settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const CacheScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Database'),
                  subtitle: const Text('Export, import, reset'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const DatabaseScreen(),
                      ),
                    );
                  },
                ),
                if (kDebugMode) ...<Widget>[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Debug'),
                    subtitle: Text(
                      settings.hasSteamGridDbKey
                          ? 'Developer tools'
                          : 'Set SteamGridDB key first for some tools',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const DebugHubScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          if (settings.errorMessage != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Card(
              color: AppColors.error.withAlpha(30),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.warning_amber, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        settings.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
