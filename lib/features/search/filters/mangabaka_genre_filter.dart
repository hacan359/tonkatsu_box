import 'package:core/models/mangabaka_genre.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../data/repositories/mangabaka_genres_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// MangaBaka `genre` — closed enum (46 entries) served from the seeded
/// `mangabaka_genres` table. Multi-select → repeated `genre=` keys (AND).
class MangaBakaGenreFilter extends SearchFilter {
  @override
  String get key => 'genre';

  @override
  String get cacheKey => 'genre_mangabaka';

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
    final List<MangaBakaGenre> genres =
        await ref.read(mangaBakaGenresProvider.future);
    return genres
        .map((MangaBakaGenre g) => FilterOption(
              id: g.key,
              label: g.name,
              value: g.key,
            ))
        .toList();
  }
}
