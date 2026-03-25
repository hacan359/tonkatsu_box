// Фильтр статуса аниме (AniList).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр статуса аниме.
///
/// Статусы соответствуют AniList MediaStatus enum.
class AniListAnimeStatusFilter extends SearchFilter {
  @override
  String get key => 'status';

  @override
  String placeholder(S l) => l.animeFilterStatus;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(
        id: 'releasing',
        label: l.animeStatusAiring,
        value: 'RELEASING',
      ),
      FilterOption(
        id: 'finished',
        label: l.animeStatusFinished,
        value: 'FINISHED',
      ),
      FilterOption(
        id: 'not_yet_released',
        label: l.animeStatusNotYetAired,
        value: 'NOT_YET_RELEASED',
      ),
      FilterOption(
        id: 'cancelled',
        label: l.animeStatusCancelled,
        value: 'CANCELLED',
      ),
    ];
  }
}
