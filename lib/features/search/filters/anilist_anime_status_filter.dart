import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// AniList MediaStatus values.
class AniListAnimeStatusFilter extends SearchFilter {
  @override
  String get key => 'status';

  @override
  String placeholder(S l) => l.status;

  @override
  FilterSemanticFamily? get semanticFamily =>
      FilterSemanticFamily.status;

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
        semantic: FilterSemantic.statusReleasing,
      ),
      FilterOption(
        id: 'finished',
        label: l.animeStatusFinished,
        value: 'FINISHED',
        semantic: FilterSemantic.statusFinished,
      ),
      FilterOption(
        id: 'not_yet_released',
        label: l.animeStatusNotYetAired,
        value: 'NOT_YET_RELEASED',
        semantic: FilterSemantic.statusNotYetReleased,
      ),
      FilterOption(
        id: 'cancelled',
        label: l.animeStatusCancelled,
        value: 'CANCELLED',
        semantic: FilterSemantic.statusCancelled,
      ),
    ];
  }
}
