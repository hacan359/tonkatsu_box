import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/simkl/simkl_types.dart';

void main() {
  group('SimklIds', () {
    test('parses ids Simkl sends as strings and as numbers', () {
      final SimklIds ids = SimklIds.fromJson(<String, dynamic>{
        'simkl': 1001,
        'slug': 'fight-club',
        'tmdb': '550',
        'imdb': 'tt0137523',
        'kitsu': '6448',
        'mal': 11061,
        'anidb': '4087',
        'anilist': 11061,
      });

      expect(ids.simkl, 1001);
      expect(ids.slug, 'fight-club');
      expect(ids.tmdb, 550);
      expect(ids.imdb, 'tt0137523');
      expect(ids.kitsu, 6448);
      expect(ids.mal, 11061);
      expect(ids.anidb, 4087);
      expect(ids.anilist, 11061);
    });

    test('leaves unparsable and missing ids null', () {
      final SimklIds ids = SimklIds.fromJson(<String, dynamic>{
        'tmdb': 'not-a-number',
      });

      expect(ids.tmdb, isNull);
      expect(ids.simkl, isNull);
      expect(SimklIds.fromJson(null).tmdb, isNull);
    });
  });

  group('SimklEntry', () {
    test('reads the movie block', () {
      final SimklEntry entry = SimklEntry.fromJson(<String, dynamic>{
        'status': 'completed',
        'user_rating': 8,
        'last_watched_at': '2026-01-02T03:04:05Z',
        'movie': <String, dynamic>{
          'title': 'Fight Club',
          'year': 1999,
          'ids': <String, dynamic>{'tmdb': '550'},
        },
      });

      expect(entry.title, 'Fight Club');
      expect(entry.year, 1999);
      expect(entry.userRating, 8);
      expect(entry.ids.tmdb, 550);
      expect(entry.lastWatchedAt, DateTime.parse('2026-01-02T03:04:05Z'));
      expect(entry.isCompleted, isTrue);
      expect(entry.isOnHold, isFalse);
      expect(entry.hasEpisodeMarks, isFalse);
    });

    test('reads the show block used by both shows and anime', () {
      final SimklEntry entry = SimklEntry.fromJson(<String, dynamic>{
        'status': 'watching',
        'anime_type': 'tv',
        'watched_episodes_count': 4,
        'total_episodes_count': 6,
        'show': <String, dynamic>{'title': 'Bleach'},
      });

      expect(entry.title, 'Bleach');
      expect(entry.animeType, 'tv');
      expect(entry.watchedEpisodesCount, 4);
      expect(entry.totalEpisodesCount, 6);
    });

    test('normalizes the status for comparisons', () {
      SimklEntry withStatus(String status) =>
          SimklEntry.fromJson(<String, dynamic>{'status': status});

      expect(withStatus(' Completed ').isCompleted, isTrue);
      expect(withStatus('HOLD').isOnHold, isTrue);
      expect(withStatus('watching').normalizedStatus, 'watching');
    });

    test('keeps a memo only when it has text', () {
      SimklEntry withMemo(Object? memo) =>
          SimklEntry.fromJson(<String, dynamic>{'memo': memo});

      expect(withMemo(<String, dynamic>{'text': '  note  '}).memoText, 'note');
      expect(withMemo(<String, dynamic>{'text': '   '}).memoText, isNull);
      expect(withMemo(<String, dynamic>{}).memoText, isNull);
      expect(withMemo(null).memoText, isNull);
    });

    test('parses seasons and skips episodes without a number', () {
      final SimklEntry entry = SimklEntry.fromJson(<String, dynamic>{
        'seasons': <Map<String, dynamic>>[
          <String, dynamic>{
            'number': 2,
            'episodes': <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 3,
                'watched_at': '2026-02-03T00:00:00Z',
              },
              <String, dynamic>{'watched_at': '2026-02-04T00:00:00Z'},
            ],
          },
        ],
      });

      expect(entry.seasons, hasLength(1));
      expect(entry.seasons.single.number, 2);
      expect(entry.seasons.single.episodes, hasLength(1));
      expect(entry.seasons.single.episodes.single.number, 3);
      expect(entry.seasons.single.episodes.single.watchedAt,
          DateTime.parse('2026-02-03T00:00:00Z'));
      expect(entry.hasEpisodeMarks, isTrue);
    });

    test('a season with an empty episode list is not an episode mark', () {
      final SimklEntry entry = SimklEntry.fromJson(<String, dynamic>{
        'seasons': <Map<String, dynamic>>[
          <String, dynamic>{'number': 1, 'episodes': <Map<String, dynamic>>[]},
        ],
      });

      expect(entry.hasEpisodeMarks, isFalse);
    });

    test('survives a payload with no media block at all', () {
      final SimklEntry entry = SimklEntry.fromJson(<String, dynamic>{});

      expect(entry.title, isEmpty);
      expect(entry.status, isEmpty);
      expect(entry.ids.tmdb, isNull);
      expect(entry.seasons, isEmpty);
    });
  });

  group('SimklAllItems', () {
    test('splits the three sections', () {
      final SimklAllItems items = SimklAllItems.fromJson(<String, dynamic>{
        'movies': <Map<String, dynamic>>[<String, dynamic>{}],
        'shows': <Map<String, dynamic>>[
          <String, dynamic>{},
          <String, dynamic>{},
        ],
        'anime': <Map<String, dynamic>>[<String, dynamic>{}],
      });

      expect(items.movies, hasLength(1));
      expect(items.shows, hasLength(2));
      expect(items.anime, hasLength(1));
      expect(items.totalCount, 4);
      expect(items.isEmpty, isFalse);
    });

    test('an account with no sections reads as empty', () {
      final SimklAllItems items = SimklAllItems.fromJson(<String, dynamic>{});

      expect(items.isEmpty, isTrue);
      expect(items.totalCount, 0);
    });
  });

  group('SimklUser', () {
    test('reads the nested user and account blocks', () {
      final SimklUser user = SimklUser.fromJson(<String, dynamic>{
        'user': <String, dynamic>{'name': 'ann'},
        'account': <String, dynamic>{'id': 7},
      });

      expect(user.name, 'ann');
      expect(user.accountId, 7);
    });

    test('falls back to an empty name', () {
      final SimklUser user = SimklUser.fromJson(<String, dynamic>{});

      expect(user.name, isEmpty);
      expect(user.accountId, isNull);
    });
  });
}
