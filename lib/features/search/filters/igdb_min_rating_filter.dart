// Фильтр минимального IGDB-рейтинга (UI 1–10 scale).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр минимального IGDB-рейтинга.
///
/// Пользователю показываем шкалу 1–10 (как TMDB и отображение в карточках).
/// IGDB API оперирует шкалой 0–100, конвертация (×10) выполняется в
/// `IgdbGamesSource` перед отправкой запроса.
class IgdbMinRatingFilter extends SearchFilter {
  @override
  String get key => 'minRating';

  @override
  String placeholder(S l) => l.browseFilterMinRating;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      const FilterOption(id: '6', label: '6+', value: 6),
      const FilterOption(id: '7', label: '7+', value: 7),
      const FilterOption(id: '8', label: '8+', value: 8),
      const FilterOption(id: '9', label: '9+', value: 9),
    ];
  }
}
