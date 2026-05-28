import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/models/collection_item.dart';
import '../../../../shared/theme/app_assets.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/cached_image.dart';

/// Off-screen widget rendered into a PNG via [RepaintBoundary].
///
/// Lays out covers in a dense grid (no labels, no headers); the watermark
/// row at the bottom matches `TierListExportView` so all PNG exports share
/// one signature.
class BulkPosterMosaicView extends StatelessWidget {
  const BulkPosterMosaicView({
    required this.items,
    required this.columns,
    this.repaintKey,
    this.precachedFiles,
    super.key,
  });

  final GlobalKey? repaintKey;
  final List<CollectionItem> items;
  final int columns;

  /// When provided, each item id maps to its already-decoded local cover
  /// file. The tile renders that file synchronously via `Image.file` instead
  /// of going through `CachedImage` — which still spins up its own
  /// `FutureBuilder` and would race against `toImage`.
  final Map<int, File>? precachedFiles;

  static const double _posterWidth = 150;
  static const double _aspectRatio = 2 / 3;
  static const double _posterHeight = _posterWidth / _aspectRatio;
  static const double _gap = 4;

  /// Picks a column count that keeps the canvas roughly square for a portrait
  /// 2:3 aspect: `cols ≈ sqrt(n * 1.5)`. Clamped so tiny sets don't look like a
  /// strip and huge sets don't blow up GPU memory at pixelRatio 2.
  static int autoColumns(int itemCount) {
    if (itemCount <= 0) return 4;
    final int cols = math.sqrt(itemCount * 1.5).round();
    return cols.clamp(4, 20);
  }

  @override
  Widget build(BuildContext context) {
    final double canvasWidth =
        columns * _posterWidth + (columns - 1) * _gap + AppSpacing.md * 2;

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(AppSpacing.md),
        width: canvasWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: <Widget>[
                for (final CollectionItem item in items)
                  SizedBox(
                    width: _posterWidth,
                    height: _posterHeight,
                    child: _PosterTile(
                      item: item,
                      precachedFile: precachedFiles?[item.id],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.surfaceBorder),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Image.asset(AppAssets.logo, width: 16, height: 16),
                const SizedBox(width: 4),
                Text(
                  'made by Tonkatsu Box',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  const _PosterTile({required this.item, this.precachedFile});

  final CollectionItem item;
  final File? precachedFile;

  @override
  Widget build(BuildContext context) {
    final String? url = item.coverUrl ?? item.thumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: precachedFile != null
          ? Image(
              // Cap decoded resolution at the on-canvas size so the
              // ImageCache doesn't evict already-loaded covers when the
              // selection runs into hundreds of items.
              image: ResizeImage(
                FileImage(precachedFile!),
                width: 300,
              ),
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext _, Object _, StackTrace? _) => _placeholder(),
            )
          : url == null
              ? _placeholder()
              : CachedImage(
                  imageType: item.imageType,
                  imageId: item.externalId.toString(),
                  remoteUrl: url,
                  fit: BoxFit.cover,
                  placeholder: _placeholder(),
                  errorWidget: _placeholder(),
                ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(
        item.placeholderIcon,
        color: AppColors.textSecondary,
        size: 48,
      ),
    );
  }
}
