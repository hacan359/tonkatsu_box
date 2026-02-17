// Экран-хаб настроек приложения.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/breadcrumb_app_bar.dart';
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
  const SettingsScreen({
    super.key,
    this.isInitialSetup = false,
  });

  /// Флаг начальной настройки (legacy, не используется).
  final bool isInitialSetup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BreadcrumbAppBar(
        crumbs: <BreadcrumbItem>[
          BreadcrumbItem(label: 'Settings'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
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
