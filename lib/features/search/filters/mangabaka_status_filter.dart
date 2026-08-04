// MangaBaka release-status filter (single-select).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// MangaBaka `status`: releasing / completed / hiatus.
class MangaBakaStatusFilter extends SearchFilter {
  @override
  String get key => 'status';

  @override
  String get cacheKey => 'status_mangabaka';

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
        label: l.mangaStatusPublishing,
        value: 'releasing',
        semantic: FilterSemantic.statusReleasing,
      ),
      FilterOption(
        id: 'completed',
        label: l.mangaStatusFinished,
        value: 'completed',
        semantic: FilterSemantic.statusFinished,
      ),
      FilterOption(
        id: 'hiatus',
        label: l.mangaStatusHiatus,
        value: 'hiatus',
        semantic: FilterSemantic.statusHiatus,
      ),
    ];
  }
}
