import 'package:core/models/mood_grid_cell.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import 'mood_grid_cell_media.dart';

/// One mood-grid cell: 2:3 cover over a label, each its own tap target
/// ([onTap] / [onLabelTap]). Empty cells show a `+` placeholder.
class MoodGridCellWidget extends StatelessWidget {
  const MoodGridCellWidget({
    required this.cell,
    required this.media,
    this.onTap,
    this.onLabelTap,
    this.onContextMenu,
    this.width = 120,
    super.key,
  });

  final MoodGridCell cell;

  /// Resolved cover / title for the cell. Pass [MoodGridCellMedia.empty]
  /// when no media is selected.
  final MoodGridCellMedia media;

  /// Cover tap — usually opens the item picker.
  final VoidCallback? onTap;

  /// Label-zone tap — usually opens the label editor.
  final VoidCallback? onLabelTap;

  /// Secondary action — right-click on desktop, long-press on mobile. The
  /// [Offset] is the global position used to anchor a popup menu.
  final void Function(Offset)? onContextMenu;

  final double width;

  /// Minimum label-zone height; keeps an empty label tappable.
  static const double _labelMinHeight = 32;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onContextMenu == null
          ? null
          : (LongPressStartDetails details) =>
              onContextMenu!(details.globalPosition),
      onSecondaryTapUp: onContextMenu == null
          ? null
          : (TapUpDetails details) => onContextMenu!(details.globalPosition),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: cell.isEmpty ? _buildEmptyCover() : _buildItemCover(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: onLabelTap,
              // Keeps D-pad traversal at one stop per cell; the label zone
              // was never reachable by gamepad before the split either.
              canRequestFocus: false,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                width: double.infinity,
                constraints:
                    const BoxConstraints(minHeight: _labelMinHeight),
                alignment: Alignment.center,
                child: Text(
                  cell.label ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        color: AppColors.surfaceLight,
        child: Center(
          child: Icon(
            Icons.add,
            size: 32,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCover() {
    final String? url = media.coverUrl;
    if (url == null || url.isEmpty) {
      return _buildPlaceholder(media.placeholderIcon);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: CachedImage(
        imageType: media.imageType,
        imageId: coverImageId(
          mediaType: cell.mediaType!,
          externalId: cell.externalId!,
          source: cell.source,
          coverUrl: url,
        ),
        remoteUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: (width * 2).toInt(),
        placeholder: _buildPlaceholder(media.placeholderIcon),
        errorWidget: _buildPlaceholder(media.placeholderIcon),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        color: AppColors.surfaceLight,
        child: Center(
          child: Icon(icon, size: 32, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
