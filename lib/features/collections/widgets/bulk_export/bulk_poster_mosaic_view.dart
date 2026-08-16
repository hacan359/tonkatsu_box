import 'dart:io';
import 'dart:math' as math;

import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_assets.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/constants/collection_item_ui.dart';

/// Off-screen widget rendered into a PNG via [RepaintBoundary]; the watermark
/// row matches `TierListExportView` so all PNG exports share one signature.
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

  /// Item id → already-decoded local cover, rendered synchronously:
  /// `CachedImage`'s own `FutureBuilder` would race against `toImage`.
  final Map<int, File>? precachedFiles;

  static const double _posterWidth = 150;
  static const double _aspectRatio = 2 / 3;
  static const double _posterHeight = _posterWidth / _aspectRatio;
  static const double _gap = 4;

  /// `cols ≈ sqrt(n * 1.5)` keeps a 2:3 grid roughly square; clamped so tiny
  /// sets don't look like a strip and huge ones don't blow up GPU memory.
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
            Divider(height: 1, color: AppColors.surfaceBorder),
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
              // Cap decoded resolution so the ImageCache doesn't evict
              // loaded covers when the selection runs into hundreds.
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
                  imageId: item.coverImageId,
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
