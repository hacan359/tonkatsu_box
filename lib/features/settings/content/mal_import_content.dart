import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/import/sources/mal/mal_import_service.dart';
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

/// Flow: file input → progress → navigate to the result screen.
class MalImportContent extends ConsumerStatefulWidget {
  const MalImportContent({super.key});

  @override
  ConsumerState<MalImportContent> createState() => _MalImportContentState();
}

class _MalImportContentState extends ConsumerState<MalImportContent> {
  final TextEditingController _newNameController = TextEditingController(
    text: 'MyAnimeList Import',
  );

  bool _isImporting = false;
  ImportProgress? _progress;

  bool _useNewCollection = true;
  int? _selectedCollectionId;
  bool _overwriteExisting = false;

  _PickedFile? _animePicked;
  _PickedFile? _mangaPicked;

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  bool get _canStart {
    if (_isImporting) return false;
    if (_animePicked == null && _mangaPicked == null) return false;
    if (_useNewCollection) {
      return _newNameController.text.trim().isNotEmpty;
    }
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
      title: l.malImportTitle,
      subtitle: l.malImportSubtitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l.malImportFilesHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _buildFileTile(
          l: l,
          label: l.malImportAnimeFile,
          picked: _animePicked,
          onPick: () => _pickFile(MalFileKind.anime),
          onRemove: () => setState(() => _animePicked = null),
        ),
        _buildFileTile(
          l: l,
          label: l.malImportMangaFile,
          picked: _mangaPicked,
          onPick: () => _pickFile(MalFileKind.manga),
          onRemove: () => setState(() => _mangaPicked = null),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCollectionSelector(l),
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          value: _overwriteExisting,
          onChanged: _isImporting
              ? null
              : (bool v) => setState(() => _overwriteExisting = v),
          title: Text(l.malImportOverwriteExisting),
          subtitle: Text(
            l.malImportOverwriteExistingHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _canStart ? _startImport : null,
            icon: const Icon(Icons.download),
            label: Text(l.malImportButton),
          ),
        ),
      ],
    );
  }

  Widget _buildFileTile({
    required S l,
    required String label,
    required _PickedFile? picked,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: AppTypography.bodySmall),
                if (picked != null)
                  Text(
                    '${picked.fileName} — ${l.malImportEntriesCount(picked.entryCount)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (picked == null)
            TextButton.icon(
              onPressed: _isImporting ? null : onPick,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.malImportPickFiles),
            )
          else
            IconButton(
              onPressed: _isImporting ? null : onRemove,
              icon: const Icon(Icons.close),
              tooltip: l.malImportRemoveFile,
            ),
        ],
      ),
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
            l.malImportTargetCollection,
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
                title: Text(l.malImportCreateNew),
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
                title: Text(l.malImportUseExisting),
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
                labelText: l.malImportNewCollectionName,
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
                    l.malImportNoCollections,
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
                  hint: l.malImportSelectCollection,
                  title: l.malImportSelectCollection,
                  enabled: !_isImporting,
                  onChanged: (int? id) =>
                      setState(() => _selectedCollectionId = id),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l.malImportErrorLoadingCollections,
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
    final bool isRateLimitWait = progress.retryWaitSeconds != null;

    final String stageText = isRateLimitWait
        ? l.malImportRateLimitWait(
            progress.retryWaitSeconds ?? 0,
            progress.retryAttempt ?? 1,
            progress.retryMaxAttempts ?? 3,
          )
        : switch (progress.stage) {
            ImportStage.reading => l.malImportReadingFiles,
            ImportStage.fetchingAnime => l.malImportResolvingAnime,
            ImportStage.fetchingManga => l.malImportResolvingManga,
            ImportStage.completed => l.malImportComplete,
            _ => l.malImportMatching,
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
                value: isRateLimitWait || progress.total == 0
                    ? null
                    : progress.progress,
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
                  l.malImportLookingUp(progress.currentItem!),
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
                l.malImportImported(progress.imported),
              ),
              _buildStatRow(
                Icons.bookmark_add,
                AppColors.brand,
                l.malImportWishlisted(progress.wishlisted),
              ),
              _buildStatRow(
                Icons.sync,
                AppColors.statusInProgress,
                l.malImportUpdated(progress.updated),
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

  Future<void> _pickFile(MalFileKind expectedKind) async {
    final S l = S.of(context);
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: l.malImportPickFiles,
      type: Platform.isAndroid ? FileType.any : FileType.custom,
      allowedExtensions: Platform.isAndroid ? null : <String>['xml'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final String? path = result.files.first.path;
    if (path == null) return;

    final File file = File(path);
    final String fileName = result.files.first.name;
    try {
      final MalImportService service = ref.read(malImportServiceProvider);
      final MalParsedFile parsed = await service.parseFile(file);

      if (parsed.kind != expectedKind) {
        if (!mounted) return;
        context.showSnack(
          parsed.kind == MalFileKind.anime
              ? l.malImportAnimeFile
              : l.malImportMangaFile,
          type: SnackType.info,
        );
      }

      setState(() {
        final _PickedFile pickedFile = _PickedFile(
          file: file,
          fileName: fileName,
          entryCount: parsed.entries.length,
        );
        if (parsed.kind == MalFileKind.anime) {
          _animePicked = pickedFile;
        } else {
          _mangaPicked = pickedFile;
        }
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      context.showSnack(
        l.malImportInvalidFile(e.message),
        type: SnackType.error,
      );
    }
  }

  Future<void> _startImport() async {
    final S l = S.of(context);
    final String authorName =
        ref.read(settingsNotifierProvider).authorName;

    setState(() {
      _isImporting = true;
      _progress = null;
    });

    try {
      final MalImportService service = ref.read(malImportServiceProvider);

      final UniversalImportResult result = await service.import(
        MalImportOptions(
          animeFile: _animePicked?.file,
          mangaFile: _mangaPicked?.file,
          author: authorName,
          newCollectionName: _newNameController.text.trim(),
          overwriteExistingItems: _overwriteExisting,
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
      context.showSnack(
        l.malImportFailed(e.toString()),
        type: SnackType.error,
      );
    }
  }
}

class _PickedFile {
  const _PickedFile({
    required this.file,
    required this.fileName,
    required this.entryCount,
  });

  final File file;
  final String fileName;
  final int entryCount;
}
