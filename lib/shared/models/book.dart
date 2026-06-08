import 'dart:convert';

import 'data_source.dart';

/// Book metadata from OpenLibrary or Fantlab.
///
/// Identity mirrors [Manga]: the cache key is the pair `(id, source)`. [id] is
/// the provider numeric id stored as a string (`"27448"` / `"3104"`) and maps
/// to `collection_items.external_id` via [externalIdInt]. The provider-native
/// id (`"OL27448W"` / `"3104"`) is kept separately in [nativeId] so the full
/// OLID is never reconstructed.
class Book {
  const Book({
    required this.id,
    required this.source,
    required this.nativeId,
    required this.title,
    this.originalTitle,
    this.authors = const <String>[],
    this.description,
    this.coverUrl,
    this.pageCount,
    this.publishYear,
    this.publishers = const <String>[],
    this.isbn10,
    this.isbn13,
    this.languages = const <String>[],
    this.subjects = const <String>[],
    this.workType,
    this.series,
    this.awards = const <String>[],
    this.rating,
    this.ratingCount,
    this.externalUrl,
    this.cachedAt,
  });

  factory Book.fromDb(Map<String, dynamic> row) {
    return Book(
      id: row['id'] as String,
      source: DataSource.fromName(row['source'] as String?),
      nativeId: (row['native_id'] as String?) ?? row['id'] as String,
      title: row['title'] as String,
      originalTitle: row['original_title'] as String?,
      authors: _decodeStringList(row['authors']),
      description: row['description'] as String?,
      coverUrl: row['cover_url'] as String?,
      pageCount: row['page_count'] as int?,
      publishYear: row['publish_year'] as int?,
      publishers: _decodeStringList(row['publishers']),
      isbn10: row['isbn_10'] as String?,
      isbn13: row['isbn_13'] as String?,
      languages: _decodeStringList(row['languages']),
      subjects: _decodeStringList(row['subjects']),
      workType: row['work_type'] as String?,
      series: row['series'] as String?,
      awards: _decodeStringList(row['awards']),
      rating: (row['rating'] as num?)?.toDouble(),
      ratingCount: row['rating_count'] as int?,
      externalUrl: row['external_url'] as String?,
      cachedAt: row['cached_at'] as int?,
    );
  }

  /// Rebuilds a [Book] from a `.xcoll` / `.xcollx` payload (the output of
  /// [toExport]). The export omits `cached_at`, so it stays null here.
  factory Book.fromExport(Map<String, dynamic> json) => Book.fromDb(json);

  /// Lightweight [Book] from an OpenLibrary `search.json` `docs[]` entry. Holds
  /// only what the search grid needs; description / subjects / rating arrive
  /// when the work is opened ([Book.fromOpenLibraryWork]).
  factory Book.fromOpenLibrarySearchDoc(Map<String, dynamic> doc) {
    final String key = doc['key'] as String? ?? '';
    final (String nativeId, String id) = _olidParts(key);
    final int? coverId = (doc['cover_i'] as num?)?.toInt();
    // search.json ratings are 1–5; the app's scale is 1–10.
    final double? avg = (doc['ratings_average'] as num?)?.toDouble();
    return Book(
      id: id,
      source: DataSource.openLibrary,
      nativeId: nativeId,
      title: doc['title'] as String? ?? 'Unknown',
      authors: _stringList(doc['author_name']),
      coverUrl: coverId != null ? coverUrlFromId(coverId) : null,
      pageCount: (doc['number_of_pages_median'] as num?)?.toInt(),
      publishYear: (doc['first_publish_year'] as num?)?.toInt(),
      languages: _stringList(doc['language']),
      subjects: _cleanSubjects(_stringList(doc['subject'])),
      rating: avg != null ? avg * 2 : null,
      ratingCount: (doc['ratings_count'] as num?)?.toInt(),
      externalUrl: 'https://openlibrary.org$key',
    );
  }

  /// Full [Book] from an OpenLibrary `/works/{OLID}.json` response, optionally
  /// enriched with `/ratings.json`, resolved author names, and one edition
  /// (`/books/{OLID}.json`) for ISBNs / page count / publishers.
  factory Book.fromOpenLibraryWork(
    Map<String, dynamic> work, {
    Map<String, dynamic>? ratings,
    List<String>? authorNames,
    Map<String, dynamic>? edition,
  }) {
    final String key = work['key'] as String? ?? '';
    final (String nativeId, String id) = _olidParts(key);

    final int? coverId = _firstCoverId(work['covers']);

    double? rating;
    int? ratingCount;
    final Object? summary =
        ratings is Map<String, dynamic> ? ratings['summary'] : null;
    if (summary is Map<String, dynamic>) {
      final double? avg = (summary['average'] as num?)?.toDouble();
      // OpenLibrary ratings are 1–5; the app's scale is 1–10.
      rating = avg != null ? avg * 2 : null;
      ratingCount = (summary['count'] as num?)?.toInt();
    }

    return Book(
      id: id,
      source: DataSource.openLibrary,
      nativeId: nativeId,
      title: work['title'] as String? ?? 'Unknown',
      originalTitle: edition?['title'] as String?,
      authors: authorNames ?? const <String>[],
      description: _cleanText(_openLibraryDescription(work['description'])),
      coverUrl: coverId != null ? coverUrlFromId(coverId) : null,
      pageCount: (edition?['number_of_pages'] as num?)?.toInt(),
      publishYear: _yearFrom(edition?['publish_date'] as String?),
      publishers: _stringList(edition?['publishers']),
      isbn10: _firstString(edition?['isbn_10']),
      isbn13: _firstString(edition?['isbn_13']),
      subjects: _cleanSubjects(_stringList(work['subjects'])),
      rating: rating,
      ratingCount: ratingCount,
      externalUrl: 'https://openlibrary.org$key',
    );
  }

  /// Provider numeric id stored as a string (`"27448"` / `"3104"`). The column
  /// type is `TEXT` as headroom for a future non-numeric id, but today the
  /// content is always digits — so [externalIdInt] feeds
  /// `collection_items.external_id` (INTEGER) without loss.
  final String id;

  /// Which provider this record came from. Part of the cache identity
  /// `(id, source)` so OpenLibrary and Fantlab entries that share a numeric id
  /// never collide.
  final DataSource source;

  /// Provider-native id: `"OL27448W"` (OpenLibrary work) or `"3104"` (Fantlab).
  final String nativeId;

  final String title;

  /// Original-language title (`work_name_orig` on Fantlab, first edition title
  /// on OpenLibrary).
  final String? originalTitle;

  final List<String> authors;

  /// Plain text — BB-codes / HTML are stripped before construction.
  final String? description;

  /// Full cover URL including scheme.
  final String? coverUrl;

  final int? pageCount;
  final int? publishYear;
  final List<String> publishers;
  final String? isbn10;
  final String? isbn13;

  /// MARC language codes (`eng`, `rus`, …).
  final List<String> languages;

  /// Deduplicated genres / tags.
  final List<String> subjects;

  /// `"роман"` / `"повесть"` / null — Fantlab only.
  final String? workType;

  /// Cycle / series name — Fantlab only.
  final String? series;

  /// Award names — Fantlab only.
  final List<String> awards;

  /// Normalised to a 1.0–10.0 scale.
  final double? rating;

  final int? ratingCount;

  /// Full URL to the source page.
  final String? externalUrl;

  /// Unix timestamp of when this row was cached; null on fresh / export data.
  final int? cachedAt;

  /// Integer key for `collection_items.external_id` (INTEGER).
  int get externalIdInt => int.parse(id);

  String? get formattedRating => rating?.toStringAsFixed(1);

  int? get releaseYear => publishYear;

  String? get authorsString => authors.isEmpty ? null : authors.join(', ');

  String? get subjectsString => subjects.isEmpty ? null : subjects.join(', ');

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'source': source.name,
      'native_id': nativeId,
      'title': title,
      'original_title': originalTitle,
      'authors': authors.isEmpty ? null : jsonEncode(authors),
      'description': description,
      'cover_url': coverUrl,
      'page_count': pageCount,
      'publish_year': publishYear,
      'publishers': publishers.isEmpty ? null : jsonEncode(publishers),
      'isbn_10': isbn10,
      'isbn_13': isbn13,
      'languages': languages.isEmpty ? null : jsonEncode(languages),
      'subjects': subjects.isEmpty ? null : jsonEncode(subjects),
      'work_type': workType,
      'series': series,
      'awards': awards.isEmpty ? null : jsonEncode(awards),
      'rating': rating,
      'rating_count': ratingCount,
      'external_url': externalUrl,
      'cached_at': cachedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// `toDb` minus the cache timestamp, for `.xcoll` / `.xcollx` payloads.
  Map<String, dynamic> toExport() {
    final Map<String, dynamic> data = toDb();
    data.remove('cached_at');
    return data;
  }

  Book copyWith({
    String? id,
    DataSource? source,
    String? nativeId,
    String? title,
    String? originalTitle,
    List<String>? authors,
    String? description,
    String? coverUrl,
    int? pageCount,
    int? publishYear,
    List<String>? publishers,
    String? isbn10,
    String? isbn13,
    List<String>? languages,
    List<String>? subjects,
    String? workType,
    String? series,
    List<String>? awards,
    double? rating,
    int? ratingCount,
    String? externalUrl,
    int? cachedAt,
  }) {
    return Book(
      id: id ?? this.id,
      source: source ?? this.source,
      nativeId: nativeId ?? this.nativeId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      pageCount: pageCount ?? this.pageCount,
      publishYear: publishYear ?? this.publishYear,
      publishers: publishers ?? this.publishers,
      isbn10: isbn10 ?? this.isbn10,
      isbn13: isbn13 ?? this.isbn13,
      languages: languages ?? this.languages,
      subjects: subjects ?? this.subjects,
      workType: workType ?? this.workType,
      series: series ?? this.series,
      awards: awards ?? this.awards,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      externalUrl: externalUrl ?? this.externalUrl,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  /// Overlays the richer fields a full work fetch adds (description, original
  /// title, cleaned subjects) onto a lightweight search-result book, keeping
  /// the search row's year / pages / languages / rating.
  Book withWorkDetails(Book full) => copyWith(
        description: full.description,
        originalTitle: full.originalTitle,
        subjects: full.subjects.isNotEmpty ? full.subjects : subjects,
        rating: rating ?? full.rating,
        ratingCount: ratingCount ?? full.ratingCount,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id && other.source == source;
  }

  @override
  int get hashCode => Object.hash(id, source);

  @override
  String toString() => 'Book(id: $id, source: ${source.name}, title: $title)';

  /// Decodes a JSON-array column into a list, tolerating null / malformed data.
  static List<String> _decodeStringList(Object? value) {
    if (value is! String || value.isEmpty) return const <String>[];
    try {
      final Object? decoded = jsonDecode(value);
      if (decoded is List<dynamic>) {
        return decoded.whereType<String>().toList();
      }
    } on FormatException {
      return const <String>[];
    }
    return const <String>[];
  }

  /// `-L` (large) cover URL for an OpenLibrary cover id. Redirects (302) to the
  /// CDN; Dio follows redirects by default.
  static String coverUrlFromId(int id) =>
      'https://covers.openlibrary.org/b/id/$id-L.jpg';

  /// `-L` cover URL by ISBN — fallback when a work has no cover id.
  static String coverUrlFromIsbn(String isbn) =>
      'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';

  /// Splits an OLID key (`/works/OL27448W`) into the native id (`OL27448W`) and
  /// the numeric id stored in [id] (`27448`). Falls back to the native id when
  /// it carries no digits.
  static (String nativeId, String id) _olidParts(String key) {
    final String nativeId =
        key.contains('/') ? key.substring(key.lastIndexOf('/') + 1) : key;
    final RegExpMatch? digits = RegExp(r'\d+').firstMatch(nativeId);
    return (nativeId, digits?.group(0) ?? nativeId);
  }

  /// First valid (positive, non-null) cover id from a work's `covers` array.
  static int? _firstCoverId(Object? covers) {
    if (covers is! List<dynamic>) return null;
    for (final Object? c in covers) {
      if (c is num && c > 0) return c.toInt();
    }
    return null;
  }

  /// OpenLibrary descriptions come as a plain string or a typed-text object
  /// `{type, value}`.
  static String? _openLibraryDescription(Object? desc) {
    if (desc is String) return desc;
    if (desc is Map<String, dynamic>) return desc['value'] as String?;
    return null;
  }

  /// Coerces a JSON array (or single value) to a `List<String>`.
  static List<String> _stringList(Object? value) {
    if (value is List<dynamic>) {
      return value.whereType<String>().where((String s) => s.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) return <String>[value];
    return const <String>[];
  }

  static String? _firstString(Object? value) {
    final List<String> list = _stringList(value);
    return list.isEmpty ? null : list.first;
  }

  /// Case-insensitive dedupe preserving first-seen order.
  static List<String> _dedupe(List<String> values) {
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final String v in values) {
      if (seen.add(v.toLowerCase())) out.add(v);
    }
    return out;
  }

  // OpenLibrary `subject` mixes real subjects with machine markers
  // (`award:hugo_award=1966`, `nyt:...=...`). Drop anything with a `:` or `=`,
  // dedupe, and cap so a card / sheet isn't buried in tags.
  static const int _maxSubjects = 15;

  static List<String> _cleanSubjects(List<String> values) {
    final List<String> human = values
        .where((String s) => !s.contains(':') && !s.contains('='))
        .toList();
    final List<String> deduped = _dedupe(human);
    return deduped.length > _maxSubjects
        ? deduped.sublist(0, _maxSubjects)
        : deduped;
  }

  /// Extracts a 4-digit year from a free-form date (`"1954"`, `"March 1954"`,
  /// `"cop. 1954"`).
  static int? _yearFrom(String? raw) {
    if (raw == null) return null;
    final RegExpMatch? m = RegExp(r'\b(\d{4})\b').firstMatch(raw);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  static final RegExp _htmlTagPattern = RegExp('<[^>]*>');

  static String? _cleanText(String? text) {
    if (text == null) return null;
    final String clean = text.replaceAll(_htmlTagPattern, '').trim();
    return clean.isEmpty ? null : clean;
  }
}
