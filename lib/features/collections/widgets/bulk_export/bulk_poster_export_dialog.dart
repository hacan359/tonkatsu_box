import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/image_cache_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/extensions/snackbar_extension.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/services/png_export_service.dart';
import 'bulk_poster_mosaic_view.dart';

Future<void> showBulkPosterExportDialog({
  required BuildContext context,
  required List<CollectionItem> items,
  String? collectionName,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => _BulkPosterExportDialog(
      items: items,
      collectionName: collectionName,
    ),
  );
}

class _BulkPosterExportDialog extends ConsumerStatefulWidget {
  const _BulkPosterExportDialog({
    required this.items,
    this.collectionName,
  });

  final List<CollectionItem> items;
  final String? collectionName;

  @override
  ConsumerState<_BulkPosterExportDialog> createState() =>
      _BulkPosterExportDialogState();
}

class _BulkPosterExportDialogState
    extends ConsumerState<_BulkPosterExportDialog> {
  static const int _previewLimit = 120;
  static const int _precacheBatchSize = 32;

  final GlobalKey _repaintKey = GlobalKey();
  final Map<int, File> _precachedFiles = <int, File>{};
  late int _columns;
  bool _saving = false;
  bool _mountFullForExport = false;
  int _precacheDone = 0;
  int _precacheTotal = 0;

  @override
  void initState() {
    super.initState();
    _columns = BulkPosterMosaicView.autoColumns(widget.items.length);
  }

  List<CollectionItem> get _previewItems => widget.items.length > _previewLimit
      ? widget.items.sublist(0, _previewLimit)
      : widget.items;

  bool get _previewIsTruncated => widget.items.length > _previewLimit;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final ThemeData theme = Theme.of(context);

    return Stack(
      children: <Widget>[
        if (_mountFullForExport)
          Positioned(
            left: -100000,
            top: -100000,
            child: Material(
              type: MaterialType.transparency,
              child: BulkPosterMosaicView(
                repaintKey: _repaintKey,
                items: widget.items,
                columns: _columns,
                precachedFiles: _precachedFiles,
              ),
            ),
          ),
        AlertDialog(
          title: Text(l.bulkExportPngTitle),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        l.bulkExportPngColumns,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _columns.toDouble(),
                          min: 4,
                          max: 20,
                          divisions: 16,
                          label: '$_columns',
                          onChanged: _saving
                              ? null
                              : (double v) =>
                                  setState(() => _columns = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$_columns',
                          textAlign: TextAlign.end,
                          style: AppTypography.body.copyWith(
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.surfaceBorder),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: BulkPosterMosaicView(
                        items: _previewItems,
                        columns: _columns,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _previewIsTruncated
                        ? l.bulkExportPngItemsCountPreview(
                            widget.items.length, _previewLimit)
                        : l.bulkExportPngItemsCount(widget.items.length),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (_saving && _precacheTotal > 0) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: _precacheTotal == 0
                          ? null
                          : _precacheDone / _precacheTotal,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.bulkExportPngPreparing(_precacheDone, _precacheTotal),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(l.cancel),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : _handleSave,
              icon: _saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save_alt),
              label: Text(l.bulkExportPngSave),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    final S l = S.of(context);
    setState(() {
      _saving = true;
      _precacheDone = 0;
      _precacheTotal = widget.items.length;
      _precachedFiles.clear();
    });

    await _precacheCovers();
    if (!mounted) return;

    setState(() => _mountFullForExport = true);

    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await SchedulerBinding.instance.endOfFrame;

    final String baseName = widget.collectionName?.trim().isNotEmpty == true
        ? widget.collectionName!.trim()
        : 'collection';
    final String fileName = '${sanitizeFileName(baseName)}.png';

    final double pixelRatio = widget.items.length > 200 ? 1.0 : 2.0;
    final BulkExportResult result = await saveBoundaryAsPng(
      repaintKey: _repaintKey,
      suggestedFileName: fileName,
      saveDialogTitle: l.bulkExportPngTitle,
      pixelRatio: pixelRatio,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _mountFullForExport = false;
      _precacheTotal = 0;
      _precacheDone = 0;
    });

    switch (result.status) {
      case BulkExportStatus.saved:
        Navigator.of(context).pop();
        context.showSnack(l.bulkExportPngSaved, type: SnackType.success);
      case BulkExportStatus.cancelled:
        break;
      case BulkExportStatus.failed:
        context.showSnack(l.bulkExportPngFailed, type: SnackType.error);
    }
  }

  Future<void> _precacheCovers() async {
    final ImageCacheService cache = ref.read(imageCacheServiceProvider);
    final List<CollectionItem> items = widget.items;

    for (int start = 0; start < items.length; start += _precacheBatchSize) {
      if (!mounted) return;
      final int end = (start + _precacheBatchSize).clamp(0, items.length);
      final List<Future<void>> batch = <Future<void>>[];

      for (int i = start; i < end; i++) {
        batch.add(_precacheOne(cache, items[i]));
      }
      await Future.wait(batch);
      if (!mounted) return;
      setState(() => _precacheDone = end);
    }
  }

  Future<void> _precacheOne(
    ImageCacheService cache,
    CollectionItem item,
  ) async {
    final String? url = item.coverUrl ?? item.thumbnailUrl;
    if (url == null) return;
    try {
      ImageResult result = await cache.getImageUri(
        type: item.imageType,
        imageId: item.externalId.toString(),
        remoteUrl: url,
      );
      if (!mounted) return;

      if (result.isMissing) {
        final bool ok = await cache.downloadImage(
          type: item.imageType,
          imageId: item.externalId.toString(),
          remoteUrl: url,
        );
        if (!mounted) return;
        if (ok) {
          result = await cache.getImageUri(
            type: item.imageType,
            imageId: item.externalId.toString(),
            remoteUrl: url,
          );
          if (!mounted) return;
        }
      }

      if (result.uri == null) return;

      if (result.isLocal) {
        final File file = File(result.uri!);
        if (file.existsSync() && file.lengthSync() > 0) {
          // Same ImageProvider key as the off-screen tile — otherwise the
          // tile decodes a second time and skips the warm cache.
          try {
            await precacheImage(
              ResizeImage(FileImage(file), width: 300),
              context,
            );
            if (!mounted) return;
            _precachedFiles[item.id] = file;
          } on Exception {
            // Corrupt cached file — drop it so the next export pulls a fresh
            // copy. Leave _precachedFiles untouched; the tile falls back to
            // a placeholder for this run.
            try {
              await file.delete();
            } on FileSystemException {
              // File already gone or locked — nothing to do.
            }
          }
        }
      } else {
        try {
          await precacheImage(NetworkImage(result.uri!), context);
        } on Exception {
          // Remote URL not loadable — tile will render a placeholder.
        }
      }
    } on Exception {
      // Single cover failing to precache must not abort the whole export.
    }
  }

}
