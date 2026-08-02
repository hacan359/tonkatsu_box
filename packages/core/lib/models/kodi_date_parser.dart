/// Kodi sends `YYYY-MM-DD HH:MM:SS` with no timezone, read here as the Kodi
/// host's local time. `null` on empty input — Kodi's way of saying "never".
DateTime? parseKodiDateTime(String? raw) {
  if (raw == null) return null;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final String normalized =
      trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}
