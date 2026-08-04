import 'dart:convert';

import '../utils/bbcode.dart';
import '../utils/stable_id.dart';
import 'book_kind.dart';
import 'data_source.dart';

export '../utils/stable_id.dart' show fnv1a64;

/// Identity mirrors [Manga]: cache key is `(id, source)`. [id] holds the
/// provider's numeric id; its native form (`OL27448W`) stays in [nativeId].
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
    this.kind = BookKind.book,
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
      kind: BookKind.fromName(row['kind'] as String?),
    );
  }

  /// Rebuilds a [Book] from a `.xcoll` / `.xcollx` payload (the output of
  /// [toExport]). The export omits `cached_at`, so it stays null here.
  factory Book.fromExport(Map<String, dynamic> json) => Book.fromDb(json);

  /// Search-grid subset; description / subjects / rating arrive later via
  /// [Book.fromOpenLibraryWork].
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

  /// Full work, optionally enriched with ratings, resolved author names and
  /// one edition for ISBNs / page count / publishers.
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

  /// Search-grid subset; description / subjects / series / awards arrive later
  /// via [Book.fromFantlabWork].
  factory Book.fromFantlabSearchMatch(Map<String, dynamic> match) {
    final String id = _fantlabId(match['work_id']);
    final String rus = _trimmed(match['rusname']);
    final String orig = _trimmed(match['name']);
    final String title =
        rus.isNotEmpty ? rus : (orig.isNotEmpty ? orig : 'Unknown');
    final int coverEdition = _fantlabCoverEdition(match);

    return Book(
      id: id,
      source: DataSource.fantlab,
      nativeId: id,
      title: title,
      originalTitle: orig.isNotEmpty && orig != title ? orig : null,
      authors: _fantlabSearchAuthors(match),
      coverUrl:
          coverEdition > 0 ? _fantlabCoverUrlFromEdition(coverEdition) : null,
      publishYear: _positiveYear(match['year']),
      workType: _nonEmpty(match['name_show_im']),
      // Fantlab ratings are already on a 1–10 scale. `midmark_by_weight`
      // matches the value the work page shows as its primary rating.
      rating: _fantlabRating(match['midmark_by_weight']) ??
          _fantlabRating(match['midmark']) ??
          _fantlabRating(match['rating']),
      ratingCount: _intOrNull(match['markcount']),
      externalUrl: _fantlabWorkUrl(id),
    );
  }

  /// Reads `/work/{id}/extended`. [extended] may arrive separately when the
  /// rich blocks come from a second call.
  factory Book.fromFantlabWork(
    Map<String, dynamic> work, {
    Map<String, dynamic>? extended,
  }) {
    final Map<String, dynamic> rich = extended ?? work;
    final String id = _fantlabId(work['work_id']);
    final String rus = _trimmed(work['work_name']);
    final String orig = _trimmed(work['work_name_orig']);
    final String title =
        rus.isNotEmpty ? rus : (orig.isNotEmpty ? orig : 'Unknown');
    final ({int? pages, String? isbn, int? editionId}) edition =
        _fantlabFirstEdition(rich['editions_blocks']);
    final Object? ratingObj = work['rating'];

    return Book(
      id: id,
      source: DataSource.fantlab,
      nativeId: id,
      title: title,
      originalTitle: orig.isNotEmpty && orig != title ? orig : null,
      authors: _fantlabWorkAuthors(work['authors']),
      description: _stripFantlabText(work['work_description']),
      // The work's own `image` is often null; fall back to the cover of its
      // first edition.
      coverUrl: _fantlabCoverUrl(work['image']) ??
          (edition.editionId != null
              ? _fantlabCoverUrlFromEdition(edition.editionId!)
              : null),
      pageCount: edition.pages,
      publishYear: _positiveYear(work['work_year']),
      isbn10: edition.isbn != null && edition.isbn!.length == 10
          ? edition.isbn
          : null,
      isbn13: edition.isbn != null && edition.isbn!.length == 13
          ? edition.isbn
          : null,
      languages: _fantlabLanguages(work['lang_code']),
      subjects: _fantlabClassificatory(rich['classificatory']),
      workType: _nonEmpty(work['work_type']),
      series: _fantlabSeries(rich['parents']),
      awards: _fantlabAwards(rich['awards']),
      rating: _fantlabRating(_fantlabRatingValue(ratingObj)),
      ratingCount:
          _intOrNull(work['val_voters']) ?? _fantlabRatingVoters(ratingObj),
      externalUrl: _fantlabWorkUrl(id),
    );
  }

  /// The `similars` payload has its own shape (`creators.authors`,
  /// `stat.rating`, `saga`), distinct from `/work/{id}`.
  factory Book.fromFantlabSimilar(Map<String, dynamic> entry) {
    final String id = _fantlabId(entry['id']);
    final String rus = _trimmed(entry['name']);
    final String orig = _trimmed(entry['name_orig']);
    final String title =
        rus.isNotEmpty ? rus : (orig.isNotEmpty ? orig : 'Unknown');
    final Object? creators = entry['creators'];
    final Object? authors =
        creators is Map<String, dynamic> ? creators['authors'] : null;
    final Object? stat = entry['stat'];
    final Object? saga = entry['saga'];

    return Book(
      id: id,
      source: DataSource.fantlab,
      nativeId: id,
      title: title,
      originalTitle: orig.isNotEmpty && orig != title ? orig : null,
      authors: _fantlabWorkAuthors(authors),
      description: _stripFantlabText(entry['description']),
      coverUrl: _fantlabCoverUrl(entry['image']),
      publishYear: _positiveYear(entry['year']),
      workType: _nonEmpty(entry['name_type']),
      series:
          saga is Map<String, dynamic> ? _nonEmpty(saga['name']) : null,
      rating: stat is Map<String, dynamic>
          ? _fantlabRating(stat['rating'])
          : null,
      ratingCount:
          stat is Map<String, dynamic> ? _intOrNull(stat['voters']) : null,
      externalUrl: _fantlabWorkUrl(id),
    );
  }

  /// Shared by ComicVine `/search` rows and `/volume/{id}`. `count_of_issues`
  /// lands in [pageCount] — issues, not pages; `characters` stands in for genres.
  factory Book.fromComicVineVolume(Map<String, dynamic> json) {
    final int numericId = _intOrNull(json['id']) ?? 0;
    final String id = numericId.toString();
    final Object? publisher = json['publisher'];
    final String? publisherName = publisher is Map<String, dynamic>
        ? _nonEmpty(publisher['name'])
        : null;
    // `description` is full HTML; `deck` is a short plain-text blurb fallback.
    final String? rawDescription =
        (json['description'] ?? json['deck']) as String?;

    return Book(
      id: id,
      source: DataSource.comicVine,
      nativeId: '4050-$id',
      title: _nonEmpty(json['name']) ?? 'Unknown',
      authors: _comicVineNames(json['people'], max: _comicVineMaxPeople),
      description: _stripHtmlText(rawDescription),
      coverUrl: _comicVineCover(json['image']),
      subjects: _comicVineNames(json['characters'], max: _comicVineMaxCharacters),
      pageCount: _intOrNull(json['count_of_issues']),
      publishYear: _yearFrom(json['start_year'] as String?),
      publishers:
          publisherName != null ? <String>[publisherName] : const <String>[],
      externalUrl: _nonEmpty(json['site_detail_url']),
      kind: BookKind.comic,
    );
  }

  /// Google's volume id is alphanumeric, so [id] is an [fnv1a64] hash of it to
  /// keep the `external_id: int` contract; the real id lives in [nativeId].
  factory Book.fromGoogleBooksVolume(Map<String, dynamic> json) {
    final String volumeId = _trimmed(json['id']);
    final Object? infoObj = json['volumeInfo'];
    final Map<String, dynamic> info =
        infoObj is Map<String, dynamic> ? infoObj : const <String, dynamic>{};

    final String title = _nonEmpty(info['title']) ?? 'Unknown';
    final String? subtitle = _nonEmpty(info['subtitle']);
    final (String? isbn10, String? isbn13) =
        _googleIsbns(info['industryIdentifiers']);
    final double? avg = (info['averageRating'] as num?)?.toDouble();
    final String? language = _nonEmpty(info['language']);
    final String? publisher = _nonEmpty(info['publisher']);
    // Catalog-only search rows report 0, with the real count only in the volume
    // detail — treat 0 as unknown so the UI omits it instead of "0 pages".
    final int? pageCount = _intOrNull(info['pageCount']);

    return Book(
      id: fnv1a64(volumeId).toString(),
      source: DataSource.googleBooks,
      nativeId: volumeId,
      title: subtitle != null ? '$title: $subtitle' : title,
      authors: _stringList(info['authors']),
      description: _stripHtmlText(info['description']),
      coverUrl: _googleCover(info['imageLinks']),
      pageCount: (pageCount != null && pageCount > 0) ? pageCount : null,
      publishYear: _yearFrom(info['publishedDate'] as String?),
      publishers:
          publisher != null ? <String>[publisher] : const <String>[],
      isbn10: isbn10,
      isbn13: isbn13,
      languages: language != null ? <String>[language] : const <String>[],
      subjects: _cleanSubjects(_stringList(info['categories'])),
      rating: avg != null && avg > 0 ? avg * 2 : null,
      ratingCount: _intOrNull(info['ratingsCount']),
      externalUrl: _nonEmpty(info['infoLink']) ??
          _nonEmpty(info['canonicalVolumeLink']),
    );
  }

  /// The Typesense document already carries the whole card, so search results
  /// need no detail follow-up. `rating` (0–5) is doubled to the app's 0–10.
  factory Book.fromHardcoverDocument(Map<String, dynamic> doc) {
    final String id = _hardcoverId(doc['id']);
    final String title = _nonEmpty(doc['title']) ?? 'Unknown';
    final String? subtitle = _nonEmpty(doc['subtitle']);
    final (String? isbn10, String? isbn13) = _hardcoverIsbns(doc['isbns']);
    final int? pages = _intOrNull(doc['pages']);
    final Object? image = doc['image'];

    return Book(
      id: id,
      source: DataSource.hardcover,
      nativeId: id,
      title: subtitle != null ? '$title: $subtitle' : title,
      authors: _stringList(doc['author_names']),
      description: _stripHtmlText(doc['description']),
      coverUrl:
          image is Map<String, dynamic> ? _nonEmpty(image['url']) : null,
      pageCount: (pages != null && pages > 0) ? pages : null,
      publishYear: _intOrNull(doc['release_year']),
      isbn10: isbn10,
      isbn13: isbn13,
      subjects: _cleanSubjects(<String>[
        ..._stringList(doc['genres']),
        ..._stringList(doc['moods']),
      ]),
      series: _hardcoverDocumentSeries(doc),
      rating: _hardcoverRating(doc['rating']),
      ratingCount: _intOrNull(doc['ratings_count']),
      externalUrl: _hardcoverBookUrl(id),
      kind: _hardcoverKind(doc['book_category_id']),
    );
  }

  /// Shared by `books_by_pk` and the `book` nested in `user_books` import rows,
  /// which simply lacks `default_physical_edition`.
  factory Book.fromHardcoverBook(Map<String, dynamic> json) {
    final String id = _hardcoverId(json['id']);
    final String title = _nonEmpty(json['title']) ?? 'Unknown';
    final String? subtitle = _nonEmpty(json['subtitle']);
    final int? pages = _intOrNull(json['pages']);
    final Object? image = json['image'];

    final Object? editionObj = json['default_physical_edition'];
    final Map<String, dynamic> edition = editionObj is Map<String, dynamic>
        ? editionObj
        : const <String, dynamic>{};
    final Object? publisher = edition['publisher'];
    final String? publisherName = publisher is Map<String, dynamic>
        ? _nonEmpty(publisher['name'])
        : null;
    final Object? language = edition['language'];
    final String? languageCode = language is Map<String, dynamic>
        ? _nonEmpty(language['code2'])
        : null;

    return Book(
      id: id,
      source: DataSource.hardcover,
      nativeId: id,
      title: subtitle != null ? '$title: $subtitle' : title,
      authors: _hardcoverAuthors(json['contributions']),
      description: _stripHtmlText(json['description']),
      coverUrl:
          image is Map<String, dynamic> ? _nonEmpty(image['url']) : null,
      pageCount: (pages != null && pages > 0) ? pages : null,
      publishYear: _intOrNull(json['release_year']),
      publishers:
          publisherName != null ? <String>[publisherName] : const <String>[],
      isbn10: _nonEmpty(edition['isbn_10']),
      isbn13: _nonEmpty(edition['isbn_13']),
      languages:
          languageCode != null ? <String>[languageCode] : const <String>[],
      subjects: _hardcoverCachedTags(json['cached_tags']),
      series: _hardcoverSeries(json['book_series']),
      rating: _hardcoverRating(json['rating']),
      ratingCount: _intOrNull(json['ratings_count']),
      externalUrl: _hardcoverBookUrl(id),
      kind: _hardcoverKind(json['book_category_id']),
    );
  }

  /// `TEXT` as headroom for a future non-numeric id, but always digits today —
  /// so [externalIdInt] feeds the INTEGER `external_id` without loss.
  final String id;

  /// Part of the cache identity `(id, source)` so OpenLibrary and Fantlab
  /// entries sharing a numeric id never collide.
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

  /// Fantlab-only form token, verbatim from the API: `роман`, `повесть`, null.
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

  /// Prose book vs. comic / graphic novel. Lets ComicVine volumes share the
  /// `book` media type while staying separable.
  final BookKind kind;

  /// Integer key for `collection_items.external_id` (INTEGER).
  int get externalIdInt => int.parse(id);

  String? get formattedRating => rating?.toStringAsFixed(1);

  int? get releaseYear => publishYear;

  /// True for ComicVine volumes — lets the UI label [pageCount] as the issue
  /// count of the series rather than a page count.
  bool get isComic => kind == BookKind.comic;

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
      'kind': kind.value,
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
    BookKind? kind,
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
      kind: kind ?? this.kind,
    );
  }

  /// Overlays a full fetch onto a lightweight search row, keeping the row's
  /// year / pages / languages / rating.
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

  /// Splits `/works/OL27448W` into native id and numeric [id]. Falls back to
  /// the native id when it carries no digits.
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
  // (`award:hugo_award=1966`); anything with `:` or `=` is dropped.
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


  /// Strips an HTML description (tags + entities) to plain text — used by the
  /// ComicVine and Google Books factories, whose descriptions come as HTML.
  static String? _stripHtmlText(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final String clean = stripBbCodes(raw);
    return clean.isEmpty ? null : clean;
  }

  /// Picks a cover from a ComicVine `image` object, preferring a mid-size URL
  /// (good for grids) and falling back to larger / smaller variants.
  static String? _comicVineCover(Object? image) {
    if (image is! Map<String, dynamic>) return null;
    for (final String key in const <String>[
      'medium_url',
      'super_url',
      'screen_large_url',
      'original_url',
    ]) {
      final String? url = _nonEmpty(image[key]);
      if (url != null) return url;
    }
    return null;
  }

  /// Present only on `/volume` detail payloads — search / browse rows omit
  /// them, keeping list items lightweight.
  static List<String> _comicVineNames(Object? raw, {required int max}) {
    if (raw is! List) return const <String>[];
    final List<String> names = <String>[];
    for (final Object? item in raw) {
      if (item is Map<String, dynamic>) {
        final String? name = _nonEmpty(item['name']);
        if (name != null && !names.contains(name)) names.add(name);
      }
      if (names.length >= max) break;
    }
    return names;
  }

  // Creators are few; characters can run to dozens — comics have no genres, so
  // the character list stands in for the genre/tag chips.
  static const int _comicVineMaxPeople = 12;
  static const int _comicVineMaxCharacters = 15;


  /// Splits a Google Books `industryIdentifiers` array into ISBN-10 / ISBN-13,
  /// keeping the first of each type.
  static (String? isbn10, String? isbn13) _googleIsbns(Object? raw) {
    if (raw is! List<dynamic>) return (null, null);
    String? isbn10;
    String? isbn13;
    for (final Map<String, dynamic> id
        in raw.whereType<Map<String, dynamic>>()) {
      final String type = _trimmed(id['type']);
      final String? value = _nonEmpty(id['identifier']);
      if (value == null) continue;
      if (type == 'ISBN_10') isbn10 ??= value;
      if (type == 'ISBN_13') isbn13 ??= value;
    }
    return (isbn10, isbn13);
  }

  /// Only thumbnail zoom levels reliably carry the cover: `small`..`extraLarge`
  /// are interior page scans, so the thumbnail is upscaled via Google's `fife`.
  static String? _googleCover(Object? imageLinks) {
    if (imageLinks is! Map<String, dynamic>) return null;
    for (final String key in const <String>['thumbnail', 'smallThumbnail']) {
      final String? url = _nonEmpty(imageLinks[key]);
      if (url != null) {
        final String clean = url
            .replaceAll('&edge=curl', '')
            .replaceFirst('http://', 'https://');
        return '$clean&fife=w800';
      }
    }
    return null;
  }


  /// `https://hardcover.app/id/book/{id}` — permanent id URL (302 to the
  /// current slug), immune to slug renames.
  static String _hardcoverBookUrl(String id) =>
      'https://hardcover.app/id/book/$id';

  /// Search documents carry `id` as a string, graph objects as an int. A
  /// non-numeric id folds through [fnv1a64] to keep the numeric contract.
  static String _hardcoverId(Object? raw) {
    if (raw is num) return raw.toInt().toString();
    if (raw is String && raw.isNotEmpty) {
      return int.tryParse(raw.trim())?.toString() ?? fnv1a64(raw).toString();
    }
    return '0';
  }

  /// `book_category_id`: 1 Book, 2 Novella, 3 Short Story, 4 Graphic Novel,
  /// … 10 Light Novel. Only graphic novels flip to [BookKind.comic].
  static BookKind _hardcoverKind(Object? categoryId) =>
      _intOrNull(categoryId) == 4 ? BookKind.comic : BookKind.book;

  /// Hardcover ratings are 0–5 floats; the app's scale is 1–10. Zero means
  /// unrated.
  static double? _hardcoverRating(Object? raw) {
    final double? rating = (raw as num?)?.toDouble();
    return (rating != null && rating > 0) ? rating * 2 : null;
  }

  /// Splits the mixed `isbns` array into the first ISBN-10 / ISBN-13.
  static (String? isbn10, String? isbn13) _hardcoverIsbns(Object? raw) {
    if (raw is! List<dynamic>) return (null, null);
    String? isbn10;
    String? isbn13;
    for (final String value in raw.whereType<String>()) {
      final String digits = value.replaceAll('-', '').trim();
      if (digits.length == 10) isbn10 ??= digits;
      if (digits.length == 13) isbn13 ??= digits;
      if (isbn10 != null && isbn13 != null) break;
    }
    return (isbn10, isbn13);
  }

  /// Distinct author names from graph `contributions` (`[{author: {name}}]`),
  /// in API order.
  static List<String> _hardcoverAuthors(Object? raw) {
    if (raw is! List<dynamic>) return const <String>[];
    final List<String> names = <String>[];
    for (final Object? item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final Object? author = item['author'];
      if (author is Map<String, dynamic>) {
        final String? name = _nonEmpty(author['name']);
        if (name != null && !names.contains(name)) names.add(name);
      }
    }
    return names;
  }

  /// Genres + moods from the `cached_tags` dictionary
  /// (`{Genre: [{tag}], Mood: [{tag}], …}`, top-10 per category).
  static List<String> _hardcoverCachedTags(Object? raw) {
    if (raw is! Map<String, dynamic>) return const <String>[];
    final List<String> values = <String>[];
    for (final String category in const <String>['Genre', 'Mood']) {
      final Object? tags = raw[category];
      if (tags is! List<dynamic>) continue;
      for (final Object? entry in tags) {
        if (entry is Map<String, dynamic>) {
          final String? tag = _nonEmpty(entry['tag']);
          if (tag != null) values.add(tag);
        }
      }
    }
    return _cleanSubjects(values);
  }

  /// Series name from a search document: the featured series, falling back
  /// to the first of `series_names`.
  static String? _hardcoverDocumentSeries(Map<String, dynamic> doc) {
    final Object? featured = doc['featured_series'];
    final Object? series =
        featured is Map<String, dynamic> ? featured['series'] : null;
    final String? name =
        series is Map<String, dynamic> ? _nonEmpty(series['name']) : null;
    return name ?? _firstString(doc['series_names']);
  }

  /// Lowest position wins — the primary series lists the book early, derived
  /// universe orderings much later.
  static String? _hardcoverSeries(Object? raw) {
    if (raw is! List<dynamic>) return null;
    String? best;
    double bestPosition = double.infinity;
    for (final Object? item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final Object? series = item['series'];
      final String? name = series is Map<String, dynamic>
          ? _nonEmpty(series['name'])
          : null;
      if (name == null) continue;
      final double position =
          (item['position'] as num?)?.toDouble() ?? double.infinity;
      if (best == null || position < bestPosition) {
        best = name;
        bestPosition = position;
      }
    }
    return best;
  }


  /// `https://fantlab.ru/work{id}` — the canonical work page.
  static String _fantlabWorkUrl(String id) => 'https://fantlab.ru/work$id';

  /// Cover URL from an edition id (search results expose `pic_edition_id`).
  static String _fantlabCoverUrlFromEdition(int editionId) =>
      'https://fantlab.ru/images/editions/big/$editionId';

  /// Prefers the manual `pic_edition_id` over Fantlab's auto pick. Returns 0
  /// when neither is set.
  static int _fantlabCoverEdition(Map<String, dynamic> match) {
    final int manual = _intOrNull(match['pic_edition_id']) ?? 0;
    if (manual > 0) return manual;
    return _intOrNull(match['pic_edition_id_auto']) ?? 0;
  }

  /// Prefixes a Fantlab image path (`/images/editions/big/24724?r=…`) with the
  /// host. Already-absolute URLs pass through.
  static String? _fantlabCoverUrl(Object? path) {
    if (path is! String || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return 'https://fantlab.ru$path';
  }

  /// Fantlab's Perl backend returns `work_id` as an int, a string, or a
  /// single-element array.
  static String _fantlabId(Object? raw) {
    if (raw is num) return raw.toInt().toString();
    if (raw is String) {
      final String trimmed = raw.trim();
      return int.tryParse(trimmed)?.toString() ?? trimmed;
    }
    if (raw is List<dynamic> && raw.isNotEmpty) return _fantlabId(raw.first);
    return '';
  }

  /// Pulls `rating` out of a `{rating, true_rating, voters}` object, or returns
  /// the value as-is (string / num / array) for the looser search payloads.
  static Object? _fantlabRatingValue(Object? rating) {
    if (rating is Map<String, dynamic>) return rating['rating'];
    return rating;
  }

  static int? _fantlabRatingVoters(Object? rating) {
    if (rating is Map<String, dynamic>) return _intOrNull(rating['voters']);
    return null;
  }

  /// Accepts a num, a numeric string (`"8.62"`), or an array (`[8.53]`).
  /// Non-positive means "no rating".
  static double? _fantlabRating(Object? raw) {
    final double? value;
    if (raw is num) {
      value = raw.toDouble();
    } else if (raw is String) {
      value = double.tryParse(raw.trim());
    } else if (raw is List<dynamic> && raw.isNotEmpty) {
      value = _fantlabRating(raw.first);
    } else {
      value = null;
    }
    return (value != null && value > 0) ? value : null;
  }

  static String _trimmed(Object? value) =>
      value is String ? value.trim() : '';

  static String? _nonEmpty(Object? value) {
    final String trimmed = _trimmed(value);
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _intOrNull(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static int? _positiveYear(Object? value) {
    final int? year = _intOrNull(value);
    return (year != null && year > 0) ? year : null;
  }

  static String? _stripFantlabText(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final String clean = stripBbCodes(raw);
    return clean.isEmpty ? null : clean;
  }

  /// MARC-ish language list from Fantlab's ISO `lang_code` (`"pl"`, `"ru"`).
  static List<String> _fantlabLanguages(Object? langCode) {
    final String? code = _nonEmpty(langCode);
    return code != null ? <String>[code] : const <String>[];
  }

  /// Individual author names from a `/search-works` match (`autor1_rusname` …
  /// `autor5_rusname`), falling back to the combined `all_autor_rusname`.
  static List<String> _fantlabSearchAuthors(Map<String, dynamic> match) {
    final List<String> out = <String>[];
    for (int i = 1; i <= 5; i++) {
      final String name = _trimmed(match['autor${i}_rusname']);
      if (name.isNotEmpty) out.add(name);
    }
    if (out.isEmpty) {
      final String all = _trimmed(match['all_autor_rusname']);
      if (all.isNotEmpty) out.add(all);
    }
    return out;
  }

  /// Keeps `type == 'autor'` or untyped, dropping translators, and caps the
  /// list so a credits-heavy work can't flood the card.
  static List<String> _fantlabWorkAuthors(Object? authors) {
    if (authors is! List<dynamic>) return const <String>[];
    final List<String> out = <String>[];
    for (final Map<String, dynamic> a
        in authors.whereType<Map<String, dynamic>>()) {
      final String? type = a['type'] as String?;
      if (type != null && type != 'autor') continue;
      final String name = _trimmed(a['name']);
      if (name.isNotEmpty) out.add(name);
      if (out.length >= 5) break;
    }
    return out;
  }

  /// Flattens the `extended.classificatory` genre tree into a clean subject
  /// list (`genre_group[].genre[].label`).
  static List<String> _fantlabClassificatory(Object? classificatory) {
    if (classificatory is! Map<String, dynamic>) return const <String>[];
    final Object? groups = classificatory['genre_group'];
    if (groups is! List<dynamic>) return const <String>[];
    final List<String> labels = <String>[];
    for (final Map<String, dynamic> group
        in groups.whereType<Map<String, dynamic>>()) {
      final Object? genres = group['genre'];
      if (genres is! List<dynamic>) continue;
      for (final Map<String, dynamic> genre
          in genres.whereType<Map<String, dynamic>>()) {
        final String label = _trimmed(genre['label']);
        if (label.isNotEmpty) labels.add(label);
      }
    }
    return _cleanSubjects(labels);
  }

  /// Award names from `extended.awards` (`win` first, then `nom`), preferring
  /// the Russian label.
  static List<String> _fantlabAwards(Object? awards) {
    if (awards is! Map<String, dynamic>) return const <String>[];
    final List<String> out = <String>[];
    for (final String key in const <String>['win', 'nom']) {
      final Object? list = awards[key];
      if (list is! List<dynamic>) continue;
      for (final Map<String, dynamic> award
          in list.whereType<Map<String, dynamic>>()) {
        final String name = _trimmed(award['award_rusname']).isNotEmpty
            ? _trimmed(award['award_rusname'])
            : _trimmed(award['award_name']);
        if (name.isNotEmpty) out.add(name);
      }
    }
    return _dedupe(out);
  }

  /// Series / cycle name from `extended.parents` — the root cycle in the
  /// `digest` chain, falling back to `cycles`.
  static String? _fantlabSeries(Object? parents) {
    if (parents is! Map<String, dynamic>) return null;
    final Object? digest = parents['digest'];
    if (digest is List<dynamic>) {
      for (final Object? chain in digest) {
        if (chain is List<dynamic>) {
          for (final Map<String, dynamic> work
              in chain.whereType<Map<String, dynamic>>()) {
            final String name = _trimmed(work['work_name']);
            if (name.isNotEmpty) return name;
          }
        } else if (chain is Map<String, dynamic>) {
          final String name = _trimmed(chain['work_name']);
          if (name.isNotEmpty) return name;
        }
      }
    }
    final Object? cycles = parents['cycles'];
    if (cycles is List<dynamic>) {
      for (final Map<String, dynamic> cycle
          in cycles.whereType<Map<String, dynamic>>()) {
        final String name = _trimmed(cycle['work_name']).isNotEmpty
            ? _trimmed(cycle['work_name'])
            : _trimmed(cycle['name']);
        if (name.isNotEmpty) return name;
      }
    }
    return null;
  }

  /// First edition id plus the first page count / ISBN found across editions —
  /// fields the bare work response lacks.
  static ({int? pages, String? isbn, int? editionId}) _fantlabFirstEdition(
    Object? blocks,
  ) {
    if (blocks is! Map<String, dynamic>) {
      return (pages: null, isbn: null, editionId: null);
    }
    int? editionId;
    int? pages;
    String? isbn;
    for (final Map<String, dynamic> block
        in blocks.values.whereType<Map<String, dynamic>>()) {
      final Object? list = block['list'];
      if (list is! List<dynamic>) continue;
      for (final Map<String, dynamic> ed
          in list.whereType<Map<String, dynamic>>()) {
        editionId ??= _intOrNull(ed['edition_id']);
        pages ??= _intOrNull(ed['pages']);
        if (isbn == null) {
          final String rawIsbn = _trimmed(ed['isbn']).replaceAll('-', '');
          if (rawIsbn.isNotEmpty) isbn = rawIsbn;
        }
        if (editionId != null && pages != null && isbn != null) {
          return (pages: pages, isbn: isbn, editionId: editionId);
        }
      }
    }
    return (pages: pages, isbn: isbn, editionId: editionId);
  }
}
