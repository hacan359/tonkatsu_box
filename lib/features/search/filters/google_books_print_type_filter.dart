import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// The reset is the explicit `all`; an untouched filter defaults to `books` so
/// magazines don't flood a plain book search.
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
