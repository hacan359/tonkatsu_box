// Парсер дат из формата Kodi JSON-RPC.
//
// Выделен в отдельный файл, чтобы использоваться из KodiMovie, KodiTvShow,
// KodiEpisode без дублирования.

/// Парсит строку Kodi-даты в [DateTime].
///
/// Kodi возвращает `"YYYY-MM-DD HH:MM:SS"` (без timezone) — трактуем как
/// local time устройства Kodi. Возвращает `null` для:
/// - `null` входа;
/// - пустой строки (Kodi так обозначает "никогда не воспроизводился");
/// - невалидного формата.
///
/// Также принимает строки с `T` между датой и временем (ISO 8601-like).
DateTime? parseKodiDateTime(String? raw) {
  if (raw == null) return null;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  // Заменяем пробел на T для DateTime.parse.
  final String normalized =
      trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}
