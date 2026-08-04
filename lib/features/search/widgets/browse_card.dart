import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/utils/url_launch.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../collections/providers/collections_provider.dart';

/// Sets of external IDs already in the user's collections. Multi-source types
/// are keyed by `(source, id)` — providers hand out colliding numeric ids, so
/// an id alone would badge the wrong card.
typedef CollectedIds = ({
  Set<int> tmdbIds,
  Set<(DataSource, int)> tvKeys,
  Set<int> gameIds,
  Set<int> vnIds,
  Set<(DataSource, int)> mangaKeys,
  Set<(DataSource, int)> animeKeys,
  Set<(DataSource, int)> bookKeys,
});

const CollectedIds kNoCollected = (
  tmdbIds: <int>{},
  tvKeys: <(DataSource, int)>{},
  gameIds: <int>{},
  vnIds: <int>{},
  mangaKeys: <(DataSource, int)>{},
  animeKeys: <(DataSource, int)>{},
  bookKeys: <(DataSource, int)>{},
);

final FutureProvider<CollectedIds> collectedIdsProvider =
    FutureProvider<CollectedIds>((Ref ref) async {
  final Map<int, List<CollectedItemInfo>> movies =
      await ref.watch(collectedMovieIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> tvShows =
      await ref.watch(collectedTvShowIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> animations =
      await ref.watch(collectedAnimationIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> games =
      await ref.watch(collectedGameIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> visualNovels =
      await ref.watch(collectedVisualNovelIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> mangas =
      await ref.watch(collectedMangaIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> animes =
      await ref.watch(collectedAnimeIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> books =
      await ref.watch(collectedBookIdsProvider.future);

  return (
    tmdbIds: <int>{...movies.keys, ...tvShows.keys, ...animations.keys},
    tvKeys: <(DataSource, int)>{
      ...tvShows.sourceKeys,
      ...animations.sourceKeys,
    },
    gameIds: games.keys.toSet(),
    vnIds: visualNovels.keys.toSet(),
    mangaKeys: mangas.sourceKeys,
    animeKeys: animes.sourceKeys,
    bookKeys: books.sourceKeys,
  );
});

/// Joins up to 3 platform names, appending "+N" for the rest.
String? buildPlatformLabel(
  List<int>? platformIds,
  Map<int, Platform> platformMap,
) {
  if (platformIds == null || platformIds.isEmpty) return null;
  if (platformMap.isEmpty) return null;
  final List<String> allNames = platformIds
      .where((int id) => platformMap.containsKey(id))
      .map((int id) => platformMap[id]!.displayName)
      .toList();
  if (allNames.isEmpty) return null;
  if (allNames.length <= 3) return allNames.join(', ');
  return '${allNames.take(3).join(', ')} +${allNames.length - 3}';
}

/// One search result. Shared by the single-source grid and both per-source
/// section layouts, so the model branches live in exactly one place.
class BrowseCard extends StatelessWidget {
  const BrowseCard({
    required this.item,
    required this.mediaType,
    required this.fallbackSource,
    required this.collected,
    required this.variant,
    required this.animeMangaTitleLanguage,
    required this.onTap,
    this.onOpenInCollection,
    this.platformMap = const <int, Platform>{},
    super.key,
  });

  final Object item;
  final MediaType mediaType;

  /// Provider used for models that do not carry one — those come from a
  /// single-source media type, so the type's only source is correct.
  final DataSource fallbackSource;

  final CollectedIds collected;
  final CardVariant variant;
  final String animeMangaTitleLanguage;
  final void Function(Object item, MediaType mediaType) onTap;
  final void Function(int externalId, MediaType mediaType, DataSource? source)?
      onOpenInCollection;
  final Map<int, Platform> platformMap;

  VoidCallback? _openCallback(
    int externalId,
    bool inCollection, {
    DataSource? source,
  }) {
    if (!inCollection || onOpenInCollection == null) return null;
    return () => onOpenInCollection!(externalId, mediaType, source);
  }

  @override
  Widget build(BuildContext context) {
    final Object entry = item;

    if (entry is Movie) {
      final bool inColl = collected.tmdbIds.contains(entry.tmdbId);
      return MediaPosterCard(
        variant: variant,
        title: entry.title,
        imageUrl: entry.posterUrl ?? '',
        cacheImageType: ImageType.moviePoster,
        cacheImageId: entry.tmdbId.toString(),
        apiRating: entry.rating,
        year: entry.releaseYear,
        mediaType: mediaType,
        isInCollection: inColl,
        source: fallbackSource,
        onSourceTap: openUrlCallback(entry.externalUrl),
        onTap: () => onTap(entry, mediaType),
        onOpenInCollection: _openCallback(entry.tmdbId, inColl),
      );
    }

    if (entry is TvShow) {
      final bool inColl =
          collected.tvKeys.contains((entry.source, entry.tmdbId));
      return MediaPosterCard(
        variant: variant,
        title: entry.title,
        imageUrl: entry.posterUrl ?? '',
        cacheImageType: ImageType.tvShowPoster,
        cacheImageId: coverImageId(
          mediaType: MediaType.tvShow,
          externalId: entry.tmdbId,
          source: entry.source,
        ),
        apiRating: entry.rating,
        year: entry.firstAirYear,
        mediaType: mediaType,
        isInCollection: inColl,
        source: entry.source,
        onSourceTap: openUrlCallback(entry.externalUrl),
        onTap: () => onTap(entry, mediaType),
        onOpenInCollection:
            _openCallback(entry.tmdbId, inColl, source: entry.source),
      );
    }

    if (entry is Game) {
      final bool inColl = collected.gameIds.contains(entry.id);
      return MediaPosterCard(
        variant: variant,
        title: entry.name,
        imageUrl: entry.coverUrl ?? '',
        cacheImageType: ImageType.gameCover,
        cacheImageId: entry.id.toString(),
        apiRating: entry.rating != null ? entry.rating! / 10.0 : null,
        year: entry.releaseYear,
        platformLabel: buildPlatformLabel(entry.platformIds, platformMap),
        timeToBeatHours: entry.timeToBeat?.primaryHours,
        mediaType: mediaType,
        isInCollection: inColl,
        source: fallbackSource,
        onSourceTap: openUrlCallback(entry.externalUrl),
        onTap: () => onTap(entry, mediaType),
        onOpenInCollection: _openCallback(entry.id, inColl),
      );
    }

    if (entry is VisualNovel) {
      final bool inColl = collected.vnIds.contains(entry.numericId);
      return MediaPosterCard(
        variant: variant,
        title: entry.title,
        imageUrl: entry.imageUrl ?? '',
        cacheImageType: ImageType.vnCover,
        cacheImageId: entry.numericId.toString(),
        apiRating: entry.rating10,
        year: entry.releaseYear,
        mediaType: mediaType,
        isInCollection: inColl,
        source: fallbackSource,
        onSourceTap: openUrlCallback(entry.externalUrl),
        onTap: () => onTap(entry, mediaType),
        onOpenInCollection: _openCallback(entry.numericId, inColl),
      );
    }

    if (entry is Manga) {
      final bool inColl = collected.mangaKeys.contains((entry.source, entry.id));
      return MediaPosterCard(
        variant: variant,
        title: entry.titleByLanguage(animeMangaTitleLanguage),
        imageUrl: entry.coverUrl ?? '',
        cacheImageType: ImageType.mangaCover,
        cacheImageId: coverImageId(
          mediaType: MediaType.manga,
          externalId: entry.id,
          source: entry.source,
        ),
        apiRating: entry.rating10,
        year: entry.releaseYear,
        mediaType: mediaType,
        typeLabelOverride: entry.formatLabel,
        isInCollection: inColl,
        source: entry.source,
        onSourceTap: openUrlCallback(entry.externalUrl),
        onTap: () => onTap(entry, mediaType),
        onOpenInCollection:
            _openCallback(entry.id, inColl, source: entry.source),
      );
    }

    if (entry is Anime) {
      final bool inColl = collected.animeKeys.contains((entry.source, entry.id));
      return MediaPosterCard(
        variant: variant,
        title: entry.titleByLanguage(animeMangaTitleLanguage),
        imageUrl: entry.coverUrl ?? '',
        cacheImageType: ImageType.animeCover,
        cacheImageId: coverImageId(
          mediaType: MediaType.anime,
          externalId: entry.id,
          source: entry.source,
        ),
        apiRating: entry.rating10,
        year: entry.releaseYear,
        mediaType: mediaType,
        typeLabelOverride: entry.formatLabel,
        isInCollection: inColl,
        source: entry.source,
        onSourceTap: openUrlCallback(entry.externalUrl),
        onTap: () => onTap(entry, mediaType),
        onOpenInCollection:
            _openCallback(entry.id, inColl, source: entry.source),
      );
    }

    if (entry is Book) {
      final int externalId = entry.externalIdInt;
      final bool inColl =
          collected.bookKeys.contains((entry.source, externalId));
      return MediaPosterCard(
        variant: variant,
        title: entry.title,
        imageUrl: entry.coverUrl ?? '',
        cacheImageType: ImageType.bookCover,
        cacheImageId: coverImageId(
          mediaType: MediaType.book,
          externalId: externalId,
          source: entry.source,
          coverUrl: entry.coverUrl,
        ),
        apiRating: entry.rating,
        year: entry.releaseYear,
        mediaType: mediaType,
        isInCollection: inColl,
        source: entry.source,
        onSourceTap: openUrlCallback(entry.externalUrl),
        onTap: () => onTap(entry, mediaType),
        onOpenInCollection:
            _openCallback(externalId, inColl, source: entry.source),
      );
    }

    return const SizedBox.shrink();
  }
}
