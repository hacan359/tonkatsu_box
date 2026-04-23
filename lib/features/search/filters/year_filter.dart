// Фильтр по году выпуска — общий для всех источников.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр по году выпуска.
///
/// Индивидуальные годы с текущего до 1980 + декадные срезы 1970s и 1960s
/// для совсем ретро (Atari-эра). Список получается длинным, поэтому в
/// popup включён поиск ([searchable] = true).
class YearFilter extends SearchFilter {
  @override
  String get key => 'year';

  @override
  bool get searchable => true;

  @override
  String placeholder(S l) => l.browseFilterYear;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    final int currentYear = DateTime.now().year;
    return <FilterOption>[
      for (int y = currentYear; y >= 1980; y--)
        FilterOption(id: y.toString(), label: y.toString(), value: y),
      const FilterOption(id: '1970s', label: '1970s', value: (1970, 1979)),
      const FilterOption(id: '1960s', label: '1960s', value: (1960, 1969)),
    ];
  }
}
