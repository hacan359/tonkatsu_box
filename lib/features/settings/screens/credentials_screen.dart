// Экран настройки API ключей (IGDB, SteamGridDB, TMDB).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
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
      label: 'Credentials',
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
      title: 'Welcome to Tonkatsu Box!',
      icon: Icons.waving_hand,
      iconColor: AppColors.brand,
      compact: compact,
      children: <Widget>[
        const Text(
          'To get started, you need to set up your IGDB API credentials. '
          'Get your Client ID and Client Secret from the Twitch Developer Console.',
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(
              const ClipboardData(text: _twitchConsoleUrl),
            );
            context.showSnack(
              'URL copied: $_twitchConsoleUrl',
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy Twitch Console URL'),
        ),
      ],
    );
  }

  // ==================== IGDB ====================

  Widget _buildIgdbSection(SettingsState settings, bool compact) {
    return SettingsSection(
      title: 'IGDB API Credentials',
      trailing: const SourceBadge(
        source: DataSource.igdb,
        size: SourceBadgeSize.large,
      ),
      compact: compact,
      children: <Widget>[
        InlineTextField(
          label: 'Client ID',
          value: _clientId,
          placeholder: 'Enter your Twitch Client ID',
          compact: compact,
          onChanged: (String value) => setState(() => _clientId = value),
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        InlineTextField(
          label: 'Client Secret',
          value: _clientSecret,
          placeholder: 'Enter your Twitch Client Secret',
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
      title: 'Connection Status',
      compact: compact,
      children: <Widget>[
        StatusDot(
          label: _connectionLabel(settings.connectionStatus),
          type: _connectionStatusType(settings.connectionStatus),
          compact: compact,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInfoRow(
          'Platforms synced',
          settings.platformCount.toString(),
          Icons.videogame_asset,
        ),
        if (settings.lastSync != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            'Last sync',
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
          label: const Text('Verify Connection'),
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
          label: const Text('Refresh Platforms'),
        ),
      ],
    );
  }

  // ==================== SteamGridDB ====================

  Widget _buildSteamGridDbSection(SettingsState settings, bool compact) {
    return SettingsSection(
      title: 'SteamGridDB API',
      trailing: const SourceBadge(
        source: DataSource.steamGridDb,
        size: SourceBadgeSize.large,
      ),
      compact: compact,
      children: <Widget>[
        InlineTextField(
          label: 'API Key',
          value: _steamGridDbApiKey,
          placeholder: settings.isSteamGridDbKeyBuiltIn
              ? 'Using built-in key'
              : 'Enter your SteamGridDB API key',
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
      title: 'TMDB API (Movies & TV)',
      trailing: const SourceBadge(
        source: DataSource.tmdb,
        size: SourceBadgeSize.large,
      ),
      compact: compact,
      children: <Widget>[
        InlineTextField(
          label: 'API Key',
          value: _tmdbApiKey,
          placeholder: settings.isTmdbKeyBuiltIn
              ? 'Using built-in key'
              : 'Enter your TMDB API key (v3)',
          obscureText: true,
          compact: compact,
          onChanged: (String value) => setState(() => _tmdbApiKey = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Row(
          children: <Widget>[
            Icon(Icons.language, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text('Content Language', style: AppTypography.body),
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
              'For better rate limits we recommend using your own API key.',
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
      title: 'Error',
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
        ConnectionStatus.connected => 'Connected',
        ConnectionStatus.error => 'Connection Error',
        ConnectionStatus.checking => 'Checking...',
        ConnectionStatus.unknown => 'Not Connected',
      };

  // ==================== Actions ====================

  Future<void> _verifyConnection() async {
    final String clientId = _clientId.trim();
    final String clientSecret = _clientSecret.trim();

    if (clientId.isEmpty || clientSecret.isEmpty) {
      context.showSnack(
        'Please enter both Client ID and Client Secret',
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
            'Connected & platforms synced!',
            type: SnackType.success,
          );
          await _downloadLogosIfEnabled();
        } else {
          context.showSnack(
            'Connected, but platform sync failed',
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
        'Platforms synced successfully!',
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
      'Downloading platform logos...',
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
          'Downloaded $downloaded logos',
          type: SnackType.success,
        );
      }
    } on Exception {
      if (mounted) {
        context.showSnack(
          'Failed to download logos',
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
              ? 'Using built-in key'
              : hasKey
                  ? 'API key saved'
                  : 'No API key',
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
              child: const Text('Reset'),
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
              child: const Text('Test'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        SizedBox(
          width: 100,
          height: 40,
          child: FilledButton(
            onPressed: onSave,
            child: const Text('Save'),
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
          'SteamGridDB API key is valid',
          type: SnackType.success,
        );
      } else {
        context.showSnack('SteamGridDB API key is invalid', type: SnackType.error);
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
          'TMDB API key is valid',
          type: SnackType.success,
        );
      } else {
        context.showSnack('TMDB API key is invalid', type: SnackType.error);
      }
    }
  }

  void _resetSteamGridDbKey() {
    ref.read(settingsNotifierProvider.notifier).resetSteamGridDbApiKeyToDefault();
    setState(() => _steamGridDbApiKey = '');
    context.showSnack('Reset to built-in key', type: SnackType.success);
  }

  void _resetTmdbKey() {
    ref.read(settingsNotifierProvider.notifier).resetTmdbApiKeyToDefault();
    setState(() => _tmdbApiKey = '');
    context.showSnack('Reset to built-in key', type: SnackType.success);
  }

  Future<void> _saveSteamGridDbKey() => _saveApiKey(
        value: _steamGridDbApiKey,
        emptyMessage: 'Please enter a SteamGridDB API key',
        setter: ref.read(settingsNotifierProvider.notifier).setSteamGridDbApiKey,
        successMessage: 'API key saved',
      );

  Future<void> _saveTmdbKey() => _saveApiKey(
        value: _tmdbApiKey,
        emptyMessage: 'Please enter a TMDB API key',
        setter: ref.read(settingsNotifierProvider.notifier).setTmdbApiKey,
        successMessage: 'TMDB API key saved',
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

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
