import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// AniList MediaFormat for TYPE=MANGA: only MANGA, NOVEL, ONE_SHOT.
/// Manhwa/Manhua are distinguished by countryOfOrigin, not format, so they're
/// excluded here.
class MangaFormatFilter extends SearchFilter {
  @override
  String get key => 'format';

  @override
  String placeholder(S l) => l.browseFilterFormat;

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
        id: 'manga',
        label: l.mangaFormatManga,
        value: 'MANGA',
      ),
      FilterOption(
        id: 'novel',
        label: l.mangaFormatNovel,
        value: 'NOVEL',
      ),
      FilterOption(
        id: 'one_shot',
        label: l.mangaFormatOneShot,
        value: 'ONE_SHOT',
      ),
    ];
  }
}
