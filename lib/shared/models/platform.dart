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

  /// Путь к ассету оверлея платформы (PNG 600×900), или `null`.
  ///
  /// Оверлей накладывается поверх обложки на карточках коллекции и тир-листа.
  String? get overlayAsset {
    final String? file = _overlayFiles[id];
    if (file == null) return null;
    return 'assets/images/platform_overlays/$file';
  }

  /// Маппинг IGDB platform ID → имя файла оверлея.
  static const Map<int, String> _overlayFiles = <int, String>{
    // Sony
    7: 'ps1.png', // PlayStation
    8: 'ps2.png', // PlayStation 2
    9: 'ps3.png', // PlayStation 3
    48: 'ps4.png', // PlayStation 4
    167: 'ps5.png', // PlayStation 5
    38: 'psp.png', // PSP
    46: 'ps_vita.png', // PS Vita
    // Nintendo home
    18: 'nes.png', // NES
    19: 'snes.png', // SNES
    4: 'n64.png', // Nintendo 64
    21: 'game_cube.png', // GameCube
    5: 'wii.png', // Wii
    41: 'wii_u.png', // Wii U
    130: 'switch_v2.png', // Nintendo Switch
    508: 'switch_2.png', // Nintendo Switch 2
    99: 'famicom.png', // Family Computer
    58: 'super_famicom.png', // Super Famicom
    51: 'famicom_disk_system.png', // FDS
    87: 'virtual_boy.png', // Virtual Boy
    307: 'game_and_watch.png', // Game & Watch
    // Nintendo portable
    33: 'game_boy.png', // Game Boy
    22: 'gbc.png', // Game Boy Color
    24: 'gba.png', // Game Boy Advance
    20: 'nds.png', // Nintendo DS
    37: '3ds.png', // Nintendo 3DS
    // Microsoft
    11: 'xbox_og.png', // Xbox
    12: 'xbox_360.png', // Xbox 360
    49: 'xbox_one.png', // Xbox One
    169: 'xbox_series.png', // Xbox Series X|S
    6: 'pc.png', // PC (Windows)
    // Sega
    29: 'sega_genesis.png', // Mega Drive / Genesis
    32: 'saturn.png', // Saturn
    23: 'dreamcast.png', // Dreamcast
    64: 'sega_master_system.png', // Master System
    84: 'sega_sg1000.png', // SG-1000
    78: 'sega_mega_cd.png', // Sega CD
    30: 'sega_32x.png', // Sega 32X
    35: 'sega_game_gear.png', // Game Gear
    // Atari
    59: 'atari_2600.png', // Atari 2600
    60: 'atari_7800.png', // Atari 7800
    66: 'atari_5200.png', // Atari 5200
    62: 'atari_jaguar.png', // Atari Jaguar
    61: 'atari_lynx.png', // Atari Lynx
    65: 'atari_xegs.png', // Atari XEGS / 8-bit
    // Neo Geo
    80: 'neo_geo.png', // Neo Geo AES
    79: 'neo_geo.png', // Neo Geo MVS
    136: 'neo_geo_cd.png', // Neo Geo CD
    120: 'neo_geo_pocket_color.png', // Neo Geo Pocket Color
    // NEC
    86: 'turbografx_16.png', // TurboGrafx-16 / PC Engine
    128: 'pc_engine_supergrafx.png', // SuperGrafx
    150: 'nec_cdrom2.png', // TG-16/PCE CD
    // Others
    50: '3do.png', // 3DO
    52: 'mame.png', // Arcade
    67: 'intellivision.png', // Intellivision
    68: 'coleco_vision.png', // ColecoVision
    70: 'vectrex.png', // Vectrex
    91: 'bally_astrocade.png', // Bally Astrocade
    88: 'magnavox_odyssey.png', // Odyssey
    133: 'magnavox_odyssey2.png', // Odyssey 2
    117: 'philips_cdi.png', // Philips CD-i
    127: 'fairchild_channel_f.png', // Fairchild Channel F
    138: 'interton_vc4000.png', // VC 4000
    506: 'amstrad_gx4000.png', // Amstrad GX4000
    15: 'commodore_64gs.png', // Commodore C64
    473: 'emerson_arcadia_2001.png', // Arcadia 2001
    375: 'epoch_super_cassette_vision.png', // Epoch SCV (mapped to 376 below)
    376: 'epoch_super_cassette_vision.png', // Epoch Super Cassette Vision
    481: 'tomy_tutor.png', // Tomy Tutor
    479: 'bandai_terebikko.png', // Terebikko
    123: 'wonderswan_color.png', // WonderSwan Color
    39: 'ios.png', // iOS
  };

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
