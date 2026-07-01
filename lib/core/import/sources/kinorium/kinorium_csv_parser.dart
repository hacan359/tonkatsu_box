import 'dart:typed_data';

import 'kinorium_entry.dart';

/// Raised when a Kinorium CSV cannot be parsed (wrong encoding, missing
/// header, no recognizable columns).
class KinoriumParseException implements Exception {
  const KinoriumParseException(this.message);

  final String message;

  @override
  String toString() => 'KinoriumParseException: $message';
}

/// Parses Kinorium's emailed CSV export into [KinoriumEntry] rows.
///
/// The file is UTF-16 LE with a BOM, tab-separated, every field wrapped in
/// double quotes (`""` escapes a literal quote). Columns are addressed by
/// their header name, not position, so the watched-list and "буду смотреть"
/// layouts both parse with the same code.
class KinoriumCsvParser {
  const KinoriumCsvParser();

  static const String _titleCol = 'Title';
  static const String _originalTitleCol = 'Original Title';
  static const String _typeCol = 'Type';
  static const String _yearCol = 'Year';
  static const String _ratingCol = 'My rating';
  static const String _dateCol = 'Date';
  static const String _genresCol = 'Genres';
  static const String _actorsCol = 'Actors';
  static const String _directorsCol = 'Directors';
  static const String _noteCol = 'Note';

  List<KinoriumEntry> parseBytes(Uint8List bytes) =>
      parseString(_decode(bytes));

  /// Parses already-decoded text. Exposed for tests that work with strings.
  List<KinoriumEntry> parseString(String content) {
    final List<List<String>> rows = _splitRows(content);
    if (rows.isEmpty) {
      throw const KinoriumParseException('File is empty');
    }

    final List<String> header = rows.first;
    final Map<String, int> index = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      index[header[i].trim()] = i;
    }

    if (!index.containsKey(_titleCol) || !index.containsKey(_typeCol)) {
      throw const KinoriumParseException(
        'Not a Kinorium export: missing Title/Type columns',
      );
    }

    final List<KinoriumEntry> entries = <KinoriumEntry>[];
    for (int r = 1; r < rows.length; r++) {
      final List<String> row = rows[r];
      final String title = _cell(row, index, _titleCol);
      if (title.isEmpty) continue;

      final String rawType = _cell(row, index, _typeCol);
      entries.add(KinoriumEntry(
        title: title,
        originalTitle: _nullable(_cell(row, index, _originalTitleCol)),
        type: KinoriumType.fromRaw(rawType),
        rawType: rawType,
        year: _parseYear(_cell(row, index, _yearCol)),
        myRating: _parseRating(_cell(row, index, _ratingCol)),
        date: _parseDate(_cell(row, index, _dateCol)),
        genres: _parseGenres(_cell(row, index, _genresCol)),
        actors: _nullable(_cell(row, index, _actorsCol)),
        directors: _nullable(_cell(row, index, _directorsCol)),
        note: _nullable(_cell(row, index, _noteCol)),
      ));
    }

    return entries;
  }

  String _cell(List<String> row, Map<String, int> index, String column) {
    final int? i = index[column];
    if (i == null || i >= row.length) return '';
    return row[i].trim();
  }

  String? _nullable(String value) => value.isEmpty ? null : value;

  int? _parseYear(String value) {
    final int? year = int.tryParse(value);
    if (year == null || year <= 0) return null;
    return year;
  }

  /// Kinorium ratings use a comma decimal separator in some locales; accept
  /// both. Anything outside 1–10 is treated as "not rated".
  double? _parseRating(String value) {
    if (value.isEmpty) return null;
    final double? rating = double.tryParse(value.replaceAll(',', '.'));
    if (rating == null || rating <= 0 || rating > 10) return null;
    return rating;
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    // Format: "YYYY-MM-DD HH:MM:SS"; DateTime.parse wants a 'T' separator.
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  List<String> _parseGenres(String value) {
    if (value.isEmpty) return const <String>[];
    return value
        .split(',')
        .map((String g) => g.trim())
        .where((String g) => g.isNotEmpty)
        .toList();
  }

  /// Decodes UTF-16 LE bytes, dropping a leading BOM. `dart:convert` has no
  /// UTF-16 codec, so the code units are assembled by hand.
  String _decode(Uint8List bytes) {
    if (bytes.length < 2) {
      throw const KinoriumParseException('File is too short to be UTF-16');
    }

    int start = 0;
    bool littleEndian = true;
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      start = 2;
    } else if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      start = 2;
      littleEndian = false;
    }

    final int unitCount = (bytes.length - start) ~/ 2;
    final List<int> units = List<int>.filled(unitCount, 0);
    for (int i = 0; i < unitCount; i++) {
      final int lo = bytes[start + i * 2];
      final int hi = bytes[start + i * 2 + 1];
      units[i] = littleEndian ? (hi << 8) | lo : (lo << 8) | hi;
    }
    return String.fromCharCodes(units);
  }

  /// Splits the TSV body into rows of fields, honouring quoted fields that may
  /// contain tabs, newlines or escaped quotes (`""`).
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
      // Skip blank trailing rows produced by the final newline.
      final bool isBlank = current.length == 1 && current.first.isEmpty;
      if (!isBlank) rows.add(current);
      current = <String>[];
    }

    final int length = content.length;
    for (int i = 0; i < length; i++) {
      final String ch = content[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < length && content[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        switch (ch) {
          case '"':
            inQuotes = true;
          case '\t':
            endField();
          case '\r':
            break;
          case '\n':
            endRow();
          default:
            field.write(ch);
        }
      }
    }

    // Flush the last field/row when the file doesn't end with a newline.
    if (field.isNotEmpty || current.isNotEmpty) {
      endRow();
    }

    return rows;
  }
}
