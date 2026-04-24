import '../../../shared/constants/platform_features.dart';
// Контент экрана настройки API ключей (без Scaffold/AppBar).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/constants/api_defaults.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_group.dart';
import '../widgets/status_dot.dart';

/// URL для получения API ключей IGDB.
const String _twitchConsoleUrl = 'https://dev.twitch.tv/console/apps';

/// Контент экрана настройки API ключей.
///
/// Содержит секции IGDB, SteamGridDB и TMDB с полями ввода ключей,
/// проверкой подключения и синхронизацией платформ.
class CredentialsContent extends ConsumerStatefulWidget {
  /// Создаёт [CredentialsContent].
  const CredentialsContent({
    super.key,
    this.isInitialSetup = false,
  });

  /// Флаг начальной настройки (показывает Welcome секцию).
  final bool isInitialSetup;

  @override
  ConsumerState<CredentialsContent> createState() =>
      _CredentialsContentState();
}

class _CredentialsContentState extends ConsumerState<CredentialsContent> {
  String _clientId = '';
  String _clientSecret = '';
  String _steamGridDbApiKey = '';
  String _tmdbApiKey = '';

  // Результат последней валидации ключа (через sync-кнопку).
  // null = ещё не проверяли, success = валиден, error = не валиден.
  StatusType? _sgdbValidated;
  StatusType? _tmdbValidated;
  bool _sgdbValidating = false;
  bool _tmdbValidating = false;

  @override
  void initState() {
    super.initState();
    final SettingsState settings = ref.read(settingsNotifierProvider);
    _clientId = settings.isIgdbKeyBuiltIn ? '' : (settings.clientId ?? '');
    _clientSecret =
        settings.isIgdbKeyBuiltIn ? '' : (settings.clientSecret ?? '');
    _steamGridDbApiKey =
        settings.isSteamGridDbKeyBuiltIn ? '' : (settings.steamGridDbApiKey ?? '');
    _tmdbApiKey =
        settings.isTmdbKeyBuiltIn ? '' : (settings.tmdbApiKey ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final bool compact = isCompactScreen(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.isInitialSetup) ...<Widget>[
          _buildWelcomeSection(),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildIgdbSection(settings, compact),
        const SizedBox(height: AppSpacing.md),
        _buildSteamGridDbSection(settings, compact),
        const SizedBox(height: AppSpacing.md),
        _buildTmdbSection(settings, compact),
        if (settings.errorMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildErrorSection(settings.errorMessage!),
        ],
      ],
    );
  }

  // ==================== Welcome ====================

  Widget _buildWelcomeSection() {
    return SettingsGroup(
      title: S.of(context).credentialsWelcome,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(S.of(context).credentialsWelcomeHint),
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
          ),
        ),
      ],
    );
  }

  // ==================== IGDB ====================

  Widget _buildIgdbSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsIgdbSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconIgdbColor,
          description: S.of(context).welcomeApiIgdbDesc,
          sourceName: 'IGDB',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: <Widget>[
              InlineTextField(
                label: S.of(context).credentialsClientId,
                value: _clientId,
                placeholder: settings.isIgdbKeyBuiltIn
                    ? S.of(context).credentialsUsingBuiltInKey
                    : S.of(context).credentialsClientIdHint,
                compact: compact,
                onChanged: (String value) =>
                    setState(() => _clientId = value),
              ),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
              InlineTextField(
                label: S.of(context).credentialsClientSecret,
                value: _clientSecret,
                placeholder: settings.isIgdbKeyBuiltIn
                    ? S.of(context).credentialsUsingBuiltInKey
                    : S.of(context).credentialsClientSecretHint,
                obscureText: true,
                compact: compact,
                onChanged: (String value) =>
                    setState(() => _clientSecret = value),
              ),
              if (settings.isIgdbKeyBuiltIn) _buildOwnKeyHint(),
              const SizedBox(height: AppSpacing.sm),
              _buildCredentialStatus(
                compact: compact,
                statusType: _connectionStatusType(settings.connectionStatus),
                statusLabel: _connectionLabel(settings.connectionStatus),
                actionTooltip: S.of(context).credentialsVerifyConnection,
                isLoading: settings.isLoading &&
                    settings.connectionStatus == ConnectionStatus.checking,
                onAction: settings.isLoading ? null : _verifyConnection,
                onReset: (settings.hasCredentials &&
                        !settings.isIgdbKeyBuiltIn &&
                        ApiDefaults.hasIgdbKey)
                    ? _resetIgdbCredentials
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== SteamGridDB ====================

  Widget _buildSteamGridDbSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsSteamGridDbSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconSteamGridDbColor,
          description: S.of(context).welcomeApiSgdbDesc,
          sourceName: 'SteamGridDB',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
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
                  setState(() {
                    _steamGridDbApiKey = value;
                    _sgdbValidated = null; // новый ключ — проверка сбрасывается
                  });
                  if (value.trim().isNotEmpty) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setSteamGridDbApiKey(value.trim());
                  }
                },
              ),
              if (settings.isSteamGridDbKeyBuiltIn) _buildOwnKeyHint(),
              const SizedBox(height: AppSpacing.sm),
              _buildCredentialStatus(
                compact: compact,
                statusType: _keyStatusType(
                  hasKey: settings.hasSteamGridDbKey,
                  isBuiltIn: settings.isSteamGridDbKeyBuiltIn,
                  validated: _sgdbValidated,
                ),
                statusLabel: _keyStatusLabel(
                  hasKey: settings.hasSteamGridDbKey,
                  isBuiltIn: settings.isSteamGridDbKeyBuiltIn,
                  validated: _sgdbValidated,
                ),
                actionTooltip: S.of(context).test,
                isLoading: _sgdbValidating,
                onAction: settings.hasSteamGridDbKey
                    ? _validateSteamGridDbKey
                    : null,
                onReset: (settings.hasSteamGridDbKey &&
                        !settings.isSteamGridDbKeyBuiltIn &&
                        ApiDefaults.hasSteamGridDbKey)
                    ? _resetSteamGridDbKey
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TMDB ====================

  Widget _buildTmdbSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsTmdbSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconTmdbColor,
          description: S.of(context).welcomeApiTmdbDesc,
          sourceName: 'TMDB',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
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
                  setState(() {
                    _tmdbApiKey = value;
                    _tmdbValidated = null; // новый ключ — проверка сбрасывается
                  });
                  if (value.trim().isNotEmpty) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setTmdbApiKey(value.trim());
                  }
                },
              ),
              if (settings.isTmdbKeyBuiltIn) _buildOwnKeyHint(),
              const SizedBox(height: AppSpacing.sm),
              _buildCredentialStatus(
                compact: compact,
                statusType: _keyStatusType(
                  hasKey: settings.hasTmdbKey,
                  isBuiltIn: settings.isTmdbKeyBuiltIn,
                  validated: _tmdbValidated,
                ),
                statusLabel: _keyStatusLabel(
                  hasKey: settings.hasTmdbKey,
                  isBuiltIn: settings.isTmdbKeyBuiltIn,
                  validated: _tmdbValidated,
                ),
                actionTooltip: S.of(context).test,
                isLoading: _tmdbValidating,
                onAction: settings.hasTmdbKey ? _validateTmdbKey : null,
                onReset: (settings.hasTmdbKey &&
                        !settings.isTmdbKeyBuiltIn &&
                        ApiDefaults.hasTmdbKey)
                    ? _resetTmdbKey
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== Hints ====================

  /// Хедер секции в стиле wizard: [лого 24x24] + "Описание (Название)".
  Widget _buildSourceHeader({
    required String iconAsset,
    required String description,
    required String sourceName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Image.asset(
            iconAsset,
            width: 24,
            height: 24,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$description ($sourceName)',
              style: AppTypography.h3.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnKeyHint() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textTertiary,
          ),
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

  Widget _buildErrorSection(String errorMessage) {
    return SettingsGroup(
      title: S.of(context).settingsError,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            errorMessage,
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  // ==================== Helpers ====================

  /// Тип StatusDot для API-ключа.
  ///
  /// Приоритет: [validated] > hasKey > !hasKey.
  StatusType _keyStatusType({
    required bool hasKey,
    required bool isBuiltIn,
    StatusType? validated,
  }) {
    if (validated != null) return validated;
    if (isBuiltIn) return StatusType.success;
    return hasKey ? StatusType.success : StatusType.inactive;
  }

  String _keyStatusLabel({
    required bool hasKey,
    required bool isBuiltIn,
    StatusType? validated,
  }) {
    if (validated == StatusType.success) {
      return S.of(context).credentialsConnected;
    }
    if (validated == StatusType.error) {
      return S.of(context).credentialsConnectionError;
    }
    if (isBuiltIn) return S.of(context).credentialsUsingBuiltInKey;
    return hasKey
        ? S.of(context).credentialsApiKeySaved
        : S.of(context).credentialsNoApiKey;
  }

  StatusType _connectionStatusType(ConnectionStatus status) =>
      switch (status) {
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
    final SettingsState settings = ref.read(settingsNotifierProvider);
    // Используем введённые ключи, или текущие из state (built-in)
    final String clientId = _clientId.trim().isNotEmpty
        ? _clientId.trim()
        : (settings.clientId ?? '');
    final String clientSecret = _clientSecret.trim().isNotEmpty
        ? _clientSecret.trim()
        : (settings.clientSecret ?? '');

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

  /// Строка статуса API ключа: StatusDot слева + sync-иконка справа.
  ///
  /// Нажатие на sync-иконку вызывает [onAction] (проверка соединения).
  /// Цвет StatusDot отражает результат: зелёный = OK, красный = ошибка.
  /// Если задан [onReset] — между StatusDot и sync отображается маленькая
  /// reset-иконка.
  Widget _buildCredentialStatus({
    required bool compact,
    required StatusType statusType,
    required String statusLabel,
    required String actionTooltip,
    required VoidCallback? onAction,
    bool isLoading = false,
    VoidCallback? onReset,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: StatusDot(
            label: statusLabel,
            type: statusType,
            compact: compact,
          ),
        ),
        if (onReset != null)
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt, size: 18),
            tooltip: S.of(context).reset,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        IconButton(
          onPressed: onAction,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 20),
          tooltip: actionTooltip,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }

  Future<void> _validateSteamGridDbKey() async {
    setState(() => _sgdbValidating = true);
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool valid = await notifier.validateSteamGridDbKey();
    if (!mounted) return;
    setState(() {
      _sgdbValidating = false;
      _sgdbValidated = valid ? StatusType.success : StatusType.error;
    });
    context.showSnack(
      valid
          ? S.of(context).credentialsSteamGridDbKeyValid
          : S.of(context).credentialsSteamGridDbKeyInvalid,
      type: valid ? SnackType.success : SnackType.error,
    );
  }

  Future<void> _validateTmdbKey() async {
    setState(() => _tmdbValidating = true);
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool valid = await notifier.validateTmdbKey();
    if (!mounted) return;
    setState(() {
      _tmdbValidating = false;
      _tmdbValidated = valid ? StatusType.success : StatusType.error;
    });
    context.showSnack(
      valid
          ? S.of(context).credentialsTmdbKeyValid
          : S.of(context).credentialsTmdbKeyInvalid,
      type: valid ? SnackType.success : SnackType.error,
    );
  }

  void _resetIgdbCredentials() {
    ref
        .read(settingsNotifierProvider.notifier)
        .resetIgdbCredentialsToDefault();
    setState(() {
      _clientId = '';
      _clientSecret = '';
    });
    context.showSnack(
      S.of(context).credentialsResetToBuiltIn,
      type: SnackType.success,
    );
  }

  void _resetSteamGridDbKey() {
    ref
        .read(settingsNotifierProvider.notifier)
        .resetSteamGridDbApiKeyToDefault();
    setState(() => _steamGridDbApiKey = '');
    context.showSnack(
      S.of(context).credentialsResetToBuiltIn,
      type: SnackType.success,
    );
  }

  void _resetTmdbKey() {
    ref.read(settingsNotifierProvider.notifier).resetTmdbApiKeyToDefault();
    setState(() => _tmdbApiKey = '');
    context.showSnack(
      S.of(context).credentialsResetToBuiltIn,
      type: SnackType.success,
    );
  }
}
