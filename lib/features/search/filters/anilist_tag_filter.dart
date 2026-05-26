import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../data/repositories/anilist_tags_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/anilist_tag.dart';
import '../models/search_source.dart';
import '../widgets/anilist_tag_picker.dart';

/// Multi-select AniList tag filter (~600 entries, served from a SQLite-backed
/// catalog cache; refreshed weekly).
///
/// [forAnime] is used purely for cache-key separation in the filter bar so
/// anime / manga can keep independent selections.
class AniListTagFilter extends SearchFilter {
  AniListTagFilter({this.forAnime = false});

  final bool forAnime;

  @override
  String get key => 'tag';

  @override
  String get cacheKey =>
      forAnime ? '${key}_anilist_anime' : '${key}_anilist_manga';

  @override
  bool get multiSelect => true;

  @override
  bool get searchable => true;

  @override
  String placeholder(S l) => l.browseFilterTag;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    final List<AniListTag> tags =
        await ref.read(aniListTagsProvider.future);
    return tags
        .map((AniListTag t) => FilterOption(
              id: t.id.toString(),
              label: t.name,
              value: t.name,
            ))
        .toList();
  }

  @override
  Future<Object?> Function(BuildContext, WidgetRef, S, Object?)?
      get openCustomPicker => showAniListTagPicker;
}
