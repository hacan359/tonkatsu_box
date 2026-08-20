import 'custom_card_entry.dart';

/// Both templates import cleanly as-is — the parser ignores the
/// `_`-prefixed hint keys of the JSON template.
abstract final class CustomCardsTemplate {
  static const String csvFileName = 'custom_cards_template.csv';
  static const String jsonFileName = 'custom_cards_template.json';

  /// CSV template: the full header row, no data rows.
  static String csv() => '${CustomCardFields.ordered.join(',')}\n';

  /// Two example cards with every field filled, plus `_...` hint keys
  /// documenting each field and its allowed values.
  static String json() => '''
[
  {
    "_help": "Every key except title and type is optional. Keys starting with _ are hints and are ignored by the import.",

    "_title": "REQUIRED. Card name.",
    "title": "Chrono Trigger",

    "_type": "REQUIRED. One of: game, movie, tv_show, animation, visual_novel, manga, anime, book.",
    "type": "game",

    "_alt_title": "Original or alternative name.",
    "alt_title": "クロノ・トリガー",

    "_description": "Free-form description shown on the card.",
    "description": "Time-travel JRPG by the dream team.",

    "_year": "Release year, number.",
    "year": 1995,

    "_genres": "Comma-separated genre list.",
    "genres": "RPG, Adventure",

    "_link": "External page URL opened from the card.",
    "link": "https://example.com/games/chrono-trigger",

    "_cover": "Cover image URL (http/https only); downloaded after import.",
    "cover": "https://example.com/covers/chrono-trigger.jpg",

    "_platform": "Abbreviation or name from the platform catalog (PS2, NES, SNES, ...); unmatched text is kept as free text.",
    "platform": "SNES",

    "_status": "One of: not_started, in_progress, completed, dropped, planned, replaying.",
    "status": "completed",

    "_rating": "Your rating, 0 to 10, decimals allowed.",
    "rating": 9.5,

    "_comment": "Personal note (the My Note field on the card).",
    "comment": "All endings unlocked.",

    "_rewatch_count": "How many times replayed / rewatched / reread.",
    "rewatch_count": 2,

    "_started_at": "Date you started, YYYY-MM-DD.",
    "started_at": "2024-01-05",

    "_completed_at": "Date you finished, YYYY-MM-DD.",
    "completed_at": "2024-02-10",

    "_time_spent_minutes": "Time spent, in minutes.",
    "time_spent_minutes": 3600,

    "_favorite": "true or false — the heart mark on the card.",
    "favorite": true,

    "_tags": "Comma-separated global tag names; missing tags are created automatically.",
    "tags": "jrpg, classics",

    "_current_episode": "Progress: episodes/chapters done (see the second example).",
    "_current_season": "Progress: seasons/volumes done (see the second example)."
  },
  {
    "title": "Fullmetal Alchemist: Brotherhood",
    "type": "anime",
    "alt_title": "鋼の錬金術師",
    "description": "Two brothers search for the Philosopher's Stone.",
    "year": 2009,
    "genres": "Action, Adventure, Drama",
    "link": "https://example.com/anime/fmab",
    "cover": "https://example.com/covers/fmab.jpg",

    "_format": "Only for manga/anime. Anime: TV, TV_SHORT, MOVIE, OVA, ONA, SPECIAL, MUSIC. Manga: MANGA, MANHWA, MANHUA, NOVEL, LIGHT_NOVEL, ONE_SHOT.",
    "format": "TV",

    "_unit_total": "Total episodes (anime/TV) or chapters (manga/book).",
    "unit_total": 64,

    "_unit_group_total": "Total seasons (TV) or volumes (manga).",
    "unit_group_total": 1,

    "_current_episode_example": "26 of 64 episodes watched:",
    "current_episode": 26,
    "current_season": 1,

    "status": "in_progress",
    "rating": 10,
    "comment": "",
    "rewatch_count": 0,
    "started_at": "2026-06-01",
    "favorite": false,
    "tags": "anime night"
  }
]
''';
}
