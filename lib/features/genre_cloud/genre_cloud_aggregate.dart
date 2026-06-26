// Pure aggregation: collection items -> facet values across genre/platform/decade.

import '../../shared/models/anime.dart';
import '../../shared/models/book.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/custom_media.dart';
import '../../shared/models/game.dart';
import '../../shared/models/manga.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/tv_show.dart';
import '../../shared/models/visual_novel.dart';
import 'facet.dart';
import 'facet_value.dart';

/// A single (facet, value) pair extracted from one item.
typedef FacetEntry = ({Facet facet, String value});

/// Extracts every (facet, value) pair an item contributes, reading the typed
/// sub-models directly. Only genre, platform and decade are produced.
///
/// Reads whichever sub-models are attached rather than switching on
/// `mediaType`, so the `animation` type (stored as a Movie or TvShow) is
/// handled for free.
List<FacetEntry> extractItemFacets(CollectionItem item) {
  final List<FacetEntry> out = <FacetEntry>[];

  void addAll(Facet facet, List<String>? values) {
    if (values == null) return;
    for (final String value in values) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty) out.add((facet: facet, value: trimmed));
    }
  }

  void addOne(Facet facet, String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) out.add((facet: facet, value: trimmed));
  }

  final Game? game = item.game;
  if (game != null) {
    addAll(Facet.genre, game.genres);
    addOne(Facet.decade, _decadeOf(game.releaseDate?.year));
  }
  // The owned platform of a game item.
  addOne(Facet.platform, item.platform?.name);

  final Movie? movie = item.movie;
  if (movie != null) {
    addAll(Facet.genre, movie.genres);
    addOne(Facet.decade, _decadeOf(movie.releaseYear));
  }

  final TvShow? tvShow = item.tvShow;
  if (tvShow != null) {
    addAll(Facet.genre, tvShow.genres);
    addOne(Facet.decade, _decadeOf(tvShow.firstAirYear));
  }

  final Anime? anime = item.anime;
  if (anime != null) {
    addAll(Facet.genre, anime.genres);
    addOne(Facet.decade, _decadeOf(anime.startYear));
  }

  final Manga? manga = item.manga;
  if (manga != null) {
    addAll(Facet.genre, manga.genres);
    addOne(Facet.decade, _decadeOf(manga.startYear));
  }

  final VisualNovel? vn = item.visualNovel;
  if (vn != null) {
    addAll(Facet.platform, vn.platforms);
    addOne(Facet.decade, _decadeOf(_yearFromReleased(vn.released)));
  }

  final Book? book = item.book;
  if (book != null) {
    addAll(Facet.genre, book.subjects);
  }

  final CustomMedia? custom = item.customMedia;
  if (custom != null) {
    addAll(Facet.genre, custom.genreList);
  }

  return out;
}

/// Counts how many items carry each facet value and resolves a dominant media
/// type per value, sorted by frequency (descending). Counting is
/// case-insensitive and de-duped per item.
///
/// [includeFacets] limits which dimensions contribute; [includeTypes] limits
/// which media types contribute (a hidden type's items are ignored, so counts,
/// dominant type and colour recompute as if it were absent).
List<FacetValue> aggregateFacets(
  List<CollectionItem> items, {
  Set<Facet>? includeFacets,
  Set<MediaType>? includeTypes,
}) {
  final Map<String, _FacetAccumulator> byKey = <String, _FacetAccumulator>{};

  for (final CollectionItem item in items) {
    if (includeTypes != null && !includeTypes.contains(item.mediaType)) {
      continue;
    }
    final Set<String> seenInItem = <String>{};
    for (final FacetEntry entry in extractItemFacets(item)) {
      if (includeFacets != null && !includeFacets.contains(entry.facet)) {
        continue;
      }
      final String key = '${entry.facet.value}:${entry.value.toLowerCase()}';
      if (!seenInItem.add(key)) continue;

      final _FacetAccumulator acc = byKey.putIfAbsent(
        key,
        () => _FacetAccumulator(entry.facet, entry.value),
      );
      acc.count++;
      acc.typeCounts.update(
        item.mediaType,
        (int value) => value + 1,
        ifAbsent: () => 1,
      );
    }
  }

  final List<FacetValue> result = byKey.values
      .map(
        (_FacetAccumulator acc) => FacetValue(
          facet: acc.facet,
          label: acc.label,
          count: acc.count,
          type: acc.dominantType,
        ),
      )
      .toList();

  result.sort((FacetValue a, FacetValue b) {
    final int byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });

  return result;
}

/// The set of facet dimensions present among [items] (drives the facet legend).
Set<Facet> presentFacets(List<CollectionItem> items) {
  final Set<Facet> facets = <Facet>{};
  for (final CollectionItem item in items) {
    for (final FacetEntry entry in extractItemFacets(item)) {
      facets.add(entry.facet);
    }
  }
  return facets;
}

/// The media types among [items] that contribute at least one facet value
/// (drives the media-type legend).
Set<MediaType> presentMediaTypes(List<CollectionItem> items) {
  final Set<MediaType> types = <MediaType>{};
  for (final CollectionItem item in items) {
    if (extractItemFacets(item).isNotEmpty) {
      types.add(item.mediaType);
    }
  }
  return types;
}

String? _decadeOf(int? year) {
  if (year == null || year < 1900 || year > 2100) return null;
  return '${(year ~/ 10) * 10}s';
}

int? _yearFromReleased(String? released) {
  if (released == null) return null;
  final RegExpMatch? match = RegExp(r'(\d{4})').firstMatch(released);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Mutable accumulator used while folding items into per-value tallies.
class _FacetAccumulator {
  _FacetAccumulator(this.facet, this.label);

  final Facet facet;
  final String label;
  int count = 0;
  final Map<MediaType, int> typeCounts = <MediaType, int>{};

  /// Media type with the most items for this value; ties break by [MediaType]
  /// declaration order.
  MediaType get dominantType {
    MediaType best = MediaType.values.first;
    int bestCount = -1;
    for (final MediaType type in MediaType.values) {
      final int c = typeCounts[type] ?? 0;
      if (c > bestCount) {
        bestCount = c;
        best = type;
      }
    }
    return best;
  }
}
