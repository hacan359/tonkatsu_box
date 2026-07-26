// MangaDex publication-demographic filter (multi-select).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// MangaDex `publicationDemographic`: shounen / shoujo / josei / seinen.
class MangaDexDemographicFilter extends SearchFilter {
  @override
  String get key => 'publicationDemographic';

  @override
  String get cacheKey => 'demographic_mangadex';

  @override
  bool get multiSelect => true;

  @override
  String placeholder(S l) => l.browseFilterDemographic;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return const <FilterOption>[
      FilterOption(id: 'shounen', label: 'Shōnen', value: 'shounen'),
      FilterOption(id: 'shoujo', label: 'Shōjo', value: 'shoujo'),
      FilterOption(id: 'seinen', label: 'Seinen', value: 'seinen'),
      FilterOption(id: 'josei', label: 'Josei', value: 'josei'),
    ];
  }
}
