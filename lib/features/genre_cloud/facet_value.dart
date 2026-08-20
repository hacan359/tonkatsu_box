import 'package:core/models/media_type.dart';
import 'package:flutter/foundation.dart';

import 'facet.dart';

/// A single value of some [Facet], how many items carry it, and the media
/// type that predominantly carries it (drives the word colour).
@immutable
class FacetValue {
  const FacetValue({
    required this.facet,
    required this.label,
    required this.count,
    required this.type,
  });

  final Facet facet;

  /// Display label (original casing of the first occurrence).
  final String label;

  /// How many items carry this value.
  final int count;

  /// Dominant media type for this value.
  final MediaType type;

  /// Stable identity key (facet + folded label).
  String get key => '${facet.value}:${label.toLowerCase()}';

  @override
  bool operator ==(Object other) =>
      other is FacetValue &&
      other.key == key &&
      other.count == count &&
      other.type == type;

  @override
  int get hashCode => Object.hash(key, count, type);

  @override
  String toString() => 'FacetValue(${facet.value}, $label, $count, ${type.value})';
}
