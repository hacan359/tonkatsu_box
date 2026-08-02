import 'dart:async';

import 'package:core/models/collection.dart';
import 'package:core/models/universal_import_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_error_extract.dart';
import '../../../core/api/simkl_api.dart';
import '../../../core/import/sources/anilist/anilist_import_service.dart'
    show ImportMode;
import '../../../core/import/sources/simkl/simkl_import_service.dart';
import '../../../core/services/import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/api_defaults.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/url_launch.dart';
import '../../../shared/widgets/collection_picker_field.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/import_result_screen.dart';
import '../widgets/settings_group.dart';

/// Form + progress UI for importing a Simkl account (movies, shows, anime).
///
/// Auth is the Simkl PIN flow: the app shows a short code, the user confirms
/// it at simkl.com/pin, and the screen polls until the token arrives. The
/// token is kept in memory only, unless the user opts into persisting it.
class SimklImportContent extends ConsumerStatefulWidget {
  /// Creates a [SimklImportContent].
  const SimklImportContent({super.key});

  @override
  ConsumerState<SimklImportContent> createState() =>
      _SimklImportContentState();
}

class _SimklImportContentState extends ConsumerState<SimklImportContent> {
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _clientIdController = TextEditingController();

  // -- Auth state.
  bool _rememberClientId = true;
  String? _token;
  String? _accountName;
  bool _checkingAccount = false;
  bool _rememberToken = false;
  SimklPin? _pin;
  bool _requestingPin = false;
  bool _pinExpired = false;
  Timer? _pollTimer;
  DateTime? _pinDeadline;
  bool _polling = false;

  // -- Import state.
  bool _isImporting = false;
  ImportProgress? _progress;
  ImportMode _mode = ImportMode.newOnly;
  bool _useNewCollection = true;
  int? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final SimklApi api = ref.read(simklApiProvider);

    // Client id: builds with a baked-in key just work, nothing is shown.
    // Keyless builds (F-Droid, self-built) ask for the user's own key.
    _rememberClientId =
        prefs.getBool(SettingsKeys.simklRememberClientId) ?? true;
    if (_needsClientId) {
      final String? savedClientId =
          prefs.getString(SettingsKeys.simklClientId);
      if (savedClientId != null && savedClientId.isNotEmpty) {
        api.setClientId(savedClientId);
        _clientIdController.text = savedClientId;
      }
    }

    _rememberToken = prefs.getBool(SettingsKeys.simklRememberToken) ?? false;
    if (_rememberToken) {
      final String? saved = prefs.getString(SettingsKeys.simklAccessToken);
      if (saved != null && saved.isNotEmpty) {
        _token = saved;
        api.setAccessToken(saved);
        unawaited(_verifyAccount());
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _newNameController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  /// True only in builds without a baked-in `SIMKL_CLIENT_ID`.
  bool get _needsClientId => !ApiDefaults.hasSimklClientId;

  bool get _canStart {
    if (_isImporting) return false;
    if (_token == null) return false;
    if (_useNewCollection) return true;
    return _selectedCollectionId != null;
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildInputSection(l),
        if (_isImporting && _progress != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildProgressSection(l),
        ],
      ],
    );
  }

  Widget _buildInputSection(S l) {
    return SettingsGroup(
      title: l.simklImportTitle,
      subtitle: l.simklImportSubtitle,
      children: <Widget>[
        _buildAccountSection(l),
        _buildModeSection(l),
        const SizedBox(height: AppSpacing.sm),
        _buildCollectionSelector(l),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _canStart ? _startImport : null,
            icon: const Icon(Icons.download),
            label: Text(l.importStart),
          ),
        ),
      ],
    );
  }

  // -- Account / PIN block --------------------------------------------------

  Widget _buildAccountSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_token == null && _needsClientId) _buildClientIdField(l),
        if (_token != null)
          _buildConnectedRow(l)
        else if (_pin != null)
          _buildPinBlock(l)
        else
          _buildGetPinBlock(l),
        CheckboxListTile(
          value: _rememberToken,
          onChanged: _isImporting
              ? null
              : (bool? v) => _setRememberToken(v ?? false),
          title: Text(l.simklRememberToken, style: AppTypography.bodySmall),
          subtitle: Text(
            l.simklRememberTokenSubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
      ],
    );
  }

  /// The app key (`client_id`) — shown only in builds without a baked-in
  /// key (F-Droid, self-built): the import needs the user's own key there.
  /// Official builds never render this block.
  Widget _buildClientIdField(S l) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_clientIdController.text.trim().isEmpty) ...<Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.key_off,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l.simklClientIdRequired,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          TextField(
            controller: _clientIdController,
            enabled: !_isImporting && _pin == null,
            decoration: InputDecoration(
              labelText: l.simklClientIdLabel,
              prefixIcon: const Icon(Icons.key_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () =>
                launchExternalUrl('https://simkl.com/settings/developer/'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.open_in_new,
                    size: 13,
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l.simklGetClientId,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CheckboxListTile(
            value: _rememberClientId,
            onChanged: _isImporting
                ? null
                : (bool? v) => _setRememberClientId(v ?? true),
            title: Text(
              l.simklRememberClientId,
              style: AppTypography.bodySmall,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildGetPinBlock(S l) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_pinExpired) ...<Widget>[
            Text(
              l.simklPinExpired,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton.icon(
            onPressed: _requestingPin ||
                    _isImporting ||
                    (_needsClientId &&
                        _clientIdController.text.trim().isEmpty)
                ? null
                : _requestPin,
            icon: _requestingPin
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.pin_outlined),
            label: Text(_pinExpired ? l.simklGetNewPin : l.simklGetPin),
          ),
        ],
      ),
    );
  }

  Widget _buildPinBlock(S l) {
    final SimklPin pin = _pin!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.simklPinPrompt,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Center(
              child: SelectableText(
                pin.userCode,
                style: AppTypography.h3.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => launchExternalUrl(pin.verificationUrl),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.open_in_new,
                    size: 13,
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l.simklOpenPinPage,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.simklWaitingConfirmation,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedRow(S l) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          if (_checkingAccount)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.check_circle,
              size: 16,
              color: AppColors.statusCompleted,
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _checkingAccount
                  ? l.simklCheckingAccount
                  : l.simklConnectedAs(_accountName ?? 'Simkl'),
              style: AppTypography.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: _isImporting ? null : _disconnect,
            icon: const Icon(Icons.link_off, size: 16),
            label: Text(l.simklDisconnect),
          ),
        ],
      ),
    );
  }

  // -- Mode / collection (the shared import-screen idiom) -------------------

  Widget _buildModeSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l.importMode,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        RadioGroup<ImportMode>(
          groupValue: _mode,
          onChanged: (ImportMode? value) {
            if (value == null || _isImporting) return;
            setState(() => _mode = value);
          },
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text(l.importModeNewOnly),
                subtitle: Text(l.importModeNewOnlySubtitle),
                leading: const Radio<ImportMode>(value: ImportMode.newOnly),
                dense: true,
                onTap: _isImporting
                    ? null
                    : () => setState(() => _mode = ImportMode.newOnly),
              ),
              ListTile(
                title: Text(l.importModeOverwrite),
                subtitle: Text(l.simklImportModeOverwriteSubtitle),
                leading: const Radio<ImportMode>(value: ImportMode.overwrite),
                dense: true,
                onTap: _isImporting
                    ? null
                    : () => setState(() => _mode = ImportMode.overwrite),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionSelector(S l) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l.importTargetCollection,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        RadioGroup<bool>(
          groupValue: _useNewCollection,
          onChanged: (bool? value) {
            if (value == null || _isImporting) return;
            setState(() {
              _useNewCollection = value;
              if (value) _selectedCollectionId = null;
            });
          },
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text(l.importCreateNew),
                leading: const Radio<bool>(value: true),
                dense: true,
                onTap: _isImporting
                    ? null
                    : () => setState(() {
                          _useNewCollection = true;
                          _selectedCollectionId = null;
                        }),
              ),
              ListTile(
                title: Text(l.importUseExistingCollection),
                leading: const Radio<bool>(value: false),
                dense: true,
                onTap: _isImporting
                    ? null
                    : () => setState(() {
                          _useNewCollection = false;
                        }),
              ),
            ],
          ),
        ),
        if (_useNewCollection)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _newNameController,
              enabled: !_isImporting,
              decoration: InputDecoration(
                labelText: l.importNewCollectionName,
                hintText: _defaultCollectionName(l),
              ),
              onChanged: (_) => setState(() {}),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: collectionsAsync.when(
              data: (List<Collection> collections) {
                if (collections.isEmpty) {
                  return Text(
                    l.importNoCollections,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                final bool selectedExists = _selectedCollectionId != null &&
                    collections.any(
                      (Collection c) => c.id == _selectedCollectionId,
                    );
                return CollectionPickerField(
                  value: selectedExists ? _selectedCollectionId : null,
                  hint: l.importSelectCollection,
                  title: l.importSelectCollection,
                  enabled: !_isImporting,
                  onChanged: (int? id) =>
                      setState(() => _selectedCollectionId = id),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l.importErrorLoadingCollections,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDropped,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressSection(S l) {
    final ImportProgress progress = _progress!;

    final String stageText = progress.retryWaitSeconds != null
        ? l.simklImportRateLimitWait(
            progress.retryWaitSeconds ?? 0,
            progress.retryAttempt ?? 1,
            progress.retryMaxAttempts ?? 4,
          )
        : switch (progress.stage) {
            ImportStage.reading => l.simklImportFetching,
            ImportStage.fetchingMovies ||
            ImportStage.fetchingTvShows ||
            ImportStage.fetchingAnime =>
              l.simklImportFetchingDetails,
            ImportStage.restoringMedia => l.simklImportWatchHistory,
            ImportStage.completed => l.importComplete,
            _ => l.importAddingItems,
          };

    return SettingsGroup(
      title: stageText,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LinearProgressIndicator(
                value: progress.total > 0 ? progress.progress : null,
              ),
              if (progress.total > 0) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${progress.current} / ${progress.total}',
                  style: AppTypography.bodySmall,
                ),
              ],
              if (progress.currentItem != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.importProcessingItem(progress.currentItem!),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _buildStatRow(
                Icons.check_circle,
                AppColors.statusCompleted,
                l.importImportedCount(progress.imported),
              ),
              _buildStatRow(
                Icons.sync,
                AppColors.statusInProgress,
                l.importUpdatedCount(progress.updated),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.body),
          ),
        ],
      ),
    );
  }

  // -- Auth flow -------------------------------------------------------------

  Future<void> _requestPin() async {
    final String clientId = _needsClientId
        ? _clientIdController.text.trim()
        : ApiDefaults.simklClientId;
    if (clientId.isEmpty) return;
    ref.read(simklApiProvider).setClientId(clientId);
    if (_needsClientId) _persistClientId(clientId);

    setState(() {
      _requestingPin = true;
      _pinExpired = false;
    });
    try {
      final SimklPin pin = await ref.read(simklApiProvider).requestPin();
      if (!mounted) return;
      setState(() {
        _pin = pin;
        _requestingPin = false;
        _pinDeadline = DateTime.now().add(Duration(seconds: pin.expiresIn));
      });
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        Duration(seconds: pin.interval < 1 ? 5 : pin.interval),
        (_) => _pollOnce(pin.userCode),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _requestingPin = false);
      final ApiError err = extractApiError(e);
      context.showErrorSnack(err.message, detail: err.detail);
    }
  }

  Future<void> _pollOnce(String userCode) async {
    if (!mounted) return;
    // The timer does not await the tick, so a slow request would otherwise
    // stack requests on top of each other.
    if (_polling) return;
    if (_pinDeadline != null && DateTime.now().isAfter(_pinDeadline!)) {
      _pollTimer?.cancel();
      setState(() {
        _pin = null;
        _pinExpired = true;
      });
      return;
    }
    _polling = true;
    try {
      final String? token =
          await ref.read(simklApiProvider).pollPin(userCode);
      if (token == null || !mounted) return;
      _pollTimer?.cancel();
      await _onToken(token);
    } on SimklApiException catch (e) {
      // A transient poll failure is fine — the next tick retries. A client
      // id failure is not: stop and surface it.
      if (!e.isClientIdFailure || !mounted) return;
      _pollTimer?.cancel();
      setState(() => _pin = null);
      context.showErrorSnack(e.message, detail: e.detail);
    } finally {
      _polling = false;
    }
  }

  Future<void> _onToken(String token) async {
    ref.read(simklApiProvider).setAccessToken(token);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    if (_rememberToken) {
      unawaited(prefs.setString(SettingsKeys.simklAccessToken, token));
    }
    setState(() {
      _token = token;
      _pin = null;
    });
    await _verifyAccount();
  }

  /// Fetches the account name so the user can spot a wrong browser session
  /// before anything is imported.
  Future<void> _verifyAccount() async {
    setState(() => _checkingAccount = true);
    try {
      final SimklUser user =
          await ref.read(simklApiProvider).getUserSettings();
      if (!mounted) return;
      setState(() {
        _accountName = user.name.isNotEmpty ? user.name : null;
        _checkingAccount = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _checkingAccount = false);
      if (e is SimklApiException &&
          (e.statusCode == 401 || e.statusCode == 403)) {
        // The stored token is no longer valid — drop it.
        _disconnect();
        return;
      }
      final ApiError err = extractApiError(e);
      context.showErrorSnack(err.message, detail: err.detail);
    }
  }

  void _persistClientId(String clientId) {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    if (_rememberClientId && clientId.isNotEmpty) {
      unawaited(prefs.setString(SettingsKeys.simklClientId, clientId));
    } else {
      unawaited(prefs.remove(SettingsKeys.simklClientId));
    }
  }

  void _setRememberClientId(bool value) {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setBool(SettingsKeys.simklRememberClientId, value));
    setState(() => _rememberClientId = value);
    _persistClientId(_clientIdController.text.trim());
  }

  void _setRememberToken(bool value) {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setBool(SettingsKeys.simklRememberToken, value));
    if (value && _token != null) {
      unawaited(prefs.setString(SettingsKeys.simklAccessToken, _token!));
    } else if (!value) {
      unawaited(prefs.remove(SettingsKeys.simklAccessToken));
    }
    setState(() => _rememberToken = value);
  }

  void _disconnect() {
    _pollTimer?.cancel();
    ref.read(simklApiProvider).clearAccessToken();
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.remove(SettingsKeys.simklAccessToken));
    setState(() {
      _token = null;
      _accountName = null;
      _pin = null;
      _pinExpired = false;
    });
  }

  // -- Import ----------------------------------------------------------------

  String _defaultCollectionName(S l) {
    return l.simklImportNewCollectionDefault(_accountName ?? 'Simkl');
  }

  Future<void> _startImport() async {
    final S l = S.of(context);
    final String authorName = ref.read(settingsNotifierProvider).authorName;
    final String newCollectionName = _newNameController.text.trim().isEmpty
        ? _defaultCollectionName(l)
        : _newNameController.text.trim();

    setState(() {
      _isImporting = true;
      _progress = null;
    });

    try {
      final SimklImportService service =
          ref.read(simklImportServiceProvider);

      final UniversalImportResult result = await service.import(
        SimklImportOptions(
          mode: _mode,
          author: authorName,
          newCollectionName: newCollectionName,
          collectionId: _useNewCollection ? null : _selectedCollectionId,
        ),
        onProgress: (ImportProgress progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() => _isImporting = false);
        if (result.fatalError != null) {
          context.showErrorSnack(
            result.fatalError!,
            detail: result.fatalDetail,
          );
        }
        return;
      }

      final int? collectionId = result.effectiveCollectionId;
      ref.invalidate(collectionsProvider);
      if (collectionId != null) {
        ref.invalidate(collectionStatsProvider(collectionId));
        ref.invalidate(collectionCoversProvider(collectionId));
        ref.invalidate(collectionItemsNotifierProvider(collectionId));
        ref.invalidate(canvasNotifierProvider(collectionId));
      }
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);

      setState(() => _isImporting = false);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              ImportResultScreen(result: result),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      final ApiError err = extractApiError(e);
      context.showErrorSnack(l.importFailed(err.message), detail: err.detail);
    }
  }
}
