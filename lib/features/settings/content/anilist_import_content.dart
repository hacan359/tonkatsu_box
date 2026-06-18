import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/anilist_api.dart';
import '../../../core/import/sources/anilist/anilist_import_service.dart';
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
import '../providers/settings_provider.dart';
import '../screens/import_result_screen.dart';
import '../widgets/settings_group.dart';

/// Form + progress UI for importing an AniList user's public anime/manga lists.
class AniListImportContent extends ConsumerStatefulWidget {
  /// Creates an [AniListImportContent].
  const AniListImportContent({super.key});

  @override
  ConsumerState<AniListImportContent> createState() =>
      _AniListImportContentState();
}

class _AniListImportContentState extends ConsumerState<AniListImportContent> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _newNameController = TextEditingController();

  bool _isImporting = false;
  ImportProgress? _progress;

  bool _includeAnime = true;
  bool _includeManga = true;
  ImportMode _mode = ImportMode.newOnly;

  bool _useNewCollection = true;
  int? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final String? saved = prefs.getString(SettingsKeys.aniListUsername);
    if (saved != null && saved.isNotEmpty) {
      _usernameController.text = saved;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newNameController.dispose();
    super.dispose();
  }

  bool get _canStart {
    if (_isImporting) return false;
    if (_usernameController.text.trim().isEmpty) return false;
    if (!_includeAnime && !_includeManga) return false;
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
      title: l.aniListImportTitle,
      subtitle: l.aniListImportSubtitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: TextField(
            controller: _usernameController,
            enabled: !_isImporting,
            decoration: InputDecoration(
              labelText: l.aniListImportUsername,
              hintText: l.aniListImportUsernameHint,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        _buildIncludeSection(l),
        _buildModeSection(l),
        const SizedBox(height: AppSpacing.sm),
        _buildCollectionSelector(l),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _canStart ? _startImport : null,
            icon: const Icon(Icons.download),
            label: Text(l.aniListImportButton),
          ),
        ),
      ],
    );
  }

  Widget _buildIncludeSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l.aniListImportInclude,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        CheckboxListTile(
          value: _includeAnime,
          onChanged: _isImporting
              ? null
              : (bool? v) => setState(() => _includeAnime = v ?? false),
          title: Text(l.aniListImportIncludeAnime),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _includeManga,
          onChanged: _isImporting
              ? null
              : (bool? v) => setState(() => _includeManga = v ?? false),
          title: Text(l.aniListImportIncludeManga),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

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
            l.aniListImportMode,
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
                title: Text(l.aniListImportModeNewOnly),
                subtitle: Text(l.aniListImportModeNewOnlySubtitle),
                leading: const Radio<ImportMode>(value: ImportMode.newOnly),
                dense: true,
                onTap: _isImporting
                    ? null
                    : () => setState(() => _mode = ImportMode.newOnly),
              ),
              ListTile(
                title: Text(l.aniListImportModeOverwrite),
                subtitle: Text(l.aniListImportModeOverwriteSubtitle),
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
            l.aniListImportTargetCollection,
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
                title: Text(l.aniListImportCreateNew),
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
                title: Text(l.aniListImportUseExisting),
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
                labelText: l.aniListImportNewCollectionName,
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
                    l.aniListImportNoCollections,
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
                  hint: l.aniListImportSelectCollection,
                  title: l.aniListImportSelectCollection,
                  enabled: !_isImporting,
                  onChanged: (int? id) =>
                      setState(() => _selectedCollectionId = id),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l.aniListImportErrorLoadingCollections,
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
      ImportStage.fetchingAnime => l.aniListImportFetchingAnime,
      ImportStage.fetchingManga => l.aniListImportFetchingManga,
      ImportStage.completed => l.aniListImportComplete,
      _ => l.aniListImportMatching,
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
                  l.aniListImportLookingUp(progress.currentItem!),
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
                l.aniListImportImported(progress.imported),
              ),
              _buildStatRow(
                Icons.sync,
                AppColors.statusInProgress,
                l.aniListImportUpdated(progress.updated),
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

  String _defaultCollectionName(S l) {
    final String trimmed = _usernameController.text.trim();
    if (trimmed.isEmpty) return l.aniListImportNewCollectionDefault('username');
    return l.aniListImportNewCollectionDefault(trimmed);
  }

  Future<void> _startImport() async {
    final S l = S.of(context);
    final String userName = _usernameController.text.trim();
    if (userName.isEmpty) {
      context.showSnack(
        l.aniListImportEmptyUsername,
        type: SnackType.error,
      );
      return;
    }
    if (!_includeAnime && !_includeManga) {
      context.showSnack(
        l.aniListImportSelectAtLeastOne,
        type: SnackType.error,
      );
      return;
    }

    final String authorName =
        ref.read(settingsNotifierProvider).authorName;
    final String newCollectionName =
        _newNameController.text.trim().isEmpty
            ? _defaultCollectionName(l)
            : _newNameController.text.trim();

    setState(() {
      _isImporting = true;
      _progress = null;
    });

    try {
      final AniListImportService service =
          ref.read(aniListImportServiceProvider);

      final UniversalImportResult result = await service.import(
        AniListImportOptions(
          userName: userName,
          mode: _mode,
          author: authorName,
          newCollectionName: newCollectionName,
          includeAnime: _includeAnime,
          includeManga: _includeManga,
          collectionId: _useNewCollection ? null : _selectedCollectionId,
        ),
        onProgress: (ImportProgress progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );

      // Persist the username for the next import — fire and forget.
      unawaited(
        ref
            .read(sharedPreferencesProvider)
            .setString(SettingsKeys.aniListUsername, userName),
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

      setState(() => _isImporting = false);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              ImportResultScreen(result: result),
        ),
      );
    } on AniListUserNotFoundException {
      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showSnack(
        l.aniListImportUserNotFound(userName),
        type: SnackType.error,
      );
    } on AniListPrivateProfileException {
      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showSnack(
        l.aniListImportPrivateProfile(userName),
        type: SnackType.error,
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showSnack(
        l.aniListImportFailed(e.toString()),
        type: SnackType.error,
      );
    }
  }
}
