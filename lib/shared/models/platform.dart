import 'dart:ui';

/// Модель платформы из IGDB.
///
/// Представляет игровую платформу (например, SNES, PlayStation, PC).
class Platform {
  /// Создаёт экземпляр [Platform].
  const Platform({
    required this.id,
    required this.name,
    this.abbreviation,
  });

  /// Создаёт [Platform] из JSON ответа IGDB API.
  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(
      id: json['id'] as int,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String?,
    );
  }

  /// Создаёт [Platform] из записи базы данных.
  factory Platform.fromDb(Map<String, dynamic> row) {
    return Platform(
      id: row['id'] as int,
      name: row['name'] as String,
      abbreviation: row['abbreviation'] as String?,
    );
  }

  /// Уникальный идентификатор платформы в IGDB.
  final int id;

  /// Полное название платформы.
  final String name;

  /// Сокращённое название (например, "SNES", "PS1").
  final String? abbreviation;

  /// Возвращает отображаемое имя (сокращение или полное название).
  String get displayName => abbreviation ?? name;

  /// Цвет семейства платформы.
  ///
  /// Определяется по IGDB platform ID:
  /// Sony (PlayStation) — синий, Nintendo — красный,
  /// Microsoft (Xbox) — зелёный, Sega — голубой,
  /// PC/Mac/Linux — серый, остальные — фиолетовый.
  Color get familyColor {
    // Sony: PS1(7), PS2(8), PS3(9), PS4(48), PS5(167), PSP(38), Vita(46)
    if (const <int>{7, 8, 9, 48, 167, 38, 46, 165}.contains(id)) {
      return const Color(0xFF0070D1); // PlayStation blue
    }
    // Nintendo: NES(18), SNES(19), N64(4), GC(21), Wii(5), WiiU(41),
    // Switch(130), GB(33), GBA(24), DS(20), 3DS(37)
    if (const <int>{18, 19, 4, 21, 5, 41, 130, 33, 24, 20, 37, 137, 159}
        .contains(id)) {
      return const Color(0xFFE60012); // Nintendo red
    }
    // Microsoft: Xbox(11), X360(12), XOne(49), XSX(169)
    if (const <int>{11, 12, 49, 169}.contains(id)) {
      return const Color(0xFF107C10); // Xbox green
    }
    // Sega: Genesis/MD(29), Saturn(32), DC(23), SMS(64), GG(35)
    if (const <int>{29, 32, 23, 64, 35, 78, 30, 84}.contains(id)) {
      return const Color(0xFF17569B); // Sega blue
    }
    // PC(6), Mac(14), Linux(3)
    if (const <int>{6, 14, 3, 162, 163}.contains(id)) {
      return const Color(0xFF6B7280); // PC gray
    }
    // Atari: 2600(59), 7800(60), Jaguar(62), Lynx(61), ST(63)
    if (const <int>{59, 60, 62, 61, 63}.contains(id)) {
      return const Color(0xFFB45309); // Atari amber
    }
    return const Color(0xFF7C3AED); // default purple
  }

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
  }) {
    return Platform(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
    );
  }
}
