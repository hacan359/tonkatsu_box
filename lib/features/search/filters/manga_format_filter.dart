// Фильтр формата манги (AniList).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр формата манги.
///
/// Форматы соответствуют AniList MediaFormat enum для TYPE=MANGA.
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
        id: 'manhwa',
        label: l.mangaFormatManhwa,
        value: 'MANHWA',
      ),
      FilterOption(
        id: 'manhua',
        label: l.mangaFormatManhua,
        value: 'MANHUA',
      ),
      FilterOption(
        id: 'one_shot',
        label: l.mangaFormatOneShot,
        value: 'ONE_SHOT',
      ),
      FilterOption(
        id: 'novel',
        label: l.mangaFormatNovel,
        value: 'NOVEL',
      ),
      FilterOption(
        id: 'light_novel',
        label: l.mangaFormatLightNovel,
        value: 'LIGHT_NOVEL',
      ),
    ];
  }
}
