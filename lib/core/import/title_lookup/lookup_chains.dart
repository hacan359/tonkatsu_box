import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/providers/settings_provider.dart';
import '../../../shared/constants/api_defaults.dart';
import '../../api/anilist_api.dart';
import '../../api/fantlab_api.dart';
import '../../api/google_books_api.dart';
import '../../api/hardcover_api.dart';
import '../../api/igdb_api.dart';
import '../../api/kitsu_api.dart';
import '../../api/mangabaka_api.dart';
import '../../api/mangadex_api.dart';
import '../../api/openlibrary_api.dart';
import '../../api/tmdb_api.dart';
import '../../api/tvdb_api.dart';
import '../../api/tvmaze_api.dart';
import '../../api/vndb_api.dart';
import '../tmdb_matcher.dart';
import 'lookup_candidate.dart';

final Provider<LookupChains> lookupChainsProvider =
    Provider<LookupChains>((Ref ref) {
  return LookupChains(
    keys: LookupKeys.fromSettings(ref.watch(settingsNotifierProvider)),
    tmdb: ref.watch(tmdbApiProvider),
    tvdb: ref.watch(tvdbApiProvider),
    tvmaze: ref.watch(tvMazeApiProvider),
    igdb: ref.watch(igdbApiProvider),
    kitsu: ref.watch(kitsuApiProvider),
    anilist: ref.watch(aniListApiProvider),
    mangadex: ref.watch(mangaDexApiProvider),
    mangabaka: ref.watch(mangaBakaApiProvider),
    vndb: ref.watch(vndbApiProvider),
    openLibrary: ref.watch(openLibraryApiProvider),
    googleBooks: ref.watch(googleBooksApiProvider),
    hardcover: ref.watch(hardcoverApiProvider),
    fantlab: ref.watch(fantlabApiProvider),
  );
});

/// Which keyed sources can be asked; the keyless ones are always on.
class LookupKeys {
  const LookupKeys({
    required this.tmdb,
    required this.tvdb,
    required this.igdb,
    required this.hardcover,
  });

  factory LookupKeys.fromSettings(SettingsState settings) => LookupKeys(
        tmdb: settings.hasTmdbKey || ApiDefaults.hasTmdbKey,
        tvdb: settings.hasTvdbKey || ApiDefaults.hasTvdbKey,
        igdb: settings.hasCredentials || ApiDefaults.hasIgdbKey,
        hardcover: settings.hasHardcoverKey,
      );

  final bool tmdb;
  final bool tvdb;
  final bool igdb;
  final bool hardcover;
}

/// Per-type source order for the custom cards import. It differs from the
/// search screen's registry on purpose (anime asks Kitsu first).
class LookupChains {
  const LookupChains({
    required LookupKeys keys,
    required TmdbApi tmdb,
    required TvdbApi tvdb,
    required TvMazeApi tvmaze,
    required IgdbApi igdb,
    required KitsuApi kitsu,
    required AniListApi anilist,
    required MangaDexApi mangadex,
    required MangaBakaApi mangabaka,
    required VndbApi vndb,
    required OpenLibraryApi openLibrary,
    required GoogleBooksApi googleBooks,
    required HardcoverApi hardcover,
    required FantlabApi fantlab,
  })  : _keys = keys,
        _tmdb = tmdb,
        _tvdb = tvdb,
        _tvmaze = tvmaze,
        _igdb = igdb,
        _kitsu = kitsu,
        _anilist = anilist,
        _mangadex = mangadex,
        _mangabaka = mangabaka,
        _vndb = vndb,
        _openLibrary = openLibrary,
        _googleBooks = googleBooks,
        _hardcover = hardcover,
        _fantlab = fantlab;

  static final RegExp _cyrillic = RegExp('[Ѐ-ӿ]');

  final LookupKeys _keys;
  final TmdbApi _tmdb;
  final TvdbApi _tvdb;
  final TvMazeApi _tvmaze;
  final IgdbApi _igdb;
  final KitsuApi _kitsu;
  final AniListApi _anilist;
  final MangaDexApi _mangadex;
  final MangaBakaApi _mangabaka;
  final VndbApi _vndb;
  final OpenLibraryApi _openLibrary;
  final GoogleBooksApi _googleBooks;
  final HardcoverApi _hardcover;
  final FantlabApi _fantlab;

  List<LookupSource> chainFor(MediaType type, String title) {
    switch (type) {
      case MediaType.movie:
        return <LookupSource>[
          if (_keys.tmdb) _tmdbMovies,
          if (_keys.tvdb) _tvdbMovies,
        ];
      case MediaType.tvShow:
        return <LookupSource>[
          if (_keys.tmdb) _tmdbShows,
          _tvmazeShows,
          if (_keys.tvdb) _tvdbSeries,
        ];
      case MediaType.animation:
        return <LookupSource>[if (_keys.tmdb) _tmdbAnimation];
      case MediaType.game:
        return <LookupSource>[if (_keys.igdb) _igdbGames];
      case MediaType.anime:
        return <LookupSource>[_kitsuAnime, _anilistAnime];
      case MediaType.manga:
        return <LookupSource>[
          _anilistManga,
          _mangadexManga,
          _mangabakaManga,
          _kitsuManga,
        ];
      case MediaType.visualNovel:
        return <LookupSource>[_vndbNovels];
      case MediaType.book:
        return <LookupSource>[
          if (_cyrillic.hasMatch(title)) _fantlabBooks,
          _openLibraryBooks,
          _googleBooksBooks,
          if (_keys.hardcover) _hardcoverBooks,
        ];
      case MediaType.audio:
      case MediaType.custom:
        return const <LookupSource>[];
    }
  }

  LookupSource get _tmdbMovies => LookupSource(
        source: DataSource.tmdb,
        isRateLimit: _tmdb429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Movie m in await _tmdb.searchMovies(q.title, year: q.year))
            _movie(m, MediaType.movie),
        ],
      );

  LookupSource get _tmdbShows => LookupSource(
        source: DataSource.tmdb,
        isRateLimit: _tmdb429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final TvShow s
              in await _tmdb.searchTvShows(q.title, firstAirDateYear: q.year))
            _show(s, MediaType.tvShow),
        ],
      );

  /// Movies and series in one list: a file row says "animation", not which.
  LookupSource get _tmdbAnimation => LookupSource(
        source: DataSource.tmdb,
        isRateLimit: _tmdb429,
        // Sequential: `.wait` wraps a 429 in ParallelWaitError, which the
        // retry would not recognise as a rate limit.
        search: (TitleQuery q) async {
          final List<Movie> movies =
              await _tmdb.searchMovies(q.title, year: q.year);
          final List<TvShow> shows =
              await _tmdb.searchTvShows(q.title, firstAirDateYear: q.year);
          return <LookupCandidate>[
            for (final Movie m in movies)
              if (TmdbMatcher.isAnimationByGenres(m.genres))
                _movie(m, MediaType.animation),
            for (final TvShow s in shows)
              if (TmdbMatcher.isAnimationByGenres(s.genres))
                _show(s, MediaType.animation),
          ];
        },
      );

  LookupSource get _tvdbMovies => LookupSource(
        source: DataSource.tvdb,
        isRateLimit: (Object e) => e is TvdbApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Movie m in await _tvdb.searchMovies(q.title, year: q.year))
            _movie(m, MediaType.movie),
        ],
      );

  LookupSource get _tvdbSeries => LookupSource(
        source: DataSource.tvdb,
        isRateLimit: (Object e) => e is TvdbApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final TvShow s in await _tvdb.searchSeries(q.title, year: q.year))
            _show(s, MediaType.tvShow),
        ],
      );

  LookupSource get _tvmazeShows => LookupSource(
        source: DataSource.tvmaze,
        isRateLimit: (Object e) =>
            e is TvMazeApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final TvShow s in await _tvmaze.searchShows(q.title))
            _show(s, MediaType.tvShow),
        ],
      );

  LookupSource get _igdbGames => LookupSource(
        source: DataSource.igdb,
        isRateLimit: (Object e) => e is IgdbApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Game g in await _igdb.searchGames(
            query: q.title,
            platformIds: q.platformId != null ? <int>[q.platformId!] : null,
          ))
            LookupCandidate(
              media: g,
              mediaType: MediaType.game,
              externalId: g.id,
              source: DataSource.igdb,
              titles: <String?>[g.name],
              year: g.releaseYear,
              platformIds: g.platformIds ?? const <int>[],
              coverUrl: g.coverUrl,
            ),
        ],
      );

  LookupSource get _kitsuAnime => LookupSource(
        source: DataSource.kitsu,
        isRateLimit: _kitsu429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Anime a in (await _kitsu.browseAnime(query: q.title)).$1)
            _anime(a),
        ],
      );

  LookupSource get _kitsuManga => LookupSource(
        source: DataSource.kitsu,
        isRateLimit: _kitsu429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Manga m in (await _kitsu.browseManga(query: q.title)).$1)
            _manga(m),
        ],
      );

  LookupSource get _anilistAnime => LookupSource(
        source: DataSource.anilist,
        isRateLimit: _anilist429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Anime a in (await _anilist.browseAnime(query: q.title)).$1)
            _anime(a),
        ],
      );

  LookupSource get _anilistManga => LookupSource(
        source: DataSource.anilist,
        isRateLimit: _anilist429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Manga m in (await _anilist.searchManga(query: q.title)).$1)
            _manga(m),
        ],
      );

  LookupSource get _mangadexManga => LookupSource(
        source: DataSource.mangadex,
        isRateLimit: (Object e) =>
            e is MangaDexApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Manga m
              in (await _mangadex.browseManga(query: q.title)).$1)
            _manga(m),
        ],
      );

  LookupSource get _mangabakaManga => LookupSource(
        source: DataSource.mangabaka,
        isRateLimit: (Object e) =>
            e is MangaBakaApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Manga m
              in (await _mangabaka.browseManga(query: q.title)).$1)
            _manga(m),
        ],
      );

  LookupSource get _vndbNovels => LookupSource(
        source: DataSource.vndb,
        isRateLimit: (Object e) => e is VndbApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final VisualNovel v in (await _vndb.searchVn(query: q.title)).$1)
            LookupCandidate(
              media: v,
              mediaType: MediaType.visualNovel,
              externalId: v.numericId,
              source: DataSource.vndb,
              titles: <String?>[v.title, v.altTitle],
              year: v.releaseYear,
              coverUrl: v.imageUrl,
            ),
        ],
      );

  LookupSource get _openLibraryBooks => LookupSource(
        source: DataSource.openLibrary,
        isRateLimit: (Object e) =>
            e is OpenLibraryApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Book b in (await _openLibrary.search(query: q.title)).$1)
            _book(b),
        ],
      );

  LookupSource get _googleBooksBooks => LookupSource(
        source: DataSource.googleBooks,
        isRateLimit: (Object e) =>
            e is GoogleBooksApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Book b in (await _googleBooks.searchVolumes(q.title)).$1)
            _book(b),
        ],
      );

  LookupSource get _hardcoverBooks => LookupSource(
        source: DataSource.hardcover,
        isRateLimit: (Object e) => e is HardcoverRateLimitException,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Book b in (await _hardcover.searchBooks(q.title)).$1)
            _book(b),
        ],
      );

  LookupSource get _fantlabBooks => LookupSource(
        source: DataSource.fantlab,
        isRateLimit: (Object e) =>
            e is FantlabApiException && e.statusCode == 429,
        search: (TitleQuery q) async => <LookupCandidate>[
          for (final Book b in (await _fantlab.searchWorks(query: q.title)).$1)
            _book(b),
        ],
      );

  static bool _tmdb429(Object e) =>
      e is TmdbApiException && e.statusCode == 429;

  static bool _kitsu429(Object e) =>
      e is KitsuApiException && e.statusCode == 429;

  static bool _anilist429(Object e) => e is AniListRateLimitException;

  // Ids and sources below mirror what the search screen's add writes, so a
  // later search recognises the imported item as already in the collection.
  static LookupCandidate _movie(Movie m, MediaType type) => LookupCandidate(
        media: m,
        mediaType: type,
        externalId: m.tmdbId,
        source: m.source,
        titles: <String?>[m.title, m.originalTitle],
        year: m.releaseYear,
        platformId: type == MediaType.animation ? AnimationSource.movie : null,
        coverUrl: m.posterUrl,
      );

  static LookupCandidate _show(TvShow s, MediaType type) => LookupCandidate(
        media: s,
        mediaType: type,
        externalId: s.tmdbId,
        source: s.source,
        titles: <String?>[s.title, s.originalTitle],
        year: s.firstAirYear,
        platformId: type == MediaType.animation ? AnimationSource.tvShow : null,
        coverUrl: s.posterUrl,
      );

  static LookupCandidate _anime(Anime a) => LookupCandidate(
        media: a,
        mediaType: MediaType.anime,
        externalId: a.id,
        source: a.source,
        titles: <String?>[a.title, a.titleEnglish, a.titleNative],
        year: a.releaseYear,
        coverUrl: a.coverUrl,
      );

  static LookupCandidate _manga(Manga m) => LookupCandidate(
        media: m,
        mediaType: MediaType.manga,
        externalId: m.id,
        source: m.source,
        titles: <String?>[m.title, m.titleEnglish, m.titleNative],
        year: m.releaseYear,
        coverUrl: m.coverUrl,
      );

  static LookupCandidate _book(Book b) => LookupCandidate(
        media: b,
        mediaType: MediaType.book,
        externalId: b.externalIdInt,
        source: b.source,
        titles: <String?>[b.title, b.originalTitle],
        year: b.releaseYear,
        coverUrl: b.coverUrl,
      );
}
