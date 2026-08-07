import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/image_type.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist_api.dart';
import '../../../core/api/kitsu_api.dart';
import '../../../core/api/mangabaka_api.dart';
import '../../../core/api/mangadex_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../search/widgets/item_details_sheet.dart';
import '../../settings/providers/settings_provider.dart'
    show settingsNotifierProvider;
import '../providers/collections_provider.dart';
import 'similars_poster_row.dart';

/// Manga sources the similars row supports; gates the section in the item
/// detail screen.
const Set<DataSource> mangaSimilarsSources = <DataSource>{
  DataSource.mangabaka,
  DataSource.mangadex,
  DataSource.anilist,
  DataSource.kitsu,
};

/// Recommendations for a seed, routed by its source; the record key carries
/// `source` so same-`id`/different-source seeds never collide.
final AutoDisposeFutureProviderFamily<List<Manga>, _MangaSeedKey>
    _mangaRecProvider =
    FutureProvider.autoDispose.family<List<Manga>, _MangaSeedKey>(
  (Ref ref, _MangaSeedKey seed) async {
    switch (seed.source) {
      case DataSource.mangadex:
        if (seed.uuid.isEmpty) return <Manga>[];
        return ref.watch(mangaDexApiProvider).getRecommendations(seed.uuid);
      case DataSource.anilist:
        return ref.watch(aniListApiProvider).getMangaRecommendations(seed.id);
      case DataSource.kitsu:
        // Both clients are read before the await: touching an autoDispose ref
        // after the card unmounts mid-fetch would throw.
        final KitsuApi kitsu = ref.watch(kitsuApiProvider);
        final AniListApi aniList = ref.watch(aniListApiProvider);
        final int? aniListId = await kitsu.getAniListMangaId(seed.id);
        if (aniListId == null) return <Manga>[];
        return aniList.getMangaRecommendations(aniListId);
      case DataSource.mangabaka:
        return ref.watch(mangaBakaApiProvider).getRecommendations(seed.id);
      default:
        return <Manga>[];
    }
  },
);

typedef _MangaSeedKey = ({DataSource source, int id, String uuid});

/// "Similar manga" row on a manga's detail page, seeded by the current title;
/// hidden while loading, on failure or when nothing comes back.
class MangaSimilarsSection extends ConsumerWidget {
  const MangaSimilarsSection({
    required this.seed,
    this.onAddManga,
    super.key,
  });

  /// The manga being viewed; its `source` picks the recommendation backend.
  final Manga seed;

  /// Adds a tapped similar manga to a collection.
  final void Function(Manga manga)? onAddManga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _MangaSeedKey seedKey = (
      source: seed.source,
      id: seed.id,
      uuid: seed.source == DataSource.mangadex
          ? mangaDexUuidFromUrl(seed.externalUrl)
          : '',
    );
    final AsyncValue<List<Manga>> async = ref.watch(_mangaRecProvider(seedKey));

    final Map<int, List<CollectedItemInfo>> ownedMap =
        ref.watch(collectedMangaIdsProvider).valueOrNull ??
            const <int, List<CollectedItemInfo>>{};
    // Recommendations all share one source (AniList for a Kitsu seed), so
    // match owned by it (a MangaBaka id can equal a MangaDex hash id).
    final DataSource recSource =
        seed.source == DataSource.kitsu ? DataSource.anilist : seed.source;
    final Set<int> ownedIds = <int>{
      for (final MapEntry<int, List<CollectedItemInfo>> e in ownedMap.entries)
        if (e.value.any((CollectedItemInfo i) => i.source == recSource))
          e.key,
    };
    final String titleLanguage =
        ref.watch(settingsNotifierProvider).animeMangaTitleLanguage;

    return async.when(
      data: (List<Manga> mangas) {
        if (mangas.isEmpty) return const SizedBox.shrink();
        return SimilarsPosterRow(
          title: S.of(context).recommendationsTitle,
          cards: <SimilarCardData>[
            for (final Manga manga in mangas)
              (
                title: manga.titleByLanguage(titleLanguage),
                imageUrl: manga.coverUrl ?? '',
                cacheImageType: ImageType.mangaCover,
                cacheImageId: coverImageId(
                  mediaType: MediaType.manga,
                  externalId: manga.id,
                  source: manga.source,
                ),
                year: manga.releaseYear,
                apiRating: manga.rating10,
                isOwned: ownedIds.contains(manga.id),
                placeholderIcon:
                    MediaTypeTheme.placeholderIconFor(MediaType.manga),
                source: manga.source,
                externalUrl: manga.externalUrl,
                onTap: () => _showManga(context, ref, manga),
              ),
          ],
        );
      },
      loading: () => const SimilarsPosterRowShimmer(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showManga(BuildContext context, WidgetRef ref, Manga manga) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => ItemDetailsSheet.manga(
        manga,
        onAddToCollection: () => onAddManga?.call(manga),
        animeMangaTitleLanguage:
            ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
      ),
    );
  }
}
