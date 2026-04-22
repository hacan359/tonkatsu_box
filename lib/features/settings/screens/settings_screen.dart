// Экран-хаб настроек приложения с единым grouped-list лейаутом.

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
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
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
import '../../wishlist/providers/wishlist_provider.dart';
import 'browse_collections_screen.dart';
import 'ra_import_screen.dart';
import 'steam_import_screen.dart';
import 'trakt_import_screen.dart';
import 'debug_hub_screen.dart';
import 'kodi_screen.dart';
import 'profiles_screen.dart';
import '../../../shared/models/profile.dart';
import '../providers/profile_provider.dart';

/// Breakpoint для переключения ширины контента.
const double _desktopBreakpoint = 800;

// iOS-style цветовая палитра для capsule-иконок в настройках.
const Color _kProfileColor = Color(0xFF4A90E2); // синий
const Color _kBackupColor = Color(0xFF42A5F5); // голубой
const Color _kImportColor = Color(0xFFFFA726); // оранжевый
const Color _kStorageColor = Color(0xFF8E8E93); // серый
const Color _kAppearanceColor = Color(0xFFA86ED4); // фиолетовый
const Color _kApiKeysColor = Color(0xFFEF5350); // красный
const Color _kIntegrationColor = Color(0xFF66BB6A); // зелёный
const Color _kDiscordColor = Color(0xFF5865F2); // Discord blurple
const Color _kAboutColor = Color(0xFF8E8E93); // серый
const Color _kDebugColor = Color(0xFFAB47BC); // пурпурный

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

  /// Фильтрует секции настроек по поисковому запросу.
  ///
  /// Оставляет только [SettingsGroup], у которых title или любой дочерний
  /// [SettingsTile] содержит query.
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
      // ============ ПРОФИЛЬ ============
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _kProfileColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    size: 17,
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
          ),
        ],
      ),
      gap,

      // ============ ДАННЫЕ (поднято выше по фидбеку) ============
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
            leadingIcon: Icons.travel_explore,
            leadingColor: _kImportColor,
            title: l.settingsBrowseCollections,
            subtitle: l.settingsBrowseCollectionsSubtitle,
            onTap: () => _pushScreen(const BrowseCollectionsScreen()),
          ),
          SettingsTile(
            leadingIcon: Icons.movie_filter_outlined,
            leadingColor: _kImportColor,
            title: l.settingsTraktImport,
            subtitle: l.settingsTraktImportSubtitle,
            onTap: () => _pushScreen(const TraktImportScreen()),
          ),
          SettingsTile(
            leadingIcon: Icons.sports_esports_outlined,
            leadingColor: _kImportColor,
            title: l.settingsSteamImport,
            subtitle: l.settingsSteamImportSubtitle,
            onTap: () => _pushScreen(const SteamImportScreen()),
          ),
          SettingsTile(
            leadingIcon: Icons.emoji_events_outlined,
            leadingColor: _kImportColor,
            title: l.settingsRaImport,
            subtitle: l.settingsRaImportSubtitle,
            onTap: () => _pushScreen(const RaImportScreen()),
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

      // ============ ОФОРМЛЕНИЕ ============
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
            value: settings.tmdbLanguage == 'ru-RU' ? 'Русский' : 'English',
            onTap: () => _showContentLanguagePicker(settings),
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

      // ============ СЕРВИСЫ ============
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
            leadingIcon: Icons.cast,
            leadingColor: _kIntegrationColor,
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
              leadingIcon: Icons.chat_bubble_outline,
              leadingColor: _kDiscordColor,
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

      // ============ О ПРИЛОЖЕНИИ ============
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

  String _apiKeysValue(SettingsState settings) {
    int count = 0;
    if (settings.hasCredentials) count++;
    if (settings.hasSteamGridDbKey) count++;
    if (settings.hasTmdbKey) count++;
    return S.of(context).settingsApiKeysValue(count);
  }

  bool _apiKeysAllSet(SettingsState settings) =>
      settings.hasCredentials &&
      settings.hasSteamGridDbKey &&
      settings.hasTmdbKey;

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
    // 1. Выбор файла
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

    // 2. Читаем манифест
    final BackupService service = ref.read(backupServiceProvider);
    final BackupManifest? manifest = await service.readManifest(zipPath);

    if (manifest == null) {
      if (context.mounted) {
        context.showSnack(l.restoreInvalidArchive, type: SnackType.error);
      }
      return;
    }

    // 3. Диалог подтверждения
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

    // 4. Выполнение восстановления
    if (!context.mounted) return;
    context.showSnack(
      l.settingsRestoreBackup,
      loading: true,
      duration: const Duration(seconds: 120),
    );

    final RestoreResult result = await service.restoreFromBackup(
      zipPath: zipPath,
      restoreWishlist: options.restoreWishlist,
      restoreSettings: options.restoreSettings,
    );

    if (!context.mounted) return;

    if (result.success) {
      // Инвалидируем провайдеры чтобы UI отобразил восстановленные данные
      ref.invalidate(collectionsProvider);
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);

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

/// Опции восстановления из диалога подтверждения.
class _RestoreOptions {
  const _RestoreOptions({
    required this.restoreWishlist,
    required this.restoreSettings,
  });

  final bool restoreWishlist;
  final bool restoreSettings;
}
