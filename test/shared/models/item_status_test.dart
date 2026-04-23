// Тесты для модели ItemStatus.
// Фокус: enum-контракт, сериализация (value / fromString), приоритеты
// сортировки, инвариант «все статусы визуально различимы» (уникальные
// цвета и иконки). Конкретные значения цветов / иконок не проверяем —
// это design decisions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/item_status.dart';

void main() {
  group('ItemStatus', () {
    group('значения enum', () {
      test('содержит 5 статусов', () {
        expect(ItemStatus.values.length, 5);
        expect(ItemStatus.values, contains(ItemStatus.notStarted));
        expect(ItemStatus.values, contains(ItemStatus.inProgress));
        expect(ItemStatus.values, contains(ItemStatus.completed));
        expect(ItemStatus.values, contains(ItemStatus.dropped));
        expect(ItemStatus.values, contains(ItemStatus.planned));
      });
    });

    group('value', () {
      test('value совпадает с ключом в БД/API', () {
        expect(ItemStatus.notStarted.value, 'not_started');
        expect(ItemStatus.inProgress.value, 'in_progress');
        expect(ItemStatus.completed.value, 'completed');
        expect(ItemStatus.dropped.value, 'dropped');
        expect(ItemStatus.planned.value, 'planned');
      });
    });

    group('fromString', () {
      test('парсит все валидные значения', () {
        expect(ItemStatus.fromString('not_started'), ItemStatus.notStarted);
        expect(ItemStatus.fromString('in_progress'), ItemStatus.inProgress);
        expect(ItemStatus.fromString('completed'), ItemStatus.completed);
        expect(ItemStatus.fromString('dropped'), ItemStatus.dropped);
        expect(ItemStatus.fromString('planned'), ItemStatus.planned);
      });

      test('fallback в notStarted для удалённого статуса on_hold', () {
        expect(ItemStatus.fromString('on_hold'), ItemStatus.notStarted);
      });

      test('fallback в notStarted для неизвестного значения', () {
        expect(ItemStatus.fromString('unknown_status'), ItemStatus.notStarted);
      });

      test('fallback в notStarted для пустой строки', () {
        expect(ItemStatus.fromString(''), ItemStatus.notStarted);
      });
    });

    group('color', () {
      test('каждый статус возвращает ненулевой цвет', () {
        for (final ItemStatus status in ItemStatus.values) {
          expect(status.color, isNotNull, reason: '${status.name} color');
        }
      });
    });

    group('materialIcon', () {
      test('все иконки уникальны (пользователь должен различать статусы)', () {
        final Set<IconData> icons = <IconData>{};
        for (final ItemStatus status in ItemStatus.values) {
          expect(icons.add(status.materialIcon), isTrue,
              reason: '${status.name} materialIcon should be unique');
        }
      });
    });

    group('statusSortPriority', () {
      test('порядок: inProgress → planned → notStarted → completed → dropped',
          () {
        final List<ItemStatus> sorted = List<ItemStatus>.from(ItemStatus.values)
          ..sort(
            (ItemStatus a, ItemStatus b) =>
                a.statusSortPriority.compareTo(b.statusSortPriority),
          );

        expect(sorted, <ItemStatus>[
          ItemStatus.inProgress,
          ItemStatus.planned,
          ItemStatus.notStarted,
          ItemStatus.completed,
          ItemStatus.dropped,
        ]);
      });

      test('все приоритеты уникальны', () {
        final List<int> allPriorities = ItemStatus.values
            .map((ItemStatus s) => s.statusSortPriority)
            .toList();
        final Set<int> uniquePriorities = allPriorities.toSet();

        expect(uniquePriorities.length, allPriorities.length);
      });

      test('все приоритеты неотрицательные', () {
        for (final ItemStatus status in ItemStatus.values) {
          expect(
            status.statusSortPriority >= 0,
            isTrue,
            reason: '${status.name} приоритет должен быть >= 0',
          );
        }
      });
    });
  });
}
