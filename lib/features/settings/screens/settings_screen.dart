import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

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
  final FocusNode _clientIdFocus = FocusNode();
  final FocusNode _clientSecretFocus = FocusNode();

  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _loadExistingCredentials();
  }

  void _loadExistingCredentials() {
    final SettingsState settings = ref.read(settingsNotifierProvider);
    _clientIdController.text = settings.clientId ?? '';
    _clientSecretController.text = settings.clientSecret ?? '';
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
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
