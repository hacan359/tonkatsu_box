import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// VNDB language availability (`lang`). Multi-select — a VN matches if it is
/// available in any of the chosen languages. Values are VNDB language codes.
class VndbLanguageFilter extends SearchFilter {
  @override
  String get key => 'language';

  @override
  String get cacheKey => 'language_vndb';

  @override
  bool get multiSelect => true;

  @override
  bool get searchable => true;

  @override
  String placeholder(S l) => l.language;

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'any', label: 'All', value: null);

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return const <FilterOption>[
      FilterOption(id: 'en', label: 'English', value: 'en'),
      FilterOption(id: 'ja', label: 'Japanese', value: 'ja'),
      FilterOption(id: 'zh-Hans', label: 'Chinese (Simplified)', value: 'zh-Hans'),
      FilterOption(id: 'zh-Hant', label: 'Chinese (Traditional)', value: 'zh-Hant'),
      FilterOption(id: 'ru', label: 'Russian', value: 'ru'),
      FilterOption(id: 'ko', label: 'Korean', value: 'ko'),
      FilterOption(id: 'es', label: 'Spanish', value: 'es'),
      FilterOption(id: 'de', label: 'German', value: 'de'),
      FilterOption(id: 'fr', label: 'French', value: 'fr'),
      FilterOption(id: 'it', label: 'Italian', value: 'it'),
      FilterOption(id: 'pt-br', label: 'Portuguese (Brazil)', value: 'pt-br'),
      FilterOption(id: 'vi', label: 'Vietnamese', value: 'vi'),
      FilterOption(id: 'pl', label: 'Polish', value: 'pl'),
      FilterOption(id: 'uk', label: 'Ukrainian', value: 'uk'),
    ];
  }
}
