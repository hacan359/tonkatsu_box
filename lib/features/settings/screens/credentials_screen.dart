// Экран настройки API ключей (IGDB, SteamGridDB, TMDB).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../shared/widgets/source_badge.dart';
import '../../../shared/constants/api_defaults.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_section.dart';
import '../widgets/status_dot.dart';

/// URL для получения API ключей IGDB.
const String _twitchConsoleUrl = 'https://dev.twitch.tv/console/apps';

/// Экран настройки API ключей.
///
/// Содержит секции IGDB, SteamGridDB и TMDB с полями ввода ключей,
/// проверкой подключения и синхронизацией платформ.
class CredentialsScreen extends ConsumerStatefulWidget {
  /// Создаёт [CredentialsScreen].
  const CredentialsScreen({
    super.key,
    this.isInitialSetup = false,
  });

  /// Флаг начальной настройки (показывает Welcome секцию).
  final bool isInitialSetup;

  @override
  ConsumerState<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends ConsumerState<CredentialsScreen> {
  String _clientId = '';
  String _clientSecret = '';
  String _steamGridDbApiKey = '';
  String _tmdbApiKey = '';

  @override
  void initState() {
    super.initState();
    final SettingsState settings = ref.read(settingsNotifierProvider);
    _clientId = settings.clientId ?? '';
    _clientSecret = settings.clientSecret ?? '';
    // Не загружаем встроенные ключи в текстовые поля —
    // показываем пустое поле с placeholder "Using built-in key"
    _steamGridDbApiKey =
        settings.isSteamGridDbKeyBuiltIn ? '' : (settings.steamGridDbApiKey ?? '');
    _tmdbApiKey =
        settings.isTmdbKeyBuiltIn ? '' : (settings.tmdbApiKey ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return BreadcrumbScope(
      label: S.of(context).credentialsTitle,
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.isInitialSetup) ...<Widget>[
                _buildWelcomeSection(compact),
                const SizedBox(height: AppSpacing.xl),
              ],
              _buildIgdbSection(settings, compact),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              _buildStatusSection(settings, compact),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              _buildActionsSection(settings),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              _buildSteamGridDbSection(settings, compact),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              _buildTmdbSection(settings, compact),
              if (settings.errorMessage != null) ...<Widget>[
                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                _buildErrorSection(settings.errorMessage!, compact),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Welcome ====================

  Widget _buildWelcomeSection(bool compact) {
    return SettingsSection(
      title: S.of(context).credentialsWelcome,
      icon: Icons.waving_hand,
      iconColor: AppColors.brand,
      compact: compact,
      children: <Widget>[
        Text(
          S.of(context).credentialsWelcomeHint,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(
              const ClipboardData(text: _twitchConsoleUrl),
            );
            context.showSnack(
              S.of(context).credentialsUrlCopied(_twitchConsoleUrl),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: Text(S.of(context).credentialsCopyTwitchUrl),
        ),
      ],
    );
  }

  // ==================== IGDB ====================

  Widget _buildIgdbSection(SettingsState settings, bool compact) {
    return SettingsSection(
      title: S.of(context).credentialsIgdbSection,
      trailing: const SourceBadge(
        source: DataSource.igdb,
        size: SourceBadgeSize.large,
      ),
      compact: compact,
      children: <Widget>[
        InlineTextField(
          label: S.of(context).credentialsClientId,
          value: _clientId,
          placeholder: S.of(context).credentialsClientIdHint,
          compact: compact,
          onChanged: (String value) => setState(() => _clientId = value),
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        InlineTextField(
          label: S.of(context).credentialsClientSecret,
          value: _clientSecret,
          placeholder: S.of(context).credentialsClientSecretHint,
          obscureText: true,
          compact: compact,
          onChanged: (String value) =>
              setState(() => _clientSecret = value),
        ),
      ],
    );
  }

  Widget _buildStatusSection(SettingsState settings, bool compact) {
    return SettingsSection(
      title: S.of(context).credentialsConnectionStatus,
      compact: compact,
      children: <Widget>[
        StatusDot(
          label: _connectionLabel(settings.connectionStatus),
          type: _connectionStatusType(settings.connectionStatus),
          compact: compact,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInfoRow(
          S.of(context).credentialsPlatformsSynced,
          settings.platformCount.toString(),
          Icons.videogame_asset,
        ),
        if (settings.lastSync != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            S.of(context).credentialsLastSync,
            _formatTimestamp(settings.lastSync!),
            Icons.schedule,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionsSection(SettingsState settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          onPressed: settings.isLoading ? null : _verifyConnection,
          icon: settings.isLoading &&
                  settings.connectionStatus == ConnectionStatus.checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.verified_user),
          label: Text(S.of(context).credentialsVerifyConnection),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed:
              settings.isLoading || !settings.isApiReady ? null : _syncPlatforms,
          icon: settings.isLoading &&
                  settings.connectionStatus != ConnectionStatus.checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(S.of(context).credentialsRefreshPlatforms),
        ),
      ],
    );
  }

  // ==================== SteamGridDB ====================

  Widget _buildSteamGridDbSection(SettingsState settings, bool compact) {
    return SettingsSection(
      title: S.of(context).credentialsSteamGridDbSection,
      trailing: const SourceBadge(
        source: DataSource.steamGridDb,
        size: SourceBadgeSize.large,
      ),
      compact: compact,
      children: <Widget>[
        InlineTextField(
          label: S.of(context).credentialsApiKey,
          value: _steamGridDbApiKey,
          placeholder: settings.isSteamGridDbKeyBuiltIn
              ? S.of(context).credentialsUsingBuiltInKey
              : S.of(context).credentialsEnterSteamGridDbKey,
          obscureText: true,
          compact: compact,
          onChanged: (String value) =>
              setState(() => _steamGridDbApiKey = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildSaveRow(
          hasKey: settings.hasSteamGridDbKey,
          isBuiltIn: settings.isSteamGridDbKeyBuiltIn,
          hasDefault: ApiDefaults.hasSteamGridDbKey,
          compact: compact,
          onSave: _saveSteamGridDbKey,
          onValidate: _validateSteamGridDbKey,
          onReset: _resetSteamGridDbKey,
        ),
        if (settings.isSteamGridDbKeyBuiltIn) _buildOwnKeyHint(),
      ],
    );
  }

  // ==================== TMDB ====================

  Widget _buildTmdbSection(SettingsState settings, bool compact) {
    return SettingsSection(
      title: S.of(context).credentialsTmdbSection,
      trailing: const SourceBadge(
        source: DataSource.tmdb,
        size: SourceBadgeSize.large,
      ),
      compact: compact,
      children: <Widget>[
        InlineTextField(
          label: S.of(context).credentialsApiKey,
          value: _tmdbApiKey,
          placeholder: settings.isTmdbKeyBuiltIn
              ? S.of(context).credentialsUsingBuiltInKey
              : S.of(context).credentialsEnterTmdbKey,
          obscureText: true,
          compact: compact,
          onChanged: (String value) => setState(() => _tmdbApiKey = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            const Icon(Icons.language, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(S.of(context).credentialsContentLanguage, style: AppTypography.body),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'ru-RU',
                label: Text('Русский'),
              ),
              ButtonSegment<String>(
                value: 'en-US',
                label: Text('English'),
              ),
            ],
            selected: <String>{settings.tmdbLanguage},
            onSelectionChanged: (Set<String> selection) {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setTmdbLanguage(selection.first);
            },
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildSaveRow(
          hasKey: settings.hasTmdbKey,
          isBuiltIn: settings.isTmdbKeyBuiltIn,
          hasDefault: ApiDefaults.hasTmdbKey,
          compact: compact,
          onSave: _saveTmdbKey,
          onValidate: _validateTmdbKey,
          onReset: _resetTmdbKey,
        ),
        if (settings.isTmdbKeyBuiltIn) _buildOwnKeyHint(),
      ],
    );
  }

  // ==================== Hints ====================

  Widget _buildOwnKeyHint() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              S.of(context).credentialsOwnKeyHint,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Error ====================

  Widget _buildErrorSection(String errorMessage, bool compact) {
    return SettingsSection(
      title: S.of(context).settingsError,
      icon: Icons.warning_amber,
      iconColor: AppColors.error,
      compact: compact,
      children: <Widget>[
        Text(
          errorMessage,
          style: AppTypography.body.copyWith(color: AppColors.error),
        ),
      ],
    );
  }

  // ==================== Helpers ====================

  StatusType _connectionStatusType(ConnectionStatus status) => switch (status) {
        ConnectionStatus.connected => StatusType.success,
        ConnectionStatus.error => StatusType.error,
        ConnectionStatus.checking => StatusType.warning,
        ConnectionStatus.unknown => StatusType.inactive,
      };

  String _connectionLabel(ConnectionStatus status) => switch (status) {
        ConnectionStatus.connected => S.of(context).credentialsConnected,
        ConnectionStatus.error => S.of(context).credentialsConnectionError,
        ConnectionStatus.checking => S.of(context).credentialsChecking,
        ConnectionStatus.unknown => S.of(context).credentialsNotConnected,
      };

  // ==================== Actions ====================

  Future<void> _verifyConnection() async {
    final String clientId = _clientId.trim();
    final String clientSecret = _clientSecret.trim();

    if (clientId.isEmpty || clientSecret.isEmpty) {
      context.showSnack(
        S.of(context).credentialsEnterBoth,
        type: SnackType.error,
      );
      return;
    }

    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    await notifier.setCredentials(
      clientId: clientId,
      clientSecret: clientSecret,
    );

    final bool success = await notifier.verifyConnection();

    if (success && mounted) {
      final bool syncOk = await notifier.syncPlatforms();
      if (mounted) {
        if (syncOk) {
          context.showSnack(
            S.of(context).credentialsConnectedSynced,
            type: SnackType.success,
          );
          await _downloadLogosIfEnabled();
        } else {
          context.showSnack(
            S.of(context).credentialsConnectedSyncFailed,
            type: SnackType.error,
          );
        }
      }
    }
  }

  Future<void> _syncPlatforms() async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool success = await notifier.syncPlatforms();

    if (success && mounted) {
      context.showSnack(
        S.of(context).credentialsPlatformsSyncedOk,
        type: SnackType.success,
      );
      await _downloadLogosIfEnabled();
    }
  }

  Future<void> _downloadLogosIfEnabled() async {
    final ImageCacheService cacheService =
        ref.read(imageCacheServiceProvider);

    final bool enabled = await cacheService.isCacheEnabled();
    if (!enabled) return;

    final DatabaseService dbService = ref.read(databaseServiceProvider);
    final List<Platform> platforms = await dbService.getAllPlatforms();

    if (!mounted) return;

    context.showSnack(
      S.of(context).credentialsDownloadingLogos,
      loading: true,
      duration: const Duration(seconds: 60),
    );

    final List<ImageDownloadTask> tasks = platforms
        .where((Platform p) => p.logoImageId != null && p.logoUrl != null)
        .map((Platform p) => ImageDownloadTask(
              imageId: p.logoImageId!,
              remoteUrl: p.logoUrl!,
            ))
        .toList();

    try {
      final int downloaded = await cacheService.downloadImages(
        type: ImageType.platformLogo,
        tasks: tasks,
      );

      if (mounted) {
        context.showSnack(
          S.of(context).credentialsDownloadedLogos(downloaded),
          type: SnackType.success,
        );
      }
    } on Exception {
      if (mounted) {
        context.showSnack(
          S.of(context).credentialsFailedDownloadLogos,
          type: SnackType.error,
        );
      }
    }
  }

  /// Строка с StatusDot + кнопками Save/Test/Reset для API ключей.
  Widget _buildSaveRow({
    required bool hasKey,
    required bool compact,
    required VoidCallback onSave,
    bool isBuiltIn = false,
    bool hasDefault = false,
    Future<void> Function()? onValidate,
    VoidCallback? onReset,
  }) {
    return Row(
      children: <Widget>[
        StatusDot(
          label: isBuiltIn
              ? S.of(context).credentialsUsingBuiltInKey
              : hasKey
                  ? S.of(context).credentialsApiKeySaved
                  : S.of(context).credentialsNoApiKey,
          type: hasKey ? StatusType.success : StatusType.inactive,
          compact: compact,
        ),
        const Spacer(),
        if (hasKey && !isBuiltIn && hasDefault && onReset != null) ...<Widget>[
          SizedBox(
            width: 80,
            height: 40,
            child: OutlinedButton(
              onPressed: onReset,
              child: Text(S.of(context).reset),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (hasKey && onValidate != null) ...<Widget>[
          SizedBox(
            width: 80,
            height: 40,
            child: OutlinedButton(
              onPressed: onValidate,
              child: Text(S.of(context).test),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        SizedBox(
          width: 100,
          height: 40,
          child: FilledButton(
            onPressed: onSave,
            child: Text(S.of(context).save),
          ),
        ),
      ],
    );
  }

  Future<void> _validateSteamGridDbKey() async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool valid = await notifier.validateSteamGridDbKey();
    if (mounted) {
      if (valid) {
        context.showSnack(
          S.of(context).credentialsSteamGridDbKeyValid,
          type: SnackType.success,
        );
      } else {
        context.showSnack(S.of(context).credentialsSteamGridDbKeyInvalid, type: SnackType.error);
      }
    }
  }

  Future<void> _validateTmdbKey() async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool valid = await notifier.validateTmdbKey();
    if (mounted) {
      if (valid) {
        context.showSnack(
          S.of(context).credentialsTmdbKeyValid,
          type: SnackType.success,
        );
      } else {
        context.showSnack(S.of(context).credentialsTmdbKeyInvalid, type: SnackType.error);
      }
    }
  }

  void _resetSteamGridDbKey() {
    ref.read(settingsNotifierProvider.notifier).resetSteamGridDbApiKeyToDefault();
    setState(() => _steamGridDbApiKey = '');
    context.showSnack(S.of(context).credentialsResetToBuiltIn, type: SnackType.success);
  }

  void _resetTmdbKey() {
    ref.read(settingsNotifierProvider.notifier).resetTmdbApiKeyToDefault();
    setState(() => _tmdbApiKey = '');
    context.showSnack(S.of(context).credentialsResetToBuiltIn, type: SnackType.success);
  }

  Future<void> _saveSteamGridDbKey() => _saveApiKey(
        value: _steamGridDbApiKey,
        emptyMessage: S.of(context).credentialsEnterSteamGridDbKeyError,
        setter: ref.read(settingsNotifierProvider.notifier).setSteamGridDbApiKey,
        successMessage: S.of(context).credentialsApiKeySaved,
      );

  Future<void> _saveTmdbKey() => _saveApiKey(
        value: _tmdbApiKey,
        emptyMessage: S.of(context).credentialsEnterTmdbKeyError,
        setter: ref.read(settingsNotifierProvider.notifier).setTmdbApiKey,
        successMessage: S.of(context).credentialsTmdbKeySaved,
      );

  Future<void> _saveApiKey({
    required String value,
    required String emptyMessage,
    required Future<void> Function(String) setter,
    required String successMessage,
  }) async {
    final String apiKey = value.trim();
    if (apiKey.isEmpty) {
      context.showSnack(emptyMessage, type: SnackType.error);
      return;
    }

    await setter(apiKey);

    if (mounted) {
      context.showSnack(successMessage, type: SnackType.success);
    }
  }

  String _formatTimestamp(int timestamp) {
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(date);
    final S l10n = S.of(context);

    if (diff.inDays > 0) {
      return l10n.timeAgo(diff.inDays, l10n.timeUnitDays(diff.inDays));
    } else if (diff.inHours > 0) {
      return l10n.timeAgo(diff.inHours, l10n.timeUnitHours(diff.inHours));
    } else if (diff.inMinutes > 0) {
      return l10n.timeAgo(diff.inMinutes, l10n.timeUnitMinutes(diff.inMinutes));
    } else {
      return l10n.timeJustNow;
    }
  }
}
