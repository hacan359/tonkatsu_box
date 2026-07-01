import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/import/sources/igdb_list/igdb_list_import_service.dart';
import '../../../core/services/import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart' as model;
import '../../../shared/models/universal_import_result.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/collection_picker_field.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/widgets/status_chip_row.dart';
import '../../home/providers/all_items_provider.dart';
import '../../search/models/search_source.dart';
import '../../search/utils/filter_ui.dart';
import '../../search/widgets/filter_dropdown.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/import_result_screen.dart';
import '../widgets/settings_group.dart';

/// Flow: CSV file pick → options (status, platform, target) → import progress.
class IgdbListImportContent extends ConsumerStatefulWidget {
  const IgdbListImportContent({super.key});

  @override
  ConsumerState<IgdbListImportContent> createState() =>
      _IgdbListImportContentState();
}

class _IgdbListImportContentState extends ConsumerState<IgdbListImportContent> {
  String? _csvPath;
  ItemStatus _status = ItemStatus.notStarted;
  int? _platformId;
  String? _platformName;
  bool _useNewCollection = true;
  int? _selectedCollectionId;

  List<model.Platform> _platforms = <model.Platform>[];
  bool _platformsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  void _loadPlatforms() {
    final DatabaseService db = ref.read(databaseServiceProvider);
    db.gameDao.getAllPlatforms().then((List<model.Platform> platforms) {
      if (!mounted) return;
      platforms.sort(
        (model.Platform a, model.Platform b) => a.name.compareTo(b.name),
      );
      setState(() {
        _platforms = platforms;
        _platformsLoaded = true;
      });
    });
  }

  bool get _igdbConnected =>
      ref.read(settingsNotifierProvider).connectionStatus ==
      ConnectionStatus.connected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!_igdbConnected) ...<Widget>[
          _buildIgdbWarning(S.of(context)),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildFilePickerSection(context),
        if (_csvPath != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildOptionsSection(context),
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
              l.igdbImportIgdbRequired,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerSection(BuildContext context) {
    final S l = S.of(context);
    return SettingsGroup(
      title: l.igdbImportTitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l.igdbImportDescription,
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
                  child: Text(l.change),
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
              label: Text(l.igdbImportSelectCsvFile),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionsSection(BuildContext context) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);
    final S l = S.of(context);

    return SettingsGroup(
      title: l.igdbImportOptions,
      children: <Widget>[
        _buildStatusSelector(l),
        _buildPlatformSelector(l),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l.igdbImportTargetCollection,
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
                title: Text(l.igdbImportCreateNew),
                leading: const Radio<bool>(value: true),
                dense: true,
                onTap: () => setState(() {
                  _useNewCollection = true;
                  _selectedCollectionId = null;
                }),
              ),
              ListTile(
                title: Text(l.igdbImportUseExisting),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: collectionsAsync.when(
              data: (List<Collection> collections) {
                if (collections.isEmpty) {
                  return Text(
                    l.igdbImportNoCollections,
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
                  hint: l.igdbImportSelectCollection,
                  title: l.igdbImportSelectCollection,
                  onChanged: (int? id) =>
                      setState(() => _selectedCollectionId = id),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l.igdbImportErrorLoadingCollections,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDropped,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _canStart ? _startImport : null,
            icon: const Icon(Icons.download),
            label: Text(l.igdbStartImport),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector(S l) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.igdbImportStatusLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          StatusChipRow(
            status: _status,
            mediaType: MediaType.game,
            onChanged: (ItemStatus status) => setState(() => _status = status),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector(S l) {
    final bool hasValue = _platformId != null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      dense: true,
      title: Text(l.igdbImportPlatformLabel, style: AppTypography.body),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              hasValue ? _platformName ?? '' : l.igdbImportPlatformSelect,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTypography.body.copyWith(
                color: hasValue ? AppColors.brand : AppColors.statusDropped,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, size: 18,
              color: AppColors.textTertiary),
        ],
      ),
      onTap: _platformsLoaded ? _pickPlatform : null,
    );
  }

  bool get _canStart {
    final bool hasTarget = _useNewCollection || _selectedCollectionId != null;
    return hasTarget && _platformId != null;
  }

  Future<void> _pickPlatform() async {
    final S l = S.of(context);
    final List<FilterOption> options = <FilterOption>[
      for (final model.Platform p in _platforms)
        FilterOption(
          id: p.id.toString(),
          label: p.abbreviation != null
              ? '${p.name} (${p.abbreviation})'
              : p.name,
          value: p.id,
        ),
    ];

    final Object? result = await showDialog<Object>(
      context: context,
      builder: (BuildContext context) => SearchableFilterDialog(
        title: l.igdbImportPlatformLabel,
        options: options,
        isLoading: false,
        currentValue: _platformId,
        allLabel: l.igdbImportPlatformSelect,
        showAllOption: false,
      ),
    );
    if (result == null || result == kFilterResetSentinel || !mounted) return;

    if (result is int) {
      setState(() {
        _platformId = result;
        _platformName = options
            .firstWhere((FilterOption o) => o.value == result)
            .label;
      });
    }
  }

  Future<void> _pickFile() async {
    final bool useAny = Platform.isAndroid;
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: S.of(context).igdbImportSelectCsvExport,
      type: useAny ? FileType.any : FileType.custom,
      allowedExtensions: useAny ? null : <String>['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final String? path = result.files.single.path;
    if (path == null) return;

    setState(() {
      _csvPath = path;
      _status = _statusFromFileName(path);
    });
  }

  Future<void> _startImport() async {
    final IgdbListImportService service =
        ref.read(igdbListImportServiceProvider);
    final S l = S.of(context);
    final String authorName = ref.read(settingsNotifierProvider).authorName;

    final ValueNotifier<ImportProgress?> progressNotifier =
        ValueNotifier<ImportProgress?>(null);

    UniversalImportResult? importResult;

    final Future<UniversalImportResult> importFuture = service.import(
      IgdbListImportOptions(
        filePath: _csvPath!,
        author: authorName,
        status: _status,
        platformId: _platformId!,
        wishlistReason: l.igdbReasonNotFound,
        collectionId: _useNewCollection ? null : _selectedCollectionId,
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
      builder: (BuildContext dialogContext) => _IgdbImportProgressDialog(
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
        ref.invalidate(canvasNotifierProvider(cid));
      }
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              ImportResultScreen(result: result),
        ),
      );
    } else if (result.fatalError != null) {
      context.showSnack(result.fatalError!, type: SnackType.error);
    }
  }

  /// Guesses the default status from the export file name (IGDB names each
  /// list export after the list: `played.csv`, `playing.csv`, …).
  ItemStatus _statusFromFileName(String path) {
    final String name = path.split(Platform.pathSeparator).last.toLowerCase();
    if (name.contains('want')) return ItemStatus.planned;
    if (name.contains('playing')) return ItemStatus.inProgress;
    if (name.contains('played')) return ItemStatus.completed;
    return ItemStatus.notStarted;
  }
}

class _IgdbImportProgressDialog extends StatelessWidget {
  const _IgdbImportProgressDialog({
    required this.progressNotifier,
    required this.importFuture,
  });

  final ValueNotifier<ImportProgress?> progressNotifier;
  final Future<UniversalImportResult> importFuture;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(S.of(context).igdbImporting),
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
