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
      if (item.displayMediaType != type) continue;
      final String? code = item.formatCode;
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

  /// Active groups unite (OR), each scoped to its own kind of item — e.g.
  /// NES + OVA keeps both NES games and OVA anime. No active groups = pass.
  static bool matchesSubfilters(
    CollectionItem item, {
    required Set<int> platformIds,
    required Set<String> mangaFormats,
    required Set<String> animeFormats,
  }) {
    if (platformIds.isEmpty && mangaFormats.isEmpty && animeFormats.isEmpty) {
      return true;
    }
    if (platformIds.contains(item.effectivePlatformId)) return true;
    final String? code = item.formatCode;
    if (code == null) return false;
    return switch (item.displayMediaType) {
      MediaType.manga => mangaFormats.contains(code),
      MediaType.anime => animeFormats.contains(code),
      _ => false,
    };
  }
}
