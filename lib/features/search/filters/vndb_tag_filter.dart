// Фильтр тегов (жанров) VNDB.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/visual_novel.dart';
import '../models/search_source.dart';
import '../providers/vndb_tag_provider.dart';

/// Фильтр тегов VNDB.
///
/// Загружает теги категории "content" (жанры) из VNDB API
/// через [vndbTagsProvider].
class VndbTagFilter extends SearchFilter {
  @override
  String get key => 'genre';

  @override
  String get cacheKey => '${key}_vndb';

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
    final List<VndbTag> tags =
        await ref.read(vndbTagsProvider.future);
    return tags
        .map(
          (VndbTag t) => FilterOption(
            id: t.id,
            label: t.name,
            value: t.id,
          ),
        )
        .toList();
  }
}
