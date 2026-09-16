import 'package:core/models/anime.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/image_type.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist_api.dart';
import '../../../core/api/kitsu_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../search/helpers/studio_search.dart';
import '../../search/widgets/item_details_sheet.dart';
import '../../settings/providers/settings_provider.dart'
    show settingsNotifierProvider;
import '../providers/collections_provider.dart';
import 'similars_poster_row.dart';

/// AniList is the similarity engine (Kitsu has no such endpoint), but results
/// are shown as Kitsu titles — only those carry seasons + the episode tracker.
final AutoDisposeFutureProviderFamily<List<Anime>, _AnimeSeedKey>
    _animeRecProvider =
    FutureProvider.autoDispose.family<List<Anime>, _AnimeSeedKey>(
  (Ref ref, _AnimeSeedKey seed) async {
    final AniListApi aniList = ref.watch(aniListApiProvider);
    final KitsuApi kitsu = ref.watch(kitsuApiProvider);
    final int? aniListId = seed.source == DataSource.kitsu
        ? await kitsu.getAniListAnimeId(seed.id)
        : seed.id;
    if (aniListId == null) return <Anime>[];
    final List<Anime> recs = await aniList.getAnimeRecommendations(aniListId);
    if (recs.isEmpty) return recs;
    final Map<int, Anime> kitsuByAniListId = await kitsu.getAnimeByAniListIds(
      <int>[for (final Anime a in recs) a.id],
    );
    // Keep the server's rating order; unmapped titles are dropped.
    return <Anime>[
      for (final Anime a in recs)
        if (kitsuByAniListId[a.id] case final Anime k) k,
    ];
  },
);

typedef _AnimeSeedKey = ({DataSource source, int id});

/// "Similar anime" row on an anime's detail page, seeded by the current
/// title; hidden while loading, on failure or when nothing comes back.
class AnimeSimilarsSection extends ConsumerWidget {
  const AnimeSimilarsSection({
    required this.seed,
    this.onAddAnime,
    super.key,
  });

  /// The anime being viewed; a Kitsu seed is bridged to its AniList id first.
  final Anime seed;

  /// Adds a tapped similar anime to a collection.
  final void Function(Anime anime)? onAddAnime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _AnimeSeedKey seedKey = (source: seed.source, id: seed.id);
    final AsyncValue<List<Anime>> async = ref.watch(_animeRecProvider(seedKey));

    final Map<int, List<CollectedItemInfo>> ownedMap =
        ref.watch(collectedAnimeIdsProvider).valueOrNull ??
            const <int, List<CollectedItemInfo>>{};
    // Recommendations are always Kitsu entities, so match owned by that
    // source regardless of the seed's own source.
    final Set<int> ownedIds = <int>{
      for (final MapEntry<int, List<CollectedItemInfo>> e in ownedMap.entries)
        if (e.value.any(
          (CollectedItemInfo i) => i.source == DataSource.kitsu,
        ))
          e.key,
    };
    final String titleLanguage =
        ref.watch(settingsNotifierProvider).animeMangaTitleLanguage;

    return async.when(
      data: (List<Anime> animes) {
        if (animes.isEmpty) return const SizedBox.shrink();
        return SimilarsPosterRow(
          title: S.of(context).recommendationsTitle,
          cards: <SimilarCardData>[
            for (final Anime anime in animes)
              (
                title: anime.titleByLanguage(titleLanguage),
                imageUrl: anime.coverUrl ?? '',
                cacheImageType: ImageType.animeCover,
                cacheImageId: coverImageId(
                  mediaType: MediaType.anime,
                  externalId: anime.id,
                  source: anime.source,
                ),
                year: anime.releaseYear,
                apiRating: anime.rating10,
                isOwned: ownedIds.contains(anime.id),
                placeholderIcon:
                    MediaTypeTheme.placeholderIconFor(MediaType.anime),
                source: anime.source,
                externalUrl: anime.externalUrl,
                onTap: () => _showAnime(context, ref, anime),
              ),
          ],
        );
      },
      loading: () => const SimilarsPosterRowShimmer(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showAnime(BuildContext context, WidgetRef ref, Anime anime) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => ItemDetailsSheet.anime(
        anime,
        onAddToCollection: () => onAddAnime?.call(anime),
        animeMangaTitleLanguage:
            ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
        onStudioTap: (String studio) => ref
            .read(searchTabRequestProvider.notifier)
            .state = studioSearchRequest(studio),
      ),
    );
  }
}
