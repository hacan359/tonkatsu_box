enum TitleMatchKind { none, unique, ambiguous }

class TitleMatch<T> {
  const TitleMatch._(this.kind, this.match, this.count);

  final TitleMatchKind kind;

  /// Set only for [TitleMatchKind.unique].
  final T? match;

  final int count;
}

final RegExp _nonLetterOrDigit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Comparison key: any alphabet survives, unlike an `[a-z0-9]` filter that
/// collapses every Cyrillic title into the same empty key.
String normalizeTitle(String value) => value
    .toLowerCase()
    .replaceAll('&', ' and ')
    .replaceAll('ё', 'е')
    .replaceAll(_nonLetterOrDigit, '');

/// Strict "exactly one": an exact normalized title (any of the result's
/// titles) plus the year when given; a prefix or a near title never counts.
TitleMatch<T> classifyTitleMatches<T>({
  required List<String> queryTitles,
  required List<T> results,
  required List<String?> Function(T result) titlesOf,
  int? year,
  int? Function(T result)? yearOf,
}) {
  final Set<String> keys = <String>{
    for (final String title in queryTitles)
      if (normalizeTitle(title).isNotEmpty) normalizeTitle(title),
  };
  final List<T> hits = <T>[
    for (final T result in results)
      if ((year == null || yearOf?.call(result) == year) &&
          titlesOf(result).any(
            (String? t) => t != null && keys.contains(normalizeTitle(t)),
          ))
        result,
  ];
  if (hits.isEmpty) return TitleMatch<T>._(TitleMatchKind.none, null, 0);
  if (hits.length == 1) {
    return TitleMatch<T>._(TitleMatchKind.unique, hits.first, 1);
  }
  return TitleMatch<T>._(TitleMatchKind.ambiguous, null, hits.length);
}
