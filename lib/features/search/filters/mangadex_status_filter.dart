// MangaDex publication-status filter (multi-select).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// MangaDex `status`: ongoing / completed / hiatus / cancelled (multi-select).
class MangaDexStatusFilter extends SearchFilter {
  @override
  String get key => 'status';

  @override
  String get cacheKey => 'status_mangadex';

  @override
  bool get multiSelect => true;

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
        id: 'ongoing',
        label: l.mangaStatusPublishing,
        value: 'ongoing',
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
      FilterOption(
        id: 'cancelled',
        label: l.mangaStatusCancelled,
        value: 'cancelled',
      ),
    ];
  }
}
