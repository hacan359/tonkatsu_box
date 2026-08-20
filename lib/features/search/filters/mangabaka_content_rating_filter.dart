import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// MangaBaka `content_rating`: safe / suggestive / explicit.
class MangaBakaContentRatingFilter extends SearchFilter {
  @override
  String get key => 'content_rating';

  @override
  String get cacheKey => 'content_rating_mangabaka';

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
