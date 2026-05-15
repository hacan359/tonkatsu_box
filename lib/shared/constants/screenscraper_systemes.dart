/// IGDB platform id → ScreenScraper `systemeid`.
///
/// Only retro/classic platforms that ScreenScraper actually covers. Modern
/// platforms (Switch, PS5, current PC) are intentionally absent — fall through
/// means no SS section is shown.
abstract final class ScreenScraperSystemes {
  static const Map<int, int> _igdbToSs = <int, int>{
    // Nintendo home
    18: 3, // NES
    99: 3, // Famicom
    19: 4, // SNES
    58: 4, // Super Famicom
    51: 106, // Famicom Disk System
    4: 14, // Nintendo 64
    21: 13, // GameCube
    5: 16, // Wii
    41: 18, // Wii U
    87: 11, // Virtual Boy
    // Nintendo portable
    33: 9, // Game Boy
    22: 10, // Game Boy Color
    24: 12, // Game Boy Advance
    20: 15, // Nintendo DS
    37: 17, // Nintendo 3DS
    // Sega
    29: 1, // Mega Drive / Genesis
    64: 2, // Master System
    32: 22, // Saturn
    23: 23, // Dreamcast
    78: 20, // Sega CD / Mega-CD
    30: 19, // Sega 32X
    35: 21, // Game Gear
    84: 109, // SG-1000
    // Sony
    7: 57, // PlayStation
    8: 58, // PlayStation 2
    9: 59, // PlayStation 3
    38: 61, // PSP
    46: 62, // PS Vita
    // Microsoft
    11: 32, // Xbox
    12: 33, // Xbox 360
    // Atari
    59: 26, // Atari 2600
    66: 40, // Atari 5200
    60: 41, // Atari 7800
    61: 28, // Atari Lynx
    62: 27, // Atari Jaguar
    // NEC
    86: 31, // TurboGrafx-16 / PC Engine
    150: 114, // PC Engine CD / TG-16 CD
    128: 105, // SuperGrafx
    // SNK
    80: 142, // Neo Geo AES
    79: 142, // Neo Geo MVS
    136: 70, // Neo Geo CD
    119: 25, // Neo Geo Pocket
    120: 82, // Neo Geo Pocket Color
    // Other classics
    50: 29, // 3DO
    52: 75, // Arcade (MAME)
    67: 115, // Intellivision
    68: 48, // ColecoVision
    70: 102, // Vectrex
    15: 66, // Commodore 64
    117: 133, // Philips CD-i
    123: 46, // WonderSwan Color
    // PC / DOS (SS covers DOS games well)
    13: 135, // DOS
  };

  /// Returns SS systemeid for an IGDB platform id, or `null` if unmapped
  /// (meaning the game is not in SS's coverage).
  static int? forIgdbPlatform(int igdbPlatformId) =>
      _igdbToSs[igdbPlatformId];

  static bool isSupported(int igdbPlatformId) =>
      _igdbToSs.containsKey(igdbPlatformId);
}
