// Информация о запущенном экземпляре Kodi для отображения в debug-панели.

/// Ответ метода `Application.GetProperties` / `JSONRPC.Version`.
///
/// Используется для человеко-читаемого отображения в "Test connection" и
/// Kodi Debug Panel: «Connected (Kodi 21.0 "Omega" on Living Room HTPC)».
class KodiApplicationInfo {
  /// Создаёт [KodiApplicationInfo].
  const KodiApplicationInfo({
    required this.versionMajor,
    required this.versionMinor,
    this.versionTag,
    this.name,
  });

  /// Парсит ответ `Application.GetProperties` с полями `version`/`name`.
  ///
  /// Kodi возвращает:
  /// ```json
  /// { "version": { "major": 21, "minor": 0, "tag": "stable" }, "name": "Kodi" }
  /// ```
  factory KodiApplicationInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? version =
        json['version'] as Map<String, dynamic>?;
    return KodiApplicationInfo(
      versionMajor: (version?['major'] as int?) ?? 0,
      versionMinor: (version?['minor'] as int?) ?? 0,
      versionTag: version?['tag'] as String?,
      name: json['name'] as String?,
    );
  }

  /// Major версия (например, 21 для "Omega").
  final int versionMajor;

  /// Minor версия.
  final int versionMinor;

  /// Tag сборки: `stable`, `beta`, `alpha`, `releasecandidate`, `prealpha`.
  final String? versionTag;

  /// Имя инстанса (обычно `"Kodi"`, может быть кастомное).
  final String? name;

  /// Короткая строка "21.0" / "21.0 beta".
  String get versionString {
    final String base = '$versionMajor.$versionMinor';
    if (versionTag == null || versionTag == 'stable') return base;
    return '$base $versionTag';
  }
}
