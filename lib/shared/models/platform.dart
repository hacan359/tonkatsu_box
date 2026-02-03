/// Модель платформы из IGDB.
///
/// Представляет игровую платформу (например, SNES, PlayStation, PC).
class Platform {
  /// Создаёт экземпляр [Platform].
  const Platform({
    required this.id,
    required this.name,
    this.abbreviation,
    this.syncedAt,
  });

  /// Создаёт [Platform] из JSON ответа IGDB API.
  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(
      id: json['id'] as int,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String?,
      syncedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Создаёт [Platform] из записи базы данных.
  factory Platform.fromDb(Map<String, dynamic> row) {
    return Platform(
      id: row['id'] as int,
      name: row['name'] as String,
      abbreviation: row['abbreviation'] as String?,
      syncedAt: row['synced_at'] as int?,
    );
  }

  /// Уникальный идентификатор платформы в IGDB.
  final int id;

  /// Полное название платформы.
  final String name;

  /// Сокращённое название (например, "SNES", "PS1").
  final String? abbreviation;

  /// Время последней синхронизации с IGDB (Unix timestamp).
  final int? syncedAt;

  /// Возвращает отображаемое имя (сокращение или полное название).
  String get displayName => abbreviation ?? name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Platform && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Platform(id: $id, name: $name)';

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'synced_at': syncedAt,
    };
  }

  /// Преобразует в JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
    };
  }

  /// Создаёт копию с изменёнными полями.
  Platform copyWith({
    int? id,
    String? name,
    String? abbreviation,
    int? syncedAt,
  }) {
    return Platform(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
