import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/import/rate_limited_retry.dart';

class _RateLimit implements Exception {}

class _Other implements Exception {}

void main() {
  // baseDelay zero so the backoff doesn't actually sleep during tests.
  const RateLimitedRetry retry = RateLimitedRetry(
    maxAttempts: 3,
    baseDelay: Duration.zero,
  );

  group('RateLimitedRetry', () {
    test('returns the result on first success without retrying', () async {
      int calls = 0;
      final int result = await retry.run<int>(
        () async {
          calls++;
          return 42;
        },
        isRateLimit: (Object e) => true,
      );

      expect(result, 42);
      expect(calls, 1);
    });

    test('retries on rate-limit errors then succeeds', () async {
      int calls = 0;
      final List<int> reportedAttempts = <int>[];
      final int result = await retry.run<int>(
        () async {
          calls++;
          if (calls < 3) throw _RateLimit();
          return 7;
        },
        isRateLimit: (Object e) => e is _RateLimit,
        onRetry: (Duration wait, int attempt) => reportedAttempts.add(attempt),
      );

      expect(result, 7);
      expect(calls, 3);
      expect(reportedAttempts, <int>[1, 2],
          reason: 'reported the two failed attempts before success');
    });

    test('rethrows immediately for non-rate-limit errors', () async {
      int calls = 0;
      await expectLater(
        retry.run<int>(
          () async {
            calls++;
            throw _Other();
          },
          isRateLimit: (Object e) => e is _RateLimit,
        ),
        throwsA(isA<_Other>()),
      );

      expect(calls, 1, reason: 'no retry for non-rate-limit errors');
    });

    test('gives up after maxAttempts and rethrows the rate-limit error',
        () async {
      int calls = 0;
      await expectLater(
        retry.run<int>(
          () async {
            calls++;
            throw _RateLimit();
          },
          isRateLimit: (Object e) => e is _RateLimit,
        ),
        throwsA(isA<_RateLimit>()),
      );

      expect(calls, 3, reason: 'tried exactly maxAttempts times');
    });
  });
}
