import 'package:flutter/material.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/cached_image.dart';

const double kTierItemWidth = 90;
const double kTierItemImageHeight = 120;
const double kTierItemMinLabelHeight = 32;
const double kTierItemMinTotalHeight =
    kTierItemImageHeight + kTierItemMinLabelHeight;

/// displayName is resolved in the parent so each card doesn't subscribe
/// to the settings provider on its own.
class TierItemCard extends StatelessWidget {
  const TierItemCard({
    required this.item,
    required this.displayName,
    this.isDraggable = false,
    this.showLabel = true,
    this.width = kTierItemWidth,
    this.height = kTierItemImageHeight,
    this.labelHeight = kTierItemMinLabelHeight,
    this.platformOverlayAsset,
    super.key,
  });

  final CollectionItem item;
  final String displayName;
  final bool isDraggable;
  final bool showLabel;
  final double width;
  final double height;

  /// Must match the height the parent reserves for the card (e.g. GridView
  /// `mainAxisExtent`) — otherwise the column overflows.
  final double labelHeight;

  final String? platformOverlayAsset;

  @override
  Widget build(BuildContext context) {
    final Widget card = _buildCard(displayName);
    if (!isDraggable) return card;

    final Widget feedback = Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.7,
        child: _buildCard(displayName),
      ),
    );
    final Widget childWhenDragging = Opacity(
      opacity: 0.3,
      child: card,
    );

    // Tap-drag conflicts with scrolling on mobile — require long-press there.
    if (kIsMobile) {
      return LongPressDraggable<int>(
        data: item.id,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: card,
      );
    }
    return Draggable<int>(
      data: item.id,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: card,
    );
  }

  Widget _buildCard(String displayName) {
    // Disable Tooltip's long-press trigger when the card is draggable on
    // mobile — otherwise it eats the gesture before LongPressDraggable.
    final TooltipTriggerMode? triggerMode = kIsMobile && isDraggable
        ? TooltipTriggerMode.manual
        : null;
    return Tooltip(
      message: displayName,
      triggerMode: triggerMode,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    item.thumbnailUrl != null
                        ? CachedImage(
                            imageType: item.imageType,
                            imageId: item.coverImageId,
                            remoteUrl: item.thumbnailUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: (width * 2).toInt(),
                            placeholder: _buildPlaceholder(),
                            errorWidget: _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                    if (platformOverlayAsset != null)
                      Positioned.fill(
                        child: Image.asset(
                          platformOverlayAsset!,
                          fit: BoxFit.fill,
                        ),
                      ),
                    if (item.mediaType == MediaType.game &&
                        item.platform != null &&
                        platformOverlayAsset == null)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: item.platform!.familyColor.withAlpha(210),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            item.platform!.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (showLabel)
              Container(
                width: width,
                height: labelHeight,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppSpacing.radiusXs),
                    bottomRight: Radius.circular(AppSpacing.radiusXs),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 2,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}
