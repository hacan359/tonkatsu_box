import 'package:core/models/item_status.dart';
import 'package:test/test.dart';

void main() {
  group('ItemStatus', () {
    group('значения enum', () {
      test('содержит 7 статусов', () {
        expect(ItemStatus.values.length, 7);
        expect(ItemStatus.values, contains(ItemStatus.notStarted));
        expect(ItemStatus.values, contains(ItemStatus.inProgress));
        expect(ItemStatus.values, contains(ItemStatus.completed));
        expect(ItemStatus.values, contains(ItemStatus.dropped));
        expect(ItemStatus.values, contains(ItemStatus.planned));
        expect(ItemStatus.values, contains(ItemStatus.replaying));
        expect(ItemStatus.values, contains(ItemStatus.ignored));
      });
    });

    group('value', () {
      test('value совпадает с ключом в БД/API', () {
        expect(ItemStatus.notStarted.value, 'not_started');
        expect(ItemStatus.inProgress.value, 'in_progress');
        expect(ItemStatus.completed.value, 'completed');
        expect(ItemStatus.dropped.value, 'dropped');
        expect(ItemStatus.planned.value, 'planned');
        expect(ItemStatus.replaying.value, 'replaying');
        expect(ItemStatus.ignored.value, 'ignored');
      });
    });

    group('fromString', () {
      test('парсит все валидные значения', () {
        expect(ItemStatus.fromString('not_started'), ItemStatus.notStarted);
        expect(ItemStatus.fromString('in_progress'), ItemStatus.inProgress);
        expect(ItemStatus.fromString('completed'), ItemStatus.completed);
        expect(ItemStatus.fromString('dropped'), ItemStatus.dropped);
        expect(ItemStatus.fromString('planned'), ItemStatus.planned);
        expect(ItemStatus.fromString('replaying'), ItemStatus.replaying);
        expect(ItemStatus.fromString('ignored'), ItemStatus.ignored);
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

    group('tryFromString', () {
      test('should return the matching status for every stored value', () {
        for (final ItemStatus status in ItemStatus.values) {
          expect(ItemStatus.tryFromString(status.value), status);
        }
      });

      test('should return null when the value is unknown or empty', () {
        expect(ItemStatus.tryFromString('on_hold'), isNull);
        expect(ItemStatus.tryFromString('unknown_status'), isNull);
        expect(ItemStatus.tryFromString(''), isNull);
      });
    });

    group('displayLabel', () {
      test('should be non-empty and unique for every status', () {
        final Set<String> labels = ItemStatus.values
            .map((ItemStatus s) => s.displayLabel)
            .toSet();
        expect(labels.length, ItemStatus.values.length);
        expect(labels.every((String l) => l.isNotEmpty), isTrue);
      });
    });

    
    
    group('statusSortPriority', () {
      test(
          'порядок: inProgress → replaying → planned → notStarted → '
          'completed → dropped → ignored', () {
        final List<ItemStatus> sorted = List<ItemStatus>.from(ItemStatus.values)
          ..sort(
            (ItemStatus a, ItemStatus b) =>
                a.statusSortPriority.compareTo(b.statusSortPriority),
          );

        expect(sorted, <ItemStatus>[
          ItemStatus.inProgress,
          ItemStatus.replaying,
          ItemStatus.planned,
          ItemStatus.notStarted,
          ItemStatus.completed,
          ItemStatus.dropped,
          ItemStatus.ignored,
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
