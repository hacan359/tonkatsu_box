import '../models/collection_item.dart';

/// Which fields the library search field matches against.
enum SearchMode {
  title,
  meta;
}

final RegExp _andSeparator = RegExp('[,，]');
final RegExp _orSeparator = RegExp('[/|]');
final RegExp _anySeparator = RegExp('[,，/|]');
final RegExp _whitespace = RegExp(r'\s+');

/// Descriptors and chip values are compared with the query separators
/// flattened to spaces, so "AC/DC" stays one phrase on both sides.
String normalizeMetaValue(String value) => value
    .toLowerCase()
    .replaceAll(_anySeparator, ' ')
    .replaceAll(_whitespace, ' ')
    .trim();

/// Comma-separated groups are ANDed, `/` (or `|`) inside a group ORs phrases;
/// a phrase keeps its spaces so "kyoto animation" is one value, not two words.
List<List<String>> parseMetaQuery(String query) {
  final List<List<String>> groups = <List<String>>[];
  for (final String group in query.toLowerCase().split(_andSeparator)) {
    final List<String> alternatives = group
        .split(_orSeparator)
        .map((String phrase) => phrase.trim().replaceAll(_whitespace, ' '))
        .where((String phrase) => phrase.isNotEmpty)
        .toList(growable: false);
    if (alternatives.isNotEmpty) groups.add(alternatives);
  }
  return groups;
}

/// Every group must have at least one phrase contained in some descriptor.
bool matchesMetaQuery(CollectionItem item, String query) =>
    matchesParsedMetaQuery(item, parseMetaQuery(query));

/// Filter loops parse once and call this per item; [groups] comes from
/// [parseMetaQuery].
bool matchesParsedMetaQuery(CollectionItem item, List<List<String>> groups) {
  if (groups.isEmpty) return true;
  final List<String> meta =
      item.searchableMeta.map(normalizeMetaValue).toList(growable: false);
  return groups.every(
    (List<String> alternatives) => alternatives.any(
      (String phrase) => meta.any((String value) => value.contains(phrase)),
    ),
  );
}

/// Adds a chip value as one more AND group unless an equal phrase is already
/// there, so tapping the same chip twice does not duplicate it.
String appendMetaTerm(String current, String value) {
  final String term = metaTermFor(value);
  final String trimmed = current.trim();
  if (trimmed.isEmpty) return term;
  final String needle = term.toLowerCase();
  final bool present = parseMetaQuery(trimmed)
      .any((List<String> group) => group.length == 1 && group.first == needle);
  return present ? trimmed : '$trimmed, $term';
}

/// A chip value typed into the query verbatim would be re-split on its own
/// commas and slashes; the separators become spaces, the case is kept.
String metaTermFor(String value) =>
    value.replaceAll(_anySeparator, ' ').replaceAll(_whitespace, ' ').trim();
