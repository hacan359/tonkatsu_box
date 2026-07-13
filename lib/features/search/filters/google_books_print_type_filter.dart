// Google Books print-type filter (single-select: all / books / magazines).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Restricts Google Books search to a print type via `volumes.list?printType=`.
/// The reset is the explicit `all`; the source defaults an *untouched* filter to
/// `books` so magazines don't flood a plain book search.
class GoogleBooksPrintTypeFilter extends SearchFilter {
  @override
  String get key => 'printType';

  @override
  String get cacheKey => 'print_type_googlebooks';

  @override
  String placeholder(S l) => l.type;

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'all', label: 'All', value: 'all');

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return const <FilterOption>[
      FilterOption(id: 'books', label: 'Books', value: 'books'),
      FilterOption(id: 'magazines', label: 'Magazines', value: 'magazines'),
    ];
  }
}
