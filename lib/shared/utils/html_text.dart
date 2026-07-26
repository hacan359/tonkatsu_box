final RegExp _htmlTagPattern = RegExp('<[^>]*>');
final RegExp _numericEntity = RegExp('&#(x?[0-9a-fA-F]+);');

/// Removes HTML markup and decodes the entities common in TVmaze summaries;
/// returns `null` when nothing readable is left. `&amp;` is decoded last so an
/// escaped entity like `&amp;lt;` stays literal instead of double-decoding.
String? stripHtmlText(String? text) {
  if (text == null) return null;
  String clean = text.replaceAll(_htmlTagPattern, '');
  clean = clean.replaceAllMapped(_numericEntity, (Match m) {
    final String body = m.group(1)!;
    final bool hex = body.startsWith('x') || body.startsWith('X');
    final int? code = hex
        ? int.tryParse(body.substring(1), radix: 16)
        : int.tryParse(body);
    return code == null ? m.group(0)! : String.fromCharCode(code);
  });
  clean = clean
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&hellip;', '…')
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–')
      .replaceAll('&lsquo;', '‘')
      .replaceAll('&rsquo;', '’')
      .replaceAll('&ldquo;', '“')
      .replaceAll('&rdquo;', '”')
      .replaceAll('&amp;', '&')
      .trim();
  return clean.isEmpty ? null : clean;
}
