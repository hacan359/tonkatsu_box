import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// AniList MediaFormat values for TYPE=ANIME.
class AniListAnimeFormatFilter extends SearchFilter {
  @override
  String get key => 'format';

  @override
  String placeholder(S l) => l.format;

  @override
  FilterSemanticFamily? get semanticFamily =>
      FilterSemanticFamily.format;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(
        id: 'tv',
        label: l.animeFormatTv,
        value: 'TV',
        semantic: FilterSemantic.formatTv,
      ),
      FilterOption(
        id: 'movie',
        label: l.animeFormatMovie,
        value: 'MOVIE',
        semantic: FilterSemantic.formatMovie,
      ),
      FilterOption(
        id: 'ova',
        label: l.animeFormatOva,
        value: 'OVA',
        semantic: FilterSemantic.formatOva,
      ),
      FilterOption(
        id: 'ona',
        label: l.animeFormatOna,
        value: 'ONA',
        semantic: FilterSemantic.formatOna,
      ),
      FilterOption(
        id: 'special',
        label: l.animeFormatSpecial,
        value: 'SPECIAL',
        semantic: FilterSemantic.formatSpecial,
      ),
      FilterOption(
        id: 'tv_short',
        label: l.animeFormatTvShort,
        value: 'TV_SHORT',
        semantic: FilterSemantic.formatTvShort,
      ),
    ];
  }
}
