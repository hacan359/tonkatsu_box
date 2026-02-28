// Фильтр по году выпуска — общий для всех источников.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр по году выпуска.
///
/// Генерирует список годов от текущего до 2000,
/// плюс декады (1990s, 1980s, 1970s).
class YearFilter extends SearchFilter {
  @override
  String get key => 'year';

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
      for (int y = currentYear; y >= 2000; y--)
        FilterOption(id: y.toString(), label: y.toString(), value: y),
      const FilterOption(id: '1990s', label: '1990s', value: (1990, 1999)),
      const FilterOption(id: '1980s', label: '1980s', value: (1980, 1989)),
      const FilterOption(id: '1970s', label: '1970s', value: (1970, 1979)),
    ];
  }
}
