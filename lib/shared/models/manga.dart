import 'dart:convert';

import '../utils/anime_manga_title_language.dart';
import 'data_source.dart';

/// Manga metadata from AniList or MangaBaka.
///
/// [id] is the provider-side id and is NOT unique on its own across
/// providers — the cache identity is the pair `(id, source)`.
class Manga {
  const Manga({
    required this.id,
    required this.title,
    this.source = DataSource.anilist,
    this.titleEnglish,
    this.titleNative,
    this.description,
    this.coverUrl,
    this.coverUrlMedium,
    this.averageScore,
    this.meanScore,
    this.popularity,
    this.status,
    this.startYear,
    this.startMonth,
    this.startDay,
    this.chapters,
    this.volumes,
    this.format,
    this.countryOfOrigin,
    this.genres,
    this.tags,
    this.authors,
    this.externalUrl,
    this.updatedAt,
    this.bannerUrl,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? titleMap =
        json['title'] as Map<String, dynamic>?;
    final String title = titleMap?['romaji'] as String? ??
        titleMap?['english'] as String? ??
        'Unknown';

    final Map<String, dynamic>? coverMap =
        json['coverImage'] as Map<String, dynamic>?;

    final Map<String, dynamic>? dateMap =
        json['startDate'] as Map<String, dynamic>?;

    final List<dynamic>? genresList = json['genres'] as List<dynamic>?;

    // AniList tag objects carry category, rank, isMediaSpoiler — we drop
    // everything except the name since per-media spoiler / category are
    // looked up from the catalog table when needed.
    List<String>? tags;
    final List<dynamic>? tagsList = json['tags'] as List<dynamic>?;
    if (tagsList != null && tagsList.isNotEmpty) {
      tags = tagsList
          .map((dynamic t) =>
              (t as Map<String, dynamic>)['name'] as String? ?? '')
          .where((String s) => s.isNotEmpty)
          .toList();
      if (tags.isEmpty) tags = null;
    }

    // Filter staff edges to author-credit roles only (Story, Art, Story & Art).
    List<String>? authors;
    final Map<String, dynamic>? staffMap =
        json['staff'] as Map<String, dynamic>?;
    if (staffMap != null) {
      final List<dynamic>? edges = staffMap['edges'] as List<dynamic>?;
      if (edges != null) {
        authors = edges
            .where((dynamic e) {
              final String? role =
                  (e as Map<String, dynamic>)['role'] as String?;
              return role == 'Story' ||
                  role == 'Art' ||
                  role == 'Story & Art';
            })
            .map((dynamic e) {
              final Map<String, dynamic> node =
                  (e as Map<String, dynamic>)['node']
                      as Map<String, dynamic>;
              final Map<String, dynamic> name =
                  node['name'] as Map<String, dynamic>;
              return name['full'] as String? ?? '';
            })
            .where((String s) => s.isNotEmpty)
            .toList();
        if (authors.isEmpty) authors = null;
      }
    }

    String? description = json['description'] as String?;
    if (description != null) {
      description = _stripHtml(description);
    }

    final int id = json['id'] as int;

    return Manga(
      id: id,
      title: title,
      titleEnglish: titleMap?['english'] as String?,
      titleNative: titleMap?['native'] as String?,
      description: description,
      coverUrl: (coverMap?['extraLarge'] ?? coverMap?['large']) as String?,
      coverUrlMedium: coverMap?['medium'] as String?,
      averageScore: json['averageScore'] as int?,
      status: json['status'] as String?,
      startYear: dateMap?['year'] as int?,
      startMonth: dateMap?['month'] as int?,
      startDay: dateMap?['day'] as int?,
      chapters: json['chapters'] as int?,
      volumes: json['volumes'] as int?,
      format: json['format'] as String?,
      genres: genresList?.map((dynamic g) => g as String).toList(),
      tags: tags,
      authors: authors,
      externalUrl: 'https://anilist.co/manga/$id',
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      bannerUrl: json['bannerImage'] as String?,
    );
  }

  /// Builds a [Manga] from a MangaBaka `/v1/series/{id}` (or search `data[]`)
  /// record. MangaBaka has a flat REST shape distinct from AniList: titles are
  /// top-level, chapters / volumes are strings, the rating is already 0–100,
  /// and only the raw cover variant is populated.
  factory Manga.fromMangaBaka(Map<String, dynamic> json) {
    final int id = (json['id'] as num).toInt();

    final List<Map<String, dynamic>> titles =
        (json['titles'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const <Map<String, dynamic>>[];

    // Map MangaBaka titles onto the AniList-style romaji / english / native
    // slots so `titleByLanguage` and the title-language setting behave the
    // same for both sources. `ja-Latn` is the real romaji — the flat
    // `romanized_title` is sometimes a localized title. Fall back to the flat
    // fields, then to whatever non-empty title exists.
    final String? romaji =
        _bakaTitle(titles, 'ja-Latn') ?? json['romanized_title'] as String?;
    final String? native =
        _bakaTitle(titles, 'ja') ?? json['native_title'] as String?;
    final String? english = _bakaTitle(titles, 'en') ?? json['title'] as String?;
    final String title =
        _firstNonEmpty(<String?>[romaji, english, native]) ?? 'Unknown';

    String? coverUrl;
    final Object? cover = json['cover'];
    if (cover is Map<String, dynamic>) {
      final Object? raw = cover['raw'];
      if (raw is Map<String, dynamic>) {
        coverUrl = raw['url'] as String?;
      } else if (raw is String) {
        coverUrl = raw;
      }
    }

    int? startYear;
    final Object? published = json['published'];
    if (published is Map<String, dynamic>) {
      final String? start = published['start_date'] as String?;
      if (start != null && start.length >= 4) {
        startYear = int.tryParse(start.substring(0, 4));
      }
    }
    startYear ??= (json['year'] as num?)?.toInt();

    final List<String>? genres = _stringList(json['genres']);
    final List<String>? tags = _stringList(json['tags']);

    final List<String> authors = <String>[
      ...?_stringList(json['authors']),
      ...?_stringList(json['artists']),
    ];

    final num? rating = json['rating'] as num?;

    String? description = json['description'] as String?;
    if (description != null) description = _stripHtml(description);

    return Manga(
      id: id,
      source: DataSource.mangabaka,
      title: title,
      titleEnglish: english,
      titleNative: native,
      description: description,
      coverUrl: coverUrl,
      averageScore: rating?.round(),
      status: _mangaBakaStatus(json['status'] as String?),
      startYear: startYear,
      chapters: _parseIntOrNull(json['total_chapters']),
      volumes: _parseIntOrNull(json['final_volume']),
      format: _mangaBakaFormat(json['type'] as String?),
      genres: genres,
      tags: tags,
      authors: authors.isEmpty ? null : authors,
      externalUrl: 'https://mangabaka.org/$id',
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  factory Manga.fromDb(Map<String, dynamic> row) {
    List<String>? genres;
    if (row['genres'] != null && (row['genres'] as String).isNotEmpty) {
      try {
        genres = (jsonDecode(row['genres'] as String) as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList();
      } on FormatException {
        genres = null;
      }
    }

    List<String>? authors;
    if (row['authors'] != null && (row['authors'] as String).isNotEmpty) {
      try {
        authors = (jsonDecode(row['authors'] as String) as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList();
      } on FormatException {
        authors = null;
      }
    }

    List<String>? tags;
    if (row['tags'] != null && (row['tags'] as String).isNotEmpty) {
      try {
        tags = (jsonDecode(row['tags'] as String) as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList();
      } on FormatException {
        tags = null;
      }
    }

    return Manga(
      id: row['id'] as int,
      source: DataSource.fromName(row['source'] as String?),
      title: row['title'] as String,
      titleEnglish: row['title_english'] as String?,
      titleNative: row['title_native'] as String?,
      description: row['description'] as String?,
      coverUrl: row['cover_url'] as String?,
      coverUrlMedium: row['cover_url_medium'] as String?,
      averageScore: row['average_score'] as int?,
      meanScore: row['mean_score'] as int?,
      popularity: row['popularity'] as int?,
      status: row['status'] as String?,
      startYear: row['start_year'] as int?,
      startMonth: row['start_month'] as int?,
      startDay: row['start_day'] as int?,
      chapters: row['chapters'] as int?,
      volumes: row['volumes'] as int?,
      format: row['format'] as String?,
      countryOfOrigin: row['country_of_origin'] as String?,
      genres: genres,
      tags: tags,
      authors: authors,
      externalUrl: row['external_url'] as String?,
      bannerUrl: row['banner_url'] as String?,
      updatedAt: row['updated_at'] as int?,
    );
  }

  /// Provider-side id. Maps to `collection_items.external_id` and the `id`
  /// column of `manga_cache`. NOT unique without [source].
  final int id;

  /// Which provider this record came from. Part of the cache identity
  /// `(id, source)` so AniList and MangaBaka entries that share a numeric id
  /// never collide.
  final DataSource source;

  /// Romaji title (always present per AniList contract).
  final String title;

  final String? titleEnglish;
  final String? titleNative;

  /// Returns the title in the requested AniList language with a fallback chain.
  String titleByLanguage(String lang) {
    return pickAnimeMangaTitle(
          lang: lang,
          romaji: title,
          english: titleEnglish,
          native: titleNative,
        ) ??
        title;
  }

  final String? description;

  final String? coverUrl;
  final String? coverUrlMedium;
  final int? averageScore;
  final int? meanScore;
  final int? popularity;

  /// One of FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED, HIATUS.
  final String? status;

  final int? startYear;
  final int? startMonth;
  final int? startDay;

  /// Null when ongoing or unknown.
  final int? chapters;

  /// Null when ongoing or unknown.
  final int? volumes;

  /// One of MANGA, NOVEL, ONE_SHOT, MANHWA, MANHUA, LIGHT_NOVEL.
  final String? format;

  /// JP, KR, CN, TW.
  final String? countryOfOrigin;

  final List<String>? genres;

  /// AniList tag names; per-media category / rank / spoiler flags are not
  /// stored — only the catalog table keeps that metadata.
  final List<String>? tags;

  final List<String>? authors;
  final String? externalUrl;

  /// Unix timestamp of when this row was cached.
  final int? updatedAt;

  /// Transient — not persisted (only present on fresh API responses).
  final String? bannerUrl;

  double? get rating10 =>
      averageScore != null ? averageScore! / 10.0 : null;

  String? get formattedRating => rating10?.toStringAsFixed(1);

  int? get releaseYear => startYear;

  String? get genresString => genres?.join(', ');

  String? get tagsString => tags?.join(', ');

  String? get authorsString => authors?.join(', ');

  String? get formatLabel => mangaFormatLabel(format);

  /// Maps an AniList / MangaBaka manga [format] code to a display label.
  /// Returns the raw code for unrecognised values and `null` when absent.
  static String? mangaFormatLabel(String? format) => switch (format) {
        'MANGA' => 'Manga',
        'NOVEL' => 'Novel',
        'ONE_SHOT' => 'One-shot',
        'MANHWA' => 'Manhwa',
        'MANHUA' => 'Manhua',
        'LIGHT_NOVEL' => 'Light Novel',
        _ => format,
      };

  String? get statusLabel => switch (status) {
        'FINISHED' => 'Finished',
        'RELEASING' => 'Releasing',
        'NOT_YET_RELEASED' => 'Not Yet Released',
        'CANCELLED' => 'Cancelled',
        'HIATUS' => 'Hiatus',
        _ => status,
      };

  String get progressString {
    final String ch = chapters != null ? '$chapters ch' : '? ch';
    final String vol = volumes != null ? ' · $volumes vol' : '';
    return '$ch$vol';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Manga && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Manga(id: $id, title: $title)';

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'source': source.name,
      'title': title,
      'title_english': titleEnglish,
      'title_native': titleNative,
      'description': description,
      'cover_url': coverUrl,
      'cover_url_medium': coverUrlMedium,
      'average_score': averageScore,
      'mean_score': meanScore,
      'popularity': popularity,
      'status': status,
      'start_year': startYear,
      'start_month': startMonth,
      'start_day': startDay,
      'chapters': chapters,
      'volumes': volumes,
      'format': format,
      'country_of_origin': countryOfOrigin,
      'genres': genres != null ? jsonEncode(genres) : null,
      'tags': tags != null ? jsonEncode(tags) : null,
      'authors': authors != null ? jsonEncode(authors) : null,
      'external_url': externalUrl,
      'banner_url': bannerUrl,
      'updated_at':
          updatedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// `toDb` minus the cache timestamp, for `.xcoll` / `.xcollx` payloads.
  Map<String, dynamic> toExport() {
    final Map<String, dynamic> data = toDb();
    data.remove('updated_at');
    return data;
  }

  Manga copyWith({
    int? id,
    DataSource? source,
    String? title,
    String? titleEnglish,
    String? titleNative,
    String? description,
    String? coverUrl,
    String? coverUrlMedium,
    int? averageScore,
    int? meanScore,
    int? popularity,
    String? status,
    int? startYear,
    int? startMonth,
    int? startDay,
    int? chapters,
    int? volumes,
    String? format,
    String? countryOfOrigin,
    List<String>? genres,
    List<String>? tags,
    List<String>? authors,
    String? externalUrl,
    int? updatedAt,
    String? bannerUrl,
  }) {
    return Manga(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      titleNative: titleNative ?? this.titleNative,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      coverUrlMedium: coverUrlMedium ?? this.coverUrlMedium,
      averageScore: averageScore ?? this.averageScore,
      meanScore: meanScore ?? this.meanScore,
      popularity: popularity ?? this.popularity,
      status: status ?? this.status,
      startYear: startYear ?? this.startYear,
      startMonth: startMonth ?? this.startMonth,
      startDay: startDay ?? this.startDay,
      chapters: chapters ?? this.chapters,
      volumes: volumes ?? this.volumes,
      format: format ?? this.format,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      authors: authors ?? this.authors,
      externalUrl: externalUrl ?? this.externalUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  /// Picks the best MangaBaka title for a language code, preferring the
  /// primary / official variant. Returns null when no title matches.
  static String? _bakaTitle(List<Map<String, dynamic>> titles, String lang) {
    final List<Map<String, dynamic>> matches = titles
        .where((Map<String, dynamic> t) => t['language'] == lang)
        .toList();
    if (matches.isEmpty) return null;
    int score(Map<String, dynamic> t) {
      int s = 0;
      if (t['is_primary'] == true) s += 2;
      final Object? traits = t['traits'];
      if (traits is List && traits.contains('official')) s += 1;
      return s;
    }

    matches.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        score(b).compareTo(score(a)));
    final Object? title = matches.first['title'];
    return (title is String && title.isNotEmpty) ? title : null;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final String? v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// MangaBaka returns chapter / volume counts as strings (e.g. `"147"`).
  static int? _parseIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static List<String>? _stringList(Object? value) {
    if (value is! List<dynamic>) return null;
    final List<String> out = value
        .whereType<String>()
        .where((String s) => s.isNotEmpty)
        .toList();
    return out.isEmpty ? null : out;
  }

  /// Maps MangaBaka `status` onto the AniList-style vocabulary used across the
  /// app ([statusLabel], progress UI).
  static String? _mangaBakaStatus(String? status) => switch (status) {
        'releasing' => 'RELEASING',
        'completed' => 'FINISHED',
        'hiatus' => 'HIATUS',
        'cancelled' => 'CANCELLED',
        'upcoming' => 'NOT_YET_RELEASED',
        _ => null,
      };

  /// Maps MangaBaka `type` onto the AniList-style format vocabulary.
  static String? _mangaBakaFormat(String? type) => switch (type) {
        'manga' => 'MANGA',
        'manhwa' => 'MANHWA',
        'manhua' => 'MANHUA',
        'novel' => 'LIGHT_NOVEL',
        'other' => 'ONE_SHOT',
        _ => null,
      };

  static final RegExp _htmlTagPattern = RegExp('<[^>]*>');

  static String? _stripHtml(String? text) {
    if (text == null) return null;
    String clean = text.replaceAll(_htmlTagPattern, '');
    clean = clean.replaceAll('&amp;', '&');
    clean = clean.replaceAll('&lt;', '<');
    clean = clean.replaceAll('&gt;', '>');
    clean = clean.replaceAll('&quot;', '"');
    clean = clean.replaceAll('&#39;', "'");
    clean = clean.replaceAll('&nbsp;', ' ');
    clean = clean.trim();
    return clean.isEmpty ? null : clean;
  }
}
