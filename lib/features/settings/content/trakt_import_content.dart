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
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../widgets/settings_section.dart';

/// Контент экрана импорта из Trakt.tv ZIP-выгрузки.
///
/// Поддерживает: выбор ZIP файла, preview, настройка опций, прогресс.
/// Используется как standalone в десктопном sidebar и внутри [TraktImportScreen].
class TraktImportContent extends ConsumerStatefulWidget {
  /// Создаёт [TraktImportContent].
  const TraktImportContent({
    super.key,
    this.onImportComplete,
  });

  /// Callback при завершении импорта.
  /// На мобиле — `Navigator.pop()`, на десктопе — сброс формы/snackbar.
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

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildInstructionsSection(context, compact),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
        _buildFilePickerSection(context, compact),
        if (_zipInfo != null && _zipInfo!.isValid) ...<Widget>[
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
          _buildPreviewSection(context, compact),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
          _buildOptionsSection(context, compact),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
          _buildImportButton(context, compact),
        ],
      ],
    );
  }

  Widget _buildInstructionsSection(BuildContext context, bool compact) {
    return SettingsSection(
      title: S.of(context).traktImportFrom,
      icon: Icons.info_outline,
      subtitle: S.of(context).traktImportDescription,
      compact: compact,
      children: const <Widget>[],
    );
  }

  Widget _buildFilePickerSection(BuildContext context, bool compact) {
    return SettingsSection(
      title: S.of(context).traktZipFile,
      icon: Icons.folder_zip,
      compact: compact,
      children: <Widget>[
        if (_isValidating)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_zipPath != null && _zipInfo != null && _zipInfo!.isValid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                const Icon(Icons.check_circle, color: AppColors.statusCompleted,
                    size: 20),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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

  Widget _buildPreviewSection(BuildContext context, bool compact) {
    final TraktZipInfo info = _zipInfo!;

    final S l10n = S.of(context);
    return SettingsSection(
      title: l10n.traktPreview,
      icon: Icons.preview,
      subtitle: l10n.traktUser(info.username),
      compact: compact,
      children: <Widget>[
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
        horizontal: AppSpacing.sm,
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

  Widget _buildOptionsSection(BuildContext context, bool compact) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);

    final S l10n = S.of(context);
    return SettingsSection(
      title: l10n.traktOptions,
      icon: Icons.tune,
      compact: compact,
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
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
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
              ),
              ListTile(
                title: Text(l10n.traktUseExisting),
                leading: const Radio<bool>(value: false),
                dense: true,
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
              loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _buildImportButton(BuildContext context, bool compact) {
    final bool canImport =
        _importWatched || _importRatings || _importWatchlist;
    final bool hasTarget =
        _useNewCollection || _selectedCollectionId != null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.lg,
      ),
      child: FilledButton.icon(
        onPressed: canImport && hasTarget ? _startImport : null,
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
      ref.invalidate(allItemsNotifierProvider);

      final StringBuffer message = StringBuffer(
        S.of(context).traktImportedItems(result.itemsImported),
      );
      if (result.itemsUpdated > 0) {
        message.write(', updated ${result.itemsUpdated}');
      }
      if (result.itemsSkipped > 0) {
        message.write(', skipped ${result.itemsSkipped}');
      }
      if (result.wishlistItemsAdded > 0) {
        message.write(', ${result.wishlistItemsAdded} to wishlist');
      }

      context.showSnack(message.toString(), type: SnackType.success);
      widget.onImportComplete?.call();
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
