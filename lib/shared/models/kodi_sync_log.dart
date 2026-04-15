// Запись лога Kodi sync для отображения в debug-панели.

/// Уровень записи лога Kodi sync.
enum KodiSyncLogLevel {
  /// Информационное сообщение (например, «Sync started», «Found N movies»).
  info,

  /// Предупреждение (например, «Item skipped: no uniqueid»).
  warn,

  /// Ошибка (например, «Connection failed: 401»).
  error,
}

/// Запись в лог Kodi sync.
///
/// Хранится только в памяти сервиса (list из ≤50 записей) — не уходит
/// в БД. Для postmortem'а пользователь копирует список в буфер и
/// отправляет репортер.
class KodiSyncLog {
  /// Создаёт [KodiSyncLog].
  const KodiSyncLog({
    required this.timestamp,
    required this.level,
    required this.message,
    this.detail,
  });

  /// Создаёт запись с `timestamp = DateTime.now()`.
  factory KodiSyncLog.now({
    required KodiSyncLogLevel level,
    required String message,
    String? detail,
  }) {
    return KodiSyncLog(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      detail: detail,
    );
  }

  /// Когда запись была создана.
  final DateTime timestamp;

  /// Уровень лога.
  final KodiSyncLogLevel level;

  /// Текст сообщения.
  final String message;

  /// Опциональные детали — stack trace, raw response и т.п.
  final String? detail;
}
