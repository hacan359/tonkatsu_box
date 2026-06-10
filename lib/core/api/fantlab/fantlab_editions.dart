import '../../../shared/utils/bbcode.dart';

/// One Fantlab edition (`издание`) of a work, built from `/work/{id}/extended`
/// `editions_blocks`. Transient — used only to pick a cover / metadata for a
/// [Book]; never persisted.
class FantlabEdition {
  const FantlabEdition({
    required this.editionId,
    required this.name,
    required this.hasCover,
    this.year,
    this.langCode,
    this.langName,
    this.publisher,
    this.pages,
    this.isbn,
  });

  final int editionId;
  final String name;

  /// `pic_num > 0` — the cover URL resolves to a real scan. Otherwise the URL
  /// returns Fantlab's SVG "no cover" placeholder (HTTP 200, not a 404).
  final bool hasCover;

  final int? year;
  final String? langCode;
  final String? langName;
  final String? publisher;
  final int? pages;
  final String? isbn;

  /// Tiny cover thumbnail (60×94, ~7 KB). Too blurry for the picker — use
  /// [coverUrl] there — but handy where a minimal preview is enough.
  String get coverThumbUrl =>
      'https://fantlab.ru/images/editions/small/$editionId';

  /// Full cover (200×316, the largest Fantlab serves). Shown in the picker and
  /// applied to the book when this edition is chosen.
  String get coverUrl => 'https://fantlab.ru/images/editions/big/$editionId';
}

/// A named group of editions — a Fantlab `editions_blocks` entry (Издания,
/// Периодика, Самиздат, Аудиокниги, Электронные, Иностранные).
class FantlabEditionBlock {
  const FantlabEditionBlock({required this.title, required this.editions});

  final String title;
  final List<FantlabEdition> editions;
}

/// Parses a `/work/{id}/extended` `editions_blocks` map into ordered blocks.
/// Within each block, editions with a real cover come first. Tolerant to
/// Fantlab's loose typing; malformed or coverless-id entries are skipped.
List<FantlabEditionBlock> parseFantlabEditionBlocks(Object? blocks) {
  if (blocks is! Map<String, dynamic>) return const <FantlabEditionBlock>[];
  final List<FantlabEditionBlock> out = <FantlabEditionBlock>[];
  for (final Object? block in blocks.values) {
    if (block is! Map<String, dynamic>) continue;
    final Object? list = block['list'];
    if (list is! List<dynamic>) continue;

    final List<FantlabEdition> editions = <FantlabEdition>[];
    for (final Map<String, dynamic> ed
        in list.whereType<Map<String, dynamic>>()) {
      final int? id = _int(ed['edition_id']);
      if (id == null || id <= 0) continue;
      editions.add(FantlabEdition(
        editionId: id,
        name: _str(ed['name']) ?? '',
        hasCover: (_int(ed['pic_num']) ?? 0) > 0,
        year: _positiveYear(ed['year']),
        langCode: _str(ed['lang_code']),
        langName: _str(ed['lang']),
        publisher: _publisher(ed['publisher']),
        pages: _int(ed['pages']),
        isbn: _isbn(ed['isbn']),
      ));
    }
    if (editions.isEmpty) continue;

    // Covers first; stable otherwise so the API's chronological order survives.
    editions.sort((FantlabEdition a, FantlabEdition b) {
      if (a.hasCover == b.hasCover) return 0;
      return a.hasCover ? -1 : 1;
    });
    out.add(FantlabEditionBlock(
      title: _str(block['title']) ?? '',
      editions: editions,
    ));
  }
  return out;
}

int? _int(Object? raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

String? _str(Object? raw) {
  if (raw is! String) return null;
  final String trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _positiveYear(Object? raw) {
  final int? year = _int(raw);
  return (year != null && year > 0) ? year : null;
}

String? _publisher(Object? raw) {
  final String? value = _str(raw);
  if (value == null) return null;
  final String clean = stripBbCodes(value);
  return clean.isEmpty ? null : clean;
}

String? _isbn(Object? raw) {
  final String? value = _str(raw);
  if (value == null) return null;
  final String clean = value.replaceAll('-', '').replaceAll(' ', '');
  return clean.isEmpty ? null : clean;
}
