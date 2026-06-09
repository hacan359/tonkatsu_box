import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Animated series, animated movies, or both.
class AnimeTypeFilter extends SearchFilter {
  @override
  String get key => 'animeType';

  @override
  String placeholder(S l) => l.browseFilterType;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'all',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(
        id: 'series',
        label: l.browseAnimeTypeSeries,
        value: 'series',
      ),
      FilterOption(
        id: 'movies',
        label: l.browseAnimeTypeMovies,
        value: 'movies',
      ),
    ];
  }
}
