import '../models/anime.dart';
import '../models/collection_item.dart';
import '../models/manga.dart';
import '../models/media_type.dart';

/// Helpers for the manga / anime `format` subfilter: canonical chip ordering,
/// display labels, and extracting the distinct formats present in a list of
/// collection items.
abstract final class MediaFormat {
  /// Manga format codes in the order their chips should appear.
  static const List<String> mangaOrder = <String>[
    'MANGA',
    'MANHWA',
    'MANHUA',
    'NOVEL',
    'LIGHT_NOVEL',
    'ONE_SHOT',
  ];

  /// Anime format codes in the order their chips should appear.
  static const List<String> animeOrder = <String>[
    'TV',
    'TV_SHORT',
    'MOVIE',
    'OVA',
    'ONA',
    'SPECIAL',
    'MUSIC',
  ];

  /// Display label for a format [code] of the given manga/anime [type].
  /// Falls back to the raw code for unrecognised values.
  static String label(MediaType type, String code) =>
      (type == MediaType.manga
              ? Manga.mangaFormatLabel(code)
              : Anime.animeFormatLabel(code)) ??
          code;

  /// Distinct, canonically-ordered format codes present among [items] for the
  /// given manga/anime [type]. Empty for any other media type.
  static List<String> present(List<CollectionItem> items, MediaType type) {
    if (type != MediaType.manga && type != MediaType.anime) {
      return const <String>[];
    }
    final List<String> order =
        type == MediaType.manga ? mangaOrder : animeOrder;
    final Set<String> found = <String>{};
    for (final CollectionItem item in items) {
      if (item.mediaType != type) continue;
      final String? code =
          type == MediaType.manga ? item.manga?.format : item.anime?.format;
      if (code != null && code.isNotEmpty) found.add(code);
    }
    final List<String> result = found.toList()
      ..sort((String a, String b) {
        final int ia = order.indexOf(a);
        final int ib = order.indexOf(b);
        final int sa = ia == -1 ? order.length : ia;
        final int sb = ib == -1 ? order.length : ib;
        return sa != sb ? sa.compareTo(sb) : a.compareTo(b);
      });
    return result;
  }

  /// Whether [item] survives the combined manga + anime format filter.
  ///
  /// With neither set active everything passes. Once any format is selected the
  /// filter narrows globally like the games platform filter: only a manga whose
  /// format is in [mangaFormats], or an anime whose format is in [animeFormats],
  /// survives — every other item (games, other media types, unselected formats)
  /// is hidden. Selecting formats in both sets keeps either (OR).
  static bool matchesFormatFilter(
    CollectionItem item, {
    required Set<String> mangaFormats,
    required Set<String> animeFormats,
  }) {
    if (mangaFormats.isEmpty && animeFormats.isEmpty) return true;
    switch (item.mediaType) {
      case MediaType.manga:
        final String? code = item.manga?.format;
        return code != null && mangaFormats.contains(code);
      case MediaType.anime:
        final String? code = item.anime?.format;
        return code != null && animeFormats.contains(code);
      default:
        return false;
    }
  }
}
