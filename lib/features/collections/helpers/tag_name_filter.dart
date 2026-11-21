import 'package:core/models/tag.dart';

/// Below this many tags a chip row is scanned faster than it is typed into.
const int kTagSearchMinTags = 8;

/// Case-insensitive substring match on the name; [keepIds] always survive so
/// an active filter never vanishes behind the query.
List<Tag> filterTagsByName(
  List<Tag> tags,
  String query, {
  Set<int> keepIds = const <int>{},
}) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return tags;
  return <Tag>[
    for (final Tag tag in tags)
      if (keepIds.contains(tag.id) || tag.name.toLowerCase().contains(q)) tag,
  ];
}
