// Экран-хаб настроек приложения с двумя лейаутами.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../content/cache_content.dart';
import '../content/credentials_content.dart';
import '../content/credits_content.dart';
import '../content/database_content.dart';
import '../content/trakt_import_content.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_sidebar.dart';
import '../widgets/settings_tile.dart';
import '../../welcome/screens/welcome_screen.dart';
import 'cache_screen.dart';
import 'credentials_screen.dart';
import 'credits_screen.dart';
import 'database_screen.dart';
import 'trakt_import_screen.dart';
import 'debug_hub_screen.dart';

/// Breakpoint для переключения mobile / desktop лейаута.
const double _desktopBreakpoint = 800;

/// Хаб настроек приложения.
///
/// На мобильных (< 800px) — плоский список в стиле iOS Settings с push-навигацией.
/// На десктопе (>= 800px) — sidebar слева + content panel справа.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Создаёт [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';
  int _selectedIndex = 0;

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
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    if (isDesktop) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  // ==================== Mobile Layout ====================

  Widget _buildMobileLayout() {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: <Widget>[
          // PROFILE
          SettingsGroup(
            title: S.of(context).settingsProfile,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: InlineTextField(
                  label: S.of(context).settingsAuthorName,
                  value: settings.authorName,
                  placeholder: S.of(context).settingsAuthorPlaceholder,
                  compact: true,
                  onChanged: (String value) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setDefaultAuthor(value);
                  },
                ),
              ),
              SettingsTile(
                title: S.of(context).settingsAppLanguage,
                value: settings.appLanguage == 'ru' ? 'Русский' : 'English',
                onTap: () => _showLanguagePicker(settings),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // CONNECTIONS
          SettingsGroup(
            title: S.of(context).settingsConnections,
            children: <Widget>[
              SettingsTile(
                title: S.of(context).settingsApiKeys,
                value: _apiKeysValue(settings),
                onTap: () => _pushScreen(const CredentialsScreen()),
              ),
              SettingsTile(
                title: S.of(context).settingsShowRecommendations,
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

          // DATA
          SettingsGroup(
            title: S.of(context).settingsData,
            children: <Widget>[
              SettingsTile(
                title: S.of(context).settingsCache,
                onTap: () => _pushScreen(const CacheScreen()),
              ),
              SettingsTile(
                title: S.of(context).settingsDatabase,
                onTap: () => _pushScreen(const DatabaseScreen()),
              ),
              SettingsTile(
                title: S.of(context).settingsTraktImport,
                onTap: () => _pushScreen(const TraktImportScreen()),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ABOUT
          SettingsGroup(
            title: S.of(context).settingsAbout,
            children: <Widget>[
              SettingsTile(
                title: S.of(context).settingsWelcomeGuide,
                onTap: () => _pushScreen(
                  const WelcomeScreen(fromSettings: true),
                ),
              ),
              SettingsTile(
                title: S.of(context).settingsCreditsLicenses,
                onTap: () => _pushScreen(const CreditsScreen()),
              ),
              SettingsTile(
                title: S.of(context).settingsVersion,
                value: _appVersion.isNotEmpty ? _appVersion : '...',
                showChevron: false,
              ),
            ],
          ),

          // DEBUG (kDebugMode only)
          if (kDebugMode) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SettingsGroup(
              title: S.of(context).settingsDebug,
              children: <Widget>[
                SettingsTile(
                  title: S.of(context).settingsDebug,
                  value: settings.hasSteamGridDbKey
                      ? S.of(context).settingsDebugSubtitle
                      : S.of(context).settingsDebugSubtitleNoKey,
                  onTap: () => _pushScreen(const DebugHubScreen()),
                ),
              ],
            ),
          ],

          // ERROR
          if (settings.errorMessage != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SettingsGroup(
              title: S.of(context).settingsError,
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
        ],
      ),
    );
  }

  // ==================== Desktop Layout ====================

  Widget _buildDesktopLayout() {
    final S l10n = S.of(context);

    final List<SettingsSidebarItem> sidebarItems = <SettingsSidebarItem>[
      SettingsSidebarItem(id: 'profile', label: l10n.settingsProfile),
      SettingsSidebarItem(id: 'language', label: l10n.settingsAppLanguage),
      SettingsSidebarItem(id: 'apiKeys', label: l10n.settingsApiKeys),
      const SettingsSidebarItem(label: '', isSeparator: true),
      SettingsSidebarItem(id: 'cache', label: l10n.settingsCache),
      SettingsSidebarItem(id: 'database', label: l10n.settingsDatabase),
      SettingsSidebarItem(id: 'trakt', label: l10n.settingsTraktImport),
      const SettingsSidebarItem(label: '', isSeparator: true),
      SettingsSidebarItem(id: 'welcome', label: l10n.settingsWelcomeGuide),
      SettingsSidebarItem(id: 'credits', label: l10n.settingsCreditsLicenses),
      SettingsSidebarItem(id: 'about', label: l10n.settingsAbout),
      if (kDebugMode) ...<SettingsSidebarItem>[
        const SettingsSidebarItem(label: '', isSeparator: true),
        SettingsSidebarItem(id: 'debug', label: l10n.settingsDebug),
      ],
    ];

    return Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 200,
            child: SettingsSidebar(
              selectedIndex: _selectedIndex,
              onSelected: (int i) => setState(() => _selectedIndex = i),
              items: sidebarItems,
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.surfaceBorder),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: _buildContentPanel(sidebarItems),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPanel(List<SettingsSidebarItem> items) {
    final String? sectionId =
        (_selectedIndex >= 0 && _selectedIndex < items.length)
            ? items[_selectedIndex].id
            : null;

    return switch (sectionId) {
      'profile' => _buildProfileContent(),
      'language' => _buildLanguageContent(),
      'apiKeys' => const CredentialsContent(),
      'cache' => const CacheContent(),
      'database' => const DatabaseContent(),
      'trakt' => TraktImportContent(
          onImportComplete: () => setState(() {}),
        ),
      'welcome' => _buildWelcomeLink(),
      'credits' => const CreditsContent(),
      'about' => _buildAboutContent(),
      'debug' => _buildDebugLink(),
      _ => const SizedBox.shrink(),
    };
  }

  // ==================== Content Builders ====================

  Widget _buildProfileContent() {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(S.of(context).settingsProfile, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        InlineTextField(
          label: S.of(context).settingsAuthorName,
          value: settings.authorName,
          placeholder: S.of(context).settingsAuthorPlaceholder,
          compact: false,
          onChanged: (String value) {
            ref
                .read(settingsNotifierProvider.notifier)
                .setDefaultAuthor(value);
          },
        ),
      ],
    );
  }

  Widget _buildLanguageContent() {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(S.of(context).settingsAppLanguage, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
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
    );
  }

  Widget _buildAboutContent() {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(S.of(context).settingsAbout, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        _buildAboutRow(
          S.of(context).settingsVersion,
          _appVersion.isNotEmpty ? _appVersion : '...',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildAboutRow(
          S.of(context).settingsShowRecommendations,
          null,
          trailing: Switch(
            value: settings.showRecommendations,
            onChanged: (bool value) {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setShowRecommendations(enabled: value);
            },
          ),
        ),
        if (settings.errorMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            settings.errorMessage!,
            style: const TextStyle(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildAboutRow(String label, String? value, {Widget? trailing}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(label, style: AppTypography.body),
        ),
        if (value != null)
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ?trailing,
      ],
    );
  }

  Widget _buildWelcomeLink() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(S.of(context).settingsWelcomeGuide, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => _pushScreen(
            const WelcomeScreen(fromSettings: true),
          ),
          icon: const Icon(Icons.school),
          label: Text(S.of(context).settingsWelcomeGuide),
        ),
      ],
    );
  }

  Widget _buildDebugLink() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(S.of(context).settingsDebug, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => _pushScreen(const DebugHubScreen()),
          icon: const Icon(Icons.bug_report),
          label: Text(S.of(context).settingsDebug),
        ),
      ],
    );
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
}
