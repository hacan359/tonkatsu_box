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
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _clientSecretController = TextEditingController();
  final TextEditingController _steamGridDbKeyController =
      TextEditingController();
  final TextEditingController _tmdbKeyController = TextEditingController();
  final FocusNode _clientIdFocus = FocusNode();
  final FocusNode _clientSecretFocus = FocusNode();

  bool _obscureSecret = true;
  bool _obscureSteamGridDbKey = true;
  bool _obscureTmdbKey = true;

  @override
  void initState() {
    super.initState();
    _loadExistingCredentials();
  }

  void _loadExistingCredentials() {
    final SettingsState settings = ref.read(settingsNotifierProvider);
    _clientIdController.text = settings.clientId ?? '';
    _clientSecretController.text = settings.clientSecret ?? '';
    _steamGridDbKeyController.text = settings.steamGridDbApiKey ?? '';
    _tmdbKeyController.text = settings.tmdbApiKey ?? '';
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _steamGridDbKeyController.dispose();
    _tmdbKeyController.dispose();
    _clientIdFocus.dispose();
    _clientSecretFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return BreadcrumbScope(
      label: 'Credentials',
      child: Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.isInitialSetup) ...<Widget>[
              _buildWelcomeSection(),
              const SizedBox(height: AppSpacing.xl),
            ],
            _buildIgdbSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildStatusSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildActionsSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildSteamGridDbSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildTmdbSection(settings),
            if (settings.errorMessage != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _buildErrorSection(settings.errorMessage!),
            ],
          ],
        ),
      ),
    ),
    );
  }

  // ==================== Welcome ====================

  Widget _buildWelcomeSection() {
    return Card(
      color: AppColors.gameAccent.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.waving_hand, color: AppColors.gameAccent),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Welcome to Tonkatsu Box!',
                    style: AppTypography.h2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
        ),
      ),
    );
  }

  // ==================== IGDB ====================

  Widget _buildIgdbSection(SettingsState settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                SourceBadge(
                  source: DataSource.igdb,
                  size: SourceBadgeSize.large,
                ),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'IGDB API Credentials',
                    style: AppTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _clientIdController,
              focusNode: _clientIdFocus,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                hintText: 'Enter your Twitch Client ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _clientSecretFocus.requestFocus(),
              enabled: !settings.isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _clientSecretController,
              focusNode: _clientSecretFocus,
              decoration: InputDecoration(
                labelText: 'Client Secret',
                hintText: 'Enter your Twitch Client Secret',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSecret ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureSecret = !_obscureSecret);
                  },
                ),
              ),
              obscureText: _obscureSecret,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verifyConnection(),
              enabled: !settings.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(SettingsState settings) {
    final IconData statusIcon;
    final Color statusColor;
    final String statusText;

    switch (settings.connectionStatus) {
      case ConnectionStatus.connected:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Connected';
      case ConnectionStatus.error:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        statusText = 'Connection Error';
      case ConnectionStatus.checking:
        statusIcon = Icons.sync;
        statusColor = Colors.orange;
        statusText = 'Checking...';
      case ConnectionStatus.unknown:
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
        statusText = 'Not Connected';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Connection Status', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
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
        ),
      ),
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

  Widget _buildSteamGridDbSection(SettingsState settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                SourceBadge(
                  source: DataSource.steamGridDb,
                  size: SourceBadgeSize.large,
                ),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'SteamGridDB API',
                    style: AppTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _steamGridDbKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your SteamGridDB API key',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSteamGridDbKey
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(
                        () => _obscureSteamGridDbKey = !_obscureSteamGridDbKey);
                  },
                ),
              ),
              obscureText: _obscureSteamGridDbKey,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveSteamGridDbKey(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Icon(
                  settings.hasSteamGridDbKey
                      ? Icons.check_circle
                      : Icons.help_outline,
                  color: settings.hasSteamGridDbKey
                      ? AppColors.success
                      : AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  settings.hasSteamGridDbKey ? 'API key saved' : 'No API key',
                  style: AppTypography.body.copyWith(
                    color: settings.hasSteamGridDbKey
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  height: 40,
                  child: FilledButton(
                    onPressed: _saveSteamGridDbKey,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TMDB ====================

  Widget _buildTmdbSection(SettingsState settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                SourceBadge(
                  source: DataSource.tmdb,
                  size: SourceBadgeSize.large,
                ),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'TMDB API (Movies & TV)',
                    style: AppTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _tmdbKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your TMDB API key (v3)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureTmdbKey
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureTmdbKey = !_obscureTmdbKey);
                  },
                ),
              ),
              obscureText: _obscureTmdbKey,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveTmdbKey(),
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
            Row(
              children: <Widget>[
                Icon(
                  settings.hasTmdbKey
                      ? Icons.check_circle
                      : Icons.help_outline,
                  color: settings.hasTmdbKey
                      ? AppColors.success
                      : AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  settings.hasTmdbKey ? 'API key saved' : 'No API key',
                  style: AppTypography.body.copyWith(
                    color: settings.hasTmdbKey
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  height: 40,
                  child: FilledButton(
                    onPressed: _saveTmdbKey,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Error ====================

  Widget _buildErrorSection(String errorMessage) {
    return Card(
      color: AppColors.error.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: <Widget>[
            const Icon(Icons.warning_amber, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                errorMessage,
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Actions ====================

  Future<void> _verifyConnection() async {
    final String clientId = _clientIdController.text.trim();
    final String clientSecret = _clientSecretController.text.trim();

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

    final int downloaded = await cacheService.downloadImages(
      type: ImageType.platformLogo,
      tasks: tasks,
    );

    messenger.hideCurrentSnackBar();
    if (mounted) {
      context.showAppSnackBar('Downloaded $downloaded logos');
    }
  }

  Future<void> _saveSteamGridDbKey() async {
    final String apiKey = _steamGridDbKeyController.text.trim();
    if (apiKey.isEmpty) {
      context.showAppSnackBar('Please enter a SteamGridDB API key', isError: true);
      return;
    }

    await ref.read(settingsNotifierProvider.notifier).setSteamGridDbApiKey(apiKey);

    if (mounted) {
      context.showAppSnackBar('API key saved');
    }
  }

  Future<void> _saveTmdbKey() async {
    final String apiKey = _tmdbKeyController.text.trim();
    if (apiKey.isEmpty) {
      context.showAppSnackBar('Please enter a TMDB API key', isError: true);
      return;
    }

    await ref.read(settingsNotifierProvider.notifier).setTmdbApiKey(apiKey);

    if (mounted) {
      context.showAppSnackBar('TMDB API key saved');
    }
  }

  String _formatTimestamp(int timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
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
