import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/mangadex_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../filters/mangadex_content_rating_filter.dart';
import '../filters/mangadex_demographic_filter.dart';
import '../filters/mangadex_genre_filter.dart';
import '../filters/mangadex_status_filter.dart';
import '../filters/mangadex_tag_filter.dart';
import '../models/search_source.dart';
import '../utils/filter_value_utils.dart';

const int _mangaDexPageSize = 20;

/// SearchSource backed by MangaDex (manga).
///
/// A manga provider alongside AniList / MangaBaka; items are stamped
/// [MediaType.manga] but carry `DataSource.mangadex` (set inside
/// `Manga.fromMangaDex`) so they stay distinct in the cache and collection.
class MangaDexSource extends SearchSource {
  @override
  String get id => 'mangadex';

  @override
  MediaType get outputMediaType => MediaType.manga;

  @override
  DataSource get dataSource => DataSource.mangadex;

  @override
  IconData get groupIcon => Icons.menu_book_outlined;

  @override
  String label(S l) => l.mediaTypeManga;

  @override
  IconData get icon => Icons.menu_book_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        MangaDexGenreFilter(),
        MangaDexTagFilter(),
        MangaDexStatusFilter(),
        MangaDexDemographicFilter(),
        MangaDexContentRatingFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: 'relevance'),
        BrowseSortOption(id: 'popular', apiValue: 'followedCount'),
        BrowseSortOption(id: 'top_rated', apiValue: 'rating'),
        BrowseSortOption(id: 'newest', apiValue: 'year'),
        BrowseSortOption(id: 'recently_updated', apiValue: 'latestUploadedChapter'),
        BrowseSortOption(id: 'name_asc', apiValue: 'title'),
      ];

  @override
  bool get supportsSortDuringSearch => true;

  @override
  String searchHint(S l) => l.searchHintManga;

  @override
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final MangaDexApi api = ref.read(mangaDexApiProvider);

    // Genre and theme tags live in separate filter slots but combine into one
    // `includedTags[]` (AND).
    final List<String> includedTags = <String>[
      ...?readFilterStringList(filterValues['genreTags']),
      ...?readFilterStringList(filterValues['themeTags']),
    ];
    final (List<Manga> mangas, bool hasMore, int totalPages) =
        await api.browseManga(
      query: query,
      statuses: readFilterStringList(filterValues['status']),
      demographics: readFilterStringList(filterValues['publicationDemographic']),
      contentRatings: readFilterStringList(filterValues['contentRating']),
      includedTags: includedTags.isEmpty ? null : includedTags,
      order: _orderFor(sortBy, query),
      page: page,
      perPage: _mangaDexPageSize,
    );

    return BrowseResult(
      items: mangas,
      mediaType: MediaType.manga,
      hasMore: hasMore,
      totalPages: totalPages,
      currentPage: page,
    );
  }

  /// Maps a sort id to a MangaDex `order` map. `relevance` is only valid with a
  /// text query — when browsing it falls back to popularity.
  Map<String, String> _orderFor(String sortBy, String? query) {
    final bool hasQuery = query != null && query.trim().isNotEmpty;
    return switch (sortBy) {
      'relevance' =>
        hasQuery ? <String, String>{'relevance': 'desc'} : _byFollowed,
      'popular' => _byFollowed,
      'top_rated' => <String, String>{'rating': 'desc'},
      'newest' => <String, String>{'year': 'desc'},
      'recently_updated' => <String, String>{'latestUploadedChapter': 'desc'},
      'name_asc' => <String, String>{'title': 'asc'},
      _ => hasQuery ? <String, String>{'relevance': 'desc'} : _byFollowed,
    };
  }

  static const Map<String, String> _byFollowed = <String, String>{
    'followedCount': 'desc',
  };

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
