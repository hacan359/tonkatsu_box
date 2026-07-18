import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/services/image_cache_service.dart';
import '../../theme/app_colors.dart';
import '../cached_image.dart';

/// Cover image with loading/error placeholders. Uses the local image cache
/// when both [cacheImageType] and [cacheImageId] are set.
class MediaCoverImage extends StatelessWidget {
  const MediaCoverImage({
    required this.coverUrl,
    required this.placeholderIcon,
    this.cacheImageType,
    this.cacheImageId,
    super.key,
  });

  final String? coverUrl;
  final IconData placeholderIcon;
  final ImageType? cacheImageType;
  final String? cacheImageId;

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    final bool useLocalCache = cacheImageType != null && cacheImageId != null;

    if (useLocalCache) {
      return CachedImage(
        imageType: cacheImageType!,
        imageId: cacheImageId!,
        remoteUrl: coverUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 200,
        placeholder: _buildLoadingPlaceholder(),
        errorWidget: _buildPlaceholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: coverUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      placeholder: (BuildContext ctx, String url) => _buildLoadingPlaceholder(),
      errorWidget: (BuildContext ctx, String url, Object error) =>
          _buildPlaceholder(),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        placeholderIcon,
        size: 32,
        color: AppColors.textTertiary,
      ),
    );
  }
}
