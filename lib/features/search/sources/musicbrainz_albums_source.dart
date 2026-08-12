import 'package:core/models/album.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/listenbrainz_api.dart';
import '../../../core/api/musicbrainz_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/musicbrainz_genre_filter.dart';
import '../filters/musicbrainz_primary_type_filter.dart';
import '../filters/musicbrainz_scope_filter.dart';
import '../filters/musicbrainz_studio_only_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';

/// MusicBrainz release-groups; the page order is Lucene relevance re-ranked
/// by ListenBrainz listen counts (best-effort, failures keep the order).
class MusicBrainzAlbumsSource extends SearchSource {
  @override
  String get id => 'musicbrainz';

  @override
  MediaType get outputMediaType => MediaType.music;

  @override
  DataSource get dataSource => DataSource.musicBrainz;

  @override
  String label(S l) => l.searchSourceMusic;

  @override
  IconData get icon => Icons.album;

  @override
  bool get supportsBrowse => true;

  // The MusicBrainz service rule is <1 req/s; typing at the default 400ms
  // debounce would queue 2-3 requests per second.
  @override
  Duration get searchDebounce => const Duration(milliseconds: 1200);

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        MusicBrainzScopeFilter(),
        MusicBrainzGenreFilter(),
        MusicBrainzPrimaryTypeFilter(),
        MusicBrainzStudioOnlyFilter(),
        YearFilter(),
      ];

  // Lucene has no sort; the only honest option is relevance.
  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
      ];

  @override
  String searchHint(S l) => l.searchHintMusic;

  @override
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final String text = query?.trim() ?? '';

    // Unset type defaults to Album; the sentinel means "any type", picked
    // explicitly — promo singles would otherwise flood every search.
    final Object? rawType = filterValues['type'];
    final String? primaryType = switch (rawType) {
      kMusicBrainzAnyPrimaryType => null,
      final String t => t,
      _ => 'album',
    };

    final (int?, int?) years = _yearRange(filterValues['year']);

    final MusicBrainzApi api = ref.read(musicBrainzApiProvider);
    final (List<Album> albums, bool hasMore, int total) = await api.search(
      query: text,
      queryField: filterValues['scope'] as String?,
      primaryType: primaryType,
      excludeSecondaryTypes: filterValues['studio'] == true,
      tag: filterValues['genre'] as String?,
      yearFrom: years.$1,
      yearTo: years.$2,
      page: page,
    );

    return BrowseResult(
      items: await _rerankByPopularity(ref, albums),
      mediaType: MediaType.music,
      hasMore: hasMore,
      currentPage: page,
      totalPages: total == 0 ? 1 : ((total + 19) ~/ 20),
    );
  }

  /// Listen counts pinned onto the page, most-listened first — the real
  /// "Dark Side of the Moon" outweighs its Lucene-score-100 namesakes.
  Future<List<Album>> _rerankByPopularity(Ref ref, List<Album> albums) async {
    if (albums.length < 2) return albums;
    final Map<String, int> counts = await ref
        .read(listenBrainzApiProvider)
        .getReleaseGroupPopularity(
          albums.map((Album a) => a.mbid).toList(),
        );
    if (counts.isEmpty) return albums;

    final List<Album> withCounts = albums
        .map((Album a) => counts.containsKey(a.mbid)
            ? a.copyWith(listenCount: counts[a.mbid])
            : a)
        .toList();
    // List.sort is not stable — the index tiebreaker keeps MusicBrainz
    // relevance order among equally-listened albums.
    final List<(int, Album)> indexed = <(int, Album)>[
      for (int i = 0; i < withCounts.length; i++) (i, withCounts[i]),
    ];
    indexed.sort(((int, Album) a, (int, Album) b) {
      final int byCount =
          (b.$2.listenCount ?? 0).compareTo(a.$2.listenCount ?? 0);
      return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
    });
    return <Album>[for (final (int, Album) e in indexed) e.$2];
  }

  /// YearFilter values are a single year (int) or a decade ((int, int)).
  static (int?, int?) _yearRange(Object? value) => switch (value) {
        final int year => (year, year),
        (final int from, final int to) => (from, to),
        _ => (null, null),
      };

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
