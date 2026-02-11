import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/config_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/source_badge.dart';
import '../../collections/providers/collections_provider.dart';
import '../providers/settings_provider.dart';
import 'image_debug_screen.dart';
import 'steamgriddb_debug_screen.dart';

/// URL для получения API ключей IGDB.
const String _twitchConsoleUrl = 'https://dev.twitch.tv/console/apps';

/// Экран настроек IGDB API.
///
/// Позволяет пользователю ввести учётные данные для доступа к IGDB API
/// и синхронизировать список платформ.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Создаёт [SettingsScreen].
  const SettingsScreen({
    super.key,
    this.isInitialSetup = false,
  });

  /// Флаг начальной настройки.
  ///
  /// Если true, показывается приветственное сообщение и скрывается
  /// кнопка "Назад".
  final bool isInitialSetup;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

  Future<void> _verifyConnection() async {
    final String clientId = _clientIdController.text.trim();
    final String clientSecret = _clientSecretController.text.trim();

    if (clientId.isEmpty || clientSecret.isEmpty) {
      _showSnackBar('Please enter both Client ID and Client Secret');
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
      _showSnackBar('Connection verified successfully!', isError: false);
    }
  }

  Future<void> _syncPlatforms() async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool success = await notifier.syncPlatforms();

    if (success && mounted) {
      _showSnackBar('Platforms synced successfully!', isError: false);

      // Скачиваем логотипы если включено кэширование
      await _downloadLogosIfEnabled();
    }
  }

  Future<void> _downloadLogosIfEnabled() async {
    final ImageCacheService cacheService =
        ref.read(imageCacheServiceProvider);

    final bool enabled = await cacheService.isCacheEnabled();
    if (!enabled) return;

    // Получаем платформы из БД
    final DatabaseService dbService = ref.read(databaseServiceProvider);
    final List<Platform> platforms = await dbService.getAllPlatforms();

    if (!mounted) return;

    // Показываем прогресс
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Downloading platform logos...'),
        duration: Duration(seconds: 60),
      ),
    );

    // Формируем задачи для скачивания
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
      _showSnackBar('Downloaded $downloaded logos', isError: false);
      setState(() {}); // Обновить статистику кэша
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.gameAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: const Text('IGDB API Setup'),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.isInitialSetup) ...<Widget>[
              _buildWelcomeSection(),
              const SizedBox(height: AppSpacing.xl),
            ],
            _buildCredentialsSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildStatusSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildActionsSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildCacheSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildSteamGridDbSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildTmdbSection(settings),
            const SizedBox(height: AppSpacing.lg),
            _buildConfigSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildDangerZoneSection(),
            if (kDebugMode) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _buildDeveloperToolsSection(settings),
            ],
            if (settings.errorMessage != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _buildErrorSection(settings.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

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
                Text(
                  'Welcome to xeRAbora!',
                  style: AppTypography.h2,
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
                // Копируем URL в буфер обмена (url_launcher будет добавлен позже)
                Clipboard.setData(
                  const ClipboardData(text: _twitchConsoleUrl),
                );
                _showSnackBar(
                  'URL copied: $_twitchConsoleUrl',
                  isError: false,
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

  Widget _buildCredentialsSection(SettingsState settings) {
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
                Text(
                  'IGDB API Credentials',
                  style: AppTypography.h3,
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
                    setState(() {
                      _obscureSecret = !_obscureSecret;
                    });
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
            const Text(
              'Connection Status',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
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
        const SizedBox(height: 12),
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

  Widget _buildCacheSection() {
    final ImageCacheService cacheService =
        ref.read(imageCacheServiceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.folder, color: AppColors.gameAccent),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Image Cache',
                  style: AppTypography.h3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Галка включения кэширования
            FutureBuilder<bool>(
              future: cacheService.isCacheEnabled(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                final bool enabled = snapshot.data ?? false;
                return SwitchListTile(
                  title: const Text('Offline mode'),
                  subtitle: const Text(
                    'Save images locally for offline use',
                  ),
                  value: enabled,
                  onChanged: (bool value) async {
                    await cacheService.setCacheEnabled(value);
                    setState(() {});
                  },
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),

            const Divider(),

            // Путь к кэшу
            FutureBuilder<String>(
              future: cacheService.getBaseCachePath(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                final String path = snapshot.data ?? 'Loading...';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cache folder'),
                  subtitle: Text(
                    path,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () => _selectCacheFolder(cacheService),
                    tooltip: 'Select folder',
                  ),
                );
              },
            ),

            // Статистика кэша
            FutureBuilder<(int, int)>(
              future: _getCacheStats(cacheService),
              builder: (BuildContext context, AsyncSnapshot<(int, int)> snapshot) {
                final int count = snapshot.data?.$1 ?? 0;
                final int size = snapshot.data?.$2 ?? 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cache size'),
                  subtitle: Text('$count files, ${cacheService.formatSize(size)}'),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                    onPressed: count > 0
                        ? () => _clearCache(cacheService)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<(int, int)> _getCacheStats(ImageCacheService cacheService) async {
    final int count = await cacheService.getCachedCount();
    final int size = await cacheService.getCacheSize();
    return (count, size);
  }

  Future<void> _selectCacheFolder(ImageCacheService cacheService) async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select cache folder for images',
    );

    if (selectedDirectory != null) {
      await cacheService.setCachePath(selectedDirectory);
      setState(() {});
      if (mounted) {
        _showSnackBar('Cache folder updated', isError: false);
      }
    }
  }

  Future<void> _clearCache(ImageCacheService cacheService) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'This will delete all locally saved images. '
          'They will be downloaded again during the next sync.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await cacheService.clearCache();
      setState(() {});
      if (mounted) {
        _showSnackBar('Cache cleared', isError: false);
      }
    }
  }

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
                Text(
                  'SteamGridDB API',
                  style: AppTypography.h3,
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
                    setState(() {
                      _obscureSteamGridDbKey = !_obscureSteamGridDbKey;
                    });
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
                  width: 80,
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

  Future<void> _saveSteamGridDbKey() async {
    final String apiKey = _steamGridDbKeyController.text.trim();
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    await notifier.setSteamGridDbApiKey(apiKey);

    if (mounted) {
      _showSnackBar(
        apiKey.isEmpty ? 'API key cleared' : 'API key saved',
        isError: false,
      );
    }
  }

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
                Text(
                  'TMDB API (Movies & TV)',
                  style: AppTypography.h3,
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
                    setState(() {
                      _obscureTmdbKey = !_obscureTmdbKey;
                    });
                  },
                ),
              ),
              obscureText: _obscureTmdbKey,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveTmdbKey(),
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
                  width: 80,
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

  Future<void> _saveTmdbKey() async {
    final String apiKey = _tmdbKeyController.text.trim();
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    await notifier.setTmdbApiKey(apiKey);

    if (mounted) {
      _showSnackBar(
        apiKey.isEmpty ? 'TMDB API key cleared' : 'TMDB API key saved',
        isError: false,
      );
    }
  }

  Widget _buildConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.settings_backup_restore,
                    color: AppColors.gameAccent),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Configuration',
                  style: AppTypography.h3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Export or import your API keys and settings.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportConfig,
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Export Config'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importConfig,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Import Config'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportConfig() async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final ConfigResult result = await notifier.exportConfig();

    if (!mounted) return;

    if (result.success) {
      _showSnackBar('Config exported to ${result.filePath}', isError: false);
    } else if (result.error != null) {
      _showSnackBar(result.error!);
    }
  }

  Future<void> _importConfig() async {
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final ConfigResult result = await notifier.importConfig();

    if (!mounted) return;

    if (result.success) {
      // Обновляем текстовые поля из нового state
      final SettingsState settings = ref.read(settingsNotifierProvider);
      _clientIdController.text = settings.clientId ?? '';
      _clientSecretController.text = settings.clientSecret ?? '';
      _steamGridDbKeyController.text = settings.steamGridDbApiKey ?? '';
      _tmdbKeyController.text = settings.tmdbApiKey ?? '';
      _showSnackBar('Config imported successfully', isError: false);
    } else if (result.error != null) {
      _showSnackBar(result.error!);
    }
  }

  Widget _buildDangerZoneSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.warning_amber, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Danger Zone',
                  style: AppTypography.h3.copyWith(color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Clears all collections, games, movies, TV shows and canvas data. '
              'Settings and API keys will be preserved.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetDatabase,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.delete_forever, size: 18),
                label: const Text('Reset Database'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetDatabase() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Reset Database?'),
        content: const Text(
          'This will permanently delete all your collections, games, '
          'movies, TV shows, episode progress, and canvas data.\n\n'
          'Your API keys and settings will be preserved.\n\n'
          'This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final SettingsNotifier notifier =
          ref.read(settingsNotifierProvider.notifier);
      await notifier.flushDatabase();

      if (mounted) {
        // Инвалидируем провайдер коллекций — HomeScreen перечитает пустой список
        ref.invalidate(collectionsProvider);

        _showSnackBar('Database has been reset', isError: false);

        // Возвращаемся на HomeScreen
        if (mounted) {
          Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        }
      }
    }
  }

  Widget _buildDeveloperToolsSection(SettingsState settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.bug_report, color: AppColors.gameAccent),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Developer Tools',
                  style: AppTypography.h3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.grid_view),
              title: const Text('SteamGridDB Debug Panel'),
              subtitle: Text(
                settings.hasSteamGridDbKey
                    ? 'Test API endpoints'
                    : 'Set API key first',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: settings.hasSteamGridDbKey,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const SteamGridDbDebugScreen(),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_search),
              title: const Text('Image Debug Panel'),
              subtitle: const Text('Check poster URLs and loading'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const ImageDebugScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
