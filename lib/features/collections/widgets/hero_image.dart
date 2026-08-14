import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';

/// On web `CollectionHeroService.resolve` yields a server URL and File()
/// would throw in a browser; on desktop the location is a plain file path.
ImageProvider heroImageProviderFor(String resolvedPath) {
  if (kIsWebBuild) return NetworkImage(resolvedPath);
  return FileImage(File(resolvedPath));
}

/// Full-bleed hero image with one shared cache-width policy, so every hero
/// site resolves to the same ImageCache entry.
class HeroCoverImage extends StatelessWidget {
  const HeroCoverImage({required this.provider, this.alignment, super.key});

  final ImageProvider provider;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    // Quantize to 256px steps so small resizes don't bust the ImageCache.
    final int rawCache = (w * dpr).round().clamp(480, 2560);
    final int cacheW = ((rawCache + 128) ~/ 256) * 256;

    return Image(
      image: ResizeImage(provider, width: cacheW),
      fit: BoxFit.cover,
      alignment: alignment ?? Alignment.topCenter,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => ColoredBox(color: AppColors.surface),
    );
  }
}
