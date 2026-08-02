
/// A row from SteamGridDB's `/search/autocomplete`.
class SteamGridDbGame {
  const SteamGridDbGame({
    required this.id,
    required this.name,
    this.types,
    this.verified = false,
  });

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

  final int id;

  final String name;

  /// Store tokens, e.g. `steam`, `origin`.
  final List<String>? types;

  final bool verified;

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
