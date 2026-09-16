import 'package:core/models/anime.dart';
import 'package:core/models/anilist_studio.dart';
import 'package:core/models/manga.dart';

import 'anilist_queries.dart';

class AniListMediaParser {
  const AniListMediaParser._();

  static (List<Anime> items, bool hasMore, int lastPage) animePage(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return (<Anime>[], false, 0);
    final Map<String, dynamic>? page =
        data['Page'] as Map<String, dynamic>?;
    if (page == null) return (<Anime>[], false, 0);

    final (bool hasMore, int lastPage) info = _pageInfo(page);
    final List<Anime> items = _mediaList(page)
        .map((Map<String, dynamic> json) => Anime.fromJson(json))
        .toList();
    return (items, info.$1, info.$2);
  }

  static List<AniListStudio> studios(Map<String, dynamic>? data) =>
      _studioNodes(data).map(AniListStudio.fromJson).toList();

  /// Reads the media connection of the first (and, with `perPage: 1`, only)
  /// studio returned by `animeByStudio`.
  static (List<Anime> items, bool hasMore, int lastPage) animeStudioPage(
    Map<String, dynamic>? data,
  ) {
    final List<Map<String, dynamic>> studios = _studioNodes(data);
    if (studios.isEmpty) return (<Anime>[], false, 0);
    final Map<String, dynamic>? media =
        studios.first['media'] as Map<String, dynamic>?;
    if (media == null) return (<Anime>[], false, 0);

    final (bool hasMore, int lastPage) info = _pageInfo(media);
    final List<dynamic> nodes =
        media['nodes'] as List<dynamic>? ?? <dynamic>[];
    final List<Anime> items = nodes
        .map((dynamic n) => Anime.fromJson(n as Map<String, dynamic>))
        .toList();
    return (items, info.$1, info.$2);
  }

  static (List<Manga> items, bool hasMore, int lastPage) mangaPage(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return (<Manga>[], false, 0);
    final Map<String, dynamic>? page =
        data['Page'] as Map<String, dynamic>?;
    if (page == null) return (<Manga>[], false, 0);

    final (bool hasMore, int lastPage) info = _pageInfo(page);
    final List<Manga> items = _mediaList(page)
        .map((Map<String, dynamic> json) => Manga.fromJson(json))
        .toList();
    return (items, info.$1, info.$2);
  }

  // AniList's own GraphQL MediaType tokens as returned in `type` — not our
  // MediaType enum (external-API namespace, translation boundary).
  static const String _aniListTypeAnime = 'ANIME';
  static const String _aniListTypeManga = 'MANGA';

  /// Recommendations per seed from an aliased batch response; a seed whose
  /// `Media` came back null (deleted) maps to an empty list.
  static Map<int, List<Anime>> recommendedAnimeBatch(
    Map<String, dynamic>? data,
    List<int> seedIds,
  ) =>
      _recommendationBatch(
        data,
        seedIds,
        _aniListTypeAnime,
        (Map<String, dynamic> json) => Anime.fromJson(json),
      );

  static Map<int, List<Manga>> recommendedMangaBatch(
    Map<String, dynamic>? data,
    List<int> seedIds,
  ) =>
      _recommendationBatch(
        data,
        seedIds,
        _aniListTypeManga,
        (Map<String, dynamic> json) => Manga.fromJson(json),
      );

  static Map<int, List<T>> _recommendationBatch<T>(
    Map<String, dynamic>? data,
    List<int> seedIds,
    String type,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final Map<int, List<T>> out = <int, List<T>>{};
    for (int i = 0; i < seedIds.length; i++) {
      final Map<String, dynamic>? media =
          data?[AniListQueries.recommendationAlias(i)] as Map<String, dynamic>?;
      out[seedIds[i]] =
          _recommendationMedia(media, type).map(fromJson).toList();
    }
    return out;
  }

  /// Recommendation nodes can point at deleted media (null) or cross media
  /// types — both are dropped, keeping the server's rating order.
  static List<Map<String, dynamic>> _recommendationMedia(
    Map<String, dynamic>? media,
    String type,
  ) {
    final Map<String, dynamic>? recommendations =
        media?['recommendations'] as Map<String, dynamic>?;
    final List<dynamic> nodes =
        recommendations?['nodes'] as List<dynamic>? ?? <dynamic>[];
    return <Map<String, dynamic>>[
      for (final dynamic node in nodes)
        if ((node as Map<String, dynamic>?)?['mediaRecommendation']
            case final Map<String, dynamic> rec when rec['type'] == type)
          rec,
    ];
  }

  // AniList fuzzy dates: year is mandatory, month/day may be null/0.
  static DateTime? fuzzyDate(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final int? year = raw['year'] as int?;
    if (year == null) return null;
    final int month = raw['month'] as int? ?? 1;
    final int day = raw['day'] as int? ?? 1;
    try {
      return DateTime.utc(year, month, day);
    } on ArgumentError {
      return null;
    }
  }

  static List<Map<String, dynamic>> _studioNodes(Map<String, dynamic>? data) {
    final Map<String, dynamic>? page =
        data?['Page'] as Map<String, dynamic>?;
    final List<dynamic> raw =
        page?['studios'] as List<dynamic>? ?? <dynamic>[];
    return raw.map((dynamic s) => s as Map<String, dynamic>).toList();
  }

  static (bool hasMore, int lastPage) _pageInfo(Map<String, dynamic> page) {
    final Map<String, dynamic>? info =
        page['pageInfo'] as Map<String, dynamic>?;
    final bool hasMore = info?['hasNextPage'] as bool? ?? false;
    final int lastPage = info?['lastPage'] as int? ?? 1;
    return (hasMore, lastPage);
  }

  static List<Map<String, dynamic>> _mediaList(Map<String, dynamic> page) {
    final List<dynamic> raw =
        page['media'] as List<dynamic>? ?? <dynamic>[];
    return raw
        .map((dynamic item) => item as Map<String, dynamic>)
        .toList();
  }
}
