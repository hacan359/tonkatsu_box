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
  ///
  /// Источник RA ConsoleID: API_GetConsoleIDs.php
  /// Источник IGDB Platform ID: таблица platforms в БД.
  static const Map<int, int> consolePlatformMap = <int, int>{
    1: 29, // Genesis/Mega Drive
    2: 4, // Nintendo 64
    3: 19, // SNES/Super Famicom
    4: 33, // Game Boy
    5: 24, // Game Boy Advance
    6: 22, // Game Boy Color
    7: 18, // NES/Famicom
    8: 86, // PC Engine/TurboGrafx-16
    9: 78, // Sega CD
    10: 30, // 32X
    11: 64, // Master System
    12: 7, // PlayStation
    13: 61, // Atari Lynx
    14: 119, // Neo Geo Pocket
    15: 20, // Game Gear
    16: 21, // GameCube
    17: 60, // Atari Jaguar
    18: 49, // Nintendo DS
    19: 5, // Wii
    21: 8, // PlayStation 2
    25: 59, // Atari 2600
    27: 52, // Arcade
    28: 68, // Virtual Boy
    33: 84, // SG-1000
    39: 32, // Saturn
    40: 23, // Dreamcast
    41: 38, // PlayStation Portable
    43: 50, // 3DO Interactive Multiplayer
    44: 70, // ColecoVision
    51: 62, // Atari 7800
    53: 57, // WonderSwan
    56: 136, // Neo Geo CD
    60: 35, // Game & Watch
    62: 37, // Nintendo 3DS
    76: 150, // PC Engine CD/TurboGrafx-CD
  };

  /// Обратный маппинг: IGDB Platform ID → список RA Console IDs.
  ///
  /// Один IGDB platform может соответствовать нескольким RA консолям
  /// (региональные варианты).
  static List<int> igdbToRaConsoleIds(int igdbPlatformId) {
    return consolePlatformMap.entries
        .where(
            (MapEntry<int, int> e) => e.value == igdbPlatformId)
        .map((MapEntry<int, int> e) => e.key)
        .toList();
  }

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
