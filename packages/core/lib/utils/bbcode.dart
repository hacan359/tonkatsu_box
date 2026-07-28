// Cleans Fantlab rich text: BB-codes, HTML / LINK tags and common entities.

/// A BB-code marker — an opening `[tag]` / `[tag=value]` or a closing `[/tag]`.
/// Inner text between a paired tag is kept; only the markers are removed, so
/// `[url=x]Title[/url]` and `[USER=79]Nog[/USER]` collapse to `Title` / `Nog`.
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

/// Strips Fantlab BB-codes (`[b]`, `[i]`, `[url=…]`, `[USER=…]`, `[autor=…]`,
/// `[spoiler]`, …), HTML / LINK tags and common HTML entities, preserving the
/// human-readable inner text. Newlines are normalised (CRLF → LF, runs of 3+
/// blank lines collapsed) and the result is trimmed.
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
