// Маппинг RetroAchievements игр на IGDB.

import '../../shared/models/game.dart';
import '../../shared/models/ra_game_progress.dart';
import '../api/igdb_api.dart';

/// Маппинг RA ConsoleID → IGDB Platform ID и поиск игр в IGDB.
class RaToIgdbMapper {
  /// Создаёт [RaToIgdbMapper].
  RaToIgdbMapper(this._igdbApi);

  final IgdbApi _igdbApi;

  /// RA ConsoleID → список IGDB Platform ID.
  ///
  /// Первый элемент — основной IGDB ID (используется при импорте из RA).
  /// Остальные — алиасы (региональные варианты в IGDB).
  ///
  /// Источник RA ConsoleID: rcheevos rc_consoles.h
  /// Источник IGDB Platform ID: таблица platforms в БД.
  static const Map<int, List<int>> consolePlatformMap = <int, List<int>>{
    1: <int>[29], // Genesis/Mega Drive
    2: <int>[4], // Nintendo 64
    3: <int>[19, 58], // SNES / Super Famicom
    4: <int>[33], // Game Boy
    5: <int>[24], // Game Boy Advance
    6: <int>[22], // Game Boy Color
    7: <int>[18, 99], // NES / Family Computer
    8: <int>[86, 128], // PC Engine/TurboGrafx-16 / SuperGrafx
    9: <int>[78], // Sega CD
    10: <int>[30], // 32X
    11: <int>[64], // Master System
    12: <int>[7], // PlayStation
    13: <int>[61], // Atari Lynx
    14: <int>[119, 120], // Neo Geo Pocket / Neo Geo Pocket Color
    15: <int>[35], // Game Gear
    16: <int>[21], // GameCube
    17: <int>[62], // Atari Jaguar
    18: <int>[20], // Nintendo DS
    19: <int>[5], // Wii
    21: <int>[8], // PlayStation 2
    23: <int>[133], // Magnavox Odyssey 2
    24: <int>[166], // Pokémon Mini
    25: <int>[59], // Atari 2600
    27: <int>[52], // Arcade
    28: <int>[87], // Virtual Boy
    29: <int>[27, 53], // MSX / MSX2
    33: <int>[84], // SG-1000
    37: <int>[25], // Amstrad CPC
    38: <int>[75], // Apple II
    39: <int>[32], // Saturn
    40: <int>[23], // Dreamcast
    41: <int>[38], // PlayStation Portable
    43: <int>[50], // 3DO Interactive Multiplayer
    44: <int>[68], // ColecoVision
    45: <int>[67], // Intellivision
    46: <int>[70], // Vectrex
    47: <int>[125], // PC-8800
    49: <int>[274], // PC-FX
    50: <int>[66], // Atari 5200
    51: <int>[60], // Atari 7800
    53: <int>[57, 123, 124], // WonderSwan / WonderSwan Color / SwanCrystal
    56: <int>[136], // Neo Geo CD
    57: <int>[127], // Fairchild Channel F
    60: <int>[307], // Game & Watch
    62: <int>[37, 137], // Nintendo 3DS / New Nintendo 3DS
    63: <int>[415], // Watara Supervision
    71: <int>[438], // Arduboy
    73: <int>[473], // Arcadia 2001
    74: <int>[138], // Interton VC 4000
    75: <int>[505], // Elektor TV Games Computer
    76: <int>[150], // PC Engine CD/TurboGrafx-CD
    77: <int>[410], // Atari Jaguar CD
    78: <int>[159], // Nintendo DSi
    80: <int>[504], // Uzebox
    81: <int>[51], // Famicom Disk System
  };

  /// Возвращает основной IGDB Platform ID для RA ConsoleID.
  ///
  /// Первый элемент списка — основной ID, используется при импорте из RA.
  static int? primaryIgdbPlatformId(int raConsoleId) {
    final List<int>? ids = consolePlatformMap[raConsoleId];
    return ids?.first;
  }

  /// Обратный маппинг: IGDB Platform ID → список RA Console IDs.
  ///
  /// Проверяет все IGDB ID (основные + алиасы) каждой RA консоли.
  static List<int> igdbToRaConsoleIds(int igdbPlatformId) {
    return consolePlatformMap.entries
        .where(
            (MapEntry<int, List<int>> e) => e.value.contains(igdbPlatformId))
        .map((MapEntry<int, List<int>> e) => e.key)
        .toList();
  }

  /// Ищет IGDB игру по данным из RA.
  ///
  /// Возвращает `null` если не найдено.
  Future<Game?> findIgdbGame(RaGameProgress raGame) async {
    final int? igdbPlatformId = primaryIgdbPlatformId(raGame.consoleId);

    final List<Game> results = await _igdbApi.searchGames(
      query: raGame.title,
      platformIds: igdbPlatformId != null ? <int>[igdbPlatformId] : null,
    );

    if (results.isEmpty) {
      // Fallback: поиск без фильтра платформы.
      if (igdbPlatformId != null) {
        final List<Game> fallback =
            await _igdbApi.searchGames(query: raGame.title);
        if (fallback.isEmpty) return null;
        return bestMatch(raGame.title, fallback);
      }
      return null;
    }

    return bestMatch(raGame.title, results);
  }

  static final RegExp _nonAlphaNum = RegExp('[^a-z0-9]');

  /// Находит наилучшее совпадение по названию среди кандидатов.
  ///
  /// Публичный static — используется как в поштучном поиске,
  /// так и в batch multiquery.
  static Game? bestMatch(String title, List<Game> candidates) {
    if (candidates.isEmpty) return null;

    final String normalized = normalize(title);

    // Точное совпадение.
    for (final Game game in candidates) {
      if (normalize(game.name) == normalized) return game;
    }

    // Starts with.
    for (final Game game in candidates) {
      final String gameName = normalize(game.name);
      if (gameName.startsWith(normalized) ||
          normalized.startsWith(gameName)) {
        return game;
      }
    }

    // Fallback: первый результат.
    return candidates.first;
  }

  /// Нормализует строку для сравнения: lowercase, только буквы и цифры.
  static String normalize(String s) =>
      s.toLowerCase().replaceAll(_nonAlphaNum, '');
}
