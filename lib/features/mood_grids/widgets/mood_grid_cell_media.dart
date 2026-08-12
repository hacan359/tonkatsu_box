import 'package:core/models/album.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/mood_grid_cell.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';

/// Minimal display payload for a cell, resolved from the global `*_cache`
/// tables — removing the item from a collection doesn't affect rendering.
class MoodGridCellMedia {
  const MoodGridCellMedia({
    required this.title,
    required this.coverUrl,
    required this.imageType,
    required this.placeholderIcon,
    this.year,
    this.genre,
    this.rating,
  });

  /// Empty payload — used as a stable fallback when no media reference
  /// resolves. Callers can check [title] / [coverUrl] for null.
  static const MoodGridCellMedia empty = MoodGridCellMedia(
    title: null,
    coverUrl: null,
    imageType: ImageType.gameCover,
    placeholderIcon: Icons.image_outlined,
  );

  final String? title;
  final String? coverUrl;
  final ImageType imageType;
  final IconData placeholderIcon;

  /// Release year (game / movie / show / VN / anime / manga / custom).
  final int? year;

  /// Comma-joined genre list. Empty → null.
  final String? genre;

  /// Rating normalised to a 0–10 scale with one decimal of precision.
  final double? rating;
}

/// Resolves media for all [cells] with one `IN (...)` query per media type.
/// Keyed by position; empty cells map to [MoodGridCellMedia.empty].
Future<Map<int, MoodGridCellMedia>> resolveMoodGridCellMediaBatch(
  DatabaseService db,
  List<MoodGridCell> cells,
) async {
  final List<MoodGridCell> filled =
      cells.where((MoodGridCell c) => !c.isEmpty).toList();
  if (filled.isEmpty) {
    return <int, MoodGridCellMedia>{
      for (final MoodGridCell c in cells) c.position: MoodGridCellMedia.empty,
    };
  }

  final List<int> gameIds = _idsOf(filled, MediaType.game);
  final List<int> animeIds = _idsOf(filled, MediaType.anime);
  final List<int> mangaIds = _idsOf(filled, MediaType.manga);
  final List<int> vnIds = _idsOf(filled, MediaType.visualNovel);
  final List<int> bookIds = _idsOf(filled, MediaType.book);
  final List<int> albumIds = _idsOf(filled, MediaType.music);
  final List<int> customIds = _idsOf(filled, MediaType.custom);

  // Animation cells resolve against movies or tv shows depending on their
  // AnimationSource; fold them into the matching batch.
  final List<int> movieIds = <int>{
    ..._idsOf(filled, MediaType.movie),
    ...filled
        .where((MoodGridCell c) =>
            c.mediaType == MediaType.animation &&
            c.platformId != AnimationSource.tvShow)
        .map((MoodGridCell c) => c.externalId!),
  }.toList();
  final List<int> tvShowIds = <int>{
    ..._idsOf(filled, MediaType.tvShow),
    ...filled
        .where((MoodGridCell c) =>
            c.mediaType == MediaType.animation &&
            c.platformId == AnimationSource.tvShow)
        .map((MoodGridCell c) => c.externalId!),
  }.toList();

  // Futures created up front so the per-type queries overlap; empty id
  // lists skip the DAO entirely (lambdas keep the dao access lazy).
  final Future<List<Game>> gamesF =
      _fetch(gameIds, (List<int> ids) => db.gameDao.getGamesByIds(ids));
  final Future<List<Movie>> moviesF =
      _fetch(movieIds, (List<int> ids) => db.movieDao.getMoviesByTmdbIds(ids));
  final Future<List<TvShow>> tvShowsF = _fetch(
      tvShowIds, (List<int> ids) => db.tvShowDao.getTvShowsByTmdbIds(ids));
  final Future<List<Anime>> animeF =
      _fetch(animeIds, (List<int> ids) => db.animeDao.getAnimeByIds(ids));
  final Future<List<Manga>> mangaF =
      _fetch(mangaIds, (List<int> ids) => db.mangaDao.getMangaByIds(ids));
  final Future<List<VisualNovel>> vnsF = _fetch(vnIds,
      (List<int> ids) => db.visualNovelDao.getVisualNovelsByNumericIds(ids));
  final Future<List<Book>> booksF =
      _fetch(bookIds, (List<int> ids) => db.bookDao.getBooksByIds(ids));
  final Future<List<Album>> albumsF =
      _fetch(albumIds, (List<int> ids) => db.albumDao.getAlbumsByIds(ids));
  final Future<List<CustomMedia>> customsF =
      _fetch(customIds, (List<int> ids) => db.customMediaDao.getByIds(ids));

  final Map<int, Game> games = <int, Game>{
    for (final Game g in await gamesF) g.id: g,
  };
  final Map<(int, DataSource), Movie> movies = <(int, DataSource), Movie>{
    for (final Movie m in await moviesF) (m.tmdbId, m.source): m,
  };
  final Map<(int, DataSource), TvShow> tvShows = <(int, DataSource), TvShow>{
    for (final TvShow t in await tvShowsF) (t.tmdbId, t.source): t,
  };
  final Map<(int, DataSource), Anime> anime = <(int, DataSource), Anime>{
    for (final Anime a in await animeF) (a.id, a.source): a,
  };
  final Map<(int, DataSource), Manga> manga = <(int, DataSource), Manga>{
    for (final Manga m in await mangaF) (m.id, m.source): m,
  };
  final Map<int, VisualNovel> vns = <int, VisualNovel>{
    for (final VisualNovel v in await vnsF) v.numericId: v,
  };
  final Map<(int, DataSource), Book> books = <(int, DataSource), Book>{
    for (final Book b in await booksF)
      if (int.tryParse(b.id) != null) (int.parse(b.id), b.source): b,
  };
  final Map<(int, DataSource), Album> albums = <(int, DataSource), Album>{
    for (final Album a in await albumsF) (a.id, a.source): a,
  };
  final Map<int, CustomMedia> customs = <int, CustomMedia>{
    for (final CustomMedia c in await customsF) c.id: c,
  };

  MoodGridCellMedia resolve(MoodGridCell cell) {
    final int id = cell.externalId!;
    switch (cell.mediaType!) {
      case MediaType.game:
        return _gameMedia(games[id]);
      case MediaType.movie:
        return _movieMedia(
          movies[(id, cell.source ?? DataSource.tmdb)],
          placeholderIcon: Icons.movie_outlined,
        );
      case MediaType.tvShow:
        return _tvShowMedia(
          tvShows[(id, cell.source ?? DataSource.tmdb)],
          placeholderIcon: Icons.tv_outlined,
        );
      case MediaType.animation:
        if (cell.platformId == AnimationSource.tvShow) {
          return _tvShowMedia(
            tvShows[(id, cell.source ?? DataSource.tmdb)],
            placeholderIcon: Icons.animation,
          );
        }
        return _movieMedia(
          movies[(id, cell.source ?? DataSource.tmdb)],
          placeholderIcon: Icons.animation,
        );
      case MediaType.visualNovel:
        return _visualNovelMedia(vns[id]);
      case MediaType.anime:
        return _animeMedia(anime[(id, cell.source ?? DataSource.anilist)]);
      case MediaType.manga:
        return _mangaMedia(manga[(id, cell.source ?? DataSource.anilist)]);
      case MediaType.book:
        return _bookMedia(books[(id, cell.source ?? DataSource.openLibrary)]);
      case MediaType.music:
        return _albumMedia(albums[(id, cell.source ?? DataSource.musicBrainz)]);
      case MediaType.custom:
        return _customMedia(customs[id]);
    }
  }

  return <int, MoodGridCellMedia>{
    for (final MoodGridCell c in cells)
      c.position: c.isEmpty ? MoodGridCellMedia.empty : resolve(c),
  };
}

List<int> _idsOf(List<MoodGridCell> cells, MediaType type) {
  return cells
      .where((MoodGridCell c) => c.mediaType == type)
      .map((MoodGridCell c) => c.externalId!)
      .toSet()
      .toList();
}

Future<List<T>> _fetch<T>(
  List<int> ids,
  Future<List<T>> Function(List<int>) query,
) {
  return ids.isEmpty ? Future<List<T>>.value(<T>[]) : query(ids);
}

MoodGridCellMedia _gameMedia(Game? game) {
  return MoodGridCellMedia(
    title: game?.name,
    coverUrl: game?.coverUrl,
    imageType: ImageType.gameCover,
    placeholderIcon: Icons.videogame_asset,
    year: game?.releaseDate?.year,
    genre: _joinGenres(game?.genres),
    // IGDB rating is 0–100 → normalise to 0–10.
    rating: game?.rating != null ? game!.rating! / 10.0 : null,
  );
}

MoodGridCellMedia _movieMedia(
  Movie? movie, {
  required IconData placeholderIcon,
}) {
  return MoodGridCellMedia(
    title: movie?.title,
    coverUrl: movie?.posterUrl,
    imageType: ImageType.moviePoster,
    placeholderIcon: placeholderIcon,
    year: movie?.releaseYear,
    genre: _joinGenres(movie?.genres),
    rating: movie?.rating,
  );
}

MoodGridCellMedia _tvShowMedia(
  TvShow? tvShow, {
  required IconData placeholderIcon,
}) {
  return MoodGridCellMedia(
    title: tvShow?.title,
    coverUrl: tvShow?.posterUrl,
    imageType: ImageType.tvShowPoster,
    placeholderIcon: placeholderIcon,
    year: tvShow?.firstAirYear,
    genre: _joinGenres(tvShow?.genres),
    rating: tvShow?.rating,
  );
}

MoodGridCellMedia _visualNovelMedia(VisualNovel? vn) {
  return MoodGridCellMedia(
    title: vn?.title,
    coverUrl: vn?.imageUrl,
    imageType: ImageType.vnCover,
    placeholderIcon: Icons.menu_book,
    year: _yearFromVndbDate(vn?.released),
    genre: _joinGenres(vn?.tags),
    rating: vn?.rating10,
  );
}

MoodGridCellMedia _animeMedia(Anime? anime) {
  return MoodGridCellMedia(
    title: anime?.title,
    coverUrl: anime?.coverUrl,
    imageType: ImageType.animeCover,
    placeholderIcon: Icons.play_circle_outline,
    year: anime?.seasonYear ?? anime?.startYear,
    genre: _joinGenres(anime?.genres),
    rating: anime?.rating10,
  );
}

MoodGridCellMedia _mangaMedia(Manga? manga) {
  return MoodGridCellMedia(
    title: manga?.title,
    coverUrl: manga?.coverUrl,
    imageType: ImageType.mangaCover,
    placeholderIcon: Icons.auto_stories,
    year: manga?.startYear,
    genre: _joinGenres(manga?.genres),
    rating: manga?.rating10,
  );
}

MoodGridCellMedia _bookMedia(Book? book) {
  return MoodGridCellMedia(
    title: book?.title,
    coverUrl: book?.coverUrl,
    imageType: ImageType.bookCover,
    placeholderIcon: Icons.menu_book,
    year: book?.publishYear,
    genre: _joinGenres(book?.subjects),
    rating: book?.rating,
  );
}

MoodGridCellMedia _albumMedia(Album? album) {
  return MoodGridCellMedia(
    title: album?.title,
    coverUrl: album?.coverUrl,
    imageType: ImageType.albumCover,
    placeholderIcon: Icons.album_outlined,
    year: album?.releaseYear,
    genre: _joinGenres(album?.genres),
    rating: album?.rating,
  );
}

MoodGridCellMedia _customMedia(CustomMedia? custom) {
  return MoodGridCellMedia(
    title: custom?.title,
    coverUrl: custom?.coverUrl,
    imageType: ImageType.customCover,
    placeholderIcon: Icons.bookmark_outline,
    year: custom?.year,
    genre: _normaliseCustomGenres(custom?.genres),
  );
}

String? _joinGenres(List<String>? genres) {
  if (genres == null || genres.isEmpty) return null;
  return genres.join(', ');
}

String? _normaliseCustomGenres(String? genres) {
  if (genres == null) return null;
  final String trimmed = genres.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// VNDB releases are stored as `YYYY-MM-DD` or `YYYY-MM` or `YYYY`.
int? _yearFromVndbDate(String? raw) {
  if (raw == null || raw.length < 4) return null;
  return int.tryParse(raw.substring(0, 4));
}
