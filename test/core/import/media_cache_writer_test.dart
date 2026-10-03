import 'package:core/models/anime.dart';
import 'package:core/models/game.dart';
import 'package:core/models/movie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/import/media_cache_writer.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService db;
  late MockMovieDao movieDao;
  late MockTvShowDao tvShowDao;
  late MockGameDao gameDao;
  late MockAnimeDao animeDao;
  late MockMangaDao mangaDao;
  late MockBookDao bookDao;
  late MockVisualNovelDao vnDao;
  late MediaCacheWriter sut;

  setUp(() {
    db = MockDatabaseService();
    movieDao = MockMovieDao();
    tvShowDao = MockTvShowDao();
    gameDao = MockGameDao();
    animeDao = MockAnimeDao();
    mangaDao = MockMangaDao();
    bookDao = MockBookDao();
    vnDao = MockVisualNovelDao();
    when(() => db.movieDao).thenReturn(movieDao);
    when(() => db.tvShowDao).thenReturn(tvShowDao);
    when(() => db.gameDao).thenReturn(gameDao);
    when(() => db.animeDao).thenReturn(animeDao);
    when(() => db.mangaDao).thenReturn(mangaDao);
    when(() => db.bookDao).thenReturn(bookDao);
    when(() => db.visualNovelDao).thenReturn(vnDao);
    when(() => movieDao.upsertMovies(any())).thenAnswer((_) async {});
    when(() => gameDao.upsertGames(any())).thenAnswer((_) async {});
    when(() => animeDao.upsertAnimes(any())).thenAnswer((_) async {});
    sut = MediaCacheWriter(db);
  });

  group('MediaCacheWriter', () {
    group('upsertAll', () {
      test('routes a mixed list to one batched upsert per table', () async {
        final Movie m1 = createTestMovie(tmdbId: 1);
        final Movie m2 = createTestMovie(tmdbId: 2);
        final Game g = createTestGame(id: 3);
        final Anime a = createTestAnime(id: 4);

        await sut.upsertAll(<Object>[m1, g, m2, a]);

        verify(() => movieDao.upsertMovies(<Movie>[m1, m2])).called(1);
        verify(() => gameDao.upsertGames(<Game>[g])).called(1);
        verify(() => animeDao.upsertAnimes(<Anime>[a])).called(1);
        verifyNever(() => tvShowDao.upsertTvShows(any()));
        verifyNever(() => mangaDao.upsertMangas(any()));
        verifyNever(() => bookDao.upsertBooks(any()));
        verifyNever(() => vnDao.upsertVisualNovels(any()));
      });

      test('an empty list touches no table', () async {
        await sut.upsertAll(const <Object>[]);

        verifyNever(() => movieDao.upsertMovies(any()));
        verifyNever(() => gameDao.upsertGames(any()));
      });

      test('an unsupported model is an argument error', () {
        expect(
          () => sut.upsertAll(<Object>['text']),
          throwsArgumentError,
        );
      });
    });
  });
}
