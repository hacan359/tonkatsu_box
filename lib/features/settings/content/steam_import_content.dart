import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/import/sources/steam/steam_import_service.dart';
import '../../../core/services/import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/universal_import_result.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/collection_picker_field.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/import_result_screen.dart';
import '../widgets/settings_group.dart';

/// Flow: key input → progress → result.
class SteamImportContent extends ConsumerStatefulWidget {
  const SteamImportContent({super.key});

  @override
  ConsumerState<SteamImportContent> createState() =>
      _SteamImportContentState();
}

class _SteamImportContentState extends ConsumerState<SteamImportContent> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _steamIdController = TextEditingController();

  bool _isImporting = false;
  ImportProgress? _progress;
  UniversalImportResult? _result;

  bool _rememberCredentials = false;

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
                return CollectionPickerField(
                  value: selectedExists ? _selectedCollectionId : null,
                  hint: l.steamImportSelectCollection,
                  title: l.steamImportSelectCollection,
                  enabled: !_isImporting,
                  onChanged: (int? id) =>
                      setState(() => _selectedCollectionId = id),
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

  Widget _buildProgressSection(S l) {
    final ImportProgress progress = _progress!;

    final String stageText = switch (progress.stage) {
      ImportStage.fetchingGames => l.steamImportFetchingLibrary,
      ImportStage.completed => l.steamImportComplete,
      _ => l.steamImportMatching,
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
                  l.steamImportLookingUp(progress.currentItem!),
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
                l.steamImportImported(progress.imported),
              ),
              _buildStatRow(
                Icons.bookmark_add,
                AppColors.brand,
                l.steamImportWishlisted(progress.wishlisted),
              ),
              _buildStatRow(
                Icons.sync,
                AppColors.statusInProgress,
                l.steamImportUpdated(progress.updated),
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

    final SteamImportService service = ref.read(steamImportServiceProvider);

    // The collection is created lazily inside the adapter, only after the Steam
    // library loads, so a failed import never leaves an empty collection behind.
    final UniversalImportResult result = await service.import(
      SteamImportOptions(
        apiKey: apiKey,
        steamId: steamId,
        author: authorName,
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
        context.showSnack(result.fatalError!, type: SnackType.error);
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

    setState(() {
      _isImporting = false;
      _result = result;
    });

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ImportResultScreen(result: result),
      ),
    );
  }
}
