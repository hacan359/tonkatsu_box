import 'package:core/models/anime.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/game.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/visual_novel.dart';
import 'package:core/testing/builders.dart';
import 'package:test/test.dart';

void main() {
  group('CollectionItem', () {
    group('releaseDate', () {
      test('a game carries the full IGDB date', () {
        final CollectionItem item = createTestCollectionItem(
          game: Game(id: 1, name: 'G', releaseDate: DateTime(2017, 3, 3)),
        );

        expect(item.releaseDate, DateTime(2017, 3, 3));
      });

      test('a movie has only a year: date is null, year stays', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.movie,
          movie: const Movie(tmdbId: 1, title: 'M', releaseYear: 1999),
        );

        expect(item.releaseDate, isNull);
        expect(item.releaseYear, 1999);
      });

      test('anime is built from start parts, a missing day falls to the 1st',
          () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.anime,
          anime: const Anime(
            id: 1,
            title: 'A',
            startYear: 2006,
            startMonth: 4,
          ),
        );

        expect(item.releaseDate, DateTime(2006, 4));
      });

      test('anime whose season year differs from the start date is year-only',
          () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.anime,
          anime: const Anime(
            id: 1,
            title: 'A',
            seasonYear: 2007,
            startYear: 2006,
            startMonth: 12,
            startDay: 30,
          ),
        );

        expect(item.releaseYear, 2007);
        expect(item.releaseDate, isNull);
      });

      test('manga without a start month is year-only', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: const Manga(id: 1, title: 'M', startYear: 1997),
        );

        expect(item.releaseDate, isNull);
      });

      test('an out-of-range day does not roll into the next month', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: const Manga(
            id: 1,
            title: 'M',
            startYear: 1997,
            startMonth: 7,
            startDay: 40,
          ),
        );

        expect(item.releaseDate, DateTime(1997, 7));
      });

      test('should keep the month when the day exceeds that month length', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: const Manga(
            id: 1,
            title: 'M',
            startYear: 2001,
            startMonth: 2,
            startDay: 30,
          ),
        );

        expect(item.releaseDate, DateTime(2001, 2));
      });

      test('a VNDB date parses both day and month precision', () {
        CollectionItem vn(String released) => createTestCollectionItem(
              mediaType: MediaType.visualNovel,
              visualNovel: VisualNovel(id: 'v1', title: 'V', released: released),
            );

        expect(vn('2004-01-30').releaseDate, DateTime(2004, 1, 30));
        expect(vn('2004-05').releaseDate, DateTime(2004, 5));
        expect(vn('2004').releaseDate, isNull);
        expect(vn('2004-xx').releaseDate, isNull);
      });

      test('an audio release reads the MusicBrainz first release date', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.audio,
          audioItem: createTestAudioItem(firstReleaseDate: '1973-03-01'),
        );

        expect(item.releaseDate, DateTime(1973, 3));
      });

      test('a custom item with a year only is year-only', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.custom,
          customMedia: const CustomMedia(id: 1, title: 'C', year: 2020),
        );

        expect(item.releaseDate, isNull);
        expect(item.releaseYear, 2020);
      });

      test('no release year means no date', () {
        final CollectionItem item = createTestCollectionItem(
          game: const Game(id: 1, name: 'G'),
        );

        expect(item.releaseDate, isNull);
      });
    });
  });
}
