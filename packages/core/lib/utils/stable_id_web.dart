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
  // In a browser ids above 2^53 lose precision — kept only for sources that
  // shipped with 63-bit ids (MangaDex, Google Books); new sources use fnv1a53.
  return hash.toUnsigned(63).toInt();
}

/// [fnv1a64] xor-folded to 53 bits, so the id survives a JS double exactly —
/// dart2js and JSON keep it bit-identical. Use for every new int-id source.
int fnv1a53(String input) {
  BigInt hash = _fnvOffsetBasis;
  for (final int unit in input.codeUnits) {
    hash = ((hash ^ BigInt.from(unit)) * _fnvPrime).toUnsigned(64);
  }
  // Fold the same 63-bit value the io variant folds, before any toInt().
  final BigInt masked = hash.toUnsigned(63);
  return (masked ^ (masked >> 53)).toUnsigned(53).toInt();
}
