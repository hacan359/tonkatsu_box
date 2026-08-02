import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/collection_item_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/rating_badge.dart';

/// A 2:3 cover tile for statistics blocks, with an optional rating badge.
/// Falls back to a media-type icon when the item has no cover (or is null).
class StatsPoster extends StatelessWidget {
  /// Creates a stats poster.
  const StatsPoster({
    this.item,
    this.width,
    this.rating,
    this.radius = AppSpacing.radiusSm,
    super.key,
  });

  /// The item whose cover to show; null renders the placeholder.
  final CollectionItem? item;

  /// Fixed width; null fills the parent.
  final double? width;

  /// Rating shown as a badge in the corner.
  final double? rating;

  /// Corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final CollectionItem? item = this.item;
    final String? url = item?.thumbnailUrl;
    final Widget placeholder = Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(
        item?.placeholderIcon ?? Icons.image_not_supported_outlined,
        color: AppColors.textTertiary,
        size: 20,
      ),
    );

    Widget cover;
    if (item == null || url == null) {
      cover = placeholder;
    } else {
      cover = CachedImage(
        imageType: item.imageType,
        imageId: item.coverImageId,
        remoteUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: width != null ? (width! * 2).toInt() : 300,
        placeholder: placeholder,
        errorWidget: placeholder,
      );
    }

    final double? badgeRating = rating;
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: AppSpacing.posterAspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              cover,
              if (badgeRating != null)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: RatingBadge(rating: badgeRating),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
