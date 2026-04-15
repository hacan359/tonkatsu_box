// Тесты для KodiSyncLog.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/kodi_sync_log.dart';

void main() {
  group('KodiSyncLog', () {
    test('создание с явным timestamp', () {
      final DateTime ts = DateTime(2026, 4, 15, 12);
      final KodiSyncLog log = KodiSyncLog(
        timestamp: ts,
        level: KodiSyncLogLevel.info,
        message: 'Sync started',
      );
      expect(log.timestamp, ts);
      expect(log.level, KodiSyncLogLevel.info);
      expect(log.message, 'Sync started');
      expect(log.detail, isNull);
    });

    test('detail опционален', () {
      final KodiSyncLog log = KodiSyncLog(
        timestamp: DateTime(2026),
        level: KodiSyncLogLevel.error,
        message: 'Connection failed',
        detail: 'HTTP 401',
      );
      expect(log.detail, 'HTTP 401');
    });

    test('KodiSyncLog.now() ставит текущее время', () {
      final DateTime before = DateTime.now();
      final KodiSyncLog log = KodiSyncLog.now(
        level: KodiSyncLogLevel.warn,
        message: 'Skipped item',
      );
      final DateTime after = DateTime.now();

      expect(
        log.timestamp.isAfter(before) ||
            log.timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        log.timestamp.isBefore(after) ||
            log.timestamp.isAtSameMomentAs(after),
        isTrue,
      );
      expect(log.level, KodiSyncLogLevel.warn);
    });

    test('все уровни лога определены', () {
      expect(KodiSyncLogLevel.values, <KodiSyncLogLevel>[
        KodiSyncLogLevel.info,
        KodiSyncLogLevel.warn,
        KodiSyncLogLevel.error,
      ]);
    });
  });
}
