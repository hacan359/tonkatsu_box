import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Release year: individual years from now back to 1980 plus 1970s/1960s
/// decade buckets for retro (Atari era). The list is long, so [searchable]
/// is enabled.
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
