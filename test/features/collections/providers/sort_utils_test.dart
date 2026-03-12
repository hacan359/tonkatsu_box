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
  double? apiRating,
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
    game: Game(id: id * 100, name: name, rating: apiRating),
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
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.status,
        );

        // Ожидаемый порядок по statusSortPriority:
        // inProgress(0), planned(1), notStarted(2),
        // completed(3), dropped(4)
        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[2, 3, 4, 1, 5],
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
    // Rating sort (приоритет: userRating → apiRating → null в конец)
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

      test('fallback на apiRating когда userRating отсутствует', () {
        // Game.rating делится на 10 в _resolvedMedia → apiRating=80/10=8.0
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'User 5', userRating: 5),
          _makeItem(id: 2, name: 'API 8', apiRating: 80.0),
          _makeItem(id: 3, name: 'User 9', userRating: 9),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        // userRating 9, apiRating 8.0, userRating 5
        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[3, 2, 1],
        );
      });

      test('userRating приоритетнее apiRating при наличии обоих', () {
        final List<CollectionItem> items = <CollectionItem>[
          // userRating=3 используется вместо apiRating=95/10=9.5
          _makeItem(id: 1, name: 'Low user, high api',
              userRating: 3, apiRating: 95.0),
          // Только apiRating=70/10=7.0
          _makeItem(id: 2, name: 'Only api', apiRating: 70.0),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        // apiRating 7.0 > userRating 3.0
        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[2, 1],
        );
      });

      test('элементы без обоих рейтингов — в конце', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'No Rating'),
          _makeItem(id: 2, name: 'Has User', userRating: 5),
          // apiRating=60/10=6.0
          _makeItem(id: 3, name: 'Has API', apiRating: 60.0),
          _makeItem(id: 4, name: 'Also No Rating'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        // С рейтингом первые (6.0, 5.0), без обоих — в конце
        expect(result[0].id, 3); // apiRating 6.0
        expect(result[1].id, 2); // userRating 5
        expect(result[2].userRating, isNull);
        expect(result[2].apiRating, isNull);
        expect(result[3].userRating, isNull);
        expect(result[3].apiRating, isNull);
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

      test('isDescending=true с apiRating fallback', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'API 2', apiRating: 20.0), // 20/10=2.0
          _makeItem(id: 2, name: 'User 8', userRating: 8),
          _makeItem(id: 3, name: 'None'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
          isDescending: true,
        );

        // Инвертированный: none, api 2.0, user 8
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

      test('смешанные user/api/null рейтинги корректно сортируются', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A'),
          _makeItem(id: 2, name: 'B', userRating: 1),
          _makeItem(id: 3, name: 'C', apiRating: 50.0), // 50/10=5.0
          _makeItem(id: 4, name: 'D', userRating: 10),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.rating,
        );

        // 10, 5.0, 1, null
        expect(result[0].id, 4);
        expect(result[1].id, 3);
        expect(result[2].id, 2);
        expect(result[3].id, 1);
      });
    });

    // ---------------------------------------------------------------
    // External Rating sort
    // ---------------------------------------------------------------
    group('CollectionSortMode.externalRating', () {
      test('по умолчанию высший внешний рейтинг первым', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Low', apiRating: 30.0),
          _makeItem(id: 2, name: 'High', apiRating: 95.0),
          _makeItem(id: 3, name: 'Mid', apiRating: 70.0),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.externalRating,
        );

        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[2, 3, 1],
        );
      });

      test('null apiRating всегда в конце (по умолчанию)', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'No Rating'),
          _makeItem(id: 2, name: 'Has Rating', apiRating: 50.0),
          _makeItem(id: 3, name: 'Also No Rating'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.externalRating,
        );

        expect(result.first.id, 2);
        expect(result[1].apiRating, isNull);
        expect(result[2].apiRating, isNull);
      });

      test('isDescending=true — низший рейтинг первым, null в начале', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'Low', apiRating: 30.0),
          _makeItem(id: 2, name: 'High', apiRating: 95.0),
          _makeItem(id: 3, name: 'No Rating'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.externalRating,
          isDescending: true,
        );

        expect(
          result.map((CollectionItem i) => i.id).toList(),
          <int>[3, 1, 2],
        );
      });

      test('все null apiRating — стабильный порядок', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A'),
          _makeItem(id: 2, name: 'B'),
          _makeItem(id: 3, name: 'C'),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.externalRating,
        );

        expect(result.length, 3);
      });

      test('смешанные null и ненулевые apiRating корректно разделяются', () {
        final List<CollectionItem> items = <CollectionItem>[
          _makeItem(id: 1, name: 'A'),
          _makeItem(id: 2, name: 'B', apiRating: 10.0),
          _makeItem(id: 3, name: 'C'),
          _makeItem(id: 4, name: 'D', apiRating: 90.0),
        ];

        final List<CollectionItem> result = applySortMode(
          items,
          CollectionSortMode.externalRating,
        );

        expect(result[0].id, 4);
        expect(result[1].id, 2);
        expect(result[2].apiRating, isNull);
        expect(result[3].apiRating, isNull);
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

      test('externalRating возвращает пустой список', () {
        final List<CollectionItem> result = applySortMode(
          <CollectionItem>[],
          CollectionSortMode.externalRating,
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
