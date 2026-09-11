import 'package:core/models/image_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../recommendations/providers/recommendations_provider.dart';
import '../../recommendations/utils/recommendation_cover.dart';
import 'hub_poster_strip.dart';

/// The first "because you liked" group as a strip of posters.
class HubRecommendationsPreview extends ConsumerWidget {
  const HubRecommendationsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<RecommendationResult> async =
        ref.watch(recommendationsProvider);
    return SizedBox(
      height: HubPosterStrip.posterHeight,
      child: async.when(
        loading: () => const SizedBox.shrink(),
        error: (Object error, StackTrace _) => HubPreviewNote(
          '${l.settingsError}: $error',
        ),
        data: (RecommendationResult result) {
          final RecommendationRowUi? row = result.rows.firstOrNull;
          if (result.status != RecommendationStatus.ready || row == null) {
            return HubPreviewNote(l.recommendationsEmpty);
          }
          return HubPosterStrip(
            posters: row.items.map(_poster).toList(),
            emptyText:
                '${l.recommendationsBecauseLabel} ${row.becauseTitles.join(', ')}',
          );
        },
      ),
    );
  }

  static HubPoster _poster(RecommendedItem item) {
    final ({ImageType type, String id}) cache = recommendationCoverCache(item);
    return HubPoster(
      cacheType: cache.type,
      cacheId: cache.id,
      url: item.posterUrl,
      placeholderIcon: MediaTypeTheme.placeholderIconFor(item.mediaType),
    );
  }
}
