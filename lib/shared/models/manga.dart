// Модель манги из AniList.

import 'dart:convert';

/// Модель манги из AniList GraphQL API.
///
/// Представляет мангу с метаданными из AniList.
class Manga {
  /// Создаёт экземпляр [Manga].
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
    this.authors,
    this.externalUrl,
    this.updatedAt,
    this.bannerUrl,
  });

  /// Создаёт [Manga] из JSON ответа AniList GraphQL API.
  factory Manga.fromJson(Map<String, dynamic> json) {
    // Title
    final Map<String, dynamic>? titleMap =
        json['title'] as Map<String, dynamic>?;
    final String title = titleMap?['romaji'] as String? ??
        titleMap?['english'] as String? ??
        'Unknown';

    // Cover
    final Map<String, dynamic>? coverMap =
        json['coverImage'] as Map<String, dynamic>?;

    // Start date
    final Map<String, dynamic>? dateMap =
        json['startDate'] as Map<String, dynamic>?;

    // Genres
    final List<dynamic>? genresList = json['genres'] as List<dynamic>?;

    // Authors from staff edges
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

    // Strip HTML from description
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
      coverUrl: coverMap?['large'] as String?,
      coverUrlMedium: coverMap?['medium'] as String?,
      averageScore: json['averageScore'] as int?,
      meanScore: json['meanScore'] as int?,
      popularity: json['popularity'] as int?,
      status: json['status'] as String?,
      startYear: dateMap?['year'] as int?,
      startMonth: dateMap?['month'] as int?,
      startDay: dateMap?['day'] as int?,
      chapters: json['chapters'] as int?,
      volumes: json['volumes'] as int?,
      format: json['format'] as String?,
      countryOfOrigin: json['countryOfOrigin'] as String?,
      genres: genresList?.map((dynamic g) => g as String).toList(),
      authors: authors,
      externalUrl: 'https://anilist.co/manga/$id',
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      bannerUrl: json['bannerImage'] as String?,
    );
  }

  /// Создаёт [Manga] из записи базы данных.
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
      authors: authors,
      externalUrl: row['external_url'] as String?,
      bannerUrl: row['banner_url'] as String?,
      updatedAt: row['updated_at'] as int?,
    );
  }

  /// AniList ID (integer — maps directly to external_id).
  final int id;

  /// Romaji название (основное).
  final String title;

  /// Английское название.
  final String? titleEnglish;

  /// Нативное (японское/корейское/китайское) название.
  final String? titleNative;

  /// Описание (HTML очищен).
  final String? description;

  /// URL обложки (large).
  final String? coverUrl;

  /// URL обложки (medium, для превью).
  final String? coverUrlMedium;

  /// Средний рейтинг 0-100.
  final int? averageScore;

  /// Средний балл 0-100.
  final int? meanScore;

  /// Ранг популярности.
  final int? popularity;

  /// Статус публикации: FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED,
  /// HIATUS.
  final String? status;

  /// Год начала публикации.
  final int? startYear;

  /// Месяц начала публикации.
  final int? startMonth;

  /// День начала публикации.
  final int? startDay;

  /// Всего глав (null если ongoing/неизвестно).
  final int? chapters;

  /// Всего томов (null если ongoing/неизвестно).
  final int? volumes;

  /// Формат: MANGA, NOVEL, ONE_SHOT, MANHWA, MANHUA, LIGHT_NOVEL.
  final String? format;

  /// Страна происхождения: JP, KR, CN, TW.
  final String? countryOfOrigin;

  /// Список жанров (["Action", "Adventure", "Fantasy"]).
  final List<String>? genres;

  /// Имена авторов.
  final List<String>? authors;

  /// URL страницы на AniList.
  final String? externalUrl;

  /// Время кеширования (Unix timestamp).
  final int? updatedAt;

  /// URL баннера (transient, не сохраняется в БД).
  final String? bannerUrl;

  // ===== Computed =====

  /// Рейтинг в шкале 0-10.
  double? get rating10 =>
      averageScore != null ? averageScore! / 10.0 : null;

  /// Форматированный рейтинг (0-10).
  String? get formattedRating =>
      rating10?.toStringAsFixed(1);

  /// Год релиза.
  int? get releaseYear => startYear;

  /// Жанры в виде строки через запятую.
  String? get genresString => genres?.join(', ');

  /// Авторы в виде строки через запятую.
  String? get authorsString => authors?.join(', ');

  /// Человекочитаемая метка формата.
  String? get formatLabel => switch (format) {
        'MANGA' => 'Manga',
        'NOVEL' => 'Novel',
        'ONE_SHOT' => 'One-shot',
        'MANHWA' => 'Manhwa',
        'MANHUA' => 'Manhua',
        'LIGHT_NOVEL' => 'Light Novel',
        _ => format,
      };

  /// Человекочитаемый статус.
  String? get statusLabel => switch (status) {
        'FINISHED' => 'Finished',
        'RELEASING' => 'Releasing',
        'NOT_YET_RELEASED' => 'Not Yet Released',
        'CANCELLED' => 'Cancelled',
        'HIATUS' => 'Hiatus',
        _ => status,
      };

  /// Строка прогресса: "23 ch · 5 vol" или "? ch" и т.д.
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

  /// Преобразует в Map для сохранения в базу данных.
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
      'authors': authors != null ? jsonEncode(authors) : null,
      'external_url': externalUrl,
      'banner_url': bannerUrl,
      'updated_at':
          updatedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Преобразует в Map для экспорта коллекции.
  Map<String, dynamic> toExport() {
    final Map<String, dynamic> data = toDb();
    data.remove('updated_at');
    return data;
  }

  /// Создаёт копию с изменёнными полями.
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
      authors: authors ?? this.authors,
      externalUrl: externalUrl ?? this.externalUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  static final RegExp _htmlTagPattern = RegExp('<[^>]*>');

  /// Убирает HTML-теги из описания.
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
