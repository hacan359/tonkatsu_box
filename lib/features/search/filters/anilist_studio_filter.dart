import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';
import '../widgets/anilist_studio_picker.dart';

/// Single-select by studio name via a live `studios(search:)` picker. Exclusive:
/// `Studio.media` takes no search/genre/status arguments (see animeByStudio).
class AniListStudioFilter extends SearchFilter {
  static const String filterKey = 'studio';

  @override
  String get key => filterKey;

  // MusicBrainz also has a 'studio' key (studio albums only).
  @override
  String get cacheKey => '${key}_anilist_anime';

  @override
  bool get exclusive => true;

  @override
  String placeholder(S l) => l.studioLabel;

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'any', label: 'All', value: null);

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async =>
      const <FilterOption>[];

  @override
  Future<Object?> Function(BuildContext, WidgetRef, S, Object?)?
  get openCustomPicker => showAniListStudioPicker;
}
