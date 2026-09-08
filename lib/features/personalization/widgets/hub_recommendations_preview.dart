import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../recommendations/providers/recommendations_provider.dart';
import '../../recommendations/utils/recommendation_cover.dart';

/// The first "because you liked" group as a strip of posters — as many as fit,
/// no scrolling; the full screen is one tap away.
class HubRecommendationsPreview extends ConsumerWidget {
  const HubRecommendationsPreview({super.key});

  static const double _posterWidth = 56;
  static const double _posterHeight = 84;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<RecommendationResult> async =
        ref.watch(recommendationsProvider);
    return SizedBox(
      height: _posterHeight,
      child: async.when(
        loading: () => const SizedBox.shrink(),
        error: (Object error, StackTrace _) => _Note(
          '${l.settingsError}: $error',
        ),
        data: (RecommendationResult result) {
          final RecommendationRowUi? row = result.rows.firstOrNull;
          if (result.status != RecommendationStatus.ready || row == null) {
            return _Note(l.recommendationsEmpty);
          }
          return _PosterStrip(row: row);
        },
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

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

class _PosterStrip extends StatelessWidget {
  const _PosterStrip({required this.row});

  final RecommendationRowUi row;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = AppSpacing.sm;
        final int fit = ((constraints.maxWidth + gap) /
                (HubRecommendationsPreview._posterWidth + gap))
            .floor();
        final List<RecommendedItem> shown =
            row.items.take(fit.clamp(0, row.items.length)).toList();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < shown.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: gap),
              _Poster(item: shown[i]),
            ],
            if (shown.isEmpty)
              Expanded(
                child: _Note(
                  '${l.recommendationsBecauseLabel} '
                  '${row.becauseTitles.join(', ')}',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.item});

  final RecommendedItem item;

  @override
  Widget build(BuildContext context) {
    final ({ImageType type, String id}) cache = recommendationCoverCache(item);
    final Widget placeholder = Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(
        MediaTypeTheme.placeholderIconFor(item.mediaType),
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: SizedBox(
        width: HubRecommendationsPreview._posterWidth,
        child: CachedImage(
          imageType: cache.type,
          imageId: cache.id,
          remoteUrl: item.posterUrl ?? '',
          fit: BoxFit.cover,
          placeholder: placeholder,
          errorWidget: placeholder,
        ),
      ),
    );
  }
}
