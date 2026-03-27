// Контент экрана импорта данных из Trakt.tv (без Scaffold/AppBar).

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/trakt_zip_import_service.dart';
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

/// Контент экрана импорта из Trakt.tv ZIP-выгрузки.
///
/// Поддерживает: выбор ZIP файла, preview, настройка опций, прогресс.
class TraktImportContent extends ConsumerStatefulWidget {
  /// Создаёт [TraktImportContent].
  const TraktImportContent({
    super.key,
    this.onImportComplete,
  });

  /// Callback при завершении импорта.
  final VoidCallback? onImportComplete;

  @override
  ConsumerState<TraktImportContent> createState() =>
      _TraktImportContentState();
}

class _TraktImportContentState extends ConsumerState<TraktImportContent> {
  TraktZipInfo? _zipInfo;
  String? _zipPath;
  bool _importWatched = true;
  bool _importRatings = true;
  bool _importWatchlist = true;
  bool _useNewCollection = true;
  int? _selectedCollectionId;
  bool _isValidating = false;
  String? _validationError;

  bool get _hasOwnTmdbKey {
    final SettingsState settings = ref.read(settingsNotifierProvider);
    return settings.hasTmdbKey && !settings.isTmdbKeyBuiltIn;
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final bool hasOwnKey =
        settings.hasTmdbKey && !settings.isTmdbKeyBuiltIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!hasOwnKey) _buildTmdbKeyWarning(context),
        _buildFilePickerSection(context),
        if (_zipInfo != null && _zipInfo!.isValid) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildPreviewSection(context),
          const SizedBox(height: AppSpacing.md),
          _buildOptionsSection(context),
          const SizedBox(height: AppSpacing.md),
          _buildImportButton(context),
        ],
      ],
    );
  }

  Widget _buildTmdbKeyWarning(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(25),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.warning.withAlpha(80)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                S.of(context).traktRequiresOwnTmdbKey,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerSection(BuildContext context) {
    return SettingsGroup(
      title: S.of(context).traktImportFrom,
      children: <Widget>[
        // Инструкция по скачиванию данных с Trakt.tv
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            S.of(context).traktImportDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (_isValidating)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_zipPath != null && _zipInfo != null && _zipInfo!.isValid)
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
                    _zipPath!.split(Platform.pathSeparator).last,
                    style: AppTypography.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _pickFile,
                  child: Text(S.of(context).change),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder_open),
                  label: Text(S.of(context).traktSelectZipFile),
                ),
                if (_validationError != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _validationError!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.statusDropped,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    final TraktZipInfo info = _zipInfo!;
    final S l10n = S.of(context);

    return SettingsGroup(
      title: l10n.traktPreview,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            l10n.traktUser(info.username),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _buildPreviewRow(
          Icons.movie,
          l10n.traktWatchedMovies,
          info.watchedMovieCount,
        ),
        _buildPreviewRow(
          Icons.tv,
          l10n.traktWatchedShows,
          info.watchedShowCount,
        ),
        _buildPreviewRow(
          Icons.star,
          l10n.traktRatedMovies,
          info.ratedMovieCount,
        ),
        _buildPreviewRow(
          Icons.star_half,
          l10n.traktRatedShows,
          info.ratedShowCount,
        ),
        _buildPreviewRow(
          Icons.bookmark,
          l10n.traktWatchlist,
          info.watchlistCount,
        ),
      ],
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: AppTypography.body),
          ),
          Text(
            '$count',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(BuildContext context) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);
    final S l10n = S.of(context);

    return SettingsGroup(
      title: l10n.traktOptions,
      children: <Widget>[
        CheckboxListTile(
          title: Text(l10n.traktImportWatched),
          subtitle: Text(l10n.traktImportWatchedDesc),
          value: _importWatched,
          dense: true,
          onChanged: (bool? value) {
            setState(() => _importWatched = value ?? true);
          },
        ),
        CheckboxListTile(
          title: Text(l10n.traktImportRatings),
          subtitle: Text(l10n.traktImportRatingsDesc),
          value: _importRatings,
          dense: true,
          onChanged: (bool? value) {
            setState(() => _importRatings = value ?? true);
          },
        ),
        CheckboxListTile(
          title: Text(l10n.traktImportWatchlist),
          subtitle: Text(l10n.traktImportWatchlistDesc),
          value: _importWatchlist,
          dense: true,
          onChanged: (bool? value) {
            setState(() => _importWatchlist = value ?? true);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.traktTargetCollection,
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
                title: Text(l10n.traktCreateNew),
                leading: const Radio<bool>(value: true),
                dense: true,
                onTap: () => setState(() {
                  _useNewCollection = true;
                  _selectedCollectionId = null;
                }),
              ),
              ListTile(
                title: Text(l10n.traktUseExisting),
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
                    l10n.traktNoCollections,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return DropdownButtonFormField<int>(
                  initialValue: _selectedCollectionId,
                  hint: Text(l10n.traktSelectCollection),
                  isExpanded: true,
                  items: collections.map((Collection c) {
                    return DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() => _selectedCollectionId = value);
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l10n.traktErrorLoadingCollections,
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
    final bool canImport =
        _importWatched || _importRatings || _importWatchlist;
    final bool hasTarget =
        _useNewCollection || _selectedCollectionId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: FilledButton.icon(
        onPressed:
            canImport && hasTarget && _hasOwnTmdbKey ? _startImport : null,
        icon: const Icon(Icons.download),
        label: Text(S.of(context).traktStartImport),
      ),
    );
  }

  Future<void> _pickFile() async {
    final bool useAny = Platform.isAndroid;
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: S.of(context).traktSelectZipExport,
      type: useAny ? FileType.any : FileType.custom,
      allowedExtensions: useAny ? null : <String>['zip'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final String? path = result.files.single.path;
    if (path == null) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
      _zipInfo = null;
      _zipPath = null;
    });

    final TraktZipImportService service =
        ref.read(traktZipImportServiceProvider);
    final TraktZipInfo info = await service.validateZip(path);

    if (!mounted) return;

    setState(() {
      _isValidating = false;
      if (info.isValid) {
        _zipInfo = info;
        _zipPath = path;
        _validationError = null;
      } else {
        _zipInfo = null;
        _zipPath = null;
        _validationError = info.error ?? S.of(context).traktInvalidExport;
      }
    });
  }

  Future<void> _startImport() async {
    final TraktZipImportService service =
        ref.read(traktZipImportServiceProvider);

    final ValueNotifier<ImportProgress?> progressNotifier =
        ValueNotifier<ImportProgress?>(null);

    TraktImportResult? importResult;

    final Future<TraktImportResult> importFuture = service.importFromZip(
      options: TraktImportOptions(
        zipPath: _zipPath!,
        collectionId: _useNewCollection ? null : _selectedCollectionId,
        importWatched: _importWatched,
        importRatings: _importRatings,
        importWatchlist: _importWatchlist,
      ),
      onProgress: (ImportProgress progress) {
        progressNotifier.value = progress;
      },
    ).then((TraktImportResult result) {
      importResult = result;
      return result;
    });

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _TraktImportProgressDialog(
        progressNotifier: progressNotifier,
        importFuture: importFuture,
      ),
    );

    progressNotifier.dispose();

    if (importResult == null || !mounted) return;

    final TraktImportResult result = importResult!;

    if (result.success) {
      ref.invalidate(collectionsProvider);
      if (result.collection != null) {
        final int cid = result.collection!.id;
        ref.invalidate(collectionStatsProvider(cid));
        ref.invalidate(collectionCoversProvider(cid));
        ref.invalidate(collectionItemsNotifierProvider(cid));
        ref.invalidate(canvasNotifierProvider(cid));
      }
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ImportResultScreen(
            result: result.toUniversal(),
          ),
        ),
      );
      if (mounted) {
        widget.onImportComplete?.call();
      }
    } else if (result.error != null) {
      context.showSnack(result.error!, type: SnackType.error);
    }
  }
}

// ---------------------------------------------------------------------------
// Progress Dialog
// ---------------------------------------------------------------------------

class _TraktImportProgressDialog extends StatelessWidget {
  const _TraktImportProgressDialog({
    required this.progressNotifier,
    required this.importFuture,
  });

  final ValueNotifier<ImportProgress?> progressNotifier;
  final Future<TraktImportResult> importFuture;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(S.of(context).traktImporting),
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
        FutureBuilder<TraktImportResult>(
          future: importFuture,
          builder: (BuildContext context,
              AsyncSnapshot<TraktImportResult> snapshot) {
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
