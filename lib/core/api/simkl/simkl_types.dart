/// Typed error for Simkl requests.
///
/// Simkl reports a missing/over-quota `client_id` as `412 client_id_failed`
/// rather than the usual 429 — [isClientIdFailure] flags that case so callers
/// can show a meaningful message instead of a generic failure.
class SimklApiException implements Exception {
  const SimklApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  bool get isClientIdFailure => statusCode == 412;

  @override
  String toString() => 'SimklApiException: $message';
}

/// A PIN issued by `GET /oauth/pin`: the user enters [userCode] at
/// [verificationUrl] while the app polls until the token arrives.
class SimklPin {
  const SimklPin({
    required this.userCode,
    required this.verificationUrl,
    required this.expiresIn,
    required this.interval,
  });

  factory SimklPin.fromJson(Map<String, dynamic> json) {
    return SimklPin(
      userCode: (json['user_code'] as String?) ?? '',
      verificationUrl:
          (json['verification_url'] as String?) ?? 'https://simkl.com/pin',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 900,
      interval: (json['interval'] as num?)?.toInt() ?? 5,
    );
  }

  final String userCode;
  final String verificationUrl;

  /// Seconds until the code expires (Simkl issues 15 minutes).
  final int expiresIn;

  /// Suggested seconds between polls.
  final int interval;
}

/// Account info from `GET /users/settings`, shown before the import starts so
/// the user can verify the browser session matched the expected account.
class SimklUser {
  const SimklUser({required this.name, this.accountId});

  factory SimklUser.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? user = json['user'] as Map<String, dynamic>?;
    final Map<String, dynamic>? account =
        json['account'] as Map<String, dynamic>?;
    return SimklUser(
      name: (user?['name'] as String?) ?? '',
      accountId: (account?['id'] as num?)?.toInt(),
    );
  }

  final String name;
  final int? accountId;
}

/// External ids attached to a Simkl entry. Simkl sends most of them as JSON
/// strings ("tmdb": "324346"), so everything is parsed tolerantly.
class SimklIds {
  const SimklIds({
    this.simkl,
    this.slug,
    this.tmdb,
    this.imdb,
    this.kitsu,
    this.mal,
    this.anidb,
    this.anilist,
  });

  factory SimklIds.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SimklIds();
    int? asInt(String key) {
      final Object? value = json[key];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return SimklIds(
      simkl: asInt('simkl'),
      slug: json['slug'] as String?,
      tmdb: asInt('tmdb'),
      imdb: json['imdb'] as String?,
      kitsu: asInt('kitsu'),
      mal: asInt('mal'),
      anidb: asInt('anidb'),
      anilist: asInt('anilist'),
    );
  }

  final int? simkl;
  final String? slug;
  final int? tmdb;
  final String? imdb;
  final int? kitsu;
  final int? mal;
  final int? anidb;
  final int? anilist;
}

/// A single watched-episode mark inside a Simkl season.
class SimklEpisodeMark {
  const SimklEpisodeMark({required this.number, this.watchedAt});

  final int number;
  final DateTime? watchedAt;
}

/// A season block from `episode_watched_at=yes`. For anime Simkl always sends
/// a single season `number: 1` with absolute episode numbers.
class SimklSeason {
  const SimklSeason({required this.number, required this.episodes});

  final int number;
  final List<SimklEpisodeMark> episodes;
}

/// One entry of `GET /sync/all-items` (a movie, a show, or an anime).
class SimklEntry {
  const SimklEntry({
    required this.title,
    required this.status,
    required this.ids,
    this.year,
    this.userRating,
    this.lastWatchedAt,
    this.addedToWatchlistAt,
    this.watchedEpisodesCount = 0,
    this.totalEpisodesCount = 0,
    this.memoText,
    this.animeType,
    this.seasons = const <SimklSeason>[],
  });

  factory SimklEntry.fromJson(Map<String, dynamic> json) {
    // Movies nest the title object under `movie`; shows AND anime under
    // `show` (anime is distinguished only by the section + `anime_type`).
    final Map<String, dynamic> media =
        (json['movie'] ?? json['show']) as Map<String, dynamic>? ??
            <String, dynamic>{};

    DateTime? date(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;

    final Object? memo = json['memo'];
    final String? memoText =
        memo is Map<String, dynamic> ? memo['text'] as String? : null;

    final List<SimklSeason> seasons = <SimklSeason>[
      for (final Map<String, dynamic> season
          in ((json['seasons'] as List<dynamic>?) ?? <dynamic>[])
              .whereType<Map<String, dynamic>>())
        SimklSeason(
          number: (season['number'] as num?)?.toInt() ?? 1,
          episodes: <SimklEpisodeMark>[
            for (final Map<String, dynamic> episode
                in ((season['episodes'] as List<dynamic>?) ?? <dynamic>[])
                    .whereType<Map<String, dynamic>>())
              if (episode['number'] is num)
                SimklEpisodeMark(
                  number: (episode['number'] as num).toInt(),
                  watchedAt: date(episode['watched_at']),
                ),
          ],
        ),
    ];

    return SimklEntry(
      title: (media['title'] as String?) ?? '',
      year: (media['year'] as num?)?.toInt(),
      status: (json['status'] as String?) ?? '',
      ids: SimklIds.fromJson(media['ids'] as Map<String, dynamic>?),
      userRating: (json['user_rating'] as num?)?.toInt(),
      lastWatchedAt: date(json['last_watched_at']),
      addedToWatchlistAt: date(json['added_to_watchlist_at']),
      watchedEpisodesCount:
          (json['watched_episodes_count'] as num?)?.toInt() ?? 0,
      totalEpisodesCount:
          (json['total_episodes_count'] as num?)?.toInt() ?? 0,
      memoText: (memoText != null && memoText.trim().isNotEmpty)
          ? memoText.trim()
          : null,
      animeType: json['anime_type'] as String?,
      seasons: seasons,
    );
  }

  final String title;
  final int? year;

  /// Raw Simkl status: watching / plantowatch / completed / hold / dropped.
  final String status;

  /// [status] with casing and stray spacing normalized — Simkl is consistent
  /// in practice, but every comparison goes through this to stay safe.
  String get normalizedStatus => status.toLowerCase().trim();

  bool get isCompleted => normalizedStatus == 'completed';

  /// Simkl's "on hold"; our ItemStatus has no equivalent, so the importer
  /// stores these as planned plus a tag.
  bool get isOnHold => normalizedStatus == 'hold';

  final SimklIds ids;

  /// 1–10, null when unrated.
  final int? userRating;

  final DateTime? lastWatchedAt;
  final DateTime? addedToWatchlistAt;
  final int watchedEpisodesCount;
  final int totalEpisodesCount;

  /// User note from Simkl (`memos=yes`), null when absent or blank.
  final String? memoText;

  /// Only present in the anime section (`tv`, `movie`, `ova`, ...).
  final String? animeType;

  /// Per-episode watch marks; empty when the user never checked episodes.
  final List<SimklSeason> seasons;

  bool get hasEpisodeMarks =>
      seasons.any((SimklSeason s) => s.episodes.isNotEmpty);
}

/// The three sections of `GET /sync/all-items`.
class SimklAllItems {
  const SimklAllItems({
    required this.movies,
    required this.shows,
    required this.anime,
  });

  factory SimklAllItems.fromJson(Map<String, dynamic> json) {
    List<SimklEntry> section(String key) => <SimklEntry>[
          for (final Map<String, dynamic> row
              in ((json[key] as List<dynamic>?) ?? <dynamic>[])
                  .whereType<Map<String, dynamic>>())
            SimklEntry.fromJson(row),
        ];

    return SimklAllItems(
      movies: section('movies'),
      shows: section('shows'),
      anime: section('anime'),
    );
  }

  final List<SimklEntry> movies;
  final List<SimklEntry> shows;
  final List<SimklEntry> anime;

  bool get isEmpty => movies.isEmpty && shows.isEmpty && anime.isEmpty;

  int get totalCount => movies.length + shows.length + anime.length;
}
