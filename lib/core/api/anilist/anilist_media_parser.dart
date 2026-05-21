import '../../../shared/models/anime.dart';
import '../../../shared/models/manga.dart';

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
