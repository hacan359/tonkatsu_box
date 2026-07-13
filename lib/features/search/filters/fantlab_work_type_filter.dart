// Fantlab work-type filter (single-select). `/search-works` has no server-side
// filter, so the chosen type is applied by matching each match's `name_eng`
// inside FantlabApi — see core/api/fantlab/README.md.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Narrows Fantlab results to a literary work type. Values are Fantlab's stable
/// English type names (`name_eng`): `novel` / `story` / `shortstory` / `cycle`.
class FantlabWorkTypeFilter extends SearchFilter {
  @override
  String get key => 'work_type';

  @override
  String get cacheKey => 'work_type_fantlab';

  @override
  String placeholder(S l) => l.type;

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'all', label: 'All', value: null);

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'novel', label: l.fantlabTypeNovel, value: 'novel'),
      FilterOption(id: 'story', label: l.fantlabTypeNovella, value: 'story'),
      FilterOption(
        id: 'shortstory',
        label: l.fantlabTypeShortStory,
        value: 'shortstory',
      ),
      FilterOption(id: 'cycle', label: l.fantlabTypeCycle, value: 'cycle'),
    ];
  }
}
