import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/mangabaka_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_assets.dart';
import '../filters/mangabaka_content_rating_filter.dart';
import '../filters/mangabaka_genre_filter.dart';
import '../filters/mangabaka_status_filter.dart';
import '../filters/mangabaka_tag_filter.dart';
import '../filters/mangabaka_type_filter.dart';
import '../models/search_source.dart';
import '../utils/filter_value_utils.dart';

const int _mangaBakaPageSize = 20;

/// SearchSource backed by MangaBaka (manga / manhwa / manhua / light novels).
///
/// A second manga provider alongside AniList; items are stamped
/// [MediaType.manga] but carry `DataSource.mangabaka` (set inside
/// `Manga.fromMangaBaka`) so they stay distinct from AniList in the cache and
/// collection.
class MangaBakaSource extends SearchSource {
  @override
  String get id => 'mangabaka';

  @override
  MediaType get outputMediaType => MediaType.manga;

  @override
  String get groupId => 'mangabaka';

  @override
  String get groupName => 'MangaBaka';

  @override
  IconData get groupIcon => Icons.local_library_outlined;

  @override
  String label(S l) => l.mediaTypeManga;

  @override
  IconData get icon => Icons.local_library_outlined;

  @override
  String? get iconAsset => AppAssets.iconMangaBakaColor;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        MangaBakaTypeFilter(),
        MangaBakaGenreFilter(),
        MangaBakaTagFilter(),
        MangaBakaStatusFilter(),
        MangaBakaContentRatingFilter(),
      ];

  // MangaBaka has no server-side sort — a single relevance option keeps the
  // sort dropdown inert. supportsSortDuringSearch stays false.
  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
      ];

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
    final MangaBakaApi api = ref.read(mangaBakaApiProvider);

    final (List<Manga> mangas, bool hasMore, int totalPages) =
        await api.browseManga(
      query: query,
      type: filterValues['type'] as String?,
      status: filterValues['status'] as String?,
      contentRating: filterValues['content_rating'] as String?,
      genres: readFilterStringList(filterValues['genre']),
      tags: readFilterStringList(filterValues['tag']),
      page: page,
      perPage: _mangaBakaPageSize,
    );

    return BrowseResult(
      items: mangas,
      mediaType: MediaType.manga,
      hasMore: hasMore,
      totalPages: totalPages,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
