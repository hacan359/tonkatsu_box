// Маппинг RetroAchievements игр на IGDB.

import '../../shared/models/game.dart';
import '../../shared/models/ra_game_progress.dart';
import '../api/igdb_api.dart';

/// Маппинг RA ConsoleID → IGDB Platform ID и поиск игр в IGDB.
class RaToIgdbMapper {
  /// Создаёт [RaToIgdbMapper].
  RaToIgdbMapper(this._igdbApi);

  final IgdbApi _igdbApi;

  /// RA ConsoleID → IGDB Platform ID.
  static const Map<int, int> consolePlatformMap = <int, int>{
    1: 29, // Genesis/Mega Drive
    2: 4, // Nintendo 64
    3: 19, // SNES
    4: 33, // Game Boy
    5: 24, // Game Boy Advance
    6: 22, // Game Boy Color
    7: 18, // NES
    8: 86, // TurboGrafx-16
    9: 78, // Sega CD
    10: 30, // Sega 32X
    11: 64, // Sega Master System
    12: 7, // PlayStation
    13: 61, // Atari Lynx
    14: 50, // 3DO
    15: 23, // Dreamcast
    18: 49, // Nintendo DS
    21: 8, // PlayStation 2
    25: 38, // PlayStation Portable
    27: 159, // Arcade
    28: 68, // Virtual Boy
    33: 20, // Game Gear
    34: 32, // Saturn
    37: 130, // PC Engine
    38: 35, // Game & Watch
    39: 24, // Game Boy Advance (subsets)
    41: 79, // Neo Geo MVS
    43: 136, // 3DO Interactive Multiplayer
    44: 70, // ColecoVision
    46: 62, // Atari 7800
    47: 60, // Atari Jaguar
    51: 59, // Atari 2600
    53: 37, // Nintendo 3DS
    56: 57, // WonderSwan
    57: 75, // WonderSwan Color
    76: 130, // PC Engine CD
    77: 18, // NES (subsets)
    78: 19, // SNES (subsets)
  };

  /// Ищет IGDB игру по данным из RA.
  ///
  /// Возвращает `null` если не найдено.
  Future<Game?> findIgdbGame(RaGameProgress raGame) async {
    final int? igdbPlatformId = consolePlatformMap[raGame.consoleId];

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
        return _bestMatch(raGame.title, fallback);
      }
      return null;
    }

    return _bestMatch(raGame.title, results);
  }

  /// Находит наилучшее совпадение по названию.
  Game? _bestMatch(String raTitle, List<Game> candidates) {
    final String normalized = _normalize(raTitle);

    // Точное совпадение.
    for (final Game game in candidates) {
      if (_normalize(game.name) == normalized) return game;
    }

    // Starts with.
    for (final Game game in candidates) {
      final String gameName = _normalize(game.name);
      if (gameName.startsWith(normalized) ||
          normalized.startsWith(gameName)) {
        return game;
      }
    }

    // Fallback: первый результат.
    return candidates.first;
  }

  /// Нормализует строку для сравнения: lowercase, только буквы и цифры.
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
}
