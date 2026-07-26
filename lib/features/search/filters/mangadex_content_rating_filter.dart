// MangaDex content-rating filter (multi-select).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// MangaDex `contentRating`: safe / suggestive / erotica / pornographic.
/// When nothing is selected the API defaults to safe + suggestive.
class MangaDexContentRatingFilter extends SearchFilter {
  @override
  String get key => 'contentRating';

  @override
  String get cacheKey => 'content_rating_mangadex';

  @override
  bool get multiSelect => true;

  @override
  String placeholder(S l) => l.browseFilterContentRating;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: 'safe', label: l.contentRatingSafe, value: 'safe'),
      FilterOption(
        id: 'suggestive',
        label: l.contentRatingSuggestive,
        value: 'suggestive',
      ),
      FilterOption(
        id: 'erotica',
        label: l.contentRatingErotica,
        value: 'erotica',
      ),
      FilterOption(
        id: 'pornographic',
        label: l.contentRatingPornographic,
        value: 'pornographic',
      ),
    ];
  }
}
