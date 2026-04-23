// Фильтр оригинального языка TMDB (with_original_language).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр оригинального языка TMDB.
///
/// Отправляется в `with_original_language` как ISO 639-1 код (en/ja/ko/…).
/// Полезен для поиска аниме (ja), k-drama (ko), c-drama (zh) и т.п.
class TmdbLanguageFilter extends SearchFilter {
  @override
  String get key => 'originalLanguage';

  @override
  bool get searchable => true;

  @override
  String placeholder(S l) => l.browseFilterLanguage;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'en', label: l.languageEnglish, value: 'en'),
      FilterOption(id: 'ja', label: l.languageJapanese, value: 'ja'),
      FilterOption(id: 'ko', label: l.languageKorean, value: 'ko'),
      FilterOption(id: 'zh', label: l.languageChinese, value: 'zh'),
      FilterOption(id: 'fr', label: l.languageFrench, value: 'fr'),
      FilterOption(id: 'es', label: l.languageSpanish, value: 'es'),
      FilterOption(id: 'de', label: l.languageGerman, value: 'de'),
      FilterOption(id: 'ru', label: l.languageRussian, value: 'ru'),
      FilterOption(id: 'it', label: l.languageItalian, value: 'it'),
      FilterOption(id: 'pt', label: l.languagePortuguese, value: 'pt'),
    ];
  }
}
