// Контент экрана импорта библиотеки Steam (без Scaffold/AppBar).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/steam_import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/import_result_screen.dart';
import '../widgets/settings_group.dart';

/// Контент экрана импорта библиотеки Steam.
///
/// Три состояния: ввод ключей → прогресс → результат.
class SteamImportContent extends ConsumerStatefulWidget {
  /// Создаёт [SteamImportContent].
  const SteamImportContent({super.key});

  @override
  ConsumerState<SteamImportContent> createState() =>
      _SteamImportContentState();
}

class _SteamImportContentState extends ConsumerState<SteamImportContent> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _steamIdController = TextEditingController();

  bool _isImporting = false;
  SteamImportProgress? _progress;
  SteamImportResult? _result;

  bool _rememberCredentials = false;

  // Выбор коллекции
  bool _useNewCollection = true;
  int? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final bool remember =
        prefs.getBool(SettingsKeys.steamRememberCredentials) ?? false;
    if (!remember) return;
    final String? apiKey = prefs.getString(SettingsKeys.steamApiKey);
    final String? steamId = prefs.getString(SettingsKeys.steamId);
    if (apiKey != null) _apiKeyController.text = apiKey;
    if (steamId != null) _steamIdController.text = steamId;
    _rememberCredentials = true;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _steamIdController.dispose();
    super.dispose();
  }

  bool get _canStart =>
      _apiKeyController.text.trim().isNotEmpty &&
      _steamIdController.text.trim().isNotEmpty &&
      (_useNewCollection || _selectedCollectionId != null) &&
      !_isImporting;

  bool get _igdbConnected =>
      ref.read(settingsNotifierProvider).connectionStatus ==
      ConnectionStatus.connected;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    if (_result != null) {
      // Result is shown on ImportResultScreen — this should not happen
      // but keep as fallback.
      return Center(
        child: Text(l.steamImportComplete, style: AppTypography.h3),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!_igdbConnected) ...<Widget>[
          _buildIgdbWarning(l),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildInputSection(l),
        if (_isImporting && _progress != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildProgressSection(l),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IGDB warning
  // ---------------------------------------------------------------------------

  Widget _buildIgdbWarning(S l) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusDropped.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.statusDropped.withAlpha(77)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber, color: AppColors.statusDropped),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l.steamImportIgdbRequired,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input fields
  // ---------------------------------------------------------------------------

  Widget _buildInputSection(S l) {
    return SettingsGroup(
      title: l.steamImportTitle,
      subtitle: l.steamImportSubtitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _apiKeyController,
                enabled: !_isImporting,
                decoration: InputDecoration(
                  labelText: l.steamImportApiKey,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildHelperLink(
                l.steamImportApiKeyHint,
                'https://steamcommunity.com/dev/apikey',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _steamIdController,
                enabled: !_isImporting,
                decoration: InputDecoration(
                  labelText: l.steamImportSteamId,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildHelperLink(
                l.steamImportSteamIdHint,
                'https://steamidfinder.com',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.public,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l.steamImportPublicWarning,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: CheckboxListTile(
            value: _rememberCredentials,
            onChanged: _isImporting
                ? null
                : (bool? value) {
                    setState(() => _rememberCredentials = value ?? false);
                  },
            title: Text(
              l.steamImportRememberCredentials,
              style: AppTypography.bodySmall,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCollectionSelector(l),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _canStart ? _startImport : null,
            icon: const Icon(Icons.download),
            label: Text(l.steamImportButton),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Collection selector
  // ---------------------------------------------------------------------------

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
            l.steamImportTargetCollection,
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
                title: Text(l.steamImportCreateNew),
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
                title: Text(l.steamImportUseExisting),
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
        if (!_useNewCollection)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: collectionsAsync.when(
              data: (List<Collection> collections) {
                if (collections.isEmpty) {
                  return Text(
                    l.steamImportNoCollections,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                final bool selectedExists = _selectedCollectionId != null &&
                    collections.any(
                      (Collection c) => c.id == _selectedCollectionId,
                    );
                return DropdownButtonFormField<int>(
                  initialValue: selectedExists ? _selectedCollectionId : null,
                  hint: Text(l.steamImportSelectCollection),
                  isExpanded: true,
                  items: collections.map((Collection c) {
                    return DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _isImporting
                      ? null
                      : (int? value) {
                          setState(() => _selectedCollectionId = value);
                        },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l.steamImportErrorLoadingCollections,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDropped,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  Widget _buildProgressSection(S l) {
    final SteamImportProgress progress = _progress!;

    final String stageText;
    switch (progress.stage) {
      case SteamImportStage.fetchingLibrary:
        stageText = l.steamImportFetchingLibrary;
      case SteamImportStage.matchingGames:
        stageText = l.steamImportMatching;
      case SteamImportStage.completed:
        stageText = l.steamImportComplete;
    }

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
              if (progress.currentName != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.steamImportLookingUp(progress.currentName!),
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
                l.steamImportImported(progress.importedCount),
              ),
              _buildStatRow(
                Icons.bookmark_add,
                AppColors.brand,
                l.steamImportWishlisted(progress.wishlistedCount),
              ),
              _buildStatRow(
                Icons.sync,
                AppColors.statusInProgress,
                l.steamImportUpdated(progress.updatedCount),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildHelperLink(String text, String url) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.brand,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.brand,
        ),
      ),
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

  // ---------------------------------------------------------------------------
  // Import logic
  // ---------------------------------------------------------------------------

  Future<void> _startImport() async {
    final String apiKey = _apiKeyController.text.trim();
    final String steamId = _steamIdController.text.trim();
    final String authorName =
        ref.read(settingsNotifierProvider).authorName;

    setState(() {
      _isImporting = true;
      _progress = null;
      _result = null;
    });

    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    if (_rememberCredentials) {
      unawaited(prefs.setString(SettingsKeys.steamApiKey, apiKey));
      unawaited(prefs.setString(SettingsKeys.steamId, steamId));
      unawaited(prefs.setBool(SettingsKeys.steamRememberCredentials, true));
    } else {
      unawaited(prefs.remove(SettingsKeys.steamApiKey));
      unawaited(prefs.remove(SettingsKeys.steamId));
      unawaited(prefs.setBool(SettingsKeys.steamRememberCredentials, false));
    }

    try {
      final SteamImportService service =
          ref.read(steamImportServiceProvider);

      // Коллекция создаётся лениво — только после успешной загрузки
      // библиотеки Steam, чтобы не оставлять пустую коллекцию при ошибке.
      final SteamImportResult result = await service.importLibrary(
        apiKey: apiKey,
        steamId: steamId,
        collectionId: _useNewCollection ? null : _selectedCollectionId,
        createCollection: _useNewCollection
            ? () async {
                final DatabaseService db = ref.read(databaseServiceProvider);
                final Collection collection = await db.createCollection(
                  name: 'Steam Library',
                  author: authorName,
                );
                return collection.id;
              }
            : null,
        onProgress: (SteamImportProgress progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );
      final int collectionId = result.collectionId;

      if (!mounted) return;

      ref.invalidate(collectionsProvider);
      ref.invalidate(collectionStatsProvider(collectionId));
      ref.invalidate(collectionCoversProvider(collectionId));
      ref.invalidate(collectionItemsNotifierProvider(collectionId));
      ref.invalidate(canvasNotifierProvider(collectionId));
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);

      // Fetch collection for result screen
      final Collection? resultCollection =
          await ref.read(databaseServiceProvider).getCollectionById(collectionId);

      setState(() {
        _isImporting = false;
        _result = result;
      });

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ImportResultScreen(
            result: result.toUniversal(collection: resultCollection),
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showSnack(e.toString(), type: SnackType.error);
    }
  }
}
