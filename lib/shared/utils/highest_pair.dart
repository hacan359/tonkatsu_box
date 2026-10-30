/// The lexicographically largest pair: first by the coarse number, then by
/// the fine one. `null` for an empty input.
(int, int)? highestPair(Iterable<(int, int)> pairs) {
  (int, int)? best;
  for (final (int coarse, int fine) in pairs) {
    if (best == null ||
        coarse > best.$1 ||
        (coarse == best.$1 && fine > best.$2)) {
      best = (coarse, fine);
    }
  }
  return best;
}
