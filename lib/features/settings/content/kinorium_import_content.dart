import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/import_service.dart';
import '../../../core/import/sources/kinorium/kinorium_import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/universal_import_result.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/collection_picker_field.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/import_result_screen.dart';
import '../widgets/settings_group.dart';

/// Flow: CSV file pick → options (watchlist toggle, target) → import progress.
class KinoriumImportContent extends ConsumerStatefulWidget {
  const KinoriumImportContent({
    super.key,
    this.onImportComplete,
  });

  final VoidCallback? onImportComplete;

  @override
  ConsumerState<KinoriumImportContent> createState() =>
      _KinoriumImportContentState();
}

class _KinoriumImportContentState extends ConsumerState<KinoriumImportContent> {
  String? _csvPath;
  bool _isWishlist = false;
  bool _importNotes = false;
  bool _useNewCollection = true;
  int? _selectedCollectionId;

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final bool hasOwnTmdbKey =
        settings.hasTmdbKey && !settings.isTmdbKeyBuiltIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!hasOwnTmdbKey) _buildTmdbKeyHint(context),
        _buildFilePickerSection(context),
        if (_csvPath != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildOptionsSection(context),
          const SizedBox(height: AppSpacing.md),
          _buildImportButton(context),
        ],
      ],
    );
  }

  Widget _buildTmdbKeyHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.brand.withAlpha(25),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.brand.withAlpha(80)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.info_outline, color: AppColors.brand, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                S.of(context).kinoriumRecommendOwnTmdbKey,
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.brand),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerSection(BuildContext context) {
    final S l10n = S.of(context);
    return SettingsGroup(
      title: l10n.kinoriumImportFrom,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.kinoriumImportDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (_csvPath != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.check_circle,
                  color: AppColors.statusCompleted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _csvPath!.split(Platform.pathSeparator).last,
                    style: AppTypography.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _pickFile,
                  child: Text(l10n.change),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.kinoriumSelectCsvFile),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionsSection(BuildContext context) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);
    final S l10n = S.of(context);

    return SettingsGroup(
      title: l10n.kinoriumOptions,
      children: <Widget>[
        CheckboxListTile(
          title: Text(l10n.kinoriumIsWatchlist),
          subtitle: Text(l10n.kinoriumIsWatchlistDesc),
          value: _isWishlist,
          dense: true,
          onChanged: (bool? value) {
            setState(() => _isWishlist = value ?? false);
          },
        ),
        CheckboxListTile(
          title: Text(l10n.kinoriumImportNotes),
          subtitle: Text(l10n.kinoriumImportNotesDesc),
          value: _importNotes,
          dense: true,
          onChanged: (bool? value) {
            setState(() => _importNotes = value ?? false);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.kinoriumTargetCollection,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        RadioGroup<bool>(
          groupValue: _useNewCollection,
          onChanged: (bool? value) {
            if (value == null) return;
            setState(() {
              _useNewCollection = value;
              if (value) _selectedCollectionId = null;
            });
          },
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text(l10n.kinoriumCreateNew),
                leading: const Radio<bool>(value: true),
                dense: true,
                onTap: () => setState(() {
                  _useNewCollection = true;
                  _selectedCollectionId = null;
                }),
              ),
              ListTile(
                title: Text(l10n.kinoriumUseExisting),
                leading: const Radio<bool>(value: false),
                dense: true,
                onTap: () => setState(() {
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
                    l10n.kinoriumNoCollections,
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
                  hint: l10n.kinoriumSelectCollection,
                  title: l10n.kinoriumSelectCollection,
                  onChanged: (int? id) =>
                      setState(() => _selectedCollectionId = id),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l10n.kinoriumErrorLoadingCollections,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDropped,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImportButton(BuildContext context) {
    final bool hasTarget =
        _useNewCollection || _selectedCollectionId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: FilledButton.icon(
        onPressed: hasTarget ? _startImport : null,
        icon: const Icon(Icons.download),
        label: Text(S.of(context).kinoriumStartImport),
      ),
    );
  }

  Future<void> _pickFile() async {
    final bool useAny = Platform.isAndroid;
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: S.of(context).kinoriumSelectCsvExport,
      type: useAny ? FileType.any : FileType.custom,
      allowedExtensions: useAny ? null : <String>['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final String? path = result.files.single.path;
    if (path == null) return;

    setState(() => _csvPath = path);
  }

  Future<void> _startImport() async {
    final KinoriumImportService service =
        ref.read(kinoriumImportServiceProvider);

    final ValueNotifier<ImportProgress?> progressNotifier =
        ValueNotifier<ImportProgress?>(null);

    UniversalImportResult? importResult;

    final Future<UniversalImportResult> importFuture = service.import(
      KinoriumImportOptions(
        filePath: _csvPath!,
        collectionId: _useNewCollection ? null : _selectedCollectionId,
        isWishlist: _isWishlist,
        importNotes: _importNotes,
      ),
      onProgress: (ImportProgress progress) {
        progressNotifier.value = progress;
      },
    ).then((UniversalImportResult result) {
      importResult = result;
      return result;
    });

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _KinoriumImportProgressDialog(
        progressNotifier: progressNotifier,
        importFuture: importFuture,
      ),
    );

    progressNotifier.dispose();

    if (importResult == null || !mounted) return;

    final UniversalImportResult result = importResult!;

    if (result.success) {
      ref.invalidate(collectionsProvider);
      final int? cid = result.effectiveCollectionId;
      if (cid != null) {
        ref.invalidate(collectionStatsProvider(cid));
        ref.invalidate(collectionCoversProvider(cid));
        ref.invalidate(collectionItemsNotifierProvider(cid));
      }
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              ImportResultScreen(result: result),
        ),
      );
      if (mounted) {
        widget.onImportComplete?.call();
      }
    } else if (result.fatalError != null) {
      context.showSnack(result.fatalError!, type: SnackType.error);
    }
  }
}

class _KinoriumImportProgressDialog extends StatelessWidget {
  const _KinoriumImportProgressDialog({
    required this.progressNotifier,
    required this.importFuture,
  });

  final ValueNotifier<ImportProgress?> progressNotifier;
  final Future<UniversalImportResult> importFuture;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(S.of(context).kinoriumImporting),
      content: ValueListenableBuilder<ImportProgress?>(
        valueListenable: progressNotifier,
        builder:
            (BuildContext context, ImportProgress? progress, Widget? child) {
          if (progress == null) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                progress.stage.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (progress.message != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  progress.message!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress.total > 0 ? progress.progress : null,
              ),
              if (progress.total > 0) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  '${progress.current} / ${progress.total}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
      actions: <Widget>[
        FutureBuilder<UniversalImportResult>(
          future: importFuture,
          builder: (BuildContext context,
              AsyncSnapshot<UniversalImportResult> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(S.of(context).done),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
