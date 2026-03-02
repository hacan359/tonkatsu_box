// Контент экрана настройки API ключей (без Scaffold/AppBar).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/source_badge.dart';
import '../../../shared/constants/api_defaults.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_section.dart';
import '../widgets/status_dot.dart';

/// URL для получения API ключей IGDB.
const String _twitchConsoleUrl = 'https://dev.twitch.tv/console/apps';

/// Контент экрана настройки API ключей.
///
/// Содержит секции IGDB, SteamGridDB и TMDB с полями ввода ключей,
/// проверкой подключения и синхронизацией платформ.
/// Используется как standalone в десктопном sidebar и внутри [CredentialsScreen].
class CredentialsContent extends ConsumerStatefulWidget {
  /// Создаёт [CredentialsContent].
  const CredentialsContent({
    super.key,
    this.isInitialSetup = false,
  });

  /// Флаг начальной настройки (показывает Welcome секцию).
  final bool isInitialSetup;

  @override
  ConsumerState<CredentialsContent> createState() => _CredentialsContentState();
}

class _CredentialsContentState extends ConsumerState<CredentialsContent> {
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
    _steamGridDbApiKey =
        settings.isSteamGridDbKeyBuiltIn ? '' : (settings.steamGridDbApiKey ?? '');
    _tmdbApiKey =
        settings.isTmdbKeyBuiltIn ? '' : (settings.tmdbApiKey ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return Column(
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
          S.of(context).credentialsPlatformsAvailable,
          settings.platformCount.toString(),
          Icons.videogame_asset,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: '$label: ',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              children: <TextSpan>[
                TextSpan(
                  text: value,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
          onChanged: (String value) {
            setState(() => _steamGridDbApiKey = value);
            if (value.trim().isNotEmpty) {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setSteamGridDbApiKey(value.trim());
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildStatusRow(
          hasKey: settings.hasSteamGridDbKey,
          isBuiltIn: settings.isSteamGridDbKeyBuiltIn,
          hasDefault: ApiDefaults.hasSteamGridDbKey,
          compact: compact,
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
          onChanged: (String value) {
            setState(() => _tmdbApiKey = value);
            if (value.trim().isNotEmpty) {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setTmdbApiKey(value.trim());
            }
          },
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
            selected: <String>{ref.watch(settingsNotifierProvider).tmdbLanguage},
            onSelectionChanged: (Set<String> selection) {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setTmdbLanguage(selection.first);
            },
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildStatusRow(
          hasKey: settings.hasTmdbKey,
          isBuiltIn: settings.isTmdbKeyBuiltIn,
          hasDefault: ApiDefaults.hasTmdbKey,
          compact: compact,
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
      context.showSnack(
        S.of(context).credentialsConnectedSynced,
        type: SnackType.success,
      );
    }
  }

  /// Строка статуса API ключа с кнопками Test/Reset.
  Widget _buildStatusRow({
    required bool hasKey,
    required bool compact,
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
          IconButton.outlined(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt, size: 20),
            tooltip: S.of(context).reset,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (hasKey && onValidate != null)
          IconButton.outlined(
            onPressed: onValidate,
            icon: const Icon(Icons.science_outlined, size: 20),
            tooltip: S.of(context).test,
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

}
