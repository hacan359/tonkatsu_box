/// Runs an action and retries it on a rate-limit error with exponential
/// backoff. Source-agnostic: the caller decides what counts as a rate limit
/// via [isRateLimit], so it works with any API client's exception type.
class RateLimitedRetry {
  const RateLimitedRetry({
    this.maxAttempts = 4,
    this.baseDelay = const Duration(seconds: 1),
  });

  /// Total attempts including the first; the action runs at most this often.
  final int maxAttempts;

  /// Backoff base: the wait before attempt N is `baseDelay * 2^(N-1)`.
  final Duration baseDelay;

  /// Runs [action], retrying when [isRateLimit] returns true for the thrown
  /// error. [onRetry] reports the upcoming wait and the (1-based) attempt that
  /// just failed. Non-rate-limit errors and the final attempt rethrow.
  Future<T> run<T>(
    Future<T> Function() action, {
    required bool Function(Object error) isRateLimit,
    void Function(Duration wait, int attempt)? onRetry,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } on Object catch (error) {
        if (!isRateLimit(error) || attempt >= maxAttempts) {
          rethrow;
        }
        final Duration wait = baseDelay * (1 << (attempt - 1));
        onRetry?.call(wait, attempt);
        await Future<void>.delayed(wait);
      }
    }
    throw StateError('RateLimitedRetry exhausted without a result');
  }
}
