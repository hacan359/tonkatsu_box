import 'dart:async';

import 'package:dio/dio.dart';

/// MusicBrainz allows one request per second per client and silently throttles
/// offenders instead of returning 503 — the gap has headroom on purpose.
const Map<String, Duration> kHostMinRequestGap = <String, Duration>{
  'musicbrainz.org': Duration(milliseconds: 1100),
  // Cover Art Archive tolerates images better than lookups, but a 40-cover
  // burst from a fresh grid still trips it — pace the background refills.
  'coverartarchive.org': Duration(milliseconds: 300),
};

/// Serialises requests to one host: starts stay in FIFO order and at least
/// [minGap] apart. Responses are not awaited — only starts are spaced.
class HostRateLimiter {
  HostRateLimiter(this.minGap);

  final Duration minGap;

  Future<void> _tail = Future<void>.value();
  DateTime _nextAllowed = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> acquire() {
    final Future<void> slot = _tail.then((_) async {
      final Duration wait = _nextAllowed.difference(DateTime.now());
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
      _nextAllowed = DateTime.now().add(minGap);
    });
    _tail = slot;
    return slot;
  }
}

// One queue per host per process, shared by every Dio instance — per-client
// queues would multiply the allowed rate by the number of clients.
final Map<String, HostRateLimiter> _limiters = <String, HostRateLimiter>{};

HostRateLimiter? limiterForHost(String host) {
  final String key = host.toLowerCase();
  final Duration? gap = kHostMinRequestGap[key];
  if (gap == null) return null;
  return _limiters.putIfAbsent(key, () => HostRateLimiter(gap));
}

/// Holds a request until its host's queue frees a slot. Must sit before the
/// web proxy rewrite so it keys on the real upstream host.
class HostRateLimitInterceptor extends Interceptor {
  HostRateLimitInterceptor({HostRateLimiter? Function(String host)? resolve})
      : _resolve = resolve ?? limiterForHost;

  final HostRateLimiter? Function(String host) _resolve;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final HostRateLimiter? limiter = _resolve(options.uri.host);
    if (limiter == null) {
      handler.next(options);
      return;
    }
    unawaited(limiter.acquire().then((_) {
      // A throw past this point would otherwise become an unhandled zone
      // error and leave the request permanently unsettled.
      try {
        handler.next(options);
      } on Object catch (e, s) {
        handler.reject(
          DioException(requestOptions: options, error: e, stackTrace: s),
        );
      }
    }));
  }
}
