import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/models/mood_grid_cell.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import 'mood_grid_cell_media.dart';

/// Renders one cell of a [MoodGrid].
///
/// Layout: cover image on top (aspect 2:3), label underneath. Empty cells
/// show a `+` placeholder. Tap opens the picker; right-click / long-press
/// opens the contextual action menu.
class MoodGridCellWidget extends ConsumerWidget {
  /// Creates a [MoodGridCellWidget].
  const MoodGridCellWidget({
    required this.cell,
    this.onTap,
    this.onContextMenu,
    this.width = 120,
    super.key,
  });

  /// Cell data.
  final MoodGridCell cell;

  /// Primary tap — opens the item picker.
  final VoidCallback? onTap;

  /// Secondary action — right-click on desktop or long-press on mobile.
  /// The [Offset] is the global position to anchor a popup menu (desktop).
  final void Function(Offset)? onContextMenu;

  /// Cell width in logical px.
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPressStart: onContextMenu == null
          ? null
          : (LongPressStartDetails details) =>
              onContextMenu!(details.globalPosition),
      child: InkWell(
        onTap: onTap,
        onSecondaryTapUp: onContextMenu == null
            ? null
            : (TapUpDetails details) => onContextMenu!(details.globalPosition),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 2 / 3,
              child: cell.isEmpty
                  ? _buildEmptyCover()
                  : _buildItemCover(context, ref),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 32,
              child: Center(
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
      ),
    );
  }

  Widget _buildEmptyCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(
            Icons.add,
            size: 32,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCover(BuildContext context, WidgetRef ref) {
    final DatabaseService db = ref.watch(databaseServiceProvider);
    return FutureBuilder<MoodGridCellMedia>(
      future: resolveMoodGridCellMedia(
        db,
        cell.mediaType!,
        cell.externalId!,
        cell.platformId,
      ),
      builder: (BuildContext ctx, AsyncSnapshot<MoodGridCellMedia> snap) {
        if (!snap.hasData) return _buildPlaceholder(Icons.image_outlined);
        final MoodGridCellMedia media = snap.data!;
        final String? url = media.coverUrl;
        if (url == null || url.isEmpty) {
          return _buildPlaceholder(media.placeholderIcon);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: CachedImage(
            imageType: media.imageType,
            imageId: cell.externalId!.toString(),
            remoteUrl: url,
            fit: BoxFit.cover,
            memCacheWidth: (width * 2).toInt(),
            placeholder: _buildPlaceholder(media.placeholderIcon),
            errorWidget: _buildPlaceholder(media.placeholderIcon),
          ),
        );
      },
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
