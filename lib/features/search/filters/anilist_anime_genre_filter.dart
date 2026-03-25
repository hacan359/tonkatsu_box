// Фильтр жанров AniList для аниме.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Жанры AniList (статический список, общий для аниме и манги).
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

/// Фильтр жанров AniList для аниме.
///
/// Использует статический список жанров AniList.
/// [cacheKey] отличается от manga-версии для раздельного кеширования.
class AniListAnimeGenreFilter extends SearchFilter {
  @override
  String get key => 'genre';

  @override
  String get cacheKey => '${key}_anilist_anime';

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
