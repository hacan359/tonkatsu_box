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
      ),
      FilterOption(
        id: 'completed',
        label: l.mangaStatusFinished,
        value: 'completed',
      ),
      FilterOption(
        id: 'hiatus',
        label: l.mangaStatusHiatus,
        value: 'hiatus',
      ),
    ];
  }
}
