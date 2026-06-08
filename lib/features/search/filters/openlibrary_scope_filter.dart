// OpenLibrary search-scope filter — picks which field the text query matches.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Chooses the field the typed query is matched against on `search.json`:
/// the reset ("All") is the catch-all `q`, the rest restrict to `title`,
/// `author` or `subject`. Values are the literal OpenLibrary query params.
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
      FilterOption(id: 'title', label: l.bookSearchTitle, value: 'title'),
      FilterOption(id: 'author', label: l.bookSearchAuthor, value: 'author'),
      FilterOption(id: 'subject', label: l.bookSearchSubject, value: 'subject'),
    ];
  }
}
