// Экран-хаб настроек приложения.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_strings.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_nav_row.dart';
import '../widgets/settings_section.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: ListView(
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
        children: <Widget>[
          SettingsSection(
            title: 'Profile',
            icon: Icons.person,
            compact: compact,
            children: <Widget>[
              InlineTextField(
                label: 'Author name',
                value: settings.authorName,
                placeholder: AppStrings.defaultAuthor,
                compact: compact,
                onChanged: (String value) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setDefaultAuthor(value);
                },
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          SettingsSection(
            title: 'Settings',
            icon: Icons.tune,
            compact: compact,
            children: <Widget>[
              SettingsNavRow(
                title: 'Credentials',
                icon: Icons.key,
                subtitle: 'IGDB, SteamGridDB, TMDB API keys',
                compact: compact,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const CredentialsScreen(),
                    ),
                  );
                },
              ),
              SettingsNavRow(
                title: 'Cache',
                icon: Icons.cached,
                subtitle: 'Image cache settings',
                compact: compact,
                showDivider: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const CacheScreen(),
                    ),
                  );
                },
              ),
              SettingsNavRow(
                title: 'Database',
                icon: Icons.storage,
                subtitle: 'Export, import, reset',
                compact: compact,
                showDivider: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const DatabaseScreen(),
                    ),
                  );
                },
              ),
              if (kDebugMode)
                SettingsNavRow(
                  title: 'Debug',
                  icon: Icons.bug_report,
                  subtitle: settings.hasSteamGridDbKey
                      ? 'Developer tools'
                      : 'Set SteamGridDB key first for some tools',
                  compact: compact,
                  showDivider: true,
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
          ),
          if (settings.errorMessage != null) ...<Widget>[
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            SettingsSection(
              title: 'Error',
              icon: Icons.warning_amber,
              iconColor: AppColors.error,
              compact: compact,
              children: <Widget>[
                Text(
                  settings.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
