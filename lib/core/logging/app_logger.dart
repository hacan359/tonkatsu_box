import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Настройка логирования для приложения.
///
/// Вызывается один раз в `main()` до `runApp()`.
/// Выводит логи через `dart:developer` — видны в консоли `flutter run`
/// и во вкладке Logging в Flutter DevTools.
abstract final class AppLogger {
  static final Logger _log = Logger('AppLogger');

  /// Инициализирует корневой логгер.
  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_onLogRecord);
  }

  /// Перехватывает необработанные ошибки Flutter и Dart.
  ///
  /// Вызывать один раз в main() после [init()].
  static void setupErrorHandlers() {
    // Ошибки в дереве виджетов (красный экран)
    FlutterError.onError = (FlutterErrorDetails details) {
      _log.severe(
        'Flutter error: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
      FlutterError.presentError(details);
    };

    // Необработанные ошибки вне Flutter (Dart isolate)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _log.severe('Unhandled platform error', error, stack);
      return true;
    };
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
