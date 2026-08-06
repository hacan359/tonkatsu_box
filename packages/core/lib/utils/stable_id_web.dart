final BigInt _fnvOffsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
final BigInt _fnvPrime = BigInt.parse('100000001b3', radix: 16);

/// 64-bit FNV-1a masked to 63 bits, so it fits SQLite's signed INTEGER. Stable
/// across runs and platforms, unlike [String.hashCode].
int fnv1a64(String input) {
  // BigInt keeps the mod-2^64 wrap exact on dart2js, where plain ints are
  // doubles; the result is bit-identical to the raw-int variant on the VM.
  BigInt hash = _fnvOffsetBasis;
  for (final int unit in input.codeUnits) {
    hash = ((hash ^ BigInt.from(unit)) * _fnvPrime).toUnsigned(64);
  }
  // toInt() is exact on the VM; in a browser ids above 2^53 lose precision —
  // acceptable for the phase-2 stub DB, revisited with DAO-RPC serialization.
  return hash.toUnsigned(63).toInt();
}
