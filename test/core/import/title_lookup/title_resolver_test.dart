import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/import/rate_limited_retry.dart';
import 'package:tonkatsu_box/core/import/title_lookup/lookup_candidate.dart';
import 'package:tonkatsu_box/core/import/title_lookup/lookup_chains.dart';
import 'package:tonkatsu_box/core/import/title_lookup/title_resolver.dart';

class _RateLimit implements Exception {}

class _FakeChains implements LookupChains {
  _FakeChains(this.sources);

  final List<LookupSource> sources;

  @override
  List<LookupSource> chainFor(MediaType type, String title) =>
      type == MediaType.audio || type == MediaType.custom
          ? const <LookupSource>[]
          : sources;
}

LookupCandidate _hit(
  String title, {
  int id = 1,
  int? year,
  List<int> platformIds = const <int>[],
  MediaType type = MediaType.movie,
  int? platformId,
}) =>
    LookupCandidate(
      media: title,
      mediaType: type,
      externalId: id,
      source: DataSource.tmdb,
      titles: <String?>[title],
      year: year,
      platformId: platformId,
      platformIds: platformIds,
    );

/// A source that returns [results] and counts its calls; [fail] throws
/// instead, [rateLimitFirst] throws a rate-limit error that many times.
class _Source {
  _Source(
    this.source,
    this.results, {
    this.fail,
    this.rateLimitFirst = 0,
  });

  final DataSource source;
  final List<LookupCandidate> results;
  final Object? fail;
  int rateLimitFirst;
  int calls = 0;

  LookupSource get lookup => LookupSource(
        source: source,
        isRateLimit: (Object e) => e is _RateLimit,
        search: (TitleQuery q) async {
          calls++;
          if (rateLimitFirst > 0) {
            rateLimitFirst--;
            throw _RateLimit();
          }
          if (fail != null) throw fail!;
          return results;
        },
      );
}

void main() {
  TitleResolver resolver(List<_Source> sources) => TitleResolver(
        _FakeChains(sources.map((_Source s) => s.lookup).toList()),
        retry: const RateLimitedRetry(baseDelay: Duration.zero),
      );

  group('TitleResolver', () {
    group('resolve', () {
      test('an empty first source falls through to a unique second hit',
          () async {
        final _Source first = _Source(DataSource.tmdb, <LookupCandidate>[]);
        final _Source second = _Source(
          DataSource.tvdb,
          <LookupCandidate>[_hit('Dune', id: 9)],
        );
        final List<DataSource> asked = <DataSource>[];

        final ResolveOutcome outcome = await resolver(<_Source>[first, second])
            .resolve(
          MediaType.movie,
          const TitleQuery(title: 'Dune'),
          onSource: asked.add,
        );

        expect(outcome, isA<ResolvedMatch>());
        expect((outcome as ResolvedMatch).candidate.externalId, 9);
        expect(asked, <DataSource>[DataSource.tmdb, DataSource.tvdb]);
      });

      test('an ambiguous first source stops the walk', () async {
        final _Source first = _Source(DataSource.tmdb, <LookupCandidate>[
          _hit('Dune', id: 1, year: 1984),
          _hit('Dune', id: 2, year: 2021),
        ]);
        final _Source second = _Source(
          DataSource.tvdb,
          <LookupCandidate>[_hit('Dune', id: 3)],
        );

        final ResolveOutcome outcome = await resolver(<_Source>[first, second])
            .resolve(MediaType.movie, const TitleQuery(title: 'Dune'));

        expect(outcome, isA<ResolvedAmbiguous>());
        expect((outcome as ResolvedAmbiguous).source, DataSource.tmdb);
        expect(outcome.count, 2);
        expect(second.calls, 0);
      });

      test('nothing anywhere, or an empty chain, is not found', () async {
        final _Source empty = _Source(DataSource.tmdb, <LookupCandidate>[]);
        expect(
          await resolver(<_Source>[empty])
              .resolve(MediaType.movie, const TitleQuery(title: 'Dune')),
          isA<ResolvedNotFound>(),
        );
        expect(
          await resolver(<_Source>[])
              .resolve(MediaType.movie, const TitleQuery(title: 'Dune')),
          isA<ResolvedNotFound>(),
        );
      });

      test('a failing source is skipped, not fatal', () async {
        final _Source broken = _Source(
          DataSource.tmdb,
          <LookupCandidate>[],
          fail: StateError('boom'),
        );
        final _Source second = _Source(
          DataSource.tvdb,
          <LookupCandidate>[_hit('Dune', id: 9)],
        );

        final ResolveOutcome outcome = await resolver(<_Source>[broken, second])
            .resolve(MediaType.movie, const TitleQuery(title: 'Dune'));

        expect((outcome as ResolvedMatch).candidate.externalId, 9);
      });

      test('a rate limit is retried on the same source', () async {
        final _Source throttled = _Source(
          DataSource.tmdb,
          <LookupCandidate>[_hit('Dune', id: 5)],
          rateLimitFirst: 2,
        );
        int waits = 0;

        final ResolveOutcome outcome =
            await resolver(<_Source>[throttled]).resolve(
          MediaType.movie,
          const TitleQuery(title: 'Dune'),
          onRateLimit: (Duration _, int _) => waits++,
        );

        expect((outcome as ResolvedMatch).candidate.externalId, 5);
        expect(throttled.calls, 3);
        expect(waits, 2);
      });

      test('custom and audio ask no source', () async {
        final _Source any = _Source(
          DataSource.tmdb,
          <LookupCandidate>[_hit('X')],
        );
        final TitleResolver sut = resolver(<_Source>[any]);

        expect(
          await sut.resolve(MediaType.custom, const TitleQuery(title: 'X')),
          isA<ResolvedNotFound>(),
        );
        expect(
          await sut.resolve(MediaType.audio, const TitleQuery(title: 'X')),
          isA<ResolvedNotFound>(),
        );
        expect(any.calls, 0);
      });

      test('a non-game match keeps the candidate platform id', () async {
        final _Source tmdb = _Source(DataSource.tmdb, <LookupCandidate>[
          _hit('Akira', type: MediaType.animation, platformId: 0),
        ]);

        final ResolveOutcome outcome = await resolver(<_Source>[tmdb])
            .resolve(MediaType.animation, const TitleQuery(title: 'Akira'));

        expect((outcome as ResolvedMatch).platformId, 0);
      });
    });

    group('resolve for games', () {
      ResolveOutcome? last;
      Future<ResolveOutcome> game(
        List<int> platformIds, {
        int? platformId,
        bool platformUnknown = false,
      }) async {
        final _Source igdb = _Source(DataSource.igdb, <LookupCandidate>[
          _hit('Doom', type: MediaType.game, platformIds: platformIds),
        ]);
        last = await resolver(<_Source>[igdb]).resolve(
          MediaType.game,
          TitleQuery(title: 'Doom', platformId: platformId),
          platformUnknown: platformUnknown,
        );
        return last!;
      }

      test('a wanted platform the game has is taken', () async {
        final ResolveOutcome o = await game(<int>[6, 19], platformId: 19);
        expect((o as ResolvedMatch).platformId, 19);
      });

      test('a wanted platform the game lacks is not a match', () async {
        expect(await game(<int>[6], platformId: 19), isA<ResolvedNotFound>());
      });

      test('a platform unknown to the catalog asks nobody', () async {
        final _Source igdb = _Source(DataSource.igdb, <LookupCandidate>[
          _hit('Doom', type: MediaType.game, platformIds: <int>[6]),
        ]);
        final ResolveOutcome o = await resolver(<_Source>[igdb]).resolve(
          MediaType.game,
          const TitleQuery(title: 'Doom'),
          platformUnknown: true,
        );
        expect(o, isA<ResolvedNotFound>());
        expect(igdb.calls, 0);
      });

      test('no platform in the file and one on the game takes it', () async {
        final ResolveOutcome o = await game(<int>[6]);
        expect((o as ResolvedMatch).platformId, 6);
      });

      test('no platform in the file and several on the game is ambiguous',
          () async {
        final ResolveOutcome o = await game(<int>[6, 19]);
        expect(o, isA<ResolvedAmbiguous>());
        expect((o as ResolvedAmbiguous).source, DataSource.igdb);
      });

      test('no platform anywhere matches without one', () async {
        final ResolveOutcome o = await game(<int>[]);
        expect((o as ResolvedMatch).platformId, isNull);
      });
    });
  });
}
