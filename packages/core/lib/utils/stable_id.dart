/// 64-bit FNV-1a masked to 63 bits, so it fits SQLite's signed INTEGER. Stable
/// across runs and platforms, unlike [String.hashCode].
int fnv1a64(String input) {
  // 64-bit FNV-1a. Dart ints are 64-bit two's-complement on the VM/AOT, so the
  // multiply wraps mod 2^64 exactly as the algorithm requires.
  int hash = 0xcbf29ce484222325; // offset basis
  for (final int unit in input.codeUnits) {
    hash ^= unit;
    hash = hash * 0x100000001b3; // FNV prime
  }
  return hash & 0x7fffffffffffffff; // mask to 63 bits → non-negative
}
