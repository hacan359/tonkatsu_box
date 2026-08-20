/// Rate-limited hosts see one shared IP for every tab, so the gap between
/// upstream requests has to hold here, not per client.
class UpstreamThrottle {
  UpstreamThrottle(this.minGap);

  final Duration minGap;

  Future<void> _tail = Future<void>.value();
  DateTime _nextAllowed = DateTime.fromMillisecondsSinceEpoch(0);

  /// FIFO slot at least [minGap] after the previous one; responses overlap.
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
