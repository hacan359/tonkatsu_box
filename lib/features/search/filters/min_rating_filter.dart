// Фильтр минимального рейтинга — для TMDB discover endpoint (vote_average.gte).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр минимального рейтинга (0–10).
///
/// Привязан к TMDB-шкале `vote_average` (значения 0–10). На AniList/VNDB
/// шкалы иные — там потребуется отдельный фильтр, если понадобится.
class MinRatingFilter extends SearchFilter {
  @override
  String get key => 'minRating';

  @override
  String placeholder(S l) => l.browseFilterMinRating;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      const FilterOption(id: '6', label: '6+', value: 6.0),
      const FilterOption(id: '7', label: '7+', value: 7.0),
      const FilterOption(id: '8', label: '8+', value: 8.0),
      const FilterOption(id: '9', label: '9+', value: 9.0),
    ];
  }
}
