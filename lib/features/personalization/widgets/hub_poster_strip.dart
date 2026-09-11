import 'dart:math' as math;

import 'package:core/models/image_type.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';

/// One poster of a hub preview, already reduced to what the strip draws.
class HubPoster {
  const HubPoster({
    required this.cacheType,
    required this.cacheId,
    required this.placeholderIcon,
    this.url,
  });

  final ImageType cacheType;
  final String cacheId;
  final IconData placeholderIcon;
  final String? url;
}

/// As many posters as fit in one line, no scrolling; the full screen is one
/// tap away. [emptyText] shows when nothing fits or there is nothing to show.
class HubPosterStrip extends StatelessWidget {
  const HubPosterStrip({
    required this.posters,
    required this.emptyText,
    super.key,
  });

  static const double posterWidth = 56;
  static const double posterHeight = 84;

  final List<HubPoster> posters;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: posterHeight,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double gap = AppSpacing.sm;
          final int fit =
              ((constraints.maxWidth + gap) / (posterWidth + gap)).floor();
          final List<HubPoster> shown = posters.take(math.max(0, fit)).toList();
          if (shown.isEmpty) return HubPreviewNote(emptyText);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < shown.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: gap),
                _Poster(poster: shown[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class HubPreviewNote extends StatelessWidget {
  const HubPreviewNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.poster});

  final HubPoster poster;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(
        poster.placeholderIcon,
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: SizedBox(
        width: HubPosterStrip.posterWidth,
        child: CachedImage(
          imageType: poster.cacheType,
          imageId: poster.cacheId,
          remoteUrl: poster.url ?? '',
          fit: BoxFit.cover,
          placeholder: placeholder,
          errorWidget: placeholder,
        ),
      ),
    );
  }
}
