import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Kitsu anime `status`: current / finished / upcoming.
class KitsuAnimeStatusFilter extends SearchFilter {
  @override
  String get key => 'status';

  @override
  String get cacheKey => 'status_kitsu_anime';

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
        id: 'current',
        label: l.animeStatusAiring,
        value: 'current',
        semantic: FilterSemantic.statusReleasing,
      ),
      FilterOption(
        id: 'finished',
        label: l.animeStatusFinished,
        value: 'finished',
        semantic: FilterSemantic.statusFinished,
      ),
      FilterOption(
        id: 'upcoming',
        label: l.animeStatusNotYetAired,
        value: 'upcoming',
        semantic: FilterSemantic.statusNotYetReleased,
      ),
    ];
  }
}
