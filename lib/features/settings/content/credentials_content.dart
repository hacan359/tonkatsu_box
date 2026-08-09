import 'package:core/models/data_source.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../core/api/screenscraper_api.dart';
import '../../../core/selfhost/credential_upload.dart';
import '../../../main.dart' show AppRestartScope;
import '../../../shared/constants/api_defaults.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_group.dart';
import '../widgets/status_dot.dart';

const String _twitchConsoleUrl = 'https://dev.twitch.tv/console/apps';

/// Settings screen content for API credentials (IGDB, SteamGridDB, TMDB,
/// ScreenScraper). Hosted inside a parent Scaffold.
class CredentialsContent extends ConsumerStatefulWidget {
  const CredentialsContent({
    super.key,
    this.isInitialSetup = false,
  });

  /// Renders the Welcome section when shown as the first-run flow.
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

  String _tvdbApiKey = '';
  String _comicVineApiKey = '';
  String _googleBooksApiKey = '';
  String _hardcoverApiKey = '';
  String _ssSsid = '';
  String _ssSspassword = '';
  bool _ssQuotaLoading = false;
  String? _ssQuotaError;
  SsUserQuota? _ssQuota;

  StatusType? _sgdbValidated;
  StatusType? _tmdbValidated;

  StatusType? _tvdbValidated;
  StatusType? _comicVineValidated;
  StatusType? _googleBooksValidated;
  StatusType? _hardcoverValidated;
  bool _sgdbValidating = false;
  bool _tmdbValidating = false;

  bool _tvdbValidating = false;
  bool _comicVineValidating = false;
  bool _googleBooksValidating = false;
  bool _hardcoverValidating = false;

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
    _tvdbApiKey =
        settings.isTvdbKeyBuiltIn ? '' : (settings.tvdbApiKey ?? '');
    _comicVineApiKey = settings.comicVineApiKey ?? '';
    _googleBooksApiKey = settings.googleBooksApiKey ?? '';
    _hardcoverApiKey = settings.hardcoverApiKey ?? '';
    _ssSsid = settings.screenScraperSsid ?? '';
    _ssSspassword = settings.screenScraperSspassword ?? '';
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
        // Web has no config-import entry of its own yet, so the fast path to a
        // filled-in screen lives here.
        if (kIsWebBuild) ...<Widget>[
          _buildServerManagedSection(),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildIgdbSection(settings, compact),
        const SizedBox(height: AppSpacing.md),
        _buildSteamGridDbSection(settings, compact),
        const SizedBox(height: AppSpacing.md),
        _buildTmdbSection(settings, compact),
        _buildTvdbSection(settings, compact),
        const SizedBox(height: AppSpacing.md),
        _buildComicVineSection(settings, compact),
        const SizedBox(height: AppSpacing.md),
        _buildGoogleBooksSection(settings, compact),
        const SizedBox(height: AppSpacing.md),
        _buildHardcoverSection(settings, compact),
        const SizedBox(height: AppSpacing.md),
        _buildScreenScraperSection(settings, compact),
        if (settings.errorMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildErrorSection(settings.errorMessage!),
        ],
      ],
    );
  }


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


  Widget _buildIgdbSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsIgdbSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconIgdbColor,
          description: S.of(context).welcomeApiIgdbDesc,
          sourceName: DataSource.igdb.label,
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
                    _sgdbValidated = null;
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


  Widget _buildTmdbSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsTmdbSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconTmdbColor,
          description: S.of(context).welcomeApiTmdbDesc,
          sourceName: DataSource.tmdb.label,
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
                    _tmdbValidated = null;
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


  Widget _buildTvdbSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsTvdbSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconTvdbColor,
          description: S.of(context).welcomeApiTvdbDesc,
          sourceName: DataSource.tvdb.brandName,
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
                value: _tvdbApiKey,
                placeholder: settings.isTvdbKeyBuiltIn
                    ? S.of(context).credentialsUsingBuiltInKey
                    : S.of(context).credentialsEnterTvdbKey,
                obscureText: true,
                compact: compact,
                onChanged: (String value) {
                  setState(() {
                    _tvdbApiKey = value;
                    _tvdbValidated = null;
                  });
                  if (value.trim().isNotEmpty) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setTvdbApiKey(value.trim());
                  }
                },
              ),
              if (settings.isTvdbKeyBuiltIn) _buildOwnKeyHint(),
              const SizedBox(height: AppSpacing.sm),
              _buildCredentialStatus(
                compact: compact,
                statusType: _keyStatusType(
                  hasKey: settings.hasTvdbKey,
                  isBuiltIn: settings.isTvdbKeyBuiltIn,
                  validated: _tvdbValidated,
                ),
                statusLabel: _keyStatusLabel(
                  hasKey: settings.hasTvdbKey,
                  isBuiltIn: settings.isTvdbKeyBuiltIn,
                  validated: _tvdbValidated,
                ),
                actionTooltip: S.of(context).test,
                isLoading: _tvdbValidating,
                onAction: settings.hasTvdbKey ? _validateTvdbKey : null,
                onReset: (settings.hasTvdbKey &&
                        !settings.isTvdbKeyBuiltIn &&
                        ApiDefaults.hasTvdbKey)
                    ? _resetTvdbKey
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildComicVineSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsComicVineSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconComicVineColor,
          description: S.of(context).welcomeApiComicVineDesc,
          sourceName: DataSource.comicVine.label,
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
                value: _comicVineApiKey,
                placeholder: S.of(context).credentialsEnterComicVineKey,
                obscureText: true,
                compact: compact,
                onChanged: (String value) {
                  setState(() {
                    _comicVineApiKey = value;
                    _comicVineValidated = null;
                  });
                  if (value.trim().isNotEmpty) {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setComicVineApiKey(value.trim());
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildCredentialStatus(
                compact: compact,
                statusType: _keyStatusType(
                  hasKey: settings.hasComicVineKey,
                  isBuiltIn: false,
                  validated: _comicVineValidated,
                ),
                statusLabel: _keyStatusLabel(
                  hasKey: settings.hasComicVineKey,
                  isBuiltIn: false,
                  validated: _comicVineValidated,
                ),
                actionTooltip: S.of(context).test,
                isLoading: _comicVineValidating,
                onAction:
                    settings.hasComicVineKey ? _validateComicVineKey : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _validateComicVineKey() async {
    setState(() => _comicVineValidating = true);
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool valid = await notifier.validateComicVineKey();
    if (!mounted) return;
    setState(() {
      _comicVineValidating = false;
      _comicVineValidated = valid ? StatusType.success : StatusType.error;
    });
    context.showSnack(
      valid
          ? S.of(context).credentialsComicVineKeyValid
          : S.of(context).credentialsComicVineKeyInvalid,
      type: valid ? SnackType.success : SnackType.error,
    );
  }


  Widget _buildGoogleBooksSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsGoogleBooksSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconGoogleBooksColor,
          description: S.of(context).welcomeApiGoogleBooksDesc,
          sourceName: DataSource.googleBooks.label,
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
                value: _googleBooksApiKey,
                placeholder: S.of(context).credentialsEnterGoogleBooksKey,
                obscureText: true,
                compact: compact,
                onChanged: (String value) {
                  setState(() {
                    _googleBooksApiKey = value;
                    _googleBooksValidated = null;
                  });
                  // The key is optional, so an empty value clears it (search
                  // still works anonymously).
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setGoogleBooksApiKey(value.trim());
                },
              ),
              _buildOwnKeyHint(),
              const SizedBox(height: AppSpacing.sm),
              _buildCredentialStatus(
                compact: compact,
                statusType: _keyStatusType(
                  hasKey: settings.hasGoogleBooksKey,
                  isBuiltIn: false,
                  validated: _googleBooksValidated,
                ),
                statusLabel: _keyStatusLabel(
                  hasKey: settings.hasGoogleBooksKey,
                  isBuiltIn: false,
                  validated: _googleBooksValidated,
                ),
                actionTooltip: S.of(context).test,
                isLoading: _googleBooksValidating,
                onAction: settings.hasGoogleBooksKey
                    ? _validateGoogleBooksKey
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _validateGoogleBooksKey() async {
    setState(() => _googleBooksValidating = true);
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool valid = await notifier.validateGoogleBooksKey();
    if (!mounted) return;
    setState(() {
      _googleBooksValidating = false;
      _googleBooksValidated = valid ? StatusType.success : StatusType.error;
    });
    context.showSnack(
      valid
          ? S.of(context).credentialsGoogleBooksKeyValid
          : S.of(context).credentialsGoogleBooksKeyInvalid,
      type: valid ? SnackType.success : SnackType.error,
    );
  }


  Widget _buildHardcoverSection(SettingsState settings, bool compact) {
    return SettingsGroup(
      title: S.of(context).credentialsHardcoverSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconHardcoverColor,
          description: S.of(context).welcomeApiHardcoverDesc,
          sourceName: DataSource.hardcover.label,
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
                value: _hardcoverApiKey,
                placeholder: S.of(context).credentialsEnterHardcoverKey,
                obscureText: true,
                compact: compact,
                onChanged: (String value) {
                  setState(() {
                    _hardcoverApiKey = value;
                    _hardcoverValidated = null;
                  });
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setHardcoverApiKey(value.trim());
                },
              ),
              _buildOwnKeyHint(),
              const SizedBox(height: AppSpacing.sm),
              _buildCredentialStatus(
                compact: compact,
                statusType: _keyStatusType(
                  hasKey: settings.hasHardcoverKey,
                  isBuiltIn: false,
                  validated: _hardcoverValidated,
                ),
                statusLabel: _keyStatusLabel(
                  hasKey: settings.hasHardcoverKey,
                  isBuiltIn: false,
                  validated: _hardcoverValidated,
                ),
                actionTooltip: S.of(context).test,
                isLoading: _hardcoverValidating,
                onAction:
                    settings.hasHardcoverKey ? _validateHardcoverKey : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _validateHardcoverKey() async {
    setState(() => _hardcoverValidating = true);
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool valid = await notifier.validateHardcoverKey();
    if (!mounted) return;
    setState(() {
      _hardcoverValidating = false;
      _hardcoverValidated = valid ? StatusType.success : StatusType.error;
    });
    context.showSnack(
      valid
          ? S.of(context).credentialsHardcoverKeyValid
          : S.of(context).credentialsHardcoverKeyInvalid,
      type: valid ? SnackType.success : SnackType.error,
    );
  }


  Widget _buildSourceHeader({
    required String description,
    required String sourceName,
    String? iconAsset,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          if (iconAsset != null)
            Image.asset(
              iconAsset,
              width: 24,
              height: 24,
              filterQuality: FilterQuality.medium,
            )
          else
            Icon(
              icon ?? Icons.api,
              size: 24,
              color: AppColors.textSecondary,
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
          Icon(
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

  Widget _buildServerManagedSection() {
    final S l = S.of(context);
    return SettingsGroup(
      title: l.credentialsServerManagedTitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.credentialsServerManagedBody,
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _uploadKeysFromConfig,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(l.credentialsUploadFromConfig),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _uploading = false;

  /// Reads the exported config in the tab and hands only its credentials to
  /// the server — nothing is written to this browser.
  Future<void> _uploadKeysFromConfig() async {
    setState(() => _uploading = true);
    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        withData: true,
      );
      final Uint8List? bytes = picked?.files.single.bytes;
      if (bytes == null) return;

      final Map<String, String> credentials = credentialsFromConfig(bytes);
      if (credentials.isEmpty) {
        if (mounted) context.showSnack(S.of(context).credentialsUploadNoKeys);
        return;
      }

      final Map<String, bool> stored = await uploadCredentials(credentials);
      if (!mounted) return;
      context.showSnack(S.of(context).credentialsUploadDone(stored.length));
      // The key store is built once at boot from /proxy/keys, so the tab keeps
      // saying "no key" until it reloads.
      await AppRestartScope.restart(context);
    } on Object catch (e) {
      if (mounted) context.showSnack('$e', type: SnackType.error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

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

  Future<void> _verifyConnection() async {
    final SettingsState settings = ref.read(settingsNotifierProvider);
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

  Future<void> _validateTvdbKey() async {
    setState(() => _tvdbValidating = true);
    final SettingsNotifier notifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool valid = await notifier.validateTvdbKey();
    if (!mounted) return;
    setState(() {
      _tvdbValidating = false;
      _tvdbValidated = valid ? StatusType.success : StatusType.error;
    });
    context.showSnack(
      valid
          ? S.of(context).credentialsTvdbKeyValid
          : S.of(context).credentialsTvdbKeyInvalid,
      type: valid ? SnackType.success : SnackType.error,
    );
  }

  void _resetTvdbKey() {
    ref.read(settingsNotifierProvider.notifier).resetTvdbApiKeyToDefault();
    setState(() => _tvdbApiKey = '');
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


  Widget _buildScreenScraperSection(SettingsState settings, bool compact) {
    final S l = S.of(context);
    return SettingsGroup(
      title: l.screenScraperSection,
      children: <Widget>[
        _buildSourceHeader(
          iconAsset: AppAssets.iconScreenScraperColor,
          description: l.screenScraperSourceDesc,
          sourceName: 'ScreenScraper',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.screenScraperUserCredsHint,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              InlineTextField(
                label: l.screenScraperSsidLabel,
                value: _ssSsid,
                placeholder: l.screenScraperSsidPlaceholder,
                compact: compact,
                onChanged: (String value) {
                  setState(() => _ssSsid = value);
                  _saveScreenScraperCreds();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              InlineTextField(
                label: l.screenScraperSspasswordLabel,
                value: _ssSspassword,
                placeholder: l.screenScraperSspasswordPlaceholder,
                obscureText: true,
                compact: compact,
                onChanged: (String value) {
                  setState(() => _ssSspassword = value);
                  _saveScreenScraperCreds();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: (settings.hasScreenScraperCreds &&
                          ApiDefaults.hasScreenScraperDevCreds &&
                          !_ssQuotaLoading)
                      ? _fetchScreenScraperQuota
                      : null,
                  icon: _ssQuotaLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_outlined, size: 16),
                  label: Text(l.screenScraperCheckQuota),
                ),
              ),
              if (_ssQuotaError != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _ssQuotaError!,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.error),
                ),
              ],
              if (_ssQuota != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                _buildScreenScraperQuotaInfo(_ssQuota!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScreenScraperQuotaInfo(SsUserQuota q) {
    final S l = S.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ssQuotaRow(
              l.screenScraperRequestsToday, '${q.requestsToday} / ${q.maxPerDay}'),
          _ssQuotaRow(l.screenScraperPerMinLimit, q.maxPerMinute.toString()),
          _ssQuotaRow(l.screenScraperParallelThreads, q.maxThreads.toString()),
          _ssQuotaRow(l.screenScraperAccountLevel, q.level.toString()),
        ],
      ),
    );
  }

  Widget _ssQuotaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: AppTypography.caption
                .copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScreenScraperCreds() async {
    await ref.read(settingsNotifierProvider.notifier).setScreenScraperCredentials(
          ssid: _ssSsid.trim(),
          sspassword: _ssSspassword.trim(),
        );
  }

  Future<void> _fetchScreenScraperQuota() async {
    setState(() {
      _ssQuotaLoading = true;
      _ssQuotaError = null;
      _ssQuota = null;
    });
    try {
      final ScreenScraperApi api = ref.read(screenScraperApiProvider);
      api.setUserCredentials(
        ssid: _ssSsid.trim(),
        sspassword: _ssSspassword.trim(),
      );
      final SsUserQuota q = await api.getUserInfo();
      if (!mounted) return;
      setState(() {
        _ssQuota = q;
        _ssQuotaLoading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _ssQuotaError = e.toString();
        _ssQuotaLoading = false;
      });
    }
  }
}
