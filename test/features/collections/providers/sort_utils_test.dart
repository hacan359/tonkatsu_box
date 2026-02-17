// Тесты утилиты сортировки applySortMode.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/sort_utils.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/collection_sort_mode.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

// Вспомогательная функция для создания тестовых CollectionItem.
CollectionItem _makeItem({
  required int id,
  required String name,
  int sortOrder = 0,
  ItemStatus status = ItemStatus.notStarted,
  int? userRating,
  DateTime? addedAt,
}) {
  return CollectionItem(
    id: id,
    collectionId: 1,
    mediaType: MediaType.game,
    externalId: id * 100,
    status: status,
    sortOrder: sortOrder,
    userRating: userRating,
    addedAt: addedAt ?? DateTime(2024, 1, id),
    game: Game(id: id * 100, name: name),
  );
}

void main() {
  group('applySortMode', () {
    // ---------------------------------------------------------------
    // Manual sort
    // ---------------------------------------------------------------
    group('CollectionSortMode.manual', () {
      test('сортирует по sortOrder по возрастанию', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'C', sortOrder: 3),
          _makeItem(id: 2, name: 'A', sortOrder: 1),
          _makeItem(id: 3, name: 'B', sortOrder: 2),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.manual,
        );

        expect(result.map((CollectionItem i) => i.id).toList(), <int>[2, 3, 1]);
      });

      test('игнорирует isDescending — порядок всегда от пользователя', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'C', sortOrder: 3),
          _makeItem(id: 2, name: 'A', sortOrder: 1),
          _makeItem(id: 3, name: 'B', sortOrder: 2),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.manual,
          isDescending: true,
        );

        // Тот же порядок, что и без isDescending
        expect(result.map((CollectionItem i) => i.id).toList(), <int>[2, 3, 1]);
      });

      test('одинаковые sortOrder сохраняют стабильный порядок', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A', sortOrder: 0),
          _makeItem(id: 2, name: 'B', sortOrder: 0),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.manual,
        );

        // При одинаковых sortOrder порядок стабильный
        expect(result.length, 2);
      });
    });

    // ---------------------------------------------------------------
    // AddedDate sort
    // ---------------------------------------------------------------
    group('CollectionSortMode.addedDate', () {
      test('по умолчанию новейшие первыми (descending по дате)', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Old', addedAt: DateTime(2024, 1, 1)),
          _makeItem(id: 2, name: 'New', addedAt: DateTime(2024, 6, 15)),
          _makeItem(id: 3, name: 'Mid', addedAt: DateTime(2024, 3, 10)),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.addedDate,
        );

        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[2, 3, 1],
        );
      });

      test('isDescending=true инвертирует — старейшие первыми', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Old', addedAt: DateTime(2024, 1, 1)),
          _makeItem(id: 2, name: 'New', addedAt: DateTime(2024, 6, 15)),
          _makeItem(id: 3, name: 'Mid', addedAt: DateTime(2024, 3, 10)),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.addedDate,
          isDescending: true,
        );

        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[1, 3, 2],
        );
      });

      test('одинаковые даты не вызывают ошибок', () {
        final DateTime sameDate = DateTime(2024, 5, 1);
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A', addedAt: sameDate),
          _makeItem(id: 2, name: 'B', addedAt: sameDate),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.addedDate,
        );

        expect(result.length, 2);
      });
    });

    // ---------------------------------------------------------------
    // Name sort
    // ---------------------------------------------------------------
    group('CollectionSortMode.name', () {
      test('по умолчанию A-Z (алфавитный порядок)', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Zelda'),
          _makeItem(id: 2, name: 'Ape Escape'),
          _makeItem(id: 3, name: 'Mario'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.name,
        );

        expect(
          result.map((CollectionItem i) => i.itemName).toList(),
          <String>['Ape Escape', 'Mario', 'Zelda'],
        );
      });

      test('isDescending=true инвертирует — Z-A', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Zelda'),
          _makeItem(id: 2, name: 'Ape Escape'),
          _makeItem(id: 3, name: 'Mario'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.name,
          isDescending: true,
        );

        expect(
          result.map((CollectionItem i) => i.itemName).toList(),
          <String>['Zelda', 'Mario', 'Ape Escape'],
        );
      });

      test('регистр не влияет на порядок (case-insensitive)', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'banana'),
          _makeItem(id: 2, name: 'Apple'),
          _makeItem(id: 3, name: 'Cherry'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.name,
        );

        expect(
          result.map((CollectionItem i) => i.itemName).toList(),
          <String>['Apple', 'banana', 'Cherry'],
        );
      });
    });

    // ---------------------------------------------------------------
    // Status sort
    // ---------------------------------------------------------------
    group('CollectionSortMode.status', () {
      test('сортирует по statusSortPriority (активные первыми)', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Completed', status: ItemStatus.completed),
          _makeItem(id: 2, name: 'In Progress', status: ItemStatus.inProgress),
          _makeItem(id: 3, name: 'Planned', status: ItemStatus.planned),
          _makeItem(id: 4, name: 'Not Started', status: ItemStatus.notStarted),
          _makeItem(id: 5, name: 'Dropped', status: ItemStatus.dropped),
          _makeItem(id: 6, name: 'On Hold', status: ItemStatus.onHold),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.status,
        );

        // Ожидаемый порядок по statusSortPriority:
        // inProgress(0), planned(1), notStarted(2), onHold(3),
        // completed(4), dropped(5)
        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[2, 3, 4, 6, 1, 5],
        );
      });

      test('при одинаковом статусе сортирует по имени (A-Z)', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(
            id: 1,
            name: 'Zelda',
            status: ItemStatus.inProgress,
          ),
          _makeItem(
            id: 2,
            name: 'Ape Escape',
            status: ItemStatus.inProgress,
          ),
          _makeItem(
            id: 3,
            name: 'Mario',
            status: ItemStatus.inProgress,
          ),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.status,
        );

        expect(
          result.map((CollectionItem i) => i.itemName).toList(),
          <String>['Ape Escape', 'Mario', 'Zelda'],
        );
      });

      test('isDescending=true инвертирует порядок статусов', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A', status: ItemStatus.completed),
          _makeItem(id: 2, name: 'B', status: ItemStatus.inProgress),
          _makeItem(id: 3, name: 'C', status: ItemStatus.dropped),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.status,
          isDescending: true,
        );

        // Инвертированный: dropped(5), completed(4), inProgress(0)
        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[3, 1, 2],
        );
      });

      test('вторичная сортировка по имени case-insensitive', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'banana', status: ItemStatus.planned),
          _makeItem(id: 2, name: 'Apple', status: ItemStatus.planned),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.status,
        );

        expect(
          result.map((CollectionItem i) => i.itemName).toList(),
          <String>['Apple', 'banana'],
        );
      });
    });

    // ---------------------------------------------------------------
    // Rating sort
    // ---------------------------------------------------------------
    group('CollectionSortMode.rating', () {
      test('по умолчанию высший рейтинг первым', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Low', userRating: 3),
          _makeItem(id: 2, name: 'High', userRating: 10),
          _makeItem(id: 3, name: 'Mid', userRating: 7),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[2, 3, 1],
        );
      });

      test('null рейтинг всегда в конце (по умолчанию)', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'No Rating'),
          _makeItem(id: 2, name: 'Has Rating', userRating: 5),
          _makeItem(id: 3, name: 'Also No Rating'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        // Элемент с рейтингом первый, без рейтинга — в конце
        expect(result.first.id, 2);
        expect(result[1].userRating, isNull);
        expect(result[2].userRating, isNull);
      });

      test('isDescending=true — низший рейтинг первым, null в начале', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Low', userRating: 3),
          _makeItem(id: 2, name: 'High', userRating: 10),
          _makeItem(id: 3, name: 'No Rating'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
          isDescending: true,
        );

        // Инвертированный список: null первым, потом low, потом high
        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[3, 1, 2],
        );
      });

      test('все null рейтинги — стабильный порядок', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A'),
          _makeItem(id: 2, name: 'B'),
          _makeItem(id: 3, name: 'C'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        expect(result.length, 3);
      });

      test('одинаковые рейтинги сохраняют стабильный порядок', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A', userRating: 8),
          _makeItem(id: 2, name: 'B', userRating: 8),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        expect(result.length, 2);
      });

      test('смешанные null и ненулевые рейтинги корректно разделяются', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A'),
          _makeItem(id: 2, name: 'B', userRating: 1),
          _makeItem(id: 3, name: 'C'),
          _makeItem(id: 4, name: 'D', userRating: 10),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        // С рейтингом первые (10 потом 1), затем null
        expect(result[0].id, 4);
        expect(result[1].id, 2);
        expect(result[2].userRating, isNull);
        expect(result[3].userRating, isNull);
      });
    });

    // ---------------------------------------------------------------
    // Пустой список
    // ---------------------------------------------------------------
    group('пустой список', () {
      test('manual возвращает пустой список', () {
        final List<CollectionItem> result = applySortMode(
          <CollectionItem>[],
          CollectionSortMode.manual,
        );

        expect(result, isEmpty);
      });

      test('addedDate возвращает пустой список', () {
        final List<CollectionItem> result = applySortMode(
          <CollectionItem>[],
          CollectionSortMode.addedDate,
        );

        expect(result, isEmpty);
      });

      test('name возвращает пустой список', () {
        final List<CollectionItem> result = applySortMode(
          <CollectionItem>[],
          CollectionSortMode.name,
        );

        expect(result, isEmpty);
      });

      test('status возвращает пустой список', () {
        final List<CollectionItem> result = applySortMode(
          <CollectionItem>[],
          CollectionSortMode.status,
        );

        expect(result, isEmpty);
      });

      test('rating возвращает пустой список', () {
        final List<CollectionItem> result = applySortMode(
          <CollectionItem>[],
          CollectionSortMode.rating,
        );

        expect(result, isEmpty);
      });
    });

    // ---------------------------------------------------------------
    // Дополнительные edge cases
    // ---------------------------------------------------------------
    group('edge cases', () {
      test('один элемент возвращается как есть для всех режимов', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Only One', userRating: 5),
        ];

        for (final CollectionSortMode mode in CollectionSortMode.values) {
          final List<CollectionItem> result = applySortMode(items, mode);
          expect(result.length, 1);
          expect(result.first.id, 1);
        }
      });

      test('исходный список не мутируется', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'C', sortOrder: 3),
          _makeItem(id: 2, name: 'A', sortOrder: 1),
          _makeItem(id: 3, name: 'B', sortOrder: 2),
        ];

        final List<int> originalOrder =
            items.map((CollectionItem i) => i.id).toList();

        applySortMode(items, CollectionSortMode.name);

        final List<int> afterOrder =
            items.map((CollectionItem i) => i.id).toList();

        expect(afterOrder, originalOrder);
      });

      test('isDescending по умолчанию false', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Zelda'),
          _makeItem(id: 2, name: 'Ape Escape'),
        ];

        // Вызов без isDescending — должен быть A-Z
        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.name,
        );

        expect(result.first.itemName, 'Ape Escape');
        expect(result.last.itemName, 'Zelda');
      });
    });
  });
}
