/// One tier level: key, label, ARGB color int and order. The Color getter lives
/// in `shared/constants/tier_definition_ui.dart`.
class TierDefinition {
  const TierDefinition({
    required this.tierKey,
    required this.label,
    required this.colorValue,
    required this.sortOrder,
  });

  factory TierDefinition.fromDb(Map<String, dynamic> row) {
    return TierDefinition(
      tierKey: row['tier_key'] as String,
      label: row['label'] as String,
      colorValue: row['color'] as int,
      sortOrder: row['sort_order'] as int,
    );
  }

  factory TierDefinition.fromExport(Map<String, dynamic> json) {
    return TierDefinition(
      tierKey: json['tier_key'] as String,
      label: json['label'] as String,
      colorValue: json['color'] as int,
      sortOrder: json['sort_order'] as int,
    );
  }

  /// Unique tier key (e.g. 'S', 'A', 'custom_1').
  final String tierKey;

  final String label;

  /// Tier label color as an ARGB int.
  final int colorValue;

  /// Sort order (0 = top tier).
  final int sortOrder;

  Map<String, dynamic> toDb(int tierListId) {
    return <String, dynamic>{
      'tier_list_id': tierListId,
      'tier_key': tierKey,
      'label': label,
      'color': colorValue,
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'tier_key': tierKey,
      'label': label,
      'color': colorValue,
      'sort_order': sortOrder,
    };
  }

  TierDefinition copyWith({
    String? tierKey,
    String? label,
    int? colorValue,
    int? sortOrder,
  }) {
    return TierDefinition(
      tierKey: tierKey ?? this.tierKey,
      label: label ?? this.label,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Default tier set: S / A / B / C.
  static const List<TierDefinition> defaults = <TierDefinition>[
    TierDefinition(
      tierKey: 'S',
      label: 'S',
      colorValue: 0xFFFF4444,
      sortOrder: 0,
    ),
    TierDefinition(
      tierKey: 'A',
      label: 'A',
      colorValue: 0xFFFF8C00,
      sortOrder: 1,
    ),
    TierDefinition(
      tierKey: 'B',
      label: 'B',
      colorValue: 0xFFFFD700,
      sortOrder: 2,
    ),
    TierDefinition(
      tierKey: 'C',
      label: 'C',
      colorValue: 0xFF44BB44,
      sortOrder: 3,
    ),
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TierDefinition && other.tierKey == tierKey;
  }

  @override
  int get hashCode => tierKey.hashCode;

  @override
  String toString() => 'TierDefinition(key: $tierKey, label: $label)';
}
