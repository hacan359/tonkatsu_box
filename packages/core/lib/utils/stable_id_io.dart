/// 64-bit FNV-1a masked to 63 bits, so it fits SQLite's signed INTEGER. Stable
/// across runs and platforms, unlike [String.hashCode].
int fnv1a64(String input) {
  // Dart ints are 64-bit two's-complement on the VM/AOT, so the
  // multiply wraps mod 2^64 exactly as the algorithm requires.
  int hash = 0xcbf29ce484222325; // offset basis
  for (final int unit in input.codeUnits) {
    hash ^= unit;
    hash = hash * 0x100000001b3; // FNV prime
  }
  return hash & 0x7fffffffffffffff; // mask to 63 bits → non-negative
}

/// [fnv1a64] xor-folded to 53 bits, so the id survives a JS double exactly —
/// dart2js and JSON keep it bit-identical. Use for every new int-id source.
int fnv1a53(String input) {
  final int hash = fnv1a64(input);
  return (hash ^ (hash >>> 53)) & 0x1fffffffffffff;
}
