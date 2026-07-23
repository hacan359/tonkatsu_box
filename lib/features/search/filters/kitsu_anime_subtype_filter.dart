import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Kitsu anime `subtype`: TV / movie / OVA / ONA / special.
class KitsuAnimeSubtypeFilter extends SearchFilter {
  @override
  String get key => 'subtype';

  @override
  String get cacheKey => 'subtype_kitsu_anime';

  @override
  String placeholder(S l) => l.type;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'TV', label: l.animeFormatTv, value: 'TV'),
      FilterOption(id: 'movie', label: l.animeFormatMovie, value: 'movie'),
      FilterOption(id: 'OVA', label: l.animeFormatOva, value: 'OVA'),
      FilterOption(id: 'ONA', label: l.animeFormatOna, value: 'ONA'),
      FilterOption(
        id: 'special',
        label: l.animeFormatSpecial,
        value: 'special',
      ),
    ];
  }
}
