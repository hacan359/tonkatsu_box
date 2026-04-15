// Тесты для чистых функций вычисления статусов и дат.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/item_status_logic.dart';

void main() {
  final DateTime now = DateTime(2026, 4, 15, 12, 30);
  final DateTime pastStart = DateTime(2026, 3, 1);
  final DateTime pastComplete = DateTime(2026, 4, 1);

  group('computeDatesForStatus', () {
    group('notStarted', () {
      test('очищает startedAt и completedAt', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.notStarted,
          currentStartedAt: pastStart,
          currentCompletedAt: pastComplete,
          now: now,
        );

        expect(result.status, ItemStatus.notStarted);
        expect(result.clearStartedAt, isTrue);
        expect(result.clearCompletedAt, isTrue);
        expect(result.lastActivityAt, now);
        expect(result.startedAt, isNull);
        expect(result.completedAt, isNull);
      });

      test('работает даже если даты уже были null', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.notStarted,
          currentStartedAt: null,
          currentCompletedAt: null,
          now: now,
        );

        expect(result.clearStartedAt, isTrue);
        expect(result.clearCompletedAt, isTrue);
        expect(result.lastActivityAt, now);
      });
    });

    group('inProgress', () {
      test('ставит startedAt в now если раньше был null', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.inProgress,
          currentStartedAt: null,
          currentCompletedAt: null,
          now: now,
        );

        expect(result.status, ItemStatus.inProgress);
        expect(result.startedAt, now);
        expect(result.clearStartedAt, isFalse);
        expect(result.clearCompletedAt, isTrue);
        expect(result.lastActivityAt, now);
      });

      test('сохраняет существующий startedAt', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.inProgress,
          currentStartedAt: pastStart,
          currentCompletedAt: pastComplete,
          now: now,
        );

        expect(result.startedAt, pastStart);
        expect(result.clearCompletedAt, isTrue);
      });
    });

    group('completed', () {
      test('ставит completedAt в now', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.completed,
          currentStartedAt: null,
          currentCompletedAt: null,
          now: now,
        );

        expect(result.status, ItemStatus.completed);
        expect(result.completedAt, now);
        expect(result.startedAt, now);
        expect(result.clearStartedAt, isFalse);
        expect(result.clearCompletedAt, isFalse);
        expect(result.lastActivityAt, now);
      });

      test('сохраняет существующий startedAt', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.completed,
          currentStartedAt: pastStart,
          currentCompletedAt: null,
          now: now,
        );

        expect(result.startedAt, pastStart);
        expect(result.completedAt, now);
      });

      test('перезаписывает completedAt даже если уже был', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.completed,
          currentStartedAt: pastStart,
          currentCompletedAt: pastComplete,
          now: now,
        );

        expect(result.completedAt, now);
      });

      test('принимает кастомную "now" — для внешнего sync', () {
        final DateTime kodiDate = DateTime(2026, 4, 12, 22, 30);
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.completed,
          currentStartedAt: null,
          currentCompletedAt: null,
          now: kodiDate,
        );

        expect(result.completedAt, kodiDate);
        expect(result.lastActivityAt, kodiDate);
        expect(result.startedAt, kodiDate);
      });
    });

    group('planned и dropped', () {
      test('planned не меняет startedAt/completedAt', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.planned,
          currentStartedAt: pastStart,
          currentCompletedAt: pastComplete,
          now: now,
        );

        expect(result.status, ItemStatus.planned);
        expect(result.startedAt, pastStart);
        expect(result.completedAt, pastComplete);
        expect(result.clearStartedAt, isFalse);
        expect(result.clearCompletedAt, isFalse);
        expect(result.lastActivityAt, now);
      });

      test('dropped не меняет startedAt/completedAt', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.dropped,
          currentStartedAt: pastStart,
          currentCompletedAt: pastComplete,
          now: now,
        );

        expect(result.status, ItemStatus.dropped);
        expect(result.startedAt, pastStart);
        expect(result.completedAt, pastComplete);
        expect(result.lastActivityAt, now);
      });

      test('dropped с null датами оставляет null', () {
        final StatusDatesUpdate result = computeDatesForStatus(
          newStatus: ItemStatus.dropped,
          currentStartedAt: null,
          currentCompletedAt: null,
          now: now,
        );

        expect(result.startedAt, isNull);
        expect(result.completedAt, isNull);
      });
    });
  });

  group('computeStatusForDates', () {
    test('completedAt ставит completed если был другой статус', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.inProgress,
        newCompletedAt: pastComplete,
        newStartedAt: null,
      );

      expect(result, ItemStatus.completed);
    });

    test('completedAt не меняет статус если уже completed', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.completed,
        newCompletedAt: pastComplete,
        newStartedAt: null,
      );

      expect(result, isNull);
    });

    test('startedAt из notStarted → inProgress', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.notStarted,
        newCompletedAt: null,
        newStartedAt: pastStart,
      );

      expect(result, ItemStatus.inProgress);
    });

    test('startedAt из planned → inProgress', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.planned,
        newCompletedAt: null,
        newStartedAt: pastStart,
      );

      expect(result, ItemStatus.inProgress);
    });

    test('startedAt из inProgress ничего не меняет', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.inProgress,
        newCompletedAt: null,
        newStartedAt: pastStart,
      );

      expect(result, isNull);
    });

    test('startedAt из dropped ничего не меняет', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.dropped,
        newCompletedAt: null,
        newStartedAt: pastStart,
      );

      expect(result, isNull);
    });

    test('startedAt из completed не меняет статус', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.completed,
        newCompletedAt: null,
        newStartedAt: pastStart,
      );

      expect(result, isNull);
    });

    test('completedAt имеет приоритет над startedAt', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.notStarted,
        newCompletedAt: pastComplete,
        newStartedAt: pastStart,
      );

      expect(result, ItemStatus.completed);
    });

    test('обе даты null — возвращает null', () {
      final ItemStatus? result = computeStatusForDates(
        currentStatus: ItemStatus.notStarted,
        newCompletedAt: null,
        newStartedAt: null,
      );

      expect(result, isNull);
    });
  });

  group('computeStatusFromProgress', () {
    group('dropped', () {
      test('никогда не меняется ни при каких флагах', () {
        for (final bool hasAny in <bool>[true, false]) {
          for (final bool fully in <bool>[true, false]) {
            expect(
              computeStatusFromProgress(
                currentStatus: ItemStatus.dropped,
                hasAnyProgress: hasAny,
                isFullyCompleted: fully,
              ),
              isNull,
              reason: 'dropped при hasAny=$hasAny fully=$fully',
            );
          }
        }
      });
    });

    group('без прогресса (hasAnyProgress == false)', () {
      test('из inProgress → notStarted', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.inProgress,
            hasAnyProgress: false,
            isFullyCompleted: false,
          ),
          ItemStatus.notStarted,
        );
      });

      test('из completed → notStarted (сняли все галочки)', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.completed,
            hasAnyProgress: false,
            isFullyCompleted: false,
          ),
          ItemStatus.notStarted,
        );
      });

      test('из notStarted не меняется', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.notStarted,
            hasAnyProgress: false,
            isFullyCompleted: false,
          ),
          isNull,
        );
      });

      test('из planned не меняется', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.planned,
            hasAnyProgress: false,
            isFullyCompleted: false,
          ),
          isNull,
        );
      });
    });

    group('полное завершение (isFullyCompleted == true)', () {
      test('из notStarted → completed', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.notStarted,
            hasAnyProgress: true,
            isFullyCompleted: true,
          ),
          ItemStatus.completed,
        );
      });

      test('из inProgress → completed', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.inProgress,
            hasAnyProgress: true,
            isFullyCompleted: true,
          ),
          ItemStatus.completed,
        );
      });

      test('из planned → completed', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.planned,
            hasAnyProgress: true,
            isFullyCompleted: true,
          ),
          ItemStatus.completed,
        );
      });

      test('из completed не меняется', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.completed,
            hasAnyProgress: true,
            isFullyCompleted: true,
          ),
          isNull,
        );
      });
    });

    group('частичный прогресс (hasAny && !fully)', () {
      test('из notStarted → inProgress', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.notStarted,
            hasAnyProgress: true,
            isFullyCompleted: false,
          ),
          ItemStatus.inProgress,
        );
      });

      test('из planned → inProgress', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.planned,
            hasAnyProgress: true,
            isFullyCompleted: false,
          ),
          ItemStatus.inProgress,
        );
      });

      test('из completed → inProgress (сняли пару галочек)', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.completed,
            hasAnyProgress: true,
            isFullyCompleted: false,
          ),
          ItemStatus.inProgress,
        );
      });

      test('из inProgress не меняется', () {
        expect(
          computeStatusFromProgress(
            currentStatus: ItemStatus.inProgress,
            hasAnyProgress: true,
            isFullyCompleted: false,
          ),
          isNull,
        );
      });
    });
  });

  group('mergeExternalStatus', () {
    group('защита dropped', () {
      test('локальный dropped не перезаписывается', () {
        for (final ItemStatus external in ItemStatus.values) {
          expect(
            mergeExternalStatus(
              currentStatus: ItemStatus.dropped,
              externalStatus: external,
            ),
            isNull,
            reason: 'dropped перезаписано на $external',
          );
        }
      });
    });

    group('external dropped блокируется для not-started состояний', () {
      test('notStarted ← external dropped: игнор', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.notStarted,
            externalStatus: ItemStatus.dropped,
          ),
          isNull,
        );
      });

      test('planned ← external dropped: игнор', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.planned,
            externalStatus: ItemStatus.dropped,
          ),
          isNull,
        );
      });

      test('inProgress ← external dropped: принимаем', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.inProgress,
            externalStatus: ItemStatus.dropped,
          ),
          ItemStatus.dropped,
        );
      });

      test('completed ← external dropped: принимаем', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.completed,
            externalStatus: ItemStatus.dropped,
          ),
          ItemStatus.dropped,
        );
      });
    });

    group('приоритет статусов', () {
      test('notStarted → planned: повышение', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.notStarted,
            externalStatus: ItemStatus.planned,
          ),
          ItemStatus.planned,
        );
      });

      test('notStarted → inProgress: повышение (Steam-случай)', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.notStarted,
            externalStatus: ItemStatus.inProgress,
          ),
          ItemStatus.inProgress,
        );
      });

      test('notStarted → completed: повышение (Kodi-случай)', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.notStarted,
            externalStatus: ItemStatus.completed,
          ),
          ItemStatus.completed,
        );
      });

      test('planned → inProgress: повышение', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.planned,
            externalStatus: ItemStatus.inProgress,
          ),
          ItemStatus.inProgress,
        );
      });

      test('planned → completed: повышение', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.planned,
            externalStatus: ItemStatus.completed,
          ),
          ItemStatus.completed,
        );
      });

      test('inProgress → completed: повышение', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.inProgress,
            externalStatus: ItemStatus.completed,
          ),
          ItemStatus.completed,
        );
      });
    });

    group('не понижает', () {
      test('completed → inProgress: игнор', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.completed,
            externalStatus: ItemStatus.inProgress,
          ),
          isNull,
        );
      });

      test('completed → planned: игнор', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.completed,
            externalStatus: ItemStatus.planned,
          ),
          isNull,
        );
      });

      test('completed → notStarted: игнор', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.completed,
            externalStatus: ItemStatus.notStarted,
          ),
          isNull,
        );
      });

      test('inProgress → planned: игнор', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.inProgress,
            externalStatus: ItemStatus.planned,
          ),
          isNull,
        );
      });

      test('inProgress → notStarted: игнор', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.inProgress,
            externalStatus: ItemStatus.notStarted,
          ),
          isNull,
        );
      });

      test('planned → notStarted: игнор', () {
        expect(
          mergeExternalStatus(
            currentStatus: ItemStatus.planned,
            externalStatus: ItemStatus.notStarted,
          ),
          isNull,
        );
      });
    });

    group('одинаковые статусы', () {
      test('игнорирует любое совпадение', () {
        for (final ItemStatus s in ItemStatus.values) {
          expect(
            mergeExternalStatus(currentStatus: s, externalStatus: s),
            isNull,
            reason: '$s не должен дать ненулевой результат',
          );
        }
      });
    });
  });
}
