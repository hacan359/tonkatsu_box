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
    _steamGridDbApiKey = settings.steamGridDbApiKey ?? '';
    _tmdbApiKey = settings.tmdbApiKey ?? '';
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
            context.showAppSnackBar(
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
          placeholder: 'Enter your SteamGridDB API key',
          obscureText: true,
          compact: compact,
          onChanged: (String value) =>
              setState(() => _steamGridDbApiKey = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildSaveRow(
          hasKey: settings.hasSteamGridDbKey,
          compact: compact,
          onSave: _saveSteamGridDbKey,
        ),
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
          placeholder: 'Enter your TMDB API key (v3)',
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
          compact: compact,
          onSave: _saveTmdbKey,
        ),
      ],
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
      context.showAppSnackBar(
        'Please enter both Client ID and Client Secret',
        isError: true,
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
      context.showAppSnackBar('Connection verified successfully!');
    }
  }

  Future<void> _syncPlatforms() async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool success = await notifier.syncPlatforms();

    if (success && mounted) {
      context.showAppSnackBar('Platforms synced successfully!');
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

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Downloading platform logos...'),
        duration: Duration(seconds: 60),
      ),
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

      messenger.hideCurrentSnackBar();
      if (mounted) {
        context.showAppSnackBar('Downloaded $downloaded logos');
      }
    } on Exception {
      messenger.hideCurrentSnackBar();
      if (mounted) {
        context.showAppSnackBar('Failed to download logos', isError: true);
      }
    }
  }

  /// Строка с StatusDot + кнопкой Save для API ключей.
  Widget _buildSaveRow({
    required bool hasKey,
    required bool compact,
    required VoidCallback onSave,
  }) {
    return Row(
      children: <Widget>[
        StatusDot(
          label: hasKey ? 'API key saved' : 'No API key',
          type: hasKey ? StatusType.success : StatusType.inactive,
          compact: compact,
        ),
        const Spacer(),
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
      context.showAppSnackBar(emptyMessage, isError: true);
      return;
    }

    await setter(apiKey);

    if (mounted) {
      context.showAppSnackBar(successMessage);
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
