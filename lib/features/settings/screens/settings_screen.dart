// Settings hub screen with a single grouped-list layout.

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/ra_api.dart';
import '../../../core/services/discord_rpc_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/constants/tmdb_content_languages.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/utils/anime_manga_title_language.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../../../core/services/update_service.dart';
import '../providers/kodi_settings_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';
import '../../welcome/screens/welcome_screen.dart';
import 'cache_screen.dart';
import 'credentials_screen.dart';
import 'credits_screen.dart';
import 'database_screen.dart';
import '../../../core/services/backup_service.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../releases/providers/releases_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import 'browse_collections_screen.dart';
import 'anilist_import_screen.dart';
import 'igdb_list_import_screen.dart';
import 'mal_import_screen.dart';
import 'ra_import_screen.dart';
import 'kinorium_import_screen.dart';
import 'steam_import_screen.dart';
import 'trakt_import_screen.dart';
import 'debug_hub_screen.dart';
import 'kodi_screen.dart';
import 'profiles_screen.dart';
import '../../../shared/models/profile.dart';
import '../providers/profile_provider.dart';

/// Breakpoint for switching content width.
const double _desktopBreakpoint = 800;

// iOS-style colour palette for the settings capsule icons.
const Color _kProfileColor = Color(0xFF4A90E2);
const Color _kBackupColor = Color(0xFF42A5F5);
const Color _kStorageColor = Color(0xFF8E8E93);
const Color _kAppearanceColor = Color(0xFFA86ED4);
const Color _kApiKeysColor = Color(0xFFEF5350);
const Color _kDiscordColor = Color(0xFF5865F2); // Discord blurple (used for RA-sync Icons.sync tile)
const Color _kAboutColor = Color(0xFF8E8E93);
const Color _kDebugColor = Color(0xFFAB47BC);

/// Settings hub screen.
///
/// One grouped-list layout for all platforms; on desktop (>= 800px) the
/// content is centred at maxWidth 600.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates a [SettingsScreen].
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
    final String searchQuery = ref.watch(settingsSearchQueryProvider);

    List<Widget> sections = _buildSections();
    if (searchQuery.isNotEmpty) {
      sections = _filterSections(sections, searchQuery.toLowerCase());
    }

    return Material(
      color: Colors.transparent,
      child: Align(
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
            children: sections,
          ),
        ),
      ),
    );
  }

  /// Filters the settings sections by the search query.
  ///
  /// Keeps only [SettingsGroup]s whose title or any child [SettingsTile]
  /// contains the query.
  static List<Widget> _filterSections(List<Widget> sections, String query) {
    final List<Widget> result = <Widget>[];
    for (final Widget section in sections) {
      if (section is SettingsGroup) {
        final bool titleMatch =
            section.title?.toLowerCase().contains(query) ?? false;
        if (titleMatch) {
          result.add(section);
          continue;
        }
        final bool childMatch = section.children.any((Widget child) {
          if (child is SettingsTile) {
            return child.title.toLowerCase().contains(query) ||
                (child.subtitle?.toLowerCase().contains(query) ?? false);
          }
          return false;
        });
        if (childMatch) {
          result.add(section);
        }
      }
    }
    return result;
  }

  // ==================== Sections ====================

  List<Widget> _buildSections() {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final S l = S.of(context);
    final Profile currentProfile = ref.watch(currentProfileProvider);

    const Widget gap = SizedBox(height: AppSpacing.md);

    return <Widget>[
      SettingsGroup(
        title: l.profiles,
        titleIcon: Icons.person_outline,
        children: <Widget>[
          SettingsTile(
            leadingIcon: Icons.switch_account,
            leadingColor: _kProfileColor,
            title: l.currentProfile(currentProfile.name),
            value: '',
            onTap: () => _pushScreen(const ProfilesScreen()),
          ),
          Builder(builder: (BuildContext ctx) {
            final bool compact = isCompactScreen(ctx);
            final double bubble = compact ? 24 : 28;
            final double iconSize = compact ? 14 : 17;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: bubble,
                    height: bubble,
                    decoration: BoxDecoration(
                      color: _kProfileColor,
                      borderRadius: BorderRadius.circular(bubble * 0.25),
                    ),
                    child: Icon(
                      Icons.drive_file_rename_outline,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
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
            );
          }),
        ],
      ),
      gap,

      // Data group sits above Appearance per user feedback.
      SettingsGroup(
        title: l.settingsBackup,
        subtitle: l.settingsBackupSubtitle,
        titleIcon: Icons.cloud_outlined,
        children: <Widget>[
          SettingsTile(
            leadingIcon: Icons.cloud_upload_outlined,
            leadingColor: _kBackupColor,
            title: l.settingsBackupAll,
            subtitle: l.settingsBackupAllSubtitle,
            onTap: () => _handleBackup(context, ref, l),
          ),
          SettingsTile(
            leadingIcon: Icons.cloud_download_outlined,
            leadingColor: _kBackupColor,
            title: l.settingsRestoreBackup,
            subtitle: l.settingsRestoreBackupSubtitle,
            onTap: () => _handleRestore(context, ref, l),
          ),
        ],
      ),
      gap,
      SettingsGroup(
        title: l.settingsImport,
        subtitle: l.settingsImportSubtitle,
        titleIcon: Icons.download_outlined,
        children: <Widget>[
          SettingsTile(
            leadingAssetPath: AppAssets.iconGithub,
            leadingAssetColored: true,
            title: l.settingsBrowseCollections,
            subtitle: l.settingsBrowseCollectionsSubtitle,
            onTap: () => _pushScreen(const BrowseCollectionsScreen()),
          ),
          SettingsTile(
            leadingAssetPath: AppAssets.iconTraktColor,
            leadingAssetColored: true,
            title: l.settingsTraktImport,
            subtitle: l.settingsTraktImportSubtitle,
            onTap: () => _pushScreen(const TraktImportScreen()),
          ),
          SettingsTile(
            leadingAssetPath: AppAssets.iconKinoriumColor,
            leadingAssetColored: true,
            title: l.settingsKinoriumImport,
            subtitle: l.settingsKinoriumImportSubtitle,
            onTap: () => _pushScreen(const KinoriumImportScreen()),
          ),
          SettingsTile(
            leadingAssetPath: AppAssets.iconSteamColor,
            leadingAssetColored: true,
            title: l.settingsSteamImport,
            subtitle: l.settingsSteamImportSubtitle,
            onTap: () => _pushScreen(const SteamImportScreen()),
          ),
          SettingsTile(
            leadingAssetPath: AppAssets.iconIgdbColor,
            leadingAssetColored: true,
            title: l.settingsIgdbImport,
            subtitle: l.settingsIgdbImportSubtitle,
            onTap: () => _pushScreen(const IgdbListImportScreen()),
          ),
          SettingsTile(
            leadingAssetPath: AppAssets.iconRaColor,
            leadingAssetColored: true,
            title: l.settingsRaImport,
            subtitle: l.settingsRaImportSubtitle,
            onTap: () => _pushScreen(const RaImportScreen()),
          ),
          SettingsTile(
            leadingAssetPath: AppAssets.iconMalColor,
            leadingAssetColored: true,
            title: l.settingsMalImport,
            subtitle: l.settingsMalImportSubtitle,
            onTap: () => _pushScreen(const MalImportScreen()),
          ),
          SettingsTile(
            leadingAssetPath: AppAssets.iconAnilistColor,
            leadingAssetColored: true,
            title: l.settingsAniListImport,
            subtitle: l.settingsAniListImportSubtitle,
            onTap: () => _pushScreen(const AniListImportScreen()),
          ),
        ],
      ),
      gap,
      SettingsGroup(
        title: l.settingsStorage,
        subtitle: l.settingsStorageSubtitle,
        titleIcon: Icons.storage_outlined,
        children: <Widget>[
          SettingsTile(
            leadingIcon: Icons.image_outlined,
            leadingColor: _kStorageColor,
            title: l.settingsCache,
            subtitle: l.settingsCacheSubtitle,
            onTap: () => _pushScreen(const CacheScreen()),
          ),
          SettingsTile(
            leadingIcon: Icons.dataset_outlined,
            leadingColor: _kStorageColor,
            title: l.settingsDatabase,
            subtitle: l.settingsDatabaseSubtitle,
            onTap: () => _pushScreen(const DatabaseScreen()),
          ),
        ],
      ),
      gap,

      SettingsGroup(
        title: l.settingsAppearance,
        subtitle: l.settingsAppearanceSubtitle,
        titleIcon: Icons.palette_outlined,
        children: <Widget>[
          SettingsTile(
            leadingIcon: Icons.language,
            leadingColor: _kAppearanceColor,
            title: l.settingsAppLanguage,
            subtitle: l.settingsAppLanguageSubtitle,
            value: settings.appLanguage == 'ru' ? 'Русский' : 'English',
            onTap: () => _showLanguagePicker(settings),
          ),
          SettingsTile(
            leadingIcon: Icons.translate,
            leadingColor: _kAppearanceColor,
            title: l.settingsContentLanguage,
            subtitle: l.settingsContentLanguageSubtitle,
            value: _contentLanguageLabel(settings.tmdbLanguage),
            onTap: () => _showContentLanguagePicker(settings),
          ),
          SettingsTile(
            leadingIcon: Icons.calendar_today_outlined,
            leadingColor: _kAppearanceColor,
            title: l.settingsDateFormat,
            subtitle: l.settingsDateFormatSubtitle,
            value: _dateFormatLabel(settings.dateFormat),
            onTap: () => _showDateFormatPicker(settings),
          ),
          SettingsTile(
            leadingIcon: Icons.title,
            leadingColor: _kAppearanceColor,
            title: l.settingsAnimeMangaTitleLanguage,
            subtitle: l.settingsAnimeMangaTitleLanguageSubtitle,
            value: _animeMangaTitleLanguageLabel(l, settings.animeMangaTitleLanguage),
            onTap: () => _showAnimeMangaTitleLanguagePicker(settings),
          ),
          SettingsTile(
            leadingIcon: Icons.thumb_up_outlined,
            leadingColor: _kAppearanceColor,
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
          SettingsTile(
            leadingIcon: Icons.filter_alt_off_outlined,
            leadingColor: _kAppearanceColor,
            title: l.settingsHideEmptyMediaTypeChevrons,
            subtitle: l.settingsHideEmptyMediaTypeChevronsSubtitle,
            showChevron: false,
            trailing: Switch(
              value: settings.hideEmptyMediaTypeChevrons,
              onChanged: (bool value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setHideEmptyMediaTypeChevrons(enabled: value);
              },
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.account_tree_outlined,
            leadingColor: _kAppearanceColor,
            title: l.settingsAlwaysShowSubcategories,
            subtitle: l.settingsAlwaysShowSubcategoriesSubtitle,
            showChevron: false,
            trailing: Switch(
              value: settings.alwaysShowSubcategories,
              onChanged: (bool value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setAlwaysShowSubcategories(enabled: value);
              },
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.videogame_asset_outlined,
            leadingColor: _kAppearanceColor,
            title: l.settingsShowPlatformOverlay,
            subtitle: l.settingsShowPlatformOverlaySubtitle,
            showChevron: false,
            trailing: Switch(
              value: settings.showPlatformOverlay,
              onChanged: (bool value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setShowPlatformOverlay(enabled: value);
              },
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.album_outlined,
            leadingColor: _kAppearanceColor,
            title: l.settingsShowBlurayOverlay,
            subtitle: l.settingsShowBlurayOverlaySubtitle,
            showChevron: false,
            trailing: Switch(
              value: settings.showBlurayOverlay,
              onChanged: (bool value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setShowBlurayOverlay(enabled: value);
              },
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.auto_awesome_outlined,
            leadingColor: _kAppearanceColor,
            title: l.settingsRichCollections,
            subtitle: l.settingsRichCollectionsSubtitle,
            showChevron: false,
            trailing: Switch(
              value: settings.richCollectionsEnabled,
              onChanged: (bool value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setRichCollectionsEnabled(enabled: value);
              },
            ),
          ),
        ],
      ),
      gap,

      SettingsGroup(
        title: l.settingsDataSources,
        subtitle: l.settingsDataSourcesSubtitle,
        titleIcon: Icons.vpn_key_outlined,
        children: <Widget>[
          SettingsTile(
            leadingIcon: Icons.key,
            leadingColor: _kApiKeysColor,
            title: l.settingsApiKeys,
            subtitle: l.settingsApiKeysSubtitle,
            value: _apiKeysValue(settings),
            valueColor: _apiKeysAllSet(settings)
                ? AppColors.success
                : null,
            onTap: () => _pushScreen(const CredentialsScreen()),
          ),
        ],
      ),
      gap,
      SettingsGroup(
        title: l.settingsIntegrations,
        titleIcon: Icons.link,
        children: <Widget>[
          SettingsTile(
            leadingAssetPath: AppAssets.iconKodiColor,
            leadingAssetColored: true,
            title: 'Kodi', // proper noun
            subtitle: l.settingsKodiSubtitle,
            statusDotColor: ref.watch(kodiSettingsProvider).enabled
                ? AppColors.success
                : null,
            value: ref.watch(kodiSettingsProvider).enabled
                ? l.settingsOn
                : '',
            valueColor: ref.watch(kodiSettingsProvider).enabled
                ? AppColors.success
                : null,
            onTap: () => _pushScreen(const KodiScreen()),
          ),
          if (kDiscordRpcAvailable)
            SettingsTile(
              leadingAssetPath: AppAssets.iconDiscordColor,
              leadingAssetColored: true,
              title: l.settingsDiscordRpc,
              subtitle: l.settingsDiscordRpcSubtitle,
              showChevron: false,
              trailing: Switch(
                value: settings.discordRpcEnabled,
                onChanged: (bool value) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setDiscordRpcEnabled(enabled: value);
                  final DiscordRpcService rpc =
                      ref.read(discordRpcServiceProvider);
                  if (value) {
                    rpc.enable();
                  } else {
                    rpc.disableRaSync();
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setDiscordRaSyncEnabled(enabled: false);
                    rpc.disable();
                  }
                },
              ),
            ),
          if (kDiscordRpcAvailable &&
              settings.discordRpcEnabled &&
              ref.read(raApiProvider).hasCredentials)
            SettingsTile(
              leadingIcon: Icons.sync,
              leadingColor: _kDiscordColor,
              title: l.settingsDiscordRaSync,
              subtitle: l.settingsDiscordRaSyncSubtitle,
              showChevron: false,
              trailing: Switch(
                value: settings.discordRaSyncEnabled,
                onChanged: (bool value) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setDiscordRaSyncEnabled(enabled: value);
                  final DiscordRpcService rpc =
                      ref.read(discordRpcServiceProvider);
                  if (value) {
                    final RaApi raApi = ref.read(raApiProvider);
                    rpc.enableRaSync(
                      raApi: raApi,
                      raUsername: raApi.username!,
                    );
                  } else {
                    rpc.disableRaSync();
                  }
                },
              ),
            ),
        ],
      ),
      gap,

      SettingsGroup(
        title: l.settingsAbout,
        titleIcon: Icons.info_outline,
        children: <Widget>[
          SettingsTile(
            leadingIcon: Icons.waving_hand_outlined,
            leadingColor: _kAboutColor,
            title: l.settingsWelcomeGuide,
            onTap: () => _pushScreen(
              const WelcomeScreen(fromSettings: true),
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.article_outlined,
            leadingColor: _kAboutColor,
            title: l.settingsCreditsLicenses,
            onTap: () => _pushScreen(const CreditsScreen()),
          ),
          _buildVersionTile(l),
        ],
      ),

      if (kDebugMode) ...<Widget>[
        gap,
        SettingsGroup(
          title: l.settingsDebug,
          titleIcon: Icons.bug_report_outlined,
          children: <Widget>[
            SettingsTile(
              leadingIcon: Icons.build_outlined,
              leadingColor: _kDebugColor,
              title: l.settingsDebug,
              value: settings.hasSteamGridDbKey
                  ? l.settingsDebugSubtitle
                  : l.settingsDebugSubtitleNoKey,
              onTap: () => _pushScreen(const DebugHubScreen()),
            ),
          ],
        ),
      ],

      gap,
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

  /// Key-source states in the same order as the credentials screen sections.
  ///
  /// Built-in default keys (IGDB / SteamGridDB / TMDB, baked in at build time)
  /// don't count: the credentials screen shows them as empty "using built-in
  /// key" fields, so a fresh production install with no keys entered must read
  /// 0/6 here rather than tallying the bundled defaults the user never set.
  List<bool> _apiKeyStates(SettingsState settings) => <bool>[
        settings.hasCredentials && !settings.isIgdbKeyBuiltIn,
        settings.hasSteamGridDbKey && !settings.isSteamGridDbKeyBuiltIn,
        settings.hasTmdbKey && !settings.isTmdbKeyBuiltIn,
        settings.hasComicVineKey,
        settings.hasGoogleBooksKey,
        settings.hasScreenScraperCreds,
      ];

  String _apiKeysValue(SettingsState settings) {
    final List<bool> states = _apiKeyStates(settings);
    final int active = states.where((bool isSet) => isSet).length;
    return S.of(context).settingsApiKeysValue(active, states.length);
  }

  bool _apiKeysAllSet(SettingsState settings) =>
      _apiKeyStates(settings).every((bool isSet) => isSet);

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

  String _contentLanguageLabel(String code) {
    for (final TmdbContentLanguage lang in kTmdbContentLanguages) {
      if (lang.code == code) return lang.nativeName;
    }
    return code;
  }

  void _showContentLanguagePicker(SettingsState settings) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(S.of(context).settingsContentLanguage),
        children: <Widget>[
          for (final TmdbContentLanguage lang in kTmdbContentLanguages)
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setTmdbLanguage(lang.code);
                Navigator.pop(dialogContext);
              },
              child: Row(
                children: <Widget>[
                  if (settings.tmdbLanguage == lang.code)
                    const Icon(Icons.check, size: 18, color: AppColors.brand)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(lang.nativeName),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _dateFormatLabel(String id) {
    final DateFormatPreset preset = DateFormatPreset.fromId(id);
    final DateTime sample = DateTime(2026, 5, 25);
    return preset.format(
      sample,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
  }

  void _showDateFormatPicker(SettingsState settings) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final String localeName =
            Localizations.localeOf(context).toLanguageTag();
        final DateTime sample = DateTime(2026, 5, 25);
        return SimpleDialog(
          title: Text(S.of(context).settingsDateFormat),
          children: <Widget>[
            for (final DateFormatPreset preset in DateFormatPreset.values)
              SimpleDialogOption(
                onPressed: () {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setDateFormat(preset.id);
                  Navigator.pop(dialogContext);
                },
                child: Row(
                  children: <Widget>[
                    if (settings.dateFormat == preset.id)
                      const Icon(Icons.check, size: 18, color: AppColors.brand)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(preset.format(sample, locale: localeName)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _animeMangaTitleLanguageLabel(S l, String id) {
    switch (AnimeMangaTitleLanguage.fromId(id)) {
      case AnimeMangaTitleLanguage.english:
        return l.settingsAnimeMangaTitleLanguageEnglish;
      case AnimeMangaTitleLanguage.native:
        return l.settingsAnimeMangaTitleLanguageNative;
      case AnimeMangaTitleLanguage.romaji:
        return l.settingsAnimeMangaTitleLanguageRomaji;
    }
  }

  void _showAnimeMangaTitleLanguagePicker(SettingsState settings) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final S l = S.of(context);
        return SimpleDialog(
          title: Text(l.settingsAnimeMangaTitleLanguage),
          children: <Widget>[
            for (final AnimeMangaTitleLanguage v in AnimeMangaTitleLanguage.values)
              SimpleDialogOption(
                onPressed: () {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setAnimeMangaTitleLanguage(v.id);
                  Navigator.pop(dialogContext);
                },
                child: Row(
                  children: <Widget>[
                    if (settings.animeMangaTitleLanguage == v.id)
                      const Icon(Icons.check, size: 18, color: AppColors.brand)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_animeMangaTitleLanguageLabel(l, v.id)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVersionTile(S l) {
    final UpdateInfo? updateInfo =
        ref.watch(updateCheckProvider).valueOrNull;
    final bool hasUpdate = updateInfo?.hasUpdate ?? false;
    final String versionText = _appVersion.isNotEmpty ? _appVersion : '...';

    if (!hasUpdate) {
      return SettingsTile(
        title: l.settingsVersion,
        value: versionText,
        showChevron: false,
      );
    }

    return SettingsTile(
      title: l.updateAvailable(updateInfo!.latestVersion),
      value: l.updateCurrent(versionText),
      titleColor: AppColors.statusInProgress,
      onTap: () => _showUpdateWarning(l, updateInfo.releaseUrl),
    );
  }

  void _showUpdateWarning(S l, String releaseUrl) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Row(
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(l.updateWarningTitle)),
          ],
        ),
        content: Text(l.updateWarningBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              launchUrl(
                Uri.parse(releaseUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l.updateWarningProceed),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup(
    BuildContext context,
    WidgetRef ref,
    S l,
  ) async {
    context.showSnack(
      l.settingsBackupAll,
      loading: true,
      duration: const Duration(seconds: 60),
    );

    final BackupService service = ref.read(backupServiceProvider);
    final BackupResult result = await service.createBackup();

    if (!context.mounted) return;

    if (result.success) {
      context.showSnack(
        l.backupSuccess(result.collectionsCount, result.itemsCount),
        type: SnackType.success,
      );
    } else if (!result.isCancelled) {
      context.showSnack(
        result.error ?? 'Backup failed',
        type: SnackType.error,
      );
    } else {
      context.hideSnack();
    }
  }

  Future<void> _handleRestore(
    BuildContext context,
    WidgetRef ref,
    S l,
  ) async {
    // 1. Pick the file.
    final bool useAny = defaultTargetPlatform == TargetPlatform.android;
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      dialogTitle: l.settingsRestoreBackup,
      type: useAny ? FileType.any : FileType.custom,
      allowedExtensions: useAny ? null : <String>['zip'],
      allowMultiple: false,
    );

    if (picked == null || picked.files.isEmpty) return;
    final String? zipPath = picked.files.first.path;
    if (zipPath == null) return;

    // 2. Read the manifest.
    final BackupService service = ref.read(backupServiceProvider);
    final BackupManifest? manifest = await service.readManifest(zipPath);

    if (manifest == null) {
      if (context.mounted) {
        context.showSnack(l.restoreInvalidArchive, type: SnackType.error);
      }
      return;
    }

    // 3. Confirmation dialog.
    if (!context.mounted) return;
    final _RestoreOptions? options = await showDialog<_RestoreOptions>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool restoreWishlist = true;
        bool restoreSettings = false;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setState) {
            final S dl = S.of(ctx);
            return AlertDialog(
              title: Text(dl.restoreConfirmTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(dl.restoreConfirmBody(
                    manifest.collectionsCount,
                    manifest.itemsCount,
                    manifest.wishlistCount,
                  )),
                  const SizedBox(height: 8),
                  Text(
                    dl.restoreConfirmHint,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: restoreWishlist,
                    onChanged: (bool? v) =>
                        setState(() => restoreWishlist = v ?? true),
                    title: Text(dl.restoreWishlist),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  if (manifest.includesConfig)
                    CheckboxListTile(
                      value: restoreSettings,
                      onChanged: (bool? v) =>
                          setState(() => restoreSettings = v ?? false),
                      title: Text(dl.restoreSettings),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(dl.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    _RestoreOptions(
                      restoreWishlist: restoreWishlist,
                      restoreSettings: restoreSettings,
                    ),
                  ),
                  child: Text(dl.restore),
                ),
              ],
            );
          },
        );
      },
    );

    if (options == null) return;

    // 4. Run the restore.
    if (!context.mounted) return;

    final ValueNotifier<BackupProgress?> progressNotifier =
        ValueNotifier<BackupProgress?>(null);

    // Modal blocking dialog runs concurrently with the await below.
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext _) =>
          _RestoreProgressDialog(progress: progressNotifier),
    ));

    ref.read(restoreInProgressProvider.notifier).state = true;
    RestoreResult result;
    try {
      result = await service.restoreFromBackup(
        zipPath: zipPath,
        restoreWishlist: options.restoreWishlist,
        restoreSettings: options.restoreSettings,
        onProgress: (BackupProgress p) => progressNotifier.value = p,
      );
    } finally {
      ref.read(restoreInProgressProvider.notifier).state = false;
      if (navigator.canPop()) navigator.pop();
      progressNotifier.dispose();
    }

    if (!context.mounted) return;

    if (result.success) {
      // Refresh derived state so the UI reflects the restored data.
      ref.invalidate(collectionsProvider);
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);
      ref.invalidate(releasesProvider);

      context.showSnack(
        l.restoreSuccess(result.collectionsRestored, result.itemsRestored),
        type: SnackType.success,
        duration: const Duration(seconds: 4),
      );
    } else if (!result.isCancelled) {
      context.showSnack(
        result.error ?? 'Restore failed',
        type: SnackType.error,
      );
    } else {
      context.hideSnack();
    }
  }
}

/// Modal, dismiss-locked progress dialog shown while a backup is being
/// restored. Blocks back/system-back via PopScope so the user can't kill
/// the app mid-write.
class _RestoreProgressDialog extends StatelessWidget {
  const _RestoreProgressDialog({required this.progress});

  final ValueListenable<BackupProgress?> progress;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l.restoreProgressTitle),
        content: ValueListenableBuilder<BackupProgress?>(
          valueListenable: progress,
          builder: (BuildContext context, BackupProgress? p, _) {
            final String stageText = _stageLabel(l, p);
            final double? value = p == null || p.total == 0
                ? null
                : (p.current / p.total).clamp(0.0, 1.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.restoreProgressWarning,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(value: value),
                const SizedBox(height: AppSpacing.sm),
                Text(stageText),
                if (p?.collectionName != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    p!.collectionName!,
                    style: const TextStyle(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _stageLabel(S l, BackupProgress? p) {
    if (p == null) return l.restoreStageReading;
    switch (p.stage) {
      case 'collections':
        return l.restoreStageCollections(p.current, p.total);
      case 'wishlist':
        return l.restoreStageWishlist;
      case 'settings':
        return l.restoreStageSettings;
      case 'finalizing':
        return l.restoreStageFinalizing;
      default:
        return p.stage;
    }
  }
}

/// Restore options chosen in the confirmation dialog.
class _RestoreOptions {
  const _RestoreOptions({
    required this.restoreWishlist,
    required this.restoreSettings,
  });

  final bool restoreWishlist;
  final bool restoreSettings;
}
