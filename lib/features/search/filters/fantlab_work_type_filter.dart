import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// `/search-works` has no server-side type filter, so FantlabApi matches each
/// result's stable `name_eng` (`novel` / `story` / `shortstory` / `cycle`).
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
