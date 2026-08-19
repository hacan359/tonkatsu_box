import 'package:test/test.dart';
import 'package:tonkatsu_server/src/upstream_throttle.dart';

void main() {
  group('UpstreamThrottle', () {
    test('should space consecutive slots by at least the gap', () async {
      final UpstreamThrottle throttle =
          UpstreamThrottle(const Duration(milliseconds: 60));
      final Stopwatch clock = Stopwatch()..start();

      await throttle.acquire();
      await throttle.acquire();
      await throttle.acquire();

      // Two gaps between three slots; 50ms of slack absorbs timer jitter.
      expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(110));
    });

    test('should serve queued acquires in FIFO order', () async {
      final UpstreamThrottle throttle =
          UpstreamThrottle(const Duration(milliseconds: 10));
      final List<int> order = <int>[];

      await Future.wait(<Future<void>>[
        throttle.acquire().then((_) => order.add(1)),
        throttle.acquire().then((_) => order.add(2)),
        throttle.acquire().then((_) => order.add(3)),
      ]);

      expect(order, <int>[1, 2, 3]);
    });
  });
}
