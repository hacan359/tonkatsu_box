import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

// Top-level slice of Podcast Index's Apple-derived taxonomy (112 entries
// counting subcategories); names are API vocabulary and stay English.
const List<String> _categories = <String>[
  'Arts',
  'Business',
  'Comedy',
  'Education',
  'Fiction',
  'Government',
  'Health',
  'History',
  'Kids',
  'Family',
  'Leisure',
  'Music',
  'News',
  'Religion',
  'Science',
  'Society',
  'Culture',
  'Sports',
  'Technology',
  'True Crime',
  'TV',
  'Film',
  'Documentary',
  'Interviews',
  'Investing',
  'Entrepreneurship',
  'Language',
  'Self-Improvement',
  'Fitness',
  'Mental',
  'Nutrition',
  'Parenting',
  'Pets',
  'Games',
  'Video-Games',
  'Hobbies',
  'Travel',
  'Politics',
  'Philosophy',
  'Astronomy',
  'Nature',
  'Mathematics',
  'Physics',
  'Cryptocurrency',
  'Football',
  'Basketball',
  'Soccer',
  'Running',
];

/// Podcast Index `cat=` filter — only the trending endpoint accepts it, so it
/// applies in Browse mode; text search upstream has no category parameter.
class PodcastIndexCategoryFilter extends SearchFilter {
  @override
  String get key => 'category';

  @override
  String get cacheKey => 'category_podcastindex';

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
    return <FilterOption>[
      for (final String category in _categories)
        FilterOption(id: category, label: category, value: category),
    ];
  }
}
