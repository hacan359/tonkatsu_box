import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Picks the `search.json` field the query matches: "All" is the catch-all
/// `q`; values are the literal OpenLibrary query params.
class OpenLibraryScopeFilter extends SearchFilter {
  @override
  String get key => 'scope';

  @override
  String get cacheKey => 'scope_openlibrary';

  @override
  String placeholder(S l) => l.bookFilterSearchBy;

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'any', label: 'All', value: null);

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'title', label: l.title, value: 'title'),
      FilterOption(id: 'author', label: l.bookSearchAuthor, value: 'author'),
      FilterOption(id: 'subject', label: l.bookSearchSubject, value: 'subject'),
    ];
  }
}
