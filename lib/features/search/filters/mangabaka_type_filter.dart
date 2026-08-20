import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// MangaBaka `type`: manga / manhwa / manhua / novel.
class MangaBakaTypeFilter extends SearchFilter {
  @override
  String get key => 'type';

  @override
  String get cacheKey => 'type_mangabaka';

  @override
  String placeholder(S l) => l.type;

  @override
  FilterSemanticFamily? get semanticFamily =>
      FilterSemanticFamily.format;

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
        label: l.mediaTypeManga,
        value: 'manga',
        semantic: FilterSemantic.typeManga,
      ),
      FilterOption(
        id: 'manhwa',
        label: l.mangaFormatManhwa,
        value: 'manhwa',
        semantic: FilterSemantic.typeManhwa,
      ),
      FilterOption(
        id: 'manhua',
        label: l.mangaFormatManhua,
        value: 'manhua',
        semantic: FilterSemantic.typeManhua,
      ),
      FilterOption(
        id: 'novel',
        label: l.mangaFormatNovel,
        value: 'novel',
        semantic: FilterSemantic.typeNovel,
      ),
    ];
  }
}
