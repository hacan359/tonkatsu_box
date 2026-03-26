// Экран-хаб настроек приложения с единым grouped-list лейаутом.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../core/services/update_service.dart';
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
import 'ra_import_screen.dart';
import 'steam_import_screen.dart';
import 'trakt_import_screen.dart';
import 'debug_hub_screen.dart';
import 'gamepad_debug_screen.dart';
import 'profiles_screen.dart';
import '../../../shared/models/profile.dart';
import '../providers/profile_provider.dart';

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

    final Profile currentProfile = ref.watch(currentProfileProvider);

    return <Widget>[
      // PROFILES
      SettingsGroup(
        title: l.profiles,
        children: <Widget>[
          SettingsTile(
            title: l.currentProfile(currentProfile.name),
            value: '',
            onTap: () => _pushScreen(const ProfilesScreen()),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),

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

      // BACKUP
      SettingsGroup(
        title: l.settingsBackup,
        subtitle: l.settingsBackupSubtitle,
        children: <Widget>[
          SettingsTile(
            title: l.settingsBackupAll,
            subtitle: l.settingsBackupAllSubtitle,
            onTap: () => _handleBackup(context, ref, l),
          ),
          SettingsTile(
            title: l.settingsRestoreBackup,
            subtitle: l.settingsRestoreBackupSubtitle,
            onTap: () => _handleRestore(context, ref, l),
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
          _buildVersionTile(l),
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
      onTap: () {
        launchUrl(
          Uri.parse(updateInfo.releaseUrl),
          mode: LaunchMode.externalApplication,
        );
      },
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
