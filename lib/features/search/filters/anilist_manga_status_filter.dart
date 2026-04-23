// Фильтр статуса публикации манги (AniList).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр статуса манги.
///
/// Статусы соответствуют AniList MediaStatus enum. Отличается от
/// [AniListAnimeStatusFilter] только лейблами: «Publishing» вместо
/// «Airing», добавлен HIATUS — частый статус для манги.
class AniListMangaStatusFilter extends SearchFilter {
  @override
  String get key => 'status';

  @override
  String placeholder(S l) => l.animeFilterStatus;

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
        id: 'releasing',
        label: l.mangaStatusPublishing,
        value: 'RELEASING',
      ),
      FilterOption(
        id: 'finished',
        label: l.mangaStatusFinished,
        value: 'FINISHED',
      ),
      FilterOption(
        id: 'not_yet_released',
        label: l.mangaStatusNotYetPublished,
        value: 'NOT_YET_RELEASED',
      ),
      FilterOption(
        id: 'cancelled',
        label: l.mangaStatusCancelled,
        value: 'CANCELLED',
      ),
      FilterOption(
        id: 'hiatus',
        label: l.mangaStatusHiatus,
        value: 'HIATUS',
      ),
    ];
  }
}
