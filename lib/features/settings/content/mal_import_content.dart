// Контент экрана импорта MyAnimeList выгрузки.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/mal_import_service.dart';
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

/// Контент экрана импорта MyAnimeList.
///
/// Состояния: ввод файлов → прогресс → переход на результат.
class MalImportContent extends ConsumerStatefulWidget {
  /// Создаёт [MalImportContent].
  const MalImportContent({super.key});

  @override
  ConsumerState<MalImportContent> createState() => _MalImportContentState();
}

class _MalImportContentState extends ConsumerState<MalImportContent> {
  final TextEditingController _newNameController = TextEditingController(
    text: 'MyAnimeList Import',
  );

  bool _isImporting = false;
  MalImportProgress? _progress;

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

  // -------------------------------------------------------------------------
  // Input
  // -------------------------------------------------------------------------

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
                return DropdownButtonFormField<int>(
                  initialValue: selectedExists ? _selectedCollectionId : null,
                  hint: Text(l.malImportSelectCollection),
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

  // -------------------------------------------------------------------------
  // Progress
  // -------------------------------------------------------------------------

  Widget _buildProgressSection(S l) {
    final MalImportProgress progress = _progress!;

    final String stageText;
    switch (progress.stage) {
      case MalImportStage.readingFiles:
        stageText = l.malImportReadingFiles;
      case MalImportStage.resolvingAnime:
        stageText = l.malImportResolvingAnime;
      case MalImportStage.resolvingManga:
        stageText = l.malImportResolvingManga;
      case MalImportStage.rateLimitWait:
        stageText = l.malImportRateLimitWait(
          progress.rateLimitWaitSeconds ?? 0,
          progress.rateLimitAttempt ?? 1,
          progress.rateLimitMaxAttempts ?? 3,
        );
      case MalImportStage.matchingEntries:
        stageText = l.malImportMatching;
      case MalImportStage.completed:
        stageText = l.malImportComplete;
    }

    final bool isRateLimitWait = progress.stage == MalImportStage.rateLimitWait;

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
              if (progress.currentName != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.malImportLookingUp(progress.currentName!),
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
                l.malImportImported(progress.importedCount),
              ),
              _buildStatRow(
                Icons.bookmark_add,
                AppColors.brand,
                l.malImportWishlisted(progress.wishlistedCount),
              ),
              _buildStatRow(
                Icons.sync,
                AppColors.statusInProgress,
                l.malImportUpdated(progress.updatedCount),
              ),
              if (progress.failedLookupCount > 0)
                _buildStatRow(
                  Icons.warning_amber,
                  AppColors.statusDropped,
                  l.malImportFailedLookup(progress.failedLookupCount),
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

  // -------------------------------------------------------------------------
  // File picking
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Import
  // -------------------------------------------------------------------------

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

      final MalImportResult result = await service.importFiles(
        animeFile: _animePicked?.file,
        mangaFile: _mangaPicked?.file,
        collectionId: _useNewCollection ? null : _selectedCollectionId,
        overwriteExistingItems: _overwriteExisting,
        createCollection: _useNewCollection
            ? () async {
                final DatabaseService db = ref.read(databaseServiceProvider);
                final Collection collection = await db.createCollection(
                  name: _newNameController.text.trim(),
                  author: authorName,
                );
                return collection.id;
              }
            : null,
        onProgress: (MalImportProgress progress) {
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

      final Collection? resultCollection = await ref
          .read(databaseServiceProvider)
          .getCollectionById(collectionId);

      setState(() => _isImporting = false);

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
