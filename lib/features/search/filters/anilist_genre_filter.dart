import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// AniList genres (static — the API has no genres endpoint).
const List<String> _aniListGenres = <String>[
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Ecchi',
  'Fantasy',
  'Horror',
  'Mahou Shoujo',
  'Mecha',
  'Music',
  'Mystery',
  'Psychological',
  'Romance',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Supernatural',
  'Thriller',
];

/// AniList genre filter. [forAnime] only splits the cache key — the genre list
/// is identical for anime and manga.
class AniListGenreFilter extends SearchFilter {
  AniListGenreFilter({this.forAnime = false});

  final bool forAnime;

  @override
  String get key => 'genre';

  @override
  String get cacheKey =>
      forAnime ? '${key}_anilist_anime' : '${key}_anilist';

  @override
  bool get multiSelect => true;

  @override
  bool get searchable => true;

  @override
  String placeholder(S l) => l.browseFilterGenre;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return _aniListGenres
        .map(
          (String genre) => FilterOption(
            id: genre.toLowerCase().replaceAll(' ', '_'),
            label: genre,
            value: genre,
          ),
        )
        .toList();
  }
}
