// Kitsu manga subtype filter (single-select).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Kitsu manga `subtype`: manga / novel / manhwa / manhua / oneshot.
class KitsuMangaSubtypeFilter extends SearchFilter {
  @override
  String get key => 'subtype';

  @override
  String get cacheKey => 'subtype_kitsu_manga';

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
      FilterOption(id: 'manga', label: l.mediaTypeManga, value: 'manga'),
      FilterOption(id: 'novel', label: l.mangaFormatNovel, value: 'novel'),
      FilterOption(id: 'manhwa', label: l.mangaFormatManhwa, value: 'manhwa'),
      FilterOption(id: 'manhua', label: l.mangaFormatManhua, value: 'manhua'),
      FilterOption(
        id: 'oneshot',
        label: l.mangaFormatOneShot,
        value: 'oneshot',
      ),
    ];
  }
}
