import 'dart:convert';

import '../utils/anime_manga_title_language.dart';

/// Manga metadata from the AniList GraphQL API.
class Manga {
  const Manga({
    required this.id,
    required this.title,
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

  /// Maps directly to external_id.
  final int id;

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

  String? get formatLabel => switch (format) {
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
