import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Filters Google Books search by language. Values are ISO-639-1 2-letter codes
/// (`en`, `ru`, …) passed to `volumes.list?langRestrict=`.
class GoogleBooksLanguageFilter extends SearchFilter {
  @override
  String get key => 'language';

  @override
  String get cacheKey => 'language_googlebooks';

  @override
  String placeholder(S l) => l.language;

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'any', label: 'All', value: null);

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return const <FilterOption>[
      FilterOption(id: 'en', label: 'English', value: 'en'),
      FilterOption(id: 'ru', label: 'Russian', value: 'ru'),
      FilterOption(id: 'ja', label: 'Japanese', value: 'ja'),
      FilterOption(id: 'fr', label: 'French', value: 'fr'),
      FilterOption(id: 'de', label: 'German', value: 'de'),
      FilterOption(id: 'es', label: 'Spanish', value: 'es'),
      FilterOption(id: 'it', label: 'Italian', value: 'it'),
      FilterOption(id: 'uk', label: 'Ukrainian', value: 'uk'),
      FilterOption(id: 'pl', label: 'Polish', value: 'pl'),
    ];
  }
}
