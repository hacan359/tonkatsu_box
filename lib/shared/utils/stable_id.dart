// Stable string→int hashing for folding a provider's non-numeric id (Google
// Books `volumeId`, MangaDex UUID) into the numeric `external_id` contract.

/// Deterministic 64-bit FNV-1a hash of [input], masked to 63 bits so the result
/// is always a non-negative [int] that fits both SQLite's signed INTEGER and a
/// native Dart int. Unlike [String.hashCode] it is stable across runs and
/// platforms, so cached / persisted ids stay valid.
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
