// MangaBaka tag filter (multi-select + custom picker with manual refresh).

import 'package:core/models/mangabaka_tag.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../data/repositories/mangabaka_tags_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';
import '../widgets/mangabaka_tag_picker.dart';

/// Multi-select MangaBaka tag filter (~2700 entries, SQLite-backed catalog
/// cache; refreshed on demand from the picker). Values are tag names — the
/// MangaBaka `tag=` filter accepts names.
class MangaBakaTagFilter extends SearchFilter {
  @override
  String get key => 'tag';

  @override
  String get cacheKey => 'tag_mangabaka';

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
    final List<MangaBakaTag> tags =
        await ref.read(mangaBakaTagsProvider.future);
    return tags
        .map((MangaBakaTag t) => FilterOption(
              id: t.id.toString(),
              label: t.name,
              value: t.name,
            ))
        .toList();
  }

  @override
  Future<Object?> Function(BuildContext, WidgetRef, S, Object?)?
      get openCustomPicker => showMangaBakaTagPicker;
}
