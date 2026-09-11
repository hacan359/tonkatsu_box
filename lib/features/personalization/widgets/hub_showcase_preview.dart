import 'package:core/models/image_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../showcase/models/showcase_item.dart';
import '../../showcase/providers/showcase_rows_provider.dart';
import '../../showcase/providers/showcase_settings_provider.dart';
import '../../showcase/utils/showcase_cover.dart';
import 'hub_poster_strip.dart';

/// The first enabled "out now" row as a strip of posters. Only that one row
/// is fetched here — the landing page must not cost the whole showcase.
class HubShowcasePreview extends ConsumerWidget {
  const HubShowcasePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final ShowcaseSettings settings = ref.watch(showcaseSettingsProvider);
    final ShowcaseRowId? row = ref
        .watch(showcaseRowOrderProvider(ShowcaseGroup.airing))
        .where(settings.isEnabled)
        .firstOrNull;
    if (row == null) {
      return SizedBox(
        height: HubPosterStrip.posterHeight,
        child: HubPreviewNote(l.showcaseAllRowsHidden),
      );
    }
    return SizedBox(
      height: HubPosterStrip.posterHeight,
      child: ref.watch(showcaseRowProvider(row)).when(
            loading: () => const SizedBox.shrink(),
            error: (Object _, StackTrace _) =>
                HubPreviewNote(l.showcaseRowError),
            data: (List<ShowcaseItem> items) => HubPosterStrip(
              posters: items.map(_poster).toList(),
              emptyText: l.showcaseHint,
            ),
          ),
    );
  }

  static HubPoster _poster(ShowcaseItem item) {
    final ({ImageType type, String id}) cache = showcaseCoverCache(item);
    return HubPoster(
      cacheType: cache.type,
      cacheId: cache.id,
      url: item.posterUrl,
      placeholderIcon: MediaTypeTheme.placeholderIconFor(item.mediaType),
    );
  }
}
