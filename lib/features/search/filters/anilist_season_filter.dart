// Фильтр сезона AniList (WINTER / SPRING / SUMMER / FALL).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр аниме-сезона AniList.
///
/// На стороне AniList сезон работает вместе с `seasonYear` — если
/// указан только сезон без года, API вернёт аниме этого сезона за все
/// годы. Стандартный кейс: «зима 2024» = WINTER + 2024.
class AniListSeasonFilter extends SearchFilter {
  @override
  String get key => 'season';

  @override
  String placeholder(S l) => l.browseFilterSeason;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'winter', label: l.seasonWinter, value: 'WINTER'),
      FilterOption(id: 'spring', label: l.seasonSpring, value: 'SPRING'),
      FilterOption(id: 'summer', label: l.seasonSummer, value: 'SUMMER'),
      FilterOption(id: 'fall', label: l.seasonFall, value: 'FALL'),
    ];
  }
}
