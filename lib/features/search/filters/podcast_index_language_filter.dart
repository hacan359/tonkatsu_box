import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

// Codes the trending endpoint matches against feed `language` tags. App
// locales first, then the biggest podcast languages.
const List<(String, String)> _languages = <(String, String)>[
  ('en', 'English'),
  ('ru', 'Русский'),
  ('es', 'Español'),
  ('fr', 'Français'),
  ('pt', 'Português'),
  ('zh', '中文'),
  ('de', 'Deutsch'),
  ('it', 'Italiano'),
  ('ja', '日本語'),
  ('ko', '한국어'),
  ('nl', 'Nederlands'),
  ('pl', 'Polski'),
  ('sv', 'Svenska'),
  ('tr', 'Türkçe'),
  ('uk', 'Українська'),
  ('hi', 'हिन्दी'),
  ('ar', 'العربية'),
];

/// Podcast Index `lang=` filter — Browse (trending) only, like the category
/// filter; the search endpoint has no language parameter.
class PodcastIndexLanguageFilter extends SearchFilter {
  @override
  String get key => 'language';

  @override
  String get cacheKey => 'language_podcastindex';

  @override
  String placeholder(S l) => l.language;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      for (final (String code, String name) in _languages)
        FilterOption(id: code, label: name, value: code),
    ];
  }
}
