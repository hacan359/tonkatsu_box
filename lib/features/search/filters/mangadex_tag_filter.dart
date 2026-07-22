// MangaDex tag filter (theme-group tags; multi-select + custom picker).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/mangadex_tags_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/mangadex_tag.dart';
import '../models/search_source.dart';
import '../widgets/mangadex_tag_picker.dart';

/// The theme-group entries of the cached MangaDex tag catalog, sorted by name.
final FutureProvider<List<MangaDexTag>> mangaDexThemesProvider =
    FutureProvider<List<MangaDexTag>>((Ref ref) async {
  final List<MangaDexTag> tags = await ref.watch(mangaDexTagsProvider.future);
  return tags.where((MangaDexTag t) => t.group == 'theme').toList()
    ..sort((MangaDexTag a, MangaDexTag b) => a.name.compareTo(b.name));
});

/// MangaDex theme-group tags (Isekai, Ninja, Magic, …). Merged with the
/// genre-group [MangaDexGenreFilter] into `includedTags[]` by the source.
class MangaDexTagFilter extends SearchFilter {
  @override
  String get key => 'themeTags';

  @override
  String get cacheKey => 'tag_mangadex';

  @override
  bool get multiSelect => true;

  @override
  bool get searchable => true;

  @override
  String placeholder(S l) => l.tagLabel;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    final List<MangaDexTag> themes =
        await ref.read(mangaDexThemesProvider.future);
    return themes
        .map((MangaDexTag t) => FilterOption(
              id: t.id,
              label: t.name,
              value: t.id,
            ))
        .toList();
  }

  @override
  Future<Object?> Function(BuildContext, WidgetRef, S, Object?)?
      get openCustomPicker => showMangaDexTagPicker;
}
