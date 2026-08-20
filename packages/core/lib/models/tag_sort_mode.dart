import 'tag.dart';

/// Display order of global tag lists; [manual] follows the stored sort_order.
enum TagSortMode {
  manual('manual'),
  alphaAsc('alpha_asc'),
  alphaDesc('alpha_desc');

  const TagSortMode(this.value);

  final String value;

  static TagSortMode fromString(String value) {
    return TagSortMode.values.firstWhere(
      (TagSortMode mode) => mode.value == value,
      orElse: () => TagSortMode.manual,
    );
  }

  /// Returns [tags] in this display order; manual keeps the incoming order.
  List<Tag> apply(List<Tag> tags) {
    switch (this) {
      case TagSortMode.manual:
        return tags;
      case TagSortMode.alphaAsc:
        return List<Tag>.of(tags)..sort(_byNameAsc);
      case TagSortMode.alphaDesc:
        return List<Tag>.of(tags)..sort((Tag a, Tag b) => _byNameAsc(b, a));
    }
  }

  static int _byNameAsc(Tag a, Tag b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
