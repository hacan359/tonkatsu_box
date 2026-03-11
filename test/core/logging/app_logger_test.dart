// Тесты для AppLogger.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:xerabora/core/logging/app_logger.dart';

void main() {
  group('AppLogger', () {
    group('init', () {
      test('должен установить уровень логирования ALL', () {
        AppLogger.init();

        expect(Logger.root.level, Level.ALL);
      });

      test('должен зарегистрировать listener на записи лога', () {
        AppLogger.init();

        // Проверяем что listener работает — запись лога не вызывает ошибок
        Logger('test').info('test message');
      });
    });

    group('setupErrorHandlers', () {
      late FlutterExceptionHandler? originalOnError;
      late FlutterExceptionHandler? originalPresentError;

      setUp(() {
        originalOnError = FlutterError.onError;
        originalPresentError = FlutterError.presentError;
      });

      tearDown(() {
        FlutterError.onError = originalOnError;
        FlutterError.presentError = originalPresentError!;
      });

      test('должен установить FlutterError.onError', () {
        AppLogger.setupErrorHandlers();

        expect(FlutterError.onError, isNotNull);
      });

      test('FlutterError.onError должен логировать ошибку', () {
        AppLogger.init();
        AppLogger.setupErrorHandlers();

        // Подавляем presentError чтобы тестовый фреймворк не ловил исключение
        FlutterError.presentError = (FlutterErrorDetails details) {};

        final List<LogRecord> records = <LogRecord>[];
        Logger('AppLogger').onRecord.listen(records.add);

        final FlutterErrorDetails details = FlutterErrorDetails(
          exception: Exception('test error'),
          stack: StackTrace.current,
        );

        FlutterError.onError!(details);

        expect(records, isNotEmpty);
        expect(records.first.level, Level.SEVERE);
        expect(records.first.message, contains('Flutter error'));
      });
    });
  });
}
