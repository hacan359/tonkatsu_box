import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// Настройка логирования для приложения.
///
/// Вызывается один раз в `main()` до `runApp()`.
/// Выводит логи через `dart:developer` — видны в консоли `flutter run`
/// и во вкладке Logging в Flutter DevTools.
abstract final class AppLogger {
  /// Инициализирует корневой логгер.
  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_onLogRecord);
  }

  static void _onLogRecord(LogRecord record) {
    developer.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}
