import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/host_rate_limiter.dart';

void main() {
  group('HostRateLimiter', () {
    test('spaces acquisitions by at least the gap', () async {
      final HostRateLimiter limiter =
          HostRateLimiter(const Duration(milliseconds: 60));
      final List<DateTime> starts = <DateTime>[];

      await Future.wait(<Future<void>>[
        for (int i = 0; i < 4; i++)
          limiter.acquire().then((_) => starts.add(DateTime.now())),
      ]);

      expect(starts, hasLength(4));
      for (int i = 1; i < starts.length; i++) {
        final Duration gap = starts[i].difference(starts[i - 1]);
        // Timers may fire a hair early; 5ms of slack avoids flakes.
        expect(
          gap,
          greaterThanOrEqualTo(const Duration(milliseconds: 55)),
          reason: 'gap between request ${i - 1} and $i was $gap',
        );
      }
    });

    test('keeps FIFO order under concurrency', () async {
      final HostRateLimiter limiter =
          HostRateLimiter(const Duration(milliseconds: 10));
      final List<int> order = <int>[];

      await Future.wait(<Future<void>>[
        for (int i = 0; i < 6; i++)
          limiter.acquire().then((_) => order.add(i)),
      ]);

      expect(order, <int>[0, 1, 2, 3, 4, 5]);
    });

    test('an idle period does not delay the next request', () async {
      final HostRateLimiter limiter =
          HostRateLimiter(const Duration(milliseconds: 30));

      await limiter.acquire();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final Stopwatch watch = Stopwatch()..start();
      await limiter.acquire();
      watch.stop();

      expect(watch.elapsed, lessThan(const Duration(milliseconds: 20)));
    });
  });

  group('limiterForHost', () {
    test('returns a limiter only for configured hosts', () {
      expect(limiterForHost('musicbrainz.org'), isNotNull);
      expect(limiterForHost('MUSICBRAINZ.ORG'), isNotNull);
      expect(limiterForHost('coverartarchive.org'), isNotNull);
      expect(limiterForHost('api.listenbrainz.org'), isNull);
    });

    test('returns the same shared instance per host', () {
      expect(
        identical(
          limiterForHost('musicbrainz.org'),
          limiterForHost('musicbrainz.org'),
        ),
        isTrue,
      );
    });
  });
}
