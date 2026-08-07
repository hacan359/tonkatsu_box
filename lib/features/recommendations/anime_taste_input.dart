import 'package:core/models/anime.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';

import 'engine/recommendation_models.dart';
import 'taste_features.dart';

/// Engine id for an anime title/candidate; the source keeps id spaces apart.
String animeTasteId(DataSource source, int id) => 'anime:${source.name}:$id';

/// Builds a [TasteTitle] from a completed collection item, or `null` when the
/// item is not an AniList anime or has no usable genres/tags.
TasteTitle? tasteTitleFromAnimeItem(CollectionItem item) {
  final Anime? anime = item.anime;
  if (item.mediaType != MediaType.anime || anime == null) return null;
  if (anime.source != DataSource.anilist) return null;
  return buildNameFeatureTitle(
    id: animeTasteId(anime.source, anime.id),
    label: item.overrideName ?? anime.title,
    genres: anime.genres,
    tags: anime.tags,
    rating: item.userRating,
    isFavorite: item.isFavorite,
  );
}

/// Builds an anime candidate [TasteTitle], or `null` without genres/tags.
TasteTitle? tasteTitleFromAnime(Anime anime) => buildNameFeatureTitle(
      id: animeTasteId(anime.source, anime.id),
      label: anime.title,
      genres: anime.genres,
      tags: anime.tags,
      rating: null,
      isFavorite: false,
    );

/// Owned-exclusion ids for every anime in the library; a Kitsu copy of an
/// AniList candidate cannot be matched (different id spaces) and may surface.
Set<String> ownedAnimeTasteIds(List<CollectionItem> items) => <String>{
      for (final CollectionItem item in items)
        if (item.mediaType == MediaType.anime)
          // The raw column first: dataSource resolves through the media
          // submodel and falls back to a per-type default when it's absent.
          animeTasteId(item.source ?? item.dataSource, item.externalId),
    };

