// Экран-хаб настроек приложения.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../shared/constants/app_strings.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_nav_row.dart';
import '../widgets/settings_section.dart';
import '../../welcome/screens/welcome_screen.dart';
import 'cache_screen.dart';
import 'credentials_screen.dart';
import 'credits_screen.dart';
import 'database_screen.dart';
import 'trakt_import_screen.dart';
import 'debug_hub_screen.dart';

/// Хаб настроек приложения.
///
/// Содержит ссылки на подразделы: Credentials, Cache, Database, Debug.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Создаёт [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              SettingsNavRow(
                title: 'Trakt Import',
                icon: Icons.movie_filter,
                subtitle: 'Import from Trakt.tv ZIP export',
                compact: compact,
                showDivider: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const TraktImportScreen(),
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
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          SettingsSection(
            title: 'Help',
            icon: Icons.help_outline,
            compact: compact,
            children: <Widget>[
              SettingsNavRow(
                title: 'Welcome Guide',
                icon: Icons.school,
                subtitle: 'Getting started with Tonkatsu Box',
                compact: compact,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const WelcomeScreen(fromSettings: true),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          SettingsSection(
            title: 'About',
            icon: Icons.info_outline,
            compact: compact,
            children: <Widget>[
              SettingsNavRow(
                title: 'Version',
                icon: Icons.tag,
                subtitle: _appVersion.isNotEmpty ? _appVersion : '...',
                compact: compact,
                onTap: () {},
              ),
              SettingsNavRow(
                title: 'Credits & Licenses',
                icon: Icons.favorite_outline,
                subtitle: 'TMDB, IGDB, SteamGridDB, open-source licenses',
                compact: compact,
                showDivider: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const CreditsScreen(),
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
