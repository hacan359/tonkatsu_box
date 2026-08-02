import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/cached_image.dart';
import '../../../../../shared/constants/collection_item_ui.dart';

class ThumbnailCell extends StatelessWidget {
  const ThumbnailCell({
    required this.item,
    required this.width,
    required this.height,
    required this.radius,
    super.key,
  });

  final CollectionItem item;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: item.thumbnailUrl != null
            ? CachedImage(
                imageType: item.imageType,
                imageId: item.coverImageId,
                remoteUrl: item.thumbnailUrl!,
                fit: BoxFit.cover,
                memCacheWidth: (width * 2).toInt(),
                placeholder: _placeholder(),
                errorWidget: _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        item.placeholderIcon,
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
  }
}
