import 'dart:convert';
import 'dart:typed_data';

import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/utils/media_format.dart';
import 'custom_card_entry.dart';

/// Parses a user-supplied JSON or CSV file into custom-card rows.
///
/// JSON: an array of objects (or one object = one card). Keys starting with
/// `_` and unknown keys are ignored, so the downloadable template with its
/// `_..._values` hint keys imports cleanly. CSV: UTF-8, comma-separated,
/// RFC 4180 quoting; columns addressed by header name, unknown columns
/// ignored. Rows are validated individually — a bad row becomes a
/// [CustomCardRow] with issues, never a whole-file failure.
class CustomCardsParser {
  const CustomCardsParser();

  static const int _yearMin = 1000;
  static const int _yearMax = 9999;
  static const double _ratingMax = 10;

  /// Parses [bytes], picking the format from [fileName]'s extension and
  /// falling back to content sniffing (`{`/`[` first → JSON, else CSV).
  List<CustomCardRow> parseBytes(Uint8List bytes, {String? fileName}) {
    final String content = _decode(bytes);
    if (content.trim().isEmpty) {
      throw const CustomCardsParseException(CustomCardsParseErrorCode.emptyFile);
    }
    final String lowerName = fileName?.toLowerCase() ?? '';
    if (lowerName.endsWith('.json')) return parseJson(content);
    if (lowerName.endsWith('.csv')) return parseCsv(content);
    final String first = content.trimLeft()[0];
    return (first == '{' || first == '[')
        ? parseJson(content)
        : parseCsv(content);
  }

  /// Parses JSON text: an array of card objects or a single card object.
  List<CustomCardRow> parseJson(String content) {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const CustomCardsParseException(
        CustomCardsParseErrorCode.invalidJson,
      );
    }

    final List<Object?> elements = switch (decoded) {
      final List<Object?> list => list,
      final Map<String, dynamic> single => <Object?>[single],
      _ => throw const CustomCardsParseException(
          CustomCardsParseErrorCode.invalidJson,
        ),
    };
    if (elements.isEmpty) {
      throw const CustomCardsParseException(CustomCardsParseErrorCode.emptyFile);
    }

    final List<CustomCardRow> rows = <CustomCardRow>[];
    for (int i = 0; i < elements.length; i++) {
      final Object? element = elements[i];
      if (element is! Map<String, dynamic>) {
        rows.add(CustomCardRow(
          index: i + 1,
          issues: const <CustomCardIssue>[
            CustomCardIssue(CustomCardIssueCode.notAnObject),
          ],
        ));
        continue;
      }
      rows.add(_validate(element, i + 1));
    }
    return rows;
  }

  /// Parses CSV text; the header must contain `title` and `type` columns.
  List<CustomCardRow> parseCsv(String content) {
    final List<List<String>> lines = _splitRows(content);
    if (lines.isEmpty) {
      throw const CustomCardsParseException(CustomCardsParseErrorCode.emptyFile);
    }

    final Map<String, int> index = <String, int>{};
    final List<String> header = lines.first;
    for (int i = 0; i < header.length; i++) {
      index[header[i].trim().toLowerCase()] = i;
    }
    if (!index.containsKey(CustomCardFields.title) ||
        !index.containsKey(CustomCardFields.type)) {
      throw const CustomCardsParseException(
        CustomCardsParseErrorCode.missingRequiredColumns,
      );
    }
    if (lines.length == 1) {
      throw const CustomCardsParseException(CustomCardsParseErrorCode.emptyFile);
    }

    final List<CustomCardRow> rows = <CustomCardRow>[];
    for (int r = 1; r < lines.length; r++) {
      final List<String> line = lines[r];
      final Map<String, dynamic> raw = <String, dynamic>{};
      for (final MapEntry<String, int> column in index.entries) {
        if (line.length > column.value) {
          raw[column.key] = line[column.value];
        }
      }
      rows.add(_validate(raw, r));
    }
    return rows;
  }

  CustomCardRow _validate(Map<String, dynamic> raw, int index) {
    final List<CustomCardIssue> issues = <CustomCardIssue>[];

    final String? title = _string(raw, CustomCardFields.title);
    if (title == null) {
      issues.add(const CustomCardIssue(CustomCardIssueCode.missingTitle));
    }

    MediaType? type;
    final String? typeText = _string(raw, CustomCardFields.type);
    if (typeText == null) {
      issues.add(const CustomCardIssue(CustomCardIssueCode.missingType));
    } else {
      type = _byValue(
        CustomCardFields.allowedTypes,
        typeText,
        (MediaType t) => t.value,
      );
      if (type == null) {
        issues.add(CustomCardIssue(
          CustomCardIssueCode.unknownType,
          field: CustomCardFields.type,
          value: typeText,
        ));
      }
    }

    final int? year = _intInRange(
      raw,
      CustomCardFields.year,
      issues,
      min: _yearMin,
      max: _yearMax,
    );
    final int? unitTotal =
        _intInRange(raw, CustomCardFields.unitTotal, issues, min: 1);
    final int? unitGroupTotal =
        _intInRange(raw, CustomCardFields.unitGroupTotal, issues, min: 1);
    final int? rewatchCount =
        _intInRange(raw, CustomCardFields.rewatchCount, issues, min: 0);

    double? rating;
    final String? ratingText = _string(raw, CustomCardFields.rating);
    if (ratingText != null) {
      rating = double.tryParse(ratingText.replaceAll(',', '.'));
      if (rating == null || rating < 0 || rating > _ratingMax) {
        issues.add(CustomCardIssue(
          CustomCardIssueCode.invalidNumber,
          field: CustomCardFields.rating,
          value: ratingText,
        ));
        rating = null;
      }
    }

    ItemStatus? status;
    final String? statusText = _string(raw, CustomCardFields.status);
    if (statusText != null) {
      status = _byValue(
        ItemStatus.values,
        statusText,
        (ItemStatus s) => s.value,
      );
      if (status == null) {
        issues.add(CustomCardIssue(
          CustomCardIssueCode.unknownStatus,
          field: CustomCardFields.status,
          value: statusText,
        ));
      }
    }

    final DateTime? startedAt =
        _date(raw, CustomCardFields.startedAt, issues);
    final DateTime? completedAt =
        _date(raw, CustomCardFields.completedAt, issues);
    final int? timeSpentMinutes =
        _intInRange(raw, CustomCardFields.timeSpentMinutes, issues, min: 0);
    final int? currentEpisode =
        _intInRange(raw, CustomCardFields.currentEpisode, issues, min: 0);
    final int? currentSeason =
        _intInRange(raw, CustomCardFields.currentSeason, issues, min: 0);
    final bool? favorite = _bool(raw, CustomCardFields.favorite, issues);

    String? format;
    final String? formatText = _string(raw, CustomCardFields.format);
    if (formatText != null) {
      final String normalized = formatText.toUpperCase();
      if (type == MediaType.manga || type == MediaType.anime) {
        final List<String> allowed = type == MediaType.manga
            ? MediaFormat.mangaOrder
            : MediaFormat.animeOrder;
        if (allowed.contains(normalized)) {
          format = normalized;
        } else {
          issues.add(CustomCardIssue(
            CustomCardIssueCode.unknownFormat,
            field: CustomCardFields.format,
            value: formatText,
          ));
        }
      } else if (type != null) {
        issues.add(CustomCardIssue(
          CustomCardIssueCode.formatNotApplicable,
          field: CustomCardFields.format,
          value: formatText,
        ));
      }
    }

    String? cover = _string(raw, CustomCardFields.cover);
    if (cover != null) {
      final String lower = cover.toLowerCase();
      if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
        issues.add(CustomCardIssue(
          CustomCardIssueCode.invalidCoverUrl,
          field: CustomCardFields.cover,
          value: cover,
        ));
        cover = null;
      }
    }

    final bool hasBlocking = title == null ||
        type == null ||
        issues.any((CustomCardIssue i) => i.code.isBlocking);
    if (hasBlocking) {
      return CustomCardRow(index: index, issues: issues, sourceTitle: title);
    }

    return CustomCardRow(
      index: index,
      issues: issues,
      sourceTitle: title,
      entry: CustomCardEntry(
        title: title,
        type: type,
        altTitle: _string(raw, CustomCardFields.altTitle),
        description: _string(raw, CustomCardFields.description),
        year: year,
        genres: _string(raw, CustomCardFields.genres),
        link: _string(raw, CustomCardFields.link),
        coverUrl: cover,
        platform: _string(raw, CustomCardFields.platform),
        format: format,
        unitTotal: unitTotal,
        unitGroupTotal: unitGroupTotal,
        status: status,
        rating: rating,
        comment: _string(raw, CustomCardFields.comment),
        rewatchCount: rewatchCount,
        startedAt: startedAt,
        completedAt: completedAt,
        timeSpentMinutes: timeSpentMinutes,
        favorite: favorite,
        currentEpisode: currentEpisode,
        currentSeason: currentSeason,
        tags: _tags(raw),
      ),
    );
  }

  /// Case-insensitive lookup of an enum-like [values] entry by its stored
  /// [value] string.
  T? _byValue<T>(
    Iterable<T> values,
    String text,
    String Function(T) value,
  ) {
    final String normalized = text.trim().toLowerCase();
    for (final T candidate in values) {
      if (value(candidate) == normalized) return candidate;
    }
    return null;
  }

  DateTime? _date(
    Map<String, dynamic> raw,
    String key,
    List<CustomCardIssue> issues,
  ) {
    final String? text = _string(raw, key);
    if (text == null) return null;
    final DateTime? parsed = DateTime.tryParse(text);
    if (parsed == null) {
      issues.add(CustomCardIssue(
        CustomCardIssueCode.invalidDate,
        field: key,
        value: text,
      ));
    }
    return parsed;
  }

  bool? _bool(
    Map<String, dynamic> raw,
    String key,
    List<CustomCardIssue> issues,
  ) {
    final Object? value = raw[key];
    if (value is bool) return value;
    final String? text = _string(raw, key);
    if (text == null) return null;
    switch (text.toLowerCase()) {
      case 'true' || '1' || 'yes':
        return true;
      case 'false' || '0' || 'no':
        return false;
    }
    issues.add(CustomCardIssue(
      CustomCardIssueCode.invalidBool,
      field: key,
      value: text,
    ));
    return null;
  }

  /// Comma-separated tag names, trimmed and deduped case-insensitively
  /// (first spelling wins). JSON may also pass a native string array.
  List<String> _tags(Map<String, dynamic> raw) {
    final Object? value = raw[CustomCardFields.tags];
    final List<String> parts;
    if (value is List<Object?>) {
      parts = <String>[for (final Object? v in value) if (v != null) '$v'];
    } else {
      final String? text = _string(raw, CustomCardFields.tags);
      if (text == null) return const <String>[];
      parts = text.split(',');
    }
    final Set<String> seen = <String>{};
    final List<String> tags = <String>[];
    for (final String part in parts) {
      final String name = part.trim();
      if (name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) tags.add(name);
    }
    return tags;
  }

  /// Trimmed string value of [key]; empty and null collapse to null. Non-string
  /// JSON scalars (numbers) are stringified so `"year": 1995` works.
  String? _string(Map<String, dynamic> raw, String key) {
    final Object? value = raw[key];
    if (value == null) return null;
    final String text = value is String ? value.trim() : value.toString();
    return text.isEmpty ? null : text;
  }

  int? _intInRange(
    Map<String, dynamic> raw,
    String key,
    List<CustomCardIssue> issues, {
    int? min,
    int? max,
  }) {
    final Object? value = raw[key];
    if (value is int) {
      if ((min != null && value < min) || (max != null && value > max)) {
        issues.add(CustomCardIssue(
          CustomCardIssueCode.invalidNumber,
          field: key,
          value: '$value',
        ));
        return null;
      }
      return value;
    }
    final String? text = _string(raw, key);
    if (text == null) return null;
    final int? parsed = int.tryParse(text);
    if (parsed == null ||
        (min != null && parsed < min) ||
        (max != null && parsed > max)) {
      issues.add(CustomCardIssue(
        CustomCardIssueCode.invalidNumber,
        field: key,
        value: text,
      ));
      return null;
    }
    return parsed;
  }

  /// RFC 4180 row splitter: quoted fields may hold commas, newlines and `""`
  /// escaped quotes; blank lines are skipped.
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
      final bool blank = current.length == 1 && current.first.trim().isEmpty;
      if (!blank) rows.add(current);
      current = <String>[];
    }

    // Code units, not String indexing: files run to thousands of rows and a
    // per-character String allocation would drag the UI isolate.
    const int quote = 0x22, comma = 0x2C, cr = 0x0D, lf = 0x0A;
    for (int i = 0; i < content.length; i++) {
      final int ch = content.codeUnitAt(i);

      if (inQuotes) {
        if (ch == quote) {
          if (i + 1 < content.length && content.codeUnitAt(i + 1) == quote) {
            field.writeCharCode(quote);
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.writeCharCode(ch);
        }
        continue;
      }

      switch (ch) {
        case quote:
          inQuotes = true;
        case comma:
          endField();
        case cr:
          // Consume a following \n so CRLF ends exactly one row.
          if (i + 1 < content.length && content.codeUnitAt(i + 1) == lf) i++;
          endRow();
        case lf:
          endRow();
        default:
          field.writeCharCode(ch);
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
