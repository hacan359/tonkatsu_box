// Модель игры из SteamGridDB API.

/// Результат поиска игры в SteamGridDB.
///
/// Представляет игру из ответа эндпоинта `/search/autocomplete`.
class SteamGridDbGame {
  /// Создаёт экземпляр [SteamGridDbGame].
  const SteamGridDbGame({
    required this.id,
    required this.name,
    this.types,
    this.verified = false,
  });

  /// Создаёт [SteamGridDbGame] из JSON ответа SteamGridDB API.
  factory SteamGridDbGame.fromJson(Map<String, dynamic> json) {
    List<String>? types;
    if (json['types'] != null) {
      final List<dynamic> typesList = json['types'] as List<dynamic>;
      types = typesList.map((dynamic t) => t as String).toList();
    }

    return SteamGridDbGame(
      id: json['id'] as int,
      name: json['name'] as String,
      types: types,
      verified: json['verified'] as bool? ?? false,
    );
  }

  /// Уникальный идентификатор игры в SteamGridDB.
  final int id;

  /// Название игры.
  final String name;

  /// Типы игры (например, "steam", "origin").
  final List<String>? types;

  /// Подтверждена ли игра на SteamGridDB.
  final bool verified;

  /// Создаёт копию с изменёнными полями.
  SteamGridDbGame copyWith({
    int? id,
    String? name,
    List<String>? types,
    bool? verified,
  }) {
    return SteamGridDbGame(
      id: id ?? this.id,
      name: name ?? this.name,
      types: types ?? this.types,
      verified: verified ?? this.verified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SteamGridDbGame && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SteamGridDbGame(id: $id, name: $name)';
}
