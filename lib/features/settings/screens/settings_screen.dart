// Экран-хаб настроек приложения с единым grouped-list лейаутом.

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
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';
import '../../welcome/screens/welcome_screen.dart';
import 'cache_screen.dart';
import 'credentials_screen.dart';
import 'credits_screen.dart';
import 'database_screen.dart';
import 'ra_import_screen.dart';
import 'steam_import_screen.dart';
import 'trakt_import_screen.dart';
import 'debug_hub_screen.dart';
import 'gamepad_debug_screen.dart';

/// Breakpoint для переключения ширины контента.
const double _desktopBreakpoint = 800;

/// Хаб настроек приложения.
///
/// Единый grouped-list лейаут для всех платформ.
/// На десктопе (>= 800px) — контент центрирован с maxWidth: 600.
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
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= _desktopBreakpoint;

    return Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? 600 : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            children: _buildSections(),
          ),
        ),
      ),
    );
  }

  // ==================== Sections ====================

  List<Widget> _buildSections() {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final S l = S.of(context);

    return <Widget>[
      // PROFILE
      SettingsGroup(
        title: l.settingsProfile,
        subtitle: l.settingsProfileSubtitle,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: InlineTextField(
              label: l.settingsAuthorName,
              value: settings.authorName,
              placeholder: l.settingsAuthorPlaceholder,
              compact: true,
              onChanged: (String value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setDefaultAuthor(value);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // APPEARANCE
      SettingsGroup(
        title: l.settingsAppearance,
        subtitle: l.settingsAppearanceSubtitle,
        children: <Widget>[
          SettingsTile(
            title: l.settingsAppLanguage,
            subtitle: l.settingsAppLanguageSubtitle,
            value: settings.appLanguage == 'ru' ? 'Русский' : 'English',
            onTap: () => _showLanguagePicker(settings),
          ),
          SettingsTile(
            title: l.settingsContentLanguage,
            subtitle: l.settingsContentLanguageSubtitle,
            value: settings.tmdbLanguage == 'ru-RU' ? 'Русский' : 'English',
            onTap: () => _showContentLanguagePicker(settings),
          ),
          SettingsTile(
            title: l.settingsShowRecommendations,
            subtitle: l.settingsShowRecommendationsSubtitle,
            showChevron: false,
            trailing: Switch(
              value: settings.showRecommendations,
              onChanged: (bool value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setShowRecommendations(enabled: value);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // DATA SOURCES
      SettingsGroup(
        title: l.settingsDataSources,
        subtitle: l.settingsDataSourcesSubtitle,
        children: <Widget>[
          SettingsTile(
            title: l.settingsApiKeys,
            subtitle: l.settingsApiKeysSubtitle,
            value: _apiKeysValue(settings),
            onTap: () => _pushScreen(const CredentialsScreen()),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // STORAGE
      SettingsGroup(
        title: l.settingsStorage,
        subtitle: l.settingsStorageSubtitle,
        children: <Widget>[
          SettingsTile(
            title: l.settingsCache,
            subtitle: l.settingsCacheSubtitle,
            onTap: () => _pushScreen(const CacheScreen()),
          ),
          SettingsTile(
            title: l.settingsDatabase,
            subtitle: l.settingsDatabaseSubtitle,
            onTap: () => _pushScreen(const DatabaseScreen()),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // IMPORT
      SettingsGroup(
        title: l.settingsImport,
        subtitle: l.settingsImportSubtitle,
        children: <Widget>[
          SettingsTile(
            title: l.settingsTraktImport,
            subtitle: l.settingsTraktImportSubtitle,
            onTap: () => _pushScreen(const TraktImportScreen()),
          ),
          SettingsTile(
            title: l.settingsSteamImport,
            subtitle: l.settingsSteamImportSubtitle,
            onTap: () => _pushScreen(const SteamImportScreen()),
          ),
          SettingsTile(
            title: l.settingsRaImport,
            subtitle: l.settingsRaImportSubtitle,
            onTap: () => _pushScreen(const RaImportScreen()),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // ABOUT
      SettingsGroup(
        title: l.settingsAbout,
        children: <Widget>[
          SettingsTile(
            title: l.settingsWelcomeGuide,
            onTap: () => _pushScreen(
              const WelcomeScreen(fromSettings: true),
            ),
          ),
          SettingsTile(
            title: l.settingsCreditsLicenses,
            onTap: () => _pushScreen(const CreditsScreen()),
          ),
          SettingsTile(
            title: l.settingsVersion,
            value: _appVersion.isNotEmpty ? _appVersion : '...',
            showChevron: false,
          ),
        ],
      ),

      // Gamepad Debug — доступен во всех окружениях
      const SizedBox(height: AppSpacing.md),
      SettingsGroup(
        title: l.settingsGamepadDebug,
        children: <Widget>[
          SettingsTile(
            title: l.settingsGamepadDebug,
            value: l.settingsGamepadDebugSubtitle,
            onTap: () => _pushScreen(const GamepadDebugScreen()),
          ),
        ],
      ),

      // DEBUG
      if (kDebugMode) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        SettingsGroup(
          title: l.settingsDebug,
          children: <Widget>[
            SettingsTile(
              title: l.settingsDebug,
              value: settings.hasSteamGridDbKey
                  ? l.settingsDebugSubtitle
                  : l.settingsDebugSubtitleNoKey,
              onTap: () => _pushScreen(const DebugHubScreen()),
            ),
          ],
        ),
      ],

      // ERROR
      if (settings.errorMessage != null) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        SettingsGroup(
          title: l.settingsError,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                settings.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ],

      const SizedBox(height: AppSpacing.md),
    ];
  }

  // ==================== Helpers ====================

  void _pushScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => screen,
      ),
    );
  }

  String _apiKeysValue(SettingsState settings) {
    int count = 0;
    if (settings.hasCredentials) count++;
    if (settings.hasSteamGridDbKey) count++;
    if (settings.hasTmdbKey) count++;
    return S.of(context).settingsApiKeysValue(count);
  }

  void _showLanguagePicker(SettingsState settings) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(S.of(context).settingsAppLanguage),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setAppLanguage('en');
              Navigator.pop(dialogContext);
            },
            child: Row(
              children: <Widget>[
                if (settings.appLanguage == 'en')
                  const Icon(Icons.check, size: 18, color: AppColors.brand)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: AppSpacing.sm),
                const Text('English'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setAppLanguage('ru');
              Navigator.pop(dialogContext);
            },
            child: Row(
              children: <Widget>[
                if (settings.appLanguage == 'ru')
                  const Icon(Icons.check, size: 18, color: AppColors.brand)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: AppSpacing.sm),
                const Text('Русский'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContentLanguagePicker(SettingsState settings) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(S.of(context).settingsContentLanguage),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setTmdbLanguage('en-US');
              Navigator.pop(dialogContext);
            },
            child: Row(
              children: <Widget>[
                if (settings.tmdbLanguage == 'en-US')
                  const Icon(Icons.check, size: 18, color: AppColors.brand)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: AppSpacing.sm),
                const Text('English'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setTmdbLanguage('ru-RU');
              Navigator.pop(dialogContext);
            },
            child: Row(
              children: <Widget>[
                if (settings.tmdbLanguage == 'ru-RU')
                  const Icon(Icons.check, size: 18, color: AppColors.brand)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: AppSpacing.sm),
                const Text('Русский'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
