// Определение тира — метка, цвет и порядок в тир-листе.

import 'dart:ui';

/// Определение тира (S, A, B, C, D, F или кастомный).
///
/// Описывает один уровень в тир-листе: ключ, метку, цвет и порядок.
class TierDefinition {
  /// Создаёт [TierDefinition].
  const TierDefinition({
    required this.tierKey,
    required this.label,
    required this.color,
    required this.sortOrder,
  });

  /// Создаёт [TierDefinition] из записи базы данных.
  factory TierDefinition.fromDb(Map<String, dynamic> row) {
    return TierDefinition(
      tierKey: row['tier_key'] as String,
      label: row['label'] as String,
      color: Color(row['color'] as int),
      sortOrder: row['sort_order'] as int,
    );
  }

  /// Создаёт [TierDefinition] из экспортированных данных.
  factory TierDefinition.fromExport(Map<String, dynamic> json) {
    return TierDefinition(
      tierKey: json['tier_key'] as String,
      label: json['label'] as String,
      color: Color(json['color'] as int),
      sortOrder: json['sort_order'] as int,
    );
  }

  /// Уникальный ключ тира (например, 'S', 'A', 'custom_1').
  final String tierKey;

  /// Отображаемая метка.
  final String label;

  /// Цвет метки тира.
  final Color color;

  /// Порядок сортировки (0 = верхний тир).
  final int sortOrder;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb(int tierListId) {
    return <String, dynamic>{
      'tier_list_id': tierListId,
      'tier_key': tierKey,
      'label': label,
      'color': color.toARGB32(),
      'sort_order': sortOrder,
    };
  }

  /// Преобразует в Map для экспорта.
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'tier_key': tierKey,
      'label': label,
      'color': color.toARGB32(),
      'sort_order': sortOrder,
    };
  }

  /// Создаёт копию с изменёнными полями.
  TierDefinition copyWith({
    String? tierKey,
    String? label,
    Color? color,
    int? sortOrder,
  }) {
    return TierDefinition(
      tierKey: tierKey ?? this.tierKey,
      label: label ?? this.label,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Набор тиров по умолчанию: S / A / B / C / D / F.
  static const List<TierDefinition> defaults = <TierDefinition>[
    TierDefinition(
      tierKey: 'S',
      label: 'S',
      color: Color(0xFFFF4444),
      sortOrder: 0,
    ),
    TierDefinition(
      tierKey: 'A',
      label: 'A',
      color: Color(0xFFFF8C00),
      sortOrder: 1,
    ),
    TierDefinition(
      tierKey: 'B',
      label: 'B',
      color: Color(0xFFFFD700),
      sortOrder: 2,
    ),
    TierDefinition(
      tierKey: 'C',
      label: 'C',
      color: Color(0xFF44BB44),
      sortOrder: 3,
    ),
    TierDefinition(
      tierKey: 'D',
      label: 'D',
      color: Color(0xFF4488FF),
      sortOrder: 4,
    ),
    TierDefinition(
      tierKey: 'F',
      label: 'F',
      color: Color(0xFF888888),
      sortOrder: 5,
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
