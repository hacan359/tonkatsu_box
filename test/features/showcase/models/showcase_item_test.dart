import 'package:core/models/anime.dart';
import 'package:core/testing/builders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/showcase/models/showcase_item.dart';

void main() {
  group('ShowcaseItem', () {
    group('fromAnime', () {
      test('counts down to the next episode when AniList has one', () {
        const int airingAt = 1789000000;
        const Anime anime = Anime(
          id: 1,
          title: 'Airing',
          nextAiringEpisode: 5,
          nextAiringAt: airingAt,
          startYear: 2026,
          startMonth: 7,
          startDay: 3,
          episodes: 12,
          duration: 24,
          format: 'TV',
          studios: <String>['MAPPA'],
        );

        final ShowcaseItem item = ShowcaseItem.fromAnime(anime, 'romaji');

        expect(
          item.nextDate,
          DateTime.fromMillisecondsSinceEpoch(airingAt * 1000),
        );
        expect(item.nextEpisode, 5);
        expect(item.hasTimeOfDay, isTrue);
        expect(item.formatLabel, 'TV');
        expect(item.episodes, 12);
        expect(item.durationMinutes, 24);
        expect(item.creator, 'MAPPA');
      });

      test('falls back to the premiere date without a next episode', () {
        const Anime anime = Anime(
          id: 1,
          title: 'Upcoming',
          nextAiringEpisode: 1,
          startYear: 2026,
          startMonth: 10,
          startDay: 4,
        );

        final ShowcaseItem item = ShowcaseItem.fromAnime(anime, 'romaji');

        expect(item.nextDate, DateTime(2026, 10, 4));
        // An episode number without its timestamp is not a countdown.
        expect(item.nextEpisode, isNull);
        expect(item.hasTimeOfDay, isFalse);
      });

      test('a partial start date is no date', () {
        const Anime anime =
            Anime(id: 1, title: 'TBA', startYear: 2026, startMonth: 10);

        expect(ShowcaseItem.fromAnime(anime, 'romaji').nextDate, isNull);
      });

      test('genres default to an empty list', () {
        expect(
          ShowcaseItem.fromAnime(createTestAnime(), 'romaji').genres,
          isEmpty,
        );
      });
    });

    group('fromMovie', () {
      test('takes the full release date from the feed', () {
        final ShowcaseItem item = ShowcaseItem.fromMovie(
          createTestMovie(overview: 'Plot', genres: <String>['Drama']),
          releaseDate: '2026-09-25',
        );

        expect(item.nextDate, DateTime(2026, 9, 25));
        expect(item.hasTimeOfDay, isFalse);
        expect(item.description, 'Plot');
        expect(item.genres, <String>['Drama']);
      });

      test('no feed date means no countdown', () {
        expect(ShowcaseItem.fromMovie(createTestMovie()).nextDate, isNull);
      });
    });

    group('fromTvShow', () {
      test('carries the next episode when the details call found one', () {
        final ShowcaseItem item = ShowcaseItem.fromTvShow(
          createTestTvShow(),
          nextAirDate: '2026-09-16',
          nextSeason: 4,
          nextEpisode: 8,
        );

        expect(item.nextDate, DateTime(2026, 9, 16));
        expect(item.nextSeason, 4);
        expect(item.nextEpisode, 8);
        expect(item.hasTimeOfDay, isFalse);
      });

      test('drops the episode numbers when there is no air date', () {
        final ShowcaseItem item = ShowcaseItem.fromTvShow(
          createTestTvShow(),
          nextSeason: 4,
          nextEpisode: 8,
        );

        expect(item.nextDate, isNull);
        expect(item.nextSeason, isNull);
        expect(item.nextEpisode, isNull);
      });
    });

    test('fromGame uses the IGDB release date', () {
      final DateTime release = DateTime(2026, 11, 20);
      final ShowcaseItem item =
          ShowcaseItem.fromGame(createTestGame(releaseDate: release));

      expect(item.nextDate, release);
    });

    test('fromAudio parses the first release date and credits artists', () {
      final ShowcaseItem item = ShowcaseItem.fromAudio(
        createTestAudioItem(
          firstReleaseDate: '2026-09-12',
          artists: <String>['A', 'B'],
        ),
      );

      expect(item.nextDate, DateTime(2026, 9, 12));
      expect(item.creator, 'A, B');
    });

    group('ISO date parsing', () {
      DateTime? parse(String? date) =>
          ShowcaseItem.fromMovie(createTestMovie(), releaseDate: date).nextDate;

      test('accepts a full date and ignores a time tail', () {
        expect(parse('2026-09-12'), DateTime(2026, 9, 12));
        expect(parse('2026-09-12T10:00:00Z'), DateTime(2026, 9, 12));
      });

      test('rejects partial dates, garbage and null', () {
        expect(parse('2026'), isNull);
        expect(parse('2026-09'), isNull);
        expect(parse('not-a-date!'), isNull);
        expect(parse(null), isNull);
      });
    });

    test('ratings land on one 0-10 scale whatever the source uses', () {
      expect(
        ShowcaseItem.fromGame(createTestGame(rating: 87)).rating,
        closeTo(8.7, 0.001),
      );
      expect(
        ShowcaseItem.fromAnime(createTestAnime(averageScore: 86), 'romaji')
            .rating,
        closeTo(8.6, 0.001),
      );
      expect(ShowcaseItem.fromGame(createTestGame()).rating, isNull);
    });
  });
}
