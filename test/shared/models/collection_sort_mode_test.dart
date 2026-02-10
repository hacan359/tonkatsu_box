// Тесты для модели CollectionSortMode

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/collection_sort_mode.dart';

void main() {
  group('CollectionSortMode', () {
    group('значения enum', () {
      test('должен содержать 4 значения', () {
        expect(CollectionSortMode.values.length, 4);
      });

      test('должен содержать все режимы сортировки', () {
        expect(CollectionSortMode.values, contains(CollectionSortMode.manual));
        expect(
          CollectionSortMode.values,
          contains(CollectionSortMode.addedDate),
        );
        expect(CollectionSortMode.values, contains(CollectionSortMode.status));
        expect(CollectionSortMode.values, contains(CollectionSortMode.name));
      });
    });

    group('value', () {
      test('manual должен иметь значение "manual"', () {
        expect(CollectionSortMode.manual.value, 'manual');
      });

      test('addedDate должен иметь значение "added_date"', () {
        expect(CollectionSortMode.addedDate.value, 'added_date');
      });

      test('status должен иметь значение "status"', () {
        expect(CollectionSortMode.status.value, 'status');
      });

      test('name должен иметь значение "name"', () {
        expect(CollectionSortMode.name.value, 'name');
      });
    });

    group('displayLabel', () {
      test('manual должен отображаться как "Manual"', () {
        expect(CollectionSortMode.manual.displayLabel, 'Manual');
      });

      test('addedDate должен отображаться как "Date Added"', () {
        expect(CollectionSortMode.addedDate.displayLabel, 'Date Added');
      });

      test('status должен отображаться как "Status"', () {
        expect(CollectionSortMode.status.displayLabel, 'Status');
      });

      test('name должен отображаться как "Name"', () {
        expect(CollectionSortMode.name.displayLabel, 'Name');
      });
    });

    group('description', () {
      test('manual должен иметь описание "Custom order"', () {
        expect(CollectionSortMode.manual.description, 'Custom order');
      });

      test('addedDate должен иметь описание "Newest first"', () {
        expect(CollectionSortMode.addedDate.description, 'Newest first');
      });

      test('status должен иметь описание "Active first"', () {
        expect(CollectionSortMode.status.description, 'Active first');
      });

      test('name должен иметь описание "A to Z"', () {
        expect(CollectionSortMode.name.description, 'A to Z');
      });
    });

    group('fromString', () {
      test('должен вернуть manual для "manual"', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('manual');

        expect(result, CollectionSortMode.manual);
      });

      test('должен вернуть addedDate для "added_date"', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('added_date');

        expect(result, CollectionSortMode.addedDate);
      });

      test('должен вернуть status для "status"', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('status');

        expect(result, CollectionSortMode.status);
      });

      test('должен вернуть name для "name"', () {
        final CollectionSortMode result = CollectionSortMode.fromString('name');

        expect(result, CollectionSortMode.name);
      });

      test('должен вернуть addedDate для неизвестного значения', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('unknown_mode');

        expect(result, CollectionSortMode.addedDate);
      });

      test('должен вернуть addedDate для пустой строки', () {
        final CollectionSortMode result = CollectionSortMode.fromString('');

        expect(result, CollectionSortMode.addedDate);
      });

      test('должен быть чувствительным к регистру', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('Manual');

        expect(result, CollectionSortMode.addedDate);
      });

      test('должен вернуть addedDate для строки с пробелами', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString(' manual ');

        expect(result, CollectionSortMode.addedDate);
      });
    });

    group('полнота свойств', () {
      test('каждый режим должен иметь непустое value', () {
        for (final CollectionSortMode mode in CollectionSortMode.values) {
          expect(
            mode.value.isNotEmpty,
            isTrue,
            reason: '${mode.name} value должен быть непустым',
          );
        }
      });

      test('каждый режим должен иметь непустой displayLabel', () {
        for (final CollectionSortMode mode in CollectionSortMode.values) {
          expect(
            mode.displayLabel.isNotEmpty,
            isTrue,
            reason: '${mode.name} displayLabel должен быть непустым',
          );
        }
      });

      test('каждый режим должен иметь непустой description', () {
        for (final CollectionSortMode mode in CollectionSortMode.values) {
          expect(
            mode.description.isNotEmpty,
            isTrue,
            reason: '${mode.name} description должен быть непустым',
          );
        }
      });

      test('все значения value должны быть уникальными', () {
        final List<String> allValues =
            CollectionSortMode.values.map((CollectionSortMode m) => m.value).toList();
        final Set<String> uniqueValues = allValues.toSet();

        expect(uniqueValues.length, allValues.length);
      });
    });
  });
}
