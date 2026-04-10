// Модель аниме из AniList.

import 'dart:convert';

/// Модель аниме из AniList GraphQL API.
///
/// Представляет аниме с метаданными из AniList.
class Anime {
  /// Создаёт экземпляр [Anime].
  const Anime({
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
    this.season,
    this.seasonYear,
    this.startYear,
    this.startMonth,
    this.startDay,
    this.episodes,
    this.duration,
    this.format,
    this.source,
    this.genres,
    this.studios,
    this.bannerUrl,
    this.nextAiringEpisode,
    this.nextAiringAt,
    this.externalUrl,
    this.updatedAt,
  });

  /// Создаёт [Anime] из JSON ответа AniList GraphQL API.
  factory Anime.fromJson(Map<String, dynamic> json) {
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

    // Studios
    List<String>? studios;
    final Map<String, dynamic>? studiosMap =
        json['studios'] as Map<String, dynamic>?;
    if (studiosMap != null) {
      final List<dynamic>? nodes = studiosMap['nodes'] as List<dynamic>?;
      if (nodes != null && nodes.isNotEmpty) {
        studios = nodes
            .map((dynamic n) =>
                (n as Map<String, dynamic>)['name'] as String? ?? '')
            .where((String s) => s.isNotEmpty)
            .toList();
        if (studios.isEmpty) studios = null;
      }
    }

    // Strip HTML from description
    String? description = json['description'] as String?;
    if (description != null) {
      description = _stripHtml(description);
    }

    final int id = json['id'] as int;

    return Anime(
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
      season: json['season'] as String?,
      seasonYear: json['seasonYear'] as int?,
      startYear: dateMap?['year'] as int?,
      startMonth: dateMap?['month'] as int?,
      startDay: dateMap?['day'] as int?,
      episodes: json['episodes'] as int?,
      duration: json['duration'] as int?,
      format: json['format'] as String?,
      source: json['source'] as String?,
      genres: genresList?.map((dynamic g) => g as String).toList(),
      studios: studios,
      bannerUrl: json['bannerImage'] as String?,
      nextAiringEpisode:
          (json['nextAiringEpisode'] as Map<String, dynamic>?)?['episode']
              as int?,
      nextAiringAt:
          (json['nextAiringEpisode'] as Map<String, dynamic>?)?['airingAt']
              as int?,
      externalUrl: 'https://anilist.co/anime/$id',
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Создаёт [Anime] из записи базы данных.
  factory Anime.fromDb(Map<String, dynamic> row) {
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

    List<String>? studios;
    if (row['studios'] != null && (row['studios'] as String).isNotEmpty) {
      try {
        studios = (jsonDecode(row['studios'] as String) as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList();
      } on FormatException {
        studios = null;
      }
    }

    return Anime(
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
      season: row['season'] as String?,
      seasonYear: row['season_year'] as int?,
      startYear: row['start_year'] as int?,
      startMonth: row['start_month'] as int?,
      startDay: row['start_day'] as int?,
      episodes: row['episodes'] as int?,
      duration: row['duration'] as int?,
      format: row['format'] as String?,
      source: row['source'] as String?,
      genres: genres,
      studios: studios,
      bannerUrl: row['banner_url'] as String?,
      nextAiringEpisode: row['next_airing_episode'] as int?,
      nextAiringAt: row['next_airing_at'] as int?,
      externalUrl: row['external_url'] as String?,
      updatedAt: row['updated_at'] as int?,
    );
  }

  /// AniList ID.
  final int id;

  /// Romaji название (основное).
  final String title;

  /// Английское название.
  final String? titleEnglish;

  /// Нативное (японское) название.
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

  /// Статус: FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED, HIATUS.
  final String? status;

  /// Сезон: WINTER, SPRING, SUMMER, FALL.
  final String? season;

  /// Год сезона.
  final int? seasonYear;

  /// Год начала.
  final int? startYear;

  /// Месяц начала.
  final int? startMonth;

  /// День начала.
  final int? startDay;

  /// Количество эпизодов (null если ongoing/неизвестно).
  final int? episodes;

  /// Длительность эпизода в минутах.
  final int? duration;

  /// Формат: TV, TV_SHORT, MOVIE, SPECIAL, OVA, ONA, MUSIC.
  final String? format;

  /// Исходный материал: ORIGINAL, MANGA, LIGHT_NOVEL, VISUAL_NOVEL, VIDEO_GAME.
  final String? source;

  /// Список жанров.
  final List<String>? genres;

  /// Список студий.
  final List<String>? studios;

  /// URL баннера (для backdrop).
  final String? bannerUrl;

  /// Номер следующего выходящего эпизода (для ongoing).
  final int? nextAiringEpisode;

  /// Unix timestamp выхода следующего эпизода.
  final int? nextAiringAt;

  /// URL страницы на AniList.
  final String? externalUrl;

  /// Время кеширования (Unix timestamp).
  final int? updatedAt;

  // ===== Computed =====

  /// Рейтинг в шкале 0-10.
  double? get rating10 =>
      averageScore != null ? averageScore! / 10.0 : null;

  /// Форматированный рейтинг (0-10).
  String? get formattedRating =>
      rating10?.toStringAsFixed(1);

  /// Год релиза.
  int? get releaseYear => seasonYear ?? startYear;

  /// Жанры в виде строки через запятую.
  String? get genresString => genres?.join(', ');

  /// Студии в виде строки через запятую.
  String? get studiosString => studios?.join(', ');

  /// Человекочитаемая метка формата.
  String? get formatLabel => switch (format) {
        'TV' => 'TV',
        'TV_SHORT' => 'TV Short',
        'MOVIE' => 'Movie',
        'SPECIAL' => 'Special',
        'OVA' => 'OVA',
        'ONA' => 'ONA',
        'MUSIC' => 'Music',
        _ => format,
      };

  /// Человекочитаемый статус.
  String? get statusLabel => switch (status) {
        'FINISHED' => 'Finished',
        'RELEASING' => 'Airing',
        'NOT_YET_RELEASED' => 'Not Yet Aired',
        'CANCELLED' => 'Cancelled',
        'HIATUS' => 'Hiatus',
        _ => status,
      };

  /// Человекочитаемый сезон.
  String? get seasonLabel {
    if (season == null) return null;
    final String seasonName = switch (season) {
      'WINTER' => 'Winter',
      'SPRING' => 'Spring',
      'SUMMER' => 'Summer',
      'FALL' => 'Fall',
      _ => season!,
    };
    return seasonYear != null ? '$seasonName $seasonYear' : seasonName;
  }

  /// Строка эпизодов: "24 ep" или "? ep".
  String get episodesString =>
      episodes != null ? '$episodes ep' : '? ep';

  /// Длительность эпизода: "24 min/ep".
  String? get durationString =>
      duration != null ? '$duration min/ep' : null;

  /// Человекочитаемый исходный материал.
  String? get sourceLabel => switch (source) {
        'ORIGINAL' => 'Original',
        'MANGA' => 'Based on Manga',
        'LIGHT_NOVEL' => 'Based on Light Novel',
        'VISUAL_NOVEL' => 'Based on Visual Novel',
        'VIDEO_GAME' => 'Based on Video Game',
        'OTHER' => 'Other',
        _ => source,
      };

  /// Есть ли информация о следующем эпизоде.
  bool get hasNextAiring =>
      nextAiringEpisode != null && nextAiringAt != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Anime && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Anime(id: $id, title: $title)';

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
      'season': season,
      'season_year': seasonYear,
      'start_year': startYear,
      'start_month': startMonth,
      'start_day': startDay,
      'episodes': episodes,
      'duration': duration,
      'format': format,
      'source': source,
      'genres': genres != null ? jsonEncode(genres) : null,
      'studios': studios != null ? jsonEncode(studios) : null,
      'banner_url': bannerUrl,
      'next_airing_episode': nextAiringEpisode,
      'next_airing_at': nextAiringAt,
      'external_url': externalUrl,
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
  Anime copyWith({
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
    String? season,
    int? seasonYear,
    int? startYear,
    int? startMonth,
    int? startDay,
    int? episodes,
    int? duration,
    String? format,
    String? source,
    List<String>? genres,
    List<String>? studios,
    String? bannerUrl,
    int? nextAiringEpisode,
    int? nextAiringAt,
    String? externalUrl,
    int? updatedAt,
  }) {
    return Anime(
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
      season: season ?? this.season,
      seasonYear: seasonYear ?? this.seasonYear,
      startYear: startYear ?? this.startYear,
      startMonth: startMonth ?? this.startMonth,
      startDay: startDay ?? this.startDay,
      episodes: episodes ?? this.episodes,
      duration: duration ?? this.duration,
      format: format ?? this.format,
      source: source ?? this.source,
      genres: genres ?? this.genres,
      studios: studios ?? this.studios,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      nextAiringEpisode: nextAiringEpisode ?? this.nextAiringEpisode,
      nextAiringAt: nextAiringAt ?? this.nextAiringAt,
      externalUrl: externalUrl ?? this.externalUrl,
      updatedAt: updatedAt ?? this.updatedAt,
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
