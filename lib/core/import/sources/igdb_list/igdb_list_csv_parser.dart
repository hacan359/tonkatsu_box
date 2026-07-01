import 'dart:convert';
import 'dart:typed_data';

/// One row of an IGDB list CSV. The export has more columns, but none are
/// personal, so only the id (for the match) and name (wishlist fallback) matter.
class IgdbListEntry {
  const IgdbListEntry({required this.id, required this.name});

  final int id;
  final String name;
}

/// Raised when an IGDB list CSV cannot be parsed (missing header, no `id`
/// column, empty file).
class IgdbListParseException implements Exception {
  const IgdbListParseException(this.message);

  final String message;

  @override
  String toString() => 'IgdbListParseException: $message';
}

/// Parses IGDB's list export CSV into [IgdbListEntry] rows.
///
/// The file is UTF-8, comma-separated, RFC 4180 quoting (fields with commas or
/// newlines wrapped in double quotes, `""` escaping a literal quote). Some
/// fields hold JSON arrays (`"[""PC"", ""Switch""]"`), so quote-awareness is
/// mandatory. Columns are addressed by header name, not position.
class IgdbListCsvParser {
  const IgdbListCsvParser();

  static const String _idCol = 'id';
  static const String _nameCol = 'game';

  List<IgdbListEntry> parseBytes(Uint8List bytes) =>
      parseString(_decode(bytes));

  /// Parses already-decoded text. Exposed for tests that work with strings.
  List<IgdbListEntry> parseString(String content) {
    final List<List<String>> rows = _splitRows(content);
    if (rows.isEmpty) {
      throw const IgdbListParseException('File is empty');
    }

    final List<String> header = rows.first;
    final Map<String, int> index = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      index[header[i].trim().toLowerCase()] = i;
    }

    final int? idIndex = index[_idCol];
    if (idIndex == null) {
      throw const IgdbListParseException(
        'CSV has no "id" column — not an IGDB list export',
      );
    }
    final int? nameIndex = index[_nameCol];

    final List<IgdbListEntry> entries = <IgdbListEntry>[];
    for (int r = 1; r < rows.length; r++) {
      final List<String> row = rows[r];
      if (row.length <= idIndex) continue;

      final int? id = int.tryParse(row[idIndex].trim());
      if (id == null) continue;

      final String name = (nameIndex != null && row.length > nameIndex)
          ? row[nameIndex].trim()
          : '';
      entries.add(IgdbListEntry(id: id, name: name.isEmpty ? 'Game #$id' : name));
    }

    return entries;
  }

  List<List<String>> _splitRows(String content) {
    final List<List<String>> rows = <List<String>>[];
    List<String> current = <String>[];
    final StringBuffer field = StringBuffer();
    bool inQuotes = false;

    void endField() {
      current.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      // Skip blank lines (e.g. a trailing newline).
      final bool blank = current.length == 1 && current.first.trim().isEmpty;
      if (!blank) rows.add(current);
      current = <String>[];
    }

    for (int i = 0; i < content.length; i++) {
      final String ch = content[i];

      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < content.length && content[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
        continue;
      }

      switch (ch) {
        case '"':
          inQuotes = true;
        case ',':
          endField();
        case '\r':
          // Consume a following \n so CRLF ends exactly one row.
          if (i + 1 < content.length && content[i + 1] == '\n') i++;
          endRow();
        case '\n':
          endRow();
        default:
          field.write(ch);
      }
    }

    // Flush the last row when the file has no trailing newline.
    if (field.isNotEmpty || current.isNotEmpty) endRow();

    return rows;
  }

  String _decode(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
