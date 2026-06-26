import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/recommendations/engine/recommendation_models.dart';
import 'package:tonkatsu_box/features/recommendations/engine/recommender.dart';

TasteTitle _title(
  String id,
  List<String> genres, {
  double? rating,
  bool fav = false,
}) =>
    TasteTitle(
      id: id,
      label: id,
      features: <String, double>{for (final String g in genres) g: 1.0},
      rating: rating,
      isFavorite: fav,
    );

void main() {
  group('Recommender', () {
    group('profile', () {
      test('is empty when no completed title carries features', () {
        final Recommender r = Recommender(<TasteTitle>[_title('a', <String>[])]);
        expect(r.profile.isEmpty, isTrue);
        expect(r.profile.clusters, isEmpty);
      });

      test('forms a single cluster below the clustering threshold', () {
        final Recommender r = Recommender(<TasteTitle>[
          _title('t1', <String>['action']),
          _title('t2', <String>['action']),
          _title('t3', <String>['action']),
        ]);
        expect(r.profile.clusters, hasLength(1));
      });

      test('splits two distinct taste groups into separate clusters', () {
        final List<TasteTitle> completed = <TasteTitle>[
          for (int i = 0; i < 5; i++)
            _title('war$i', <String>['war', 'tank', 'soldier']),
          for (int i = 0; i < 5; i++)
            _title('com$i', <String>['comedy', 'romance', 'wedding']),
        ];
        final Recommender r = Recommender(completed);
        expect(r.profile.clusters, hasLength(2));
      });

      test('records a disliked center for a title rated well below average', () {
        final Recommender r = Recommender(<TasteTitle>[
          _title('a', <String>['action'], rating: 9),
          _title('b', <String>['action'], rating: 9),
          _title('c', <String>['action'], rating: 9),
          _title('d', <String>['horror'], rating: 2),
        ]);
        expect(r.profile.dislikedCenter, isNotNull);
      });

      test('a favorited unrated title still forms a positive cluster', () {
        final Recommender r =
            Recommender(<TasteTitle>[_title('a', <String>['noir'], fav: true)]);
        expect(r.profile.clusters, isNotEmpty);
      });
    });

    group('recommend', () {
      List<TasteTitle> singleClusterTaste() => <TasteTitle>[
            _title('t1', <String>['action', 'war']),
            _title('t2', <String>['action', 'war']),
            _title('t3', <String>['action', 'war']),
          ];

      test('returns no rows when the profile is empty', () {
        final Recommender r = Recommender(<TasteTitle>[_title('a', <String>[])]);
        expect(r.recommend(<TasteTitle>[_title('c', <String>['action'])]),
            isEmpty);
      });

      test('recommends a candidate that matches the taste', () {
        final Recommender r = Recommender(singleClusterTaste());
        final List<RecommendationRow> rows =
            r.recommend(<TasteTitle>[_title('c', <String>['action', 'war'])]);
        expect(rows, isNotEmpty);
        expect(
          rows.expand((RecommendationRow row) => row.items).map((ScoredTitle s) => s.id),
          contains('c'),
        );
      });

      test('excludes a candidate sharing an id with a completed title', () {
        final Recommender r = Recommender(singleClusterTaste());
        final List<RecommendationRow> rows =
            r.recommend(<TasteTitle>[_title('t1', <String>['action', 'war'])]);
        expect(
          rows.expand((RecommendationRow row) => row.items).map((ScoredTitle s) => s.id),
          isNot(contains('t1')),
        );
      });

      test('drops a candidate whose genres are all unknown', () {
        final Recommender r = Recommender(singleClusterTaste());
        final List<RecommendationRow> rows =
            r.recommend(<TasteTitle>[_title('c', <String>['unobtanium'])]);
        expect(rows, isEmpty);
      });

      test('orders items within a row by score, best match first', () {
        final Recommender r = Recommender(singleClusterTaste());
        final List<RecommendationRow> rows = r.recommend(<TasteTitle>[
          _title('weak', <String>['action']),
          _title('strong', <String>['action', 'war']),
        ]);
        expect(rows, hasLength(1));
        final List<ScoredTitle> items = rows.single.items;
        expect(items.map((ScoredTitle s) => s.id), <String>['strong', 'weak']);
        expect(items.first.score, greaterThanOrEqualTo(items.last.score));
      });

      test('carries the cluster because-titles and genres on each row', () {
        final Recommender r = Recommender(singleClusterTaste());
        final RecommendationRow row = r
            .recommend(<TasteTitle>[_title('c', <String>['action', 'war'])])
            .single;
        expect(row.becauseTitles, isNotEmpty);
        expect(row.becauseTitles.length, lessThanOrEqualTo(3));
        expect(row.topGenres, isNotEmpty);
      });
    });

    group('similarTo', () {
      test('ranks a rarer shared genre above a common one (IDF)', () {
        final List<TasteTitle> completed = <TasteTitle>[
          _title('c1', <String>['common']),
          _title('c2', <String>['common']),
          _title('c3', <String>['common']),
          _title('c4', <String>['common']),
          _title('c5', <String>['common', 'rare']),
        ];
        final Recommender r = Recommender(completed);
        final List<ScoredTitle> ranked = r.similarTo(
          _title('target', <String>['common', 'rare']),
          <TasteTitle>[
            _title('a', <String>['rare']),
            _title('b', <String>['common']),
          ],
        );
        expect(ranked.first.id, 'a');
      });

      test('excludes the target itself from the pool', () {
        final Recommender r =
            Recommender(<TasteTitle>[_title('x', <String>['action'])]);
        final List<ScoredTitle> ranked = r.similarTo(
          _title('target', <String>['action']),
          <TasteTitle>[_title('target', <String>['action'])],
        );
        expect(ranked, isEmpty);
      });

      test('returns empty when the target has no known features', () {
        final Recommender r =
            Recommender(<TasteTitle>[_title('x', <String>['action'])]);
        final List<ScoredTitle> ranked = r.similarTo(
          _title('target', <String>['unknown']),
          <TasteTitle>[_title('a', <String>['action'])],
        );
        expect(ranked, isEmpty);
      });
    });

    group('predictRating', () {
      test('returns null when no completed title is rated', () {
        final Recommender r =
            Recommender(<TasteTitle>[_title('x', <String>['action'])]);
        expect(r.predictRating(_title('c', <String>['action'])), isNull);
      });

      test('returns null when the candidate shares no features', () {
        final Recommender r = Recommender(
            <TasteTitle>[_title('x', <String>['action'], rating: 8)]);
        expect(r.predictRating(_title('c', <String>['unknown'])), isNull);
      });

      test('is the similarity-weighted average of neighbour ratings', () {
        final Recommender r = Recommender(<TasteTitle>[
          _title('a', <String>['action'], rating: 8),
          _title('b', <String>['action'], rating: 9),
        ]);
        expect(
          r.predictRating(_title('c', <String>['action'])),
          closeTo(8.5, 1e-6),
        );
      });
    });

    group('determinism', () {
      test('produces identical rows for identical input', () {
        List<TasteTitle> completed() => <TasteTitle>[
              for (int i = 0; i < 6; i++)
                _title('war$i', <String>['war', 'tank']),
              for (int i = 0; i < 6; i++)
                _title('com$i', <String>['comedy', 'romance']),
            ];
        List<TasteTitle> candidates() => <TasteTitle>[
              _title('w', <String>['war', 'tank']),
              _title('c', <String>['comedy', 'romance']),
            ];

        final List<RecommendationRow> first =
            Recommender(completed()).recommend(candidates());
        final List<RecommendationRow> second =
            Recommender(completed()).recommend(candidates());

        expect(first.length, second.length);
        for (int i = 0; i < first.length; i++) {
          expect(first[i].becauseTitles, second[i].becauseTitles);
          expect(
            first[i].items.map((ScoredTitle s) => s.id).toList(),
            second[i].items.map((ScoredTitle s) => s.id).toList(),
          );
        }
      });
    });
  });
}
