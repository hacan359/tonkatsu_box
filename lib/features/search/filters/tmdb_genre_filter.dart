// Фильтр жанров TMDB — используется Movies, TV, Anime.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';
import '../providers/genre_provider.dart';

/// Фильтр жанров из TMDB.
///
/// Поддерживает жанры фильмов ('movie') и сериалов ('tv').
/// Данные загружаются из кэша через [movieGenresProvider] / [tvGenresProvider].
class TmdbGenreFilter extends SearchFilter {
  /// Создаёт [TmdbGenreFilter].
  ///
  /// [type] — 'movie' или 'tv'.
  TmdbGenreFilter({required this.type});

  /// Тип контента: 'movie' или 'tv'.
  final String type;

  @override
  String get key => 'genre';

  @override
  String get cacheKey => '${key}_$type';

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
    final List<TmdbGenre> genres = type == 'movie'
        ? await ref.read(movieGenresProvider.future)
        : await ref.read(tvGenresProvider.future);
    return genres
        .map(
          (TmdbGenre g) => FilterOption(
            id: g.id.toString(),
            label: g.name,
            value: g.id,
          ),
        )
        .toList();
  }
}
