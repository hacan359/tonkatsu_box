// Фильтр формата манги (AniList).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр формата манги.
///
/// AniList `MediaFormat` для TYPE=MANGA содержит только: MANGA, NOVEL,
/// ONE_SHOT. Manhwa/Manhua в AniList определяются через `countryOfOrigin`,
/// а не через format — сюда их не включаем.
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
