// Экран-хаб настроек приложения.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';
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
            title: S.of(context).settingsProfile,
            icon: Icons.person,
            compact: compact,
            children: <Widget>[
              InlineTextField(
                label: S.of(context).settingsAuthorName,
                value: settings.authorName,
                placeholder: 'User',
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
            title: S.of(context).settingsAppLanguage,
            icon: Icons.language,
            compact: compact,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
                child: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text('English'),
                    ),
                    ButtonSegment<String>(
                      value: 'ru',
                      label: Text('Русский'),
                    ),
                  ],
                  selected: <String>{settings.appLanguage},
                  onSelectionChanged: (Set<String> selected) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setAppLanguage(selected.first);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          SettingsSection(
            title: S.of(context).settingsSettings,
            icon: Icons.tune,
            compact: compact,
            children: <Widget>[
              SettingsNavRow(
                title: S.of(context).settingsCredentials,
                icon: Icons.key,
                subtitle: S.of(context).settingsCredentialsSubtitle,
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
                title: S.of(context).settingsCache,
                icon: Icons.cached,
                subtitle: S.of(context).settingsCacheSubtitle,
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
                title: S.of(context).settingsDatabase,
                icon: Icons.storage,
                subtitle: S.of(context).settingsDatabaseSubtitle,
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
                title: S.of(context).settingsTraktImport,
                icon: Icons.movie_filter,
                subtitle: S.of(context).settingsTraktImportSubtitle,
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
                  title: S.of(context).settingsDebug,
                  icon: Icons.bug_report,
                  subtitle: settings.hasSteamGridDbKey
                      ? S.of(context).settingsDebugSubtitle
                      : S.of(context).settingsDebugSubtitleNoKey,
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
            title: S.of(context).settingsHelp,
            icon: Icons.help_outline,
            compact: compact,
            children: <Widget>[
              SettingsNavRow(
                title: S.of(context).settingsWelcomeGuide,
                icon: Icons.school,
                subtitle: S.of(context).settingsWelcomeGuideSubtitle,
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
            title: S.of(context).settingsAbout,
            icon: Icons.info_outline,
            compact: compact,
            children: <Widget>[
              SettingsNavRow(
                title: S.of(context).settingsVersion,
                icon: Icons.tag,
                subtitle: _appVersion.isNotEmpty ? _appVersion : '...',
                compact: compact,
                onTap: () {},
              ),
              SettingsNavRow(
                title: S.of(context).settingsCreditsLicenses,
                icon: Icons.favorite_outline,
                subtitle: S.of(context).settingsCreditsLicensesSubtitle,
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
              title: S.of(context).settingsError,
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
