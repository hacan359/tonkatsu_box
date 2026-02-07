import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/platform.dart';
import '../providers/settings_provider.dart';
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IGDB API Setup'),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.isInitialSetup) ...<Widget>[
              _buildWelcomeSection(),
              const SizedBox(height: 32),
            ],
            _buildCredentialsSection(settings),
            const SizedBox(height: 24),
            _buildStatusSection(settings),
            const SizedBox(height: 24),
            _buildActionsSection(settings),
            const SizedBox(height: 24),
            _buildCacheSection(),
            const SizedBox(height: 24),
            _buildSteamGridDbSection(settings),
            const SizedBox(height: 24),
            _buildTmdbSection(settings),
            if (kDebugMode) ...<Widget>[
              const SizedBox(height: 24),
              _buildDeveloperToolsSection(settings),
            ],
            if (settings.errorMessage != null) ...<Widget>[
              const SizedBox(height: 16),
              _buildErrorSection(settings.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.waving_hand, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Welcome to xeRAbora!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'To get started, you need to set up your IGDB API credentials. '
              'Get your Client ID and Client Secret from the Twitch Developer Console.',
            ),
            const SizedBox(height: 8),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'API Credentials',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Connection Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            _buildInfoRow(
              'Platforms synced',
              settings.platformCount.toString(),
              Icons.videogame_asset,
            ),
            if (settings.lastSync != null) ...<Widget>[
              const SizedBox(height: 8),
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
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Image Cache',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                    style: const TextStyle(fontSize: 12),
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
            FutureBuilder<List<dynamic>>(
              future: Future.wait(<Future<dynamic>>[
                cacheService.getCachedCount(),
                cacheService.getCacheSize(),
              ]),
              builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                final int count = (snapshot.data?[0] as int?) ?? 0;
                final int size = (snapshot.data?[1] as int?) ?? 0;
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.grid_view,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'SteamGridDB API',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  settings.hasSteamGridDbKey
                      ? Icons.check_circle
                      : Icons.help_outline,
                  color: settings.hasSteamGridDbKey ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  settings.hasSteamGridDbKey ? 'API key saved' : 'No API key',
                  style: TextStyle(
                    color:
                        settings.hasSteamGridDbKey ? Colors.green : Colors.grey,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.movie,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'TMDB API (Movies & TV)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  settings.hasTmdbKey
                      ? Icons.check_circle
                      : Icons.help_outline,
                  color: settings.hasTmdbKey ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  settings.hasTmdbKey ? 'API key saved' : 'No API key',
                  style: TextStyle(
                    color:
                        settings.hasTmdbKey ? Colors.green : Colors.grey,
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

  Widget _buildDeveloperToolsSection(SettingsState settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.bug_report,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Developer Tools',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(String errorMessage) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: <Widget>[
            Icon(Icons.warning_amber, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(color: colorScheme.onErrorContainer),
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
