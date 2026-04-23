// Фильтр минимального количества голосов — отсекает новые/малоизвестные тайтлы
// с недостоверным рейтингом.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр минимального количества голосов (TMDB vote_count.gte).
///
/// В паре с [MinRatingFilter] нужен для отсеивания «9/10 с одним голосом».
class MinVotesFilter extends SearchFilter {
  @override
  String get key => 'minVotes';

  @override
  String placeholder(S l) => l.browseFilterMinVotes;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      const FilterOption(id: '100', label: '100+', value: 100),
      const FilterOption(id: '500', label: '500+', value: 500),
      const FilterOption(id: '1000', label: '1000+', value: 1000),
      const FilterOption(id: '5000', label: '5000+', value: 5000),
    ];
  }
}
