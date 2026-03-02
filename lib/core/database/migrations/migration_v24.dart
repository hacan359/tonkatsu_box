// Миграция v24: предзаполнение жанров, тегов и платформ как статических данных.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v24 — seed жанров, тегов и платформ как статических справочников.
///
/// 1. Пересоздаёт tmdb_genres с колонкой lang (EN + RU)
/// 2. Заполняет IGDB жанры
/// 3. Заполняет VNDB теги
/// 4. Пересоздаёт platforms без logo_image_id, заполняет данными
class MigrationV24 extends Migration {
  @override
  int get version => 24;

  @override
  String get description => 'Seed genres, tags, and platforms as static data';

  @override
  Future<void> migrate(Database db) async {
    // 1. Пересоздать tmdb_genres с lang
    await db.execute('DROP TABLE IF EXISTS tmdb_genres');
    await DatabaseSchema.createTmdbGenresTable(db);

    // 2. Seed TMDB genres (EN + RU, movie + tv)
    await _seedTmdbGenres(db);

    // 3. Seed IGDB genres
    await _seedIgdbGenres(db);

    // 4. Seed VNDB tags
    await _seedVndbTags(db);

    // 5. Пересоздать platforms без logo_image_id, seed данными
    await _seedPlatforms(db);
  }

  Future<void> _seedTmdbGenres(Database db) async {
    final Batch batch = db.batch();

    // Movie genres EN
    for (final ({int id, String name}) g in _tmdbMovieGenresEn) {
      batch.insert('tmdb_genres', <String, Object?>{
        'id': g.id, 'type': 'movie', 'lang': 'en', 'name': g.name,
      });
    }

    // Movie genres RU
    for (final ({int id, String name}) g in _tmdbMovieGenresRu) {
      batch.insert('tmdb_genres', <String, Object?>{
        'id': g.id, 'type': 'movie', 'lang': 'ru', 'name': g.name,
      });
    }

    // TV genres EN
    for (final ({int id, String name}) g in _tmdbTvGenresEn) {
      batch.insert('tmdb_genres', <String, Object?>{
        'id': g.id, 'type': 'tv', 'lang': 'en', 'name': g.name,
      });
    }

    // TV genres RU
    for (final ({int id, String name}) g in _tmdbTvGenresRu) {
      batch.insert('tmdb_genres', <String, Object?>{
        'id': g.id, 'type': 'tv', 'lang': 'ru', 'name': g.name,
      });
    }

    await batch.commit(noResult: true);
  }

  Future<void> _seedIgdbGenres(Database db) async {
    await db.execute('DELETE FROM igdb_genres');
    final Batch batch = db.batch();
    for (final ({int id, String name}) g in _igdbGenres) {
      batch.insert('igdb_genres', <String, Object?>{'id': g.id, 'name': g.name});
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedVndbTags(Database db) async {
    await db.execute('DELETE FROM vndb_tags');
    final Batch batch = db.batch();
    for (final ({String id, String name}) t in _vndbTags) {
      batch.insert('vndb_tags', <String, Object?>{'id': t.id, 'name': t.name});
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedPlatforms(Database db) async {
    // Пересоздаём таблицу без logo_image_id и synced_at
    await db.execute('DROP TABLE IF EXISTS platforms');
    await DatabaseSchema.createPlatformsTable(db);

    // Seed данными
    final Batch batch = db.batch();
    for (final ({int id, String name, String? abbreviation}) p in _platforms) {
      batch.insert('platforms', <String, Object?>{
        'id': p.id, 'name': p.name, 'abbreviation': p.abbreviation,
      });
    }
    await batch.commit(noResult: true);
  }
}

// ==================== TMDB Movie Genres EN ====================

const List<({int id, String name})> _tmdbMovieGenresEn = <({int id, String name})>[
  (id: 28, name: 'Action'),
  (id: 12, name: 'Adventure'),
  (id: 16, name: 'Animation'),
  (id: 35, name: 'Comedy'),
  (id: 80, name: 'Crime'),
  (id: 99, name: 'Documentary'),
  (id: 18, name: 'Drama'),
  (id: 10751, name: 'Family'),
  (id: 14, name: 'Fantasy'),
  (id: 36, name: 'History'),
  (id: 27, name: 'Horror'),
  (id: 10402, name: 'Music'),
  (id: 9648, name: 'Mystery'),
  (id: 10749, name: 'Romance'),
  (id: 878, name: 'Science Fiction'),
  (id: 10770, name: 'TV Movie'),
  (id: 53, name: 'Thriller'),
  (id: 10752, name: 'War'),
  (id: 37, name: 'Western'),
];

// ==================== TMDB Movie Genres RU ====================

const List<({int id, String name})> _tmdbMovieGenresRu = <({int id, String name})>[
  (id: 28, name: 'боевик'),
  (id: 12, name: 'приключения'),
  (id: 16, name: 'мультфильм'),
  (id: 35, name: 'комедия'),
  (id: 80, name: 'криминал'),
  (id: 99, name: 'документальный'),
  (id: 18, name: 'драма'),
  (id: 10751, name: 'семейный'),
  (id: 14, name: 'фэнтези'),
  (id: 36, name: 'история'),
  (id: 27, name: 'ужасы'),
  (id: 10402, name: 'музыка'),
  (id: 9648, name: 'детектив'),
  (id: 10749, name: 'мелодрама'),
  (id: 878, name: 'фантастика'),
  (id: 10770, name: 'телевизионный фильм'),
  (id: 53, name: 'триллер'),
  (id: 10752, name: 'военный'),
  (id: 37, name: 'вестерн'),
];

// ==================== TMDB TV Genres EN ====================

const List<({int id, String name})> _tmdbTvGenresEn = <({int id, String name})>[
  (id: 10759, name: 'Action & Adventure'),
  (id: 16, name: 'Animation'),
  (id: 35, name: 'Comedy'),
  (id: 80, name: 'Crime'),
  (id: 99, name: 'Documentary'),
  (id: 18, name: 'Drama'),
  (id: 10751, name: 'Family'),
  (id: 10762, name: 'Kids'),
  (id: 9648, name: 'Mystery'),
  (id: 10763, name: 'News'),
  (id: 10764, name: 'Reality'),
  (id: 10765, name: 'Sci-Fi & Fantasy'),
  (id: 10766, name: 'Soap'),
  (id: 10767, name: 'Talk'),
  (id: 10768, name: 'War & Politics'),
  (id: 37, name: 'Western'),
];

// ==================== TMDB TV Genres RU ====================

const List<({int id, String name})> _tmdbTvGenresRu = <({int id, String name})>[
  (id: 10759, name: 'Боевик и Приключения'),
  (id: 16, name: 'мультфильм'),
  (id: 35, name: 'комедия'),
  (id: 80, name: 'криминал'),
  (id: 99, name: 'документальный'),
  (id: 18, name: 'драма'),
  (id: 10751, name: 'семейный'),
  (id: 10762, name: 'Детский'),
  (id: 9648, name: 'детектив'),
  (id: 10763, name: 'Новости'),
  (id: 10764, name: 'Реалити-шоу'),
  (id: 10765, name: 'НФ и Фэнтези'),
  (id: 10766, name: 'Мыльная опера'),
  (id: 10767, name: 'Ток-шоу'),
  (id: 10768, name: 'Война и Политика'),
  (id: 37, name: 'вестерн'),
];

// ==================== IGDB Genres ====================

const List<({int id, String name})> _igdbGenres = <({int id, String name})>[
  (id: 31, name: 'Adventure'),
  (id: 33, name: 'Arcade'),
  (id: 35, name: 'Card & Board Game'),
  (id: 4, name: 'Fighting'),
  (id: 25, name: "Hack and slash/Beat 'em up"),
  (id: 32, name: 'Indie'),
  (id: 36, name: 'MOBA'),
  (id: 7, name: 'Music'),
  (id: 30, name: 'Pinball'),
  (id: 8, name: 'Platform'),
  (id: 2, name: 'Point-and-click'),
  (id: 9, name: 'Puzzle'),
  (id: 26, name: 'Quiz/Trivia'),
  (id: 10, name: 'Racing'),
  (id: 11, name: 'Real Time Strategy (RTS)'),
  (id: 12, name: 'Role-playing (RPG)'),
  (id: 5, name: 'Shooter'),
  (id: 13, name: 'Simulator'),
  (id: 14, name: 'Sport'),
  (id: 15, name: 'Strategy'),
  (id: 24, name: 'Tactical'),
  (id: 16, name: 'Turn-based strategy (TBS)'),
  (id: 34, name: 'Visual Novel'),
];

// ==================== VNDB Tags ====================

const List<({String id, String name})> _vndbTags = <({String id, String name})>[
  (id: 'g133', name: 'Male Protagonist'),
  (id: 'g96', name: 'Romance'),
  (id: 'g134', name: 'Female Protagonist'),
  (id: 'g2', name: 'Fantasy'),
  (id: 'g147', name: 'Drama'),
  (id: 'g3561', name: 'Student'),
  (id: 'g373', name: 'Student Heroine'),
  (id: 'g202', name: 'Fictional Beings'),
  (id: 'g533', name: 'Big Breast Sizes Heroine'),
  (id: 'g52', name: 'Earth'),
  (id: 'g3564', name: 'High School Student'),
  (id: 'g544', name: 'Student Protagonist'),
  (id: 'g3204', name: 'Heroine with Big Breasts'),
  (id: 'g47', name: 'School'),
  (id: 'g104', name: 'Comedy'),
  (id: 'g167', name: 'Health Issues'),
  (id: 'g19', name: 'Mystery'),
  (id: 'g3171', name: 'High School Student Heroine'),
  (id: 'g143', name: 'Modern Day'),
  (id: 'g253', name: 'Psychological Problems'),
  (id: 'g123', name: 'Non-human Heroine'),
  (id: 'g268', name: 'Only a Single Heroine'),
  (id: 'g137', name: 'Adult Protagonist'),
  (id: 'g322', name: 'Crime'),
  (id: 'g28', name: 'Organizations'),
  (id: 'g105', name: 'Science Fiction'),
  (id: 'g465', name: 'Adult Heroine'),
  (id: 'g60', name: 'Modern Day Earth'),
  (id: 'g157', name: 'Violence'),
  (id: 'g394', name: 'Pregnancy'),
  (id: 'g7', name: 'Horror'),
  (id: 'g98', name: 'Boy x Boy Romance'),
  (id: 'g169', name: 'Relationship Problems'),
  (id: 'g996', name: 'Monsters'),
  (id: 'g308', name: 'Domicile'),
  (id: 'g191', name: 'Heroine with Glasses'),
  (id: 'g492', name: 'Divine Beings'),
  (id: 'g3502', name: 'Gender and Sexuality Related'),
  (id: 'g168', name: 'Life and Death Drama'),
  (id: 'g506', name: 'Gender Bending'),
  (id: 'g792', name: 'Dark Skinned Characters'),
  (id: 'g154', name: 'Loli Heroine'),
  (id: 'g756', name: 'Only Virgin Heroines'),
  (id: 'g65', name: 'Fighting Heroine'),
  (id: 'g201', name: "Protagonist's Childhood Friend as a Heroine"),
  (id: 'g464', name: 'Heroine with Sexual Experience'),
  (id: 'g1184', name: 'High School Student Protagonist'),
  (id: 'g1673', name: 'Jealousy'),
  (id: 'g97', name: 'Girl x Girl Romance'),
  (id: 'g875', name: 'Twin Tail Heroine'),
  (id: 'g141', name: 'Past'),
  (id: 'g2002', name: 'Boy x Boy Romance Only'),
  (id: 'g221', name: 'Modern Day Japan'),
  (id: 'g12', name: 'Action'),
  (id: 'g602', name: 'Tsundere Heroine'),
  (id: 'g226', name: "Protagonist's Sister as a Heroine"),
  (id: 'g48', name: 'High School'),
  (id: 'g139', name: 'Fighting Protagonist'),
  (id: 'g287', name: 'Immortal Heroine'),
  (id: 'g491', name: 'Undead'),
  (id: 'g2252', name: 'Perverted Heroine'),
  (id: 'g400', name: 'Non-human Protagonist'),
  (id: 'g454', name: 'Slice of Life'),
  (id: 'g973', name: 'Adult Hero'),
  (id: 'g370', name: 'Protagonist with Health Issues'),
  (id: 'g259', name: 'Fictional World'),
  (id: 'g4', name: 'Magic'),
  (id: 'g420', name: 'Under the Same Roof'),
  (id: 'g481', name: 'Demons'),
  (id: 'g374', name: 'Heroine with Health Issues'),
  (id: 'g3562', name: 'University Student'),
  (id: 'g927', name: 'Non-human Hero'),
  (id: 'g160', name: 'Bloody Scenes'),
  (id: 'g753', name: 'Kemonomimi'),
  (id: 'g752', name: 'Furry'),
  (id: 'g1343', name: 'Homicide'),
  (id: 'g3545', name: 'Sex Industry'),
  (id: 'g177', name: 'Teacher Heroine'),
  (id: 'g589', name: 'Leader Heroine'),
  (id: 'g13', name: 'Combat'),
  (id: 'g515', name: 'Married Heroine'),
  (id: 'g880', name: 'Protagonist in Relationship'),
  (id: 'g1441', name: 'Only a Single Hero'),
  (id: 'g710', name: 'Friendship'),
  (id: 'g677', name: 'Ponytail Heroine'),
  (id: 'g980', name: 'Death of Protagonist'),
  (id: 'g494', name: 'Divine Heroine'),
  (id: 'g1986', name: 'Girl x Girl Romance Only'),
  (id: 'g6', name: 'Superpowers'),
  (id: 'g2232', name: 'Only Adult Heroines'),
  (id: 'g1971', name: 'Heroine with Children'),
  (id: 'g587', name: 'Small Breast Sizes Heroine (Non-Loli)'),
  (id: 'g1716', name: 'From Other Media'),
  (id: 'g1185', name: 'University Student Protagonist'),
  (id: 'g3183', name: 'Heroine with Huge Breasts'),
  (id: 'g594', name: 'Dark Skinned Heroine'),
  (id: 'g1207', name: 'Past Earth'),
  (id: 'g1955', name: 'Kissing Scene'),
  (id: 'g461', name: 'Heroine with Zettai Ryouiki'),
  (id: 'g658', name: 'Artist Heroine'),
];

// ==================== IGDB Platforms ====================

const List<({int id, String name, String? abbreviation})> _platforms =
    <({int id, String name, String? abbreviation})>[
  (id: 3, name: 'Linux', abbreviation: 'Linux'),
  (id: 4, name: 'Nintendo 64', abbreviation: 'N64'),
  (id: 5, name: 'Wii', abbreviation: 'Wii'),
  (id: 6, name: 'PC (Microsoft Windows)', abbreviation: 'PC'),
  (id: 7, name: 'PlayStation', abbreviation: 'PS1'),
  (id: 8, name: 'PlayStation 2', abbreviation: 'PS2'),
  (id: 9, name: 'PlayStation 3', abbreviation: 'PS3'),
  (id: 11, name: 'Xbox', abbreviation: 'XBOX'),
  (id: 12, name: 'Xbox 360', abbreviation: 'X360'),
  (id: 13, name: 'DOS', abbreviation: 'DOS'),
  (id: 14, name: 'Mac', abbreviation: 'Mac'),
  (id: 15, name: 'Commodore C64/128/MAX', abbreviation: 'C64'),
  (id: 16, name: 'Amiga', abbreviation: 'Amiga'),
  (id: 18, name: 'Nintendo Entertainment System', abbreviation: 'NES'),
  (id: 19, name: 'Super Nintendo Entertainment System', abbreviation: 'SNES'),
  (id: 20, name: 'Nintendo DS', abbreviation: 'NDS'),
  (id: 21, name: 'Nintendo GameCube', abbreviation: 'NGC'),
  (id: 22, name: 'Game Boy Color', abbreviation: 'GBC'),
  (id: 23, name: 'Dreamcast', abbreviation: 'DC'),
  (id: 24, name: 'Game Boy Advance', abbreviation: 'GBA'),
  (id: 25, name: 'Amstrad CPC', abbreviation: 'ACPC'),
  (id: 26, name: 'ZX Spectrum', abbreviation: 'ZXS'),
  (id: 27, name: 'MSX', abbreviation: 'MSX'),
  (id: 29, name: 'Sega Mega Drive/Genesis', abbreviation: 'Genesis/MegaDrive'),
  (id: 30, name: 'Sega 32X', abbreviation: 'Sega32'),
  (id: 32, name: 'Sega Saturn', abbreviation: 'Saturn'),
  (id: 33, name: 'Game Boy', abbreviation: 'Game Boy'),
  (id: 34, name: 'Android', abbreviation: 'Android'),
  (id: 35, name: 'Sega Game Gear', abbreviation: 'Game Gear'),
  (id: 37, name: 'Nintendo 3DS', abbreviation: '3DS'),
  (id: 38, name: 'PlayStation Portable', abbreviation: 'PSP'),
  (id: 39, name: 'iOS', abbreviation: 'iOS'),
  (id: 41, name: 'Wii U', abbreviation: 'WiiU'),
  (id: 42, name: 'N-Gage', abbreviation: 'NGage'),
  (id: 44, name: 'Tapwave Zodiac', abbreviation: 'zod'),
  (id: 46, name: 'PlayStation Vita', abbreviation: 'Vita'),
  (id: 47, name: 'Virtual Console', abbreviation: 'VC'),
  (id: 48, name: 'PlayStation 4', abbreviation: 'PS4'),
  (id: 49, name: 'Xbox One', abbreviation: 'XONE'),
  (id: 50, name: '3DO Interactive Multiplayer', abbreviation: '3DO'),
  (id: 51, name: 'Family Computer Disk System', abbreviation: 'fds'),
  (id: 52, name: 'Arcade', abbreviation: 'Arcade'),
  (id: 53, name: 'MSX2', abbreviation: 'MSX2'),
  (id: 55, name: 'Legacy Mobile Device', abbreviation: 'Mobile'),
  (id: 57, name: 'WonderSwan', abbreviation: 'WonderSwan'),
  (id: 58, name: 'Super Famicom', abbreviation: 'SFAM'),
  (id: 59, name: 'Atari 2600', abbreviation: 'Atari2600'),
  (id: 60, name: 'Atari 7800', abbreviation: 'Atari7800'),
  (id: 61, name: 'Atari Lynx', abbreviation: 'Lynx'),
  (id: 62, name: 'Atari Jaguar', abbreviation: 'Jaguar'),
  (id: 63, name: 'Atari ST/STE', abbreviation: 'Atari-ST'),
  (id: 64, name: 'Sega Master System/Mark III', abbreviation: 'SMS'),
  (id: 65, name: 'Atari 8-bit', abbreviation: 'Atari8bit'),
  (id: 66, name: 'Atari 5200', abbreviation: 'Atari5200'),
  (id: 67, name: 'Intellivision', abbreviation: 'intellivision'),
  (id: 68, name: 'ColecoVision', abbreviation: 'colecovision'),
  (id: 69, name: 'BBC Microcomputer System', abbreviation: 'bbcmicro'),
  (id: 70, name: 'Vectrex', abbreviation: 'vectrex'),
  (id: 71, name: 'Commodore VIC-20', abbreviation: 'vic-20'),
  (id: 72, name: 'Ouya', abbreviation: 'Ouya'),
  (id: 73, name: 'BlackBerry OS', abbreviation: 'blackberry'),
  (id: 74, name: 'Windows Phone', abbreviation: 'Win Phone'),
  (id: 75, name: 'Apple II', abbreviation: 'Apple]['),
  (id: 77, name: 'Sharp X1', abbreviation: 'x1'),
  (id: 78, name: 'Sega CD', abbreviation: 'Sega CD'),
  (id: 79, name: 'Neo Geo MVS', abbreviation: 'neogeomvs'),
  (id: 80, name: 'Neo Geo AES', abbreviation: 'neogeoaes'),
  (id: 82, name: 'Web browser', abbreviation: 'browser'),
  (id: 84, name: 'SG-1000', abbreviation: 'sg1000'),
  (id: 85, name: 'Donner Model 30', abbreviation: 'donner30'),
  (id: 86, name: 'TurboGrafx-16/PC Engine', abbreviation: 'turbografx16'),
  (id: 87, name: 'Virtual Boy', abbreviation: 'virtualboy'),
  (id: 88, name: 'Odyssey', abbreviation: 'odyssey'),
  (id: 89, name: 'Microvision', abbreviation: 'microvision'),
  (id: 90, name: 'Commodore PET', abbreviation: 'cpet'),
  (id: 91, name: 'Bally Astrocade', abbreviation: 'astrocade'),
  (id: 93, name: 'Commodore 16', abbreviation: 'C16'),
  (id: 94, name: 'Commodore Plus/4', abbreviation: 'C+4'),
  (id: 95, name: 'PDP-1', abbreviation: 'pdp1'),
  (id: 96, name: 'PDP-10', abbreviation: 'pdp10'),
  (id: 97, name: 'PDP-8', abbreviation: 'pdp-8'),
  (id: 98, name: 'DEC GT40', abbreviation: 'gt40'),
  (id: 99, name: 'Family Computer', abbreviation: 'famicom'),
  (id: 100, name: 'Analogue electronics', abbreviation: 'analogueelectronics'),
  (id: 101, name: 'Ferranti Nimrod Computer', abbreviation: 'nimrod'),
  (id: 102, name: 'EDSAC', abbreviation: 'edsac'),
  (id: 103, name: 'PDP-7', abbreviation: 'pdp-7'),
  (id: 104, name: 'HP 2100', abbreviation: 'hp2100'),
  (id: 105, name: 'HP 3000', abbreviation: 'hp3000'),
  (id: 106, name: 'SDS Sigma 7', abbreviation: 'sdssigma7'),
  (id: 107, name: 'Call-A-Computer time-shared mainframe computer system', abbreviation: 'call-a-computer'),
  (id: 108, name: 'PDP-11', abbreviation: 'pdp11'),
  (id: 109, name: 'CDC Cyber 70', abbreviation: 'cdccyber70'),
  (id: 110, name: 'PLATO', abbreviation: 'plato'),
  (id: 111, name: 'Imlac PDS-1', abbreviation: 'imlac-pds1'),
  (id: 112, name: 'Microcomputer', abbreviation: 'microcomputer'),
  (id: 113, name: 'OnLive Game System', abbreviation: 'OnLive'),
  (id: 114, name: 'Amiga CD32', abbreviation: 'Amiga CD32'),
  (id: 115, name: 'Apple IIGS', abbreviation: null),
  (id: 116, name: 'Acorn Archimedes', abbreviation: 'Acorn Archimedes'),
  (id: 117, name: 'Philips CD-i', abbreviation: 'Philips CDI'),
  (id: 118, name: 'FM Towns', abbreviation: null),
  (id: 119, name: 'Neo Geo Pocket', abbreviation: null),
  (id: 120, name: 'Neo Geo Pocket Color', abbreviation: null),
  (id: 121, name: 'Sharp X68000', abbreviation: null),
  (id: 122, name: 'Nuon', abbreviation: null),
  (id: 123, name: 'WonderSwan Color', abbreviation: null),
  (id: 124, name: 'SwanCrystal', abbreviation: null),
  (id: 125, name: 'PC-8800 Series', abbreviation: null),
  (id: 126, name: 'TRS-80', abbreviation: null),
  (id: 127, name: 'Fairchild Channel F', abbreviation: null),
  (id: 128, name: 'PC Engine SuperGrafx', abbreviation: 'supergrafx'),
  (id: 129, name: 'Texas Instruments TI-99', abbreviation: 'ti-99'),
  (id: 130, name: 'Nintendo Switch', abbreviation: 'Switch'),
  (id: 131, name: 'Super NES CD-ROM System', abbreviation: null),
  (id: 132, name: 'Amazon Fire TV', abbreviation: 'FireTV'),
  (id: 133, name: 'Odyssey 2 / Videopac G7000', abbreviation: null),
  (id: 134, name: 'Acorn Electron', abbreviation: 'Acorn Electron'),
  (id: 135, name: 'Hyper Neo Geo 64', abbreviation: null),
  (id: 136, name: 'Neo Geo CD', abbreviation: null),
  (id: 137, name: 'New Nintendo 3DS', abbreviation: 'New 3DS'),
  (id: 138, name: 'VC 4000', abbreviation: null),
  (id: 139, name: '1292 Advanced Programmable Video System', abbreviation: null),
  (id: 140, name: 'AY-3-8500', abbreviation: null),
  (id: 141, name: 'AY-3-8610', abbreviation: null),
  (id: 142, name: 'PC-50X Family', abbreviation: null),
  (id: 143, name: 'AY-3-8760', abbreviation: null),
  (id: 144, name: 'AY-3-8710', abbreviation: null),
  (id: 145, name: 'AY-3-8603', abbreviation: null),
  (id: 146, name: 'AY-3-8605', abbreviation: null),
  (id: 147, name: 'AY-3-8606', abbreviation: null),
  (id: 148, name: 'AY-3-8607', abbreviation: null),
  (id: 149, name: 'PC-9800 Series', abbreviation: null),
  (id: 150, name: 'Turbografx-16/PC Engine CD', abbreviation: null),
  (id: 151, name: 'TRS-80 Color Computer', abbreviation: null),
  (id: 152, name: 'FM-7', abbreviation: null),
  (id: 153, name: 'Dragon 32/64', abbreviation: null),
  (id: 154, name: 'Amstrad PCW', abbreviation: 'APCW'),
  (id: 155, name: 'Tatung Einstein', abbreviation: null),
  (id: 156, name: 'Thomson MO5', abbreviation: null),
  (id: 157, name: 'NEC PC-6000 Series', abbreviation: null),
  (id: 158, name: 'Commodore CDTV', abbreviation: null),
  (id: 159, name: 'Nintendo DSi', abbreviation: null),
  (id: 161, name: 'Windows Mixed Reality', abbreviation: null),
  (id: 162, name: 'Oculus VR', abbreviation: 'Oculus VR'),
  (id: 163, name: 'SteamVR', abbreviation: 'Steam VR'),
  (id: 164, name: 'Daydream', abbreviation: null),
  (id: 165, name: 'PlayStation VR', abbreviation: 'PSVR'),
  (id: 166, name: 'Pokémon mini', abbreviation: null),
  (id: 167, name: 'PlayStation 5', abbreviation: 'PS5'),
  (id: 169, name: 'Xbox Series X|S', abbreviation: 'Series X|S'),
  (id: 170, name: 'Google Stadia', abbreviation: 'Stadia'),
  (id: 203, name: 'DUPLICATE Stadia', abbreviation: null),
  (id: 236, name: 'Exidy Sorcerer', abbreviation: null),
  (id: 237, name: 'Sol-20', abbreviation: null),
  (id: 238, name: 'DVD Player', abbreviation: null),
  (id: 239, name: 'Blu-ray Player', abbreviation: null),
  (id: 240, name: 'Zeebo', abbreviation: null),
  (id: 274, name: 'PC-FX', abbreviation: null),
  (id: 306, name: 'Satellaview', abbreviation: null),
  (id: 307, name: 'Game & Watch', abbreviation: 'G&W'),
  (id: 308, name: 'Playdia', abbreviation: null),
  (id: 309, name: 'Evercade', abbreviation: 'Evercade'),
  (id: 339, name: 'Sega Pico', abbreviation: null),
  (id: 372, name: 'OOParts', abbreviation: null),
  (id: 373, name: 'Sinclair ZX81', abbreviation: null),
  (id: 374, name: 'Sharp MZ-2200', abbreviation: null),
  (id: 375, name: 'Epoch Cassette Vision', abbreviation: null),
  (id: 376, name: 'Epoch Super Cassette Vision', abbreviation: null),
  (id: 377, name: 'Plug & Play', abbreviation: null),
  (id: 378, name: 'Gamate', abbreviation: 'Gamate'),
  (id: 379, name: 'Game.com', abbreviation: null),
  (id: 380, name: 'Casio Loopy', abbreviation: null),
  (id: 381, name: 'Playdate', abbreviation: 'Playdate'),
  (id: 382, name: 'Intellivision Amico', abbreviation: null),
  (id: 384, name: 'Oculus Quest', abbreviation: null),
  (id: 385, name: 'Oculus Rift', abbreviation: null),
  (id: 386, name: 'Meta Quest 2', abbreviation: 'Meta Quest 2'),
  (id: 387, name: 'Oculus Go', abbreviation: null),
  (id: 388, name: 'Gear VR', abbreviation: 'Gear VR'),
  (id: 389, name: 'AirConsole', abbreviation: null),
  (id: 390, name: 'PlayStation VR2', abbreviation: 'PSVR2'),
  (id: 405, name: 'Windows Mobile', abbreviation: null),
  (id: 406, name: 'Sinclair QL', abbreviation: null),
  (id: 407, name: 'HyperScan', abbreviation: null),
  (id: 408, name: 'Mega Duck/Cougar Boy', abbreviation: null),
  (id: 409, name: 'Legacy Computer', abbreviation: null),
  (id: 410, name: 'Atari Jaguar CD', abbreviation: null),
  (id: 411, name: 'Handheld Electronic LCD', abbreviation: 'Handheld'),
  (id: 412, name: 'Leapster', abbreviation: null),
  (id: 413, name: 'Leapster Explorer/LeadPad Explorer', abbreviation: null),
  (id: 414, name: 'LeapTV', abbreviation: null),
  (id: 415, name: 'Watara/QuickShot Supervision', abbreviation: null),
  (id: 416, name: '64DD', abbreviation: '64DD'),
  (id: 417, name: 'Palm OS', abbreviation: null),
  (id: 438, name: 'Arduboy', abbreviation: 'Arduboy'),
  (id: 439, name: 'V.Smile', abbreviation: null),
  (id: 440, name: 'Visual Memory Unit / Visual Memory System', abbreviation: null),
  (id: 441, name: 'PocketStation', abbreviation: null),
  (id: 471, name: 'Meta Quest 3', abbreviation: 'Meta Quest 3'),
  (id: 472, name: 'visionOS', abbreviation: null),
  (id: 473, name: 'Arcadia 2001', abbreviation: null),
  (id: 474, name: 'Gizmondo', abbreviation: null),
  (id: 475, name: 'R-Zone', abbreviation: null),
  (id: 476, name: 'Apple Pippin', abbreviation: null),
  (id: 477, name: 'Panasonic Jungle', abbreviation: null),
  (id: 478, name: 'Panasonic M2', abbreviation: null),
  (id: 479, name: "Terebikko / See 'n Say Video Phone", abbreviation: null),
  (id: 480, name: "Super A'Can", abbreviation: null),
  (id: 481, name: 'Tomy Tutor / Pyuta / Grandstand Tutor', abbreviation: null),
  (id: 482, name: 'Sega CD 32X', abbreviation: null),
  (id: 486, name: 'Digiblast', abbreviation: null),
  (id: 487, name: 'LaserActive', abbreviation: null),
  (id: 504, name: 'Uzebox', abbreviation: null),
  (id: 505, name: 'Elektor TV Games Computer', abbreviation: null),
  (id: 506, name: 'Amstrad GX4000', abbreviation: 'GX4000'),
  (id: 507, name: 'Advanced Pico Beena', abbreviation: null),
  (id: 508, name: 'Nintendo Switch 2', abbreviation: 'Switch 2'),
  (id: 509, name: 'Polymega', abbreviation: null),
  (id: 510, name: 'e-Reader / Card-e Reader', abbreviation: null),
];
