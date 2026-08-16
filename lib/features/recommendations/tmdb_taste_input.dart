import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';

import 'engine/recommendation_config.dart';
import 'engine/recommendation_models.dart';

/// Engine id for a movie title/candidate.
String movieTasteId(int tmdbId) => 'movie:$tmdbId';

/// Engine id for a TV title/candidate.
String tvTasteId(int tmdbId) => 'tv:$tmdbId';

/// Collapses a genre token — a numeric id or a localized name in any case — to
/// its TMDB id, the one key that is identical in every language.
class GenreKeyResolver {
  GenreKeyResolver._(this._ids, this._nameToId);

  /// Builds a resolver for one domain (movie or TV) from its per-language
  /// id->name maps.
  factory GenreKeyResolver.fromGenreMaps(Iterable<Map<String, String>> maps) {
    final Set<String> ids = <String>{};
    final Map<String, String> nameToId = <String, String>{};
    for (final Map<String, String> map in maps) {
      map.forEach((String id, String name) {
        ids.add(id);
        nameToId[name.toLowerCase()] = id;
      });
    }
    return GenreKeyResolver._(ids, nameToId);
  }

  final Set<String> _ids;
  final Map<String, String> _nameToId;

  /// Whether [id] (an id string) is a known genre in this domain.
  bool hasId(String id) => _ids.contains(id);

  /// The id-string key for [raw]; [raw] is returned unchanged when nothing
  /// resolves it (an unknown token simply won't match any other title).
  String keyFor(String raw) =>
      _ids.contains(raw) ? raw : (_nameToId[raw.toLowerCase()] ?? raw);
}

/// Builds a [TasteTitle] from a completed collection item, or `null` when the
/// item is not a movie/TV title or has no usable genres.
TasteTitle? tasteTitleFromItem(
  CollectionItem item, {
  required GenreKeyResolver movieGenres,
  required GenreKeyResolver tvGenres,
}) {
  final Movie? m = item.movie;
  final TvShow? tv = item.tvShow;
  return switch (item.mediaType) {
    MediaType.movie when m != null => _build(
        id: movieTasteId(m.tmdbId),
        label: item.overrideName ?? m.title,
        rawGenres: m.genres,
        resolver: movieGenres,
        rating: item.userRating,
        isFavorite: item.isFavorite,
      ),
    MediaType.tvShow when tv != null => _build(
        id: tvTasteId(tv.tmdbId),
        label: item.overrideName ?? tv.title,
        rawGenres: tv.genres,
        resolver: tvGenres,
        rating: item.userRating,
        isFavorite: item.isFavorite,
      ),
    _ => null,
  };
}

/// Builds a movie candidate [TasteTitle], or `null` when [movie] has no usable
/// genres.
TasteTitle? tasteTitleFromMovie(Movie movie, GenreKeyResolver resolver) =>
    _build(
      id: movieTasteId(movie.tmdbId),
      label: movie.title,
      rawGenres: movie.genres,
      resolver: resolver,
      rating: null,
      isFavorite: false,
    );

/// Builds a TV candidate [TasteTitle], or `null` when [tv] has no usable genres.
TasteTitle? tasteTitleFromTvShow(TvShow tv, GenreKeyResolver resolver) =>
    _build(
      id: tvTasteId(tv.tmdbId),
      label: tv.title,
      rawGenres: tv.genres,
      resolver: resolver,
      rating: null,
      isFavorite: false,
    );

/// Engine ids the user already owns (movie / TV / animation across the whole
/// library), used to exclude candidates that are already in a collection.
Set<String> ownedTasteIds(List<CollectionItem> items) {
  final Set<String> ids = <String>{};
  for (final CollectionItem item in items) {
    // Animation is backed by a TMDB movie or TV id; resolve which via the
    // animation source carried on platformId.
    final String? id = switch (item.mediaType) {
      MediaType.movie => movieTasteId(item.externalId),
      MediaType.tvShow => tvTasteId(item.externalId),
      MediaType.animation => item.platformId == AnimationSource.tvShow
          ? tvTasteId(item.externalId)
          : movieTasteId(item.externalId),
      _ => null,
    };
    if (id != null) ids.add(id);
  }
  return ids;
}

TasteTitle? _build({
  required String id,
  required String label,
  required List<String>? rawGenres,
  required GenreKeyResolver resolver,
  required double? rating,
  required bool isFavorite,
}) {
  if (rawGenres == null) return null;
  final List<String> keys = <String>[
    for (final String g in rawGenres)
      if (g.trim().isNotEmpty) resolver.keyFor(g),
  ];
  if (keys.isEmpty) return null;
  return TasteTitle(
    id: id,
    label: label,
    features: <String, double>{
      for (final String k in keys) k: RecommendationConfig.genreValue,
    },
    rating: rating,
    isFavorite: isFavorite,
  );
}
