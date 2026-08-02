/// Matches an opening `[tag]` / `[tag=value]` or a closing `[/tag]`; inner text
/// survives, so `[url=x]Title[/url]` collapses to `Title`.
final RegExp _bbTag = RegExp(r'\[/?[a-zA-Z][^\]]*\]');

/// An HTML / LINK tag (Fantlab text can carry both BB-codes and HTML links).
final RegExp _htmlTag = RegExp('<[^>]+>');

/// The handful of HTML entities Fantlab descriptions actually use.
const Map<String, String> _entities = <String, String>{
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  '&#39;': "'",
  '&nbsp;': ' ',
  '&laquo;': '«',
  '&raquo;': '»',
  '&mdash;': '—',
  '&ndash;': '–',
  '&hellip;': '…',
};

final RegExp _trailingSpaces = RegExp(r'[ \t]+\n');
final RegExp _multiNewline = RegExp(r'\n{3,}');

/// Strips Fantlab BB-codes, HTML / LINK tags and common entities, keeping the
/// readable text. Newlines are normalised and the result trimmed.
String stripBbCodes(String input) {
  if (input.isEmpty) return input;

  String out = input.replaceAll(_bbTag, '').replaceAll(_htmlTag, '');
  _entities.forEach((String entity, String value) {
    out = out.replaceAll(entity, value);
  });

  return out
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(_trailingSpaces, '\n')
      .replaceAll(_multiNewline, '\n\n')
      .trim();
}
