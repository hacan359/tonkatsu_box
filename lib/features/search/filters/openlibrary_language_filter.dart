// OpenLibrary language filter (single-select, MARC 3-letter codes).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Filters OpenLibrary search by edition language. Values are MARC 3-letter
/// codes (`eng`, `rus`, …) passed to `search.json?language=`.
class OpenLibraryLanguageFilter extends SearchFilter {
  @override
  String get key => 'language';

  @override
  String get cacheKey => 'language_openlibrary';

  @override
  String placeholder(S l) => l.bookFilterLanguage;

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'any', label: 'All', value: null);

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return const <FilterOption>[
      FilterOption(id: 'eng', label: 'English', value: 'eng'),
      FilterOption(id: 'rus', label: 'Russian', value: 'rus'),
      FilterOption(id: 'jpn', label: 'Japanese', value: 'jpn'),
      FilterOption(id: 'fre', label: 'French', value: 'fre'),
      FilterOption(id: 'ger', label: 'German', value: 'ger'),
      FilterOption(id: 'spa', label: 'Spanish', value: 'spa'),
      FilterOption(id: 'ita', label: 'Italian', value: 'ita'),
      FilterOption(id: 'ukr', label: 'Ukrainian', value: 'ukr'),
      FilterOption(id: 'pol', label: 'Polish', value: 'pol'),
    ];
  }
}
