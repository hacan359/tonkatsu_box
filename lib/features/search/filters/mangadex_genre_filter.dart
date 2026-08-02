// MangaDex genre filter (multi-select, from the SQLite-cached tag catalog).

import 'package:core/models/mangadex_tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/mangadex_tags_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// The genre-group entries of the cached MangaDex tag catalog, sorted by name.
final FutureProvider<List<MangaDexTag>> mangaDexGenresProvider =
    FutureProvider<List<MangaDexTag>>((Ref ref) async {
  final List<MangaDexTag> tags = await ref.watch(mangaDexTagsProvider.future);
  return tags.where((MangaDexTag t) => t.group == 'genre').toList()
    ..sort((MangaDexTag a, MangaDexTag b) => a.name.compareTo(b.name));
});

/// MangaDex genre-group tags. Multi-select; the source merges this with the
/// theme-group [MangaDexTagFilter] into `includedTags[]` (AND). A distinct
/// [key] from the tag filter keeps their selections in separate slots.
class MangaDexGenreFilter extends SearchFilter {
  @override
  String get key => 'genreTags';

  @override
  String get cacheKey => 'genre_mangadex';

  @override
  bool get multiSelect => true;

  @override
  bool get searchable => true;

  @override
  String placeholder(S l) => l.browseFilterGenre;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    final List<MangaDexTag> genres =
        await ref.read(mangaDexGenresProvider.future);
    return genres
        .map((MangaDexTag t) => FilterOption(
              id: t.id,
              label: t.name,
              value: t.id,
            ))
        .toList();
  }
}
