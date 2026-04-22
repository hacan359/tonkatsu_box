// Фильтр формата AniList для аниме (TV / MOVIE / OVA / ONA / SPECIAL).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр формата аниме AniList.
///
/// Значения соответствуют AniList MediaFormat enum для TYPE=ANIME.
class AniListAnimeFormatFilter extends SearchFilter {
  @override
  String get key => 'format';

  @override
  String placeholder(S l) => l.browseFilterFormat;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'tv', label: l.animeFormatTv, value: 'TV'),
      FilterOption(id: 'movie', label: l.animeFormatMovie, value: 'MOVIE'),
      FilterOption(id: 'ova', label: l.animeFormatOva, value: 'OVA'),
      FilterOption(id: 'ona', label: l.animeFormatOna, value: 'ONA'),
      FilterOption(
        id: 'special',
        label: l.animeFormatSpecial,
        value: 'SPECIAL',
      ),
      FilterOption(
        id: 'tv_short',
        label: l.animeFormatTvShort,
        value: 'TV_SHORT',
      ),
    ];
  }
}
