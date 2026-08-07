import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';

import 'engine/recommendation_models.dart';
import 'taste_features.dart';

/// Manga sources with a similarity backend and genre/tag features. Kitsu
/// manga carry neither in our model, so they cannot feed a profile.
const Set<DataSource> mangaTasteSources = <DataSource>{
  DataSource.mangabaka,
  DataSource.mangadex,
  DataSource.anilist,
};

/// Engine id for a manga title/candidate; the source keeps id spaces apart
/// (a MangaBaka id can equal a MangaDex hash id).
String mangaTasteId(DataSource source, int id) => 'manga:${source.name}:$id';

/// Builds a [TasteTitle] from a completed collection item of [source], or
/// `null` when the item is another source's manga or has no genres/tags.
TasteTitle? tasteTitleFromMangaItem(CollectionItem item, DataSource source) {
  final Manga? manga = item.manga;
  if (item.mediaType != MediaType.manga || manga == null) return null;
  if (manga.source != source) return null;
  return buildNameFeatureTitle(
    id: mangaTasteId(manga.source, manga.id),
    label: item.overrideName ?? manga.title,
    genres: manga.genres,
    tags: manga.tags,
    rating: item.userRating,
    isFavorite: item.isFavorite,
  );
}

/// Builds a manga candidate [TasteTitle], or `null` without genres/tags.
TasteTitle? tasteTitleFromManga(Manga manga) => buildNameFeatureTitle(
      id: mangaTasteId(manga.source, manga.id),
      label: manga.title,
      genres: manga.genres,
      tags: manga.tags,
      rating: null,
      isFavorite: false,
    );

/// Engine ids of every manga already in the library, any source — used to
/// exclude candidates already collected.
Set<String> ownedMangaTasteIds(List<CollectionItem> items) => <String>{
      for (final CollectionItem item in items)
        if (item.mediaType == MediaType.manga)
          // The raw column first: dataSource resolves through the media
          // submodel and falls back to a per-type default when it's absent.
          mangaTasteId(item.source ?? item.dataSource, item.externalId),
    };
