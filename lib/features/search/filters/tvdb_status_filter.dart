import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Ids come from `/movies/statuses` and `/series/statuses` — the swagger
/// declares `[1,2,3]` for movies, but the API serves five.
class TvdbStatusFilter extends SearchFilter {
  TvdbStatusFilter({required this.mediaType});

  final MediaType mediaType;

  @override
  String get key => 'status';

  @override
  String get cacheKey => 'status_tvdb_${mediaType.name}';

  @override
  String placeholder(S l) => l.status;

  @override
  FilterSemanticFamily? get semanticFamily => FilterSemanticFamily.status;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    if (mediaType == MediaType.movie) {
      return <FilterOption>[
        FilterOption(
          id: 'released',
          label: l.movieStatusReleased,
          value: 5,
          semantic: FilterSemantic.statusFinished,
        ),
        FilterOption(
          id: 'completed',
          label: l.movieStatusCompleted,
          value: 4,
        ),
        FilterOption(
          id: 'post_production',
          label: l.movieStatusPostProduction,
          value: 3,
        ),
        FilterOption(
          id: 'pre_production',
          label: l.movieStatusPreProduction,
          value: 2,
        ),
        FilterOption(
          id: 'announced',
          label: l.movieStatusAnnounced,
          value: 1,
          semantic: FilterSemantic.statusNotYetReleased,
        ),
      ];
    }
    return <FilterOption>[
      FilterOption(
        id: 'continuing',
        label: l.animeStatusAiring,
        value: 1,
        semantic: FilterSemantic.statusReleasing,
      ),
      FilterOption(
        id: 'ended',
        label: l.animeStatusFinished,
        value: 2,
        semantic: FilterSemantic.statusFinished,
      ),
      FilterOption(
        id: 'upcoming',
        label: l.animeStatusNotYetAired,
        value: 3,
        semantic: FilterSemantic.statusNotYetReleased,
      ),
    ];
  }
}
