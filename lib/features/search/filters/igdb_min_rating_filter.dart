// Фильтр минимального IGDB-рейтинга (0–100 scale).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр минимального IGDB-рейтинга.
///
/// IGDB `rating` — среднее пользовательских оценок в шкале 0–100
/// (не путать с TMDB 0–10). Попадает в where-клаузу как `rating >= N`.
class IgdbMinRatingFilter extends SearchFilter {
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
      const FilterOption(id: '60', label: '60+', value: 60),
      const FilterOption(id: '70', label: '70+', value: 70),
      const FilterOption(id: '80', label: '80+', value: 80),
      const FilterOption(id: '90', label: '90+', value: 90),
    ];
  }
}
