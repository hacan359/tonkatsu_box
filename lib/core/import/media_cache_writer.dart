import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/game.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_service.dart';

final Provider<MediaCacheWriter> mediaCacheWriterProvider =
    Provider<MediaCacheWriter>(
  (Ref ref) => MediaCacheWriter(ref.watch(databaseServiceProvider)),
);

/// One batched upsert per media table, whatever mix of models an import
/// resolved; the DAOs stay the only writers.
class MediaCacheWriter {
  const MediaCacheWriter(this._db);

  final DatabaseService _db;

  Future<void> upsertAll(List<Object> media) async {
    final List<Movie> movies = <Movie>[];
    final List<TvShow> shows = <TvShow>[];
    final List<Game> games = <Game>[];
    final List<Anime> animes = <Anime>[];
    final List<Manga> mangas = <Manga>[];
    final List<Book> books = <Book>[];
    final List<VisualNovel> vns = <VisualNovel>[];
    for (final Object item in media) {
      switch (item) {
        case final Movie m:
          movies.add(m);
        case final TvShow s:
          shows.add(s);
        case final Game g:
          games.add(g);
        case final Anime a:
          animes.add(a);
        case final Manga m:
          mangas.add(m);
        case final Book b:
          books.add(b);
        case final VisualNovel v:
          vns.add(v);
        default:
          throw ArgumentError.value(item, 'media', 'Unsupported media model');
      }
    }
    if (movies.isNotEmpty) await _db.movieDao.upsertMovies(movies);
    if (shows.isNotEmpty) await _db.tvShowDao.upsertTvShows(shows);
    if (games.isNotEmpty) await _db.gameDao.upsertGames(games);
    if (animes.isNotEmpty) await _db.animeDao.upsertAnimes(animes);
    if (mangas.isNotEmpty) await _db.mangaDao.upsertMangas(mangas);
    if (books.isNotEmpty) await _db.bookDao.upsertBooks(books);
    if (vns.isNotEmpty) await _db.visualNovelDao.upsertVisualNovels(vns);
  }
}
