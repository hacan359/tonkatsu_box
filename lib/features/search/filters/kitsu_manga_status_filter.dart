// Kitsu manga status filter (single-select).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Kitsu manga `status`: current / finished / upcoming.
class KitsuMangaStatusFilter extends SearchFilter {
  @override
  String get key => 'status';

  @override
  String get cacheKey => 'status_kitsu_manga';

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
        label: l.mangaStatusPublishing,
        value: 'current',
        semantic: FilterSemantic.statusReleasing,
      ),
      FilterOption(
        id: 'finished',
        label: l.mangaStatusFinished,
        value: 'finished',
        semantic: FilterSemantic.statusFinished,
      ),
      FilterOption(
        id: 'upcoming',
        label: l.mangaStatusNotYetPublished,
        value: 'upcoming',
        semantic: FilterSemantic.statusNotYetReleased,
      ),
    ];
  }
}
