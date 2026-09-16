import '../models/collection_item.dart';
import '../models/media_type.dart';
import 'meta_search.dart';

/// One search pass over library items: the query is lowercased and parsed
/// once, then [matches] runs per item in either mode.
class ItemSearch {
  ItemSearch({
    required String query,
    required this.mode,
    required this.itemTags,
    required Map<int, String> tagNames,
    required this.titleLanguage,
  })  : _query = query.trim().toLowerCase(),
        _tagNames = <int, String>{
          for (final MapEntry<int, String> e in tagNames.entries)
            e.key: e.value.toLowerCase(),
        },
        _metaGroups = mode == SearchMode.meta
            ? parseMetaQuery(query)
            : const <List<String>>[];

  final SearchMode mode;

  /// Item id → global tag ids.
  final Map<int, List<int>> itemTags;

  /// Tag id → lowercased name; lowercased once here, not per item per tag.
  final Map<int, String> _tagNames;

  final String titleLanguage;
  final String _query;
  final List<List<String>> _metaGroups;

  bool matches(CollectionItem item) {
    if (_query.isEmpty) return true;
    if (mode == SearchMode.meta) {
      return matchesParsedMetaQuery(item, _metaGroups);
    }
    return item.displayName(titleLanguage).toLowerCase().contains(_query) ||
        _matchesTagName(item) ||
        (item.userComment?.toLowerCase().contains(_query) ?? false) ||
        (item.authorComment?.toLowerCase().contains(_query) ?? false) ||
        creatorsOf(item)
            .any((String name) => name.toLowerCase().contains(_query));
  }

  bool _matchesTagName(CollectionItem item) {
    final List<int>? ids = itemTags[item.id];
    if (ids == null) return false;
    return ids.any(
      (int id) => _tagNames[id]?.contains(_query) ?? false,
    );
  }

  /// Albums match by artist and books by author, so "pink floyd" finds the
  /// album although the query is not in its title.
  static List<String> creatorsOf(CollectionItem item) =>
      switch (item.mediaType) {
        MediaType.audio => item.audioItem?.artists ?? const <String>[],
        MediaType.book => item.book?.authors ?? const <String>[],
        _ => const <String>[],
      };
}
