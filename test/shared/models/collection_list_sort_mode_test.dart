// Тесты для модели CollectionListSortMode

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/collection_list_sort_mode.dart';

void main() {
  group('CollectionListSortMode', () {
    group('значения enum', () {
      test('должен содержать 2 значения', () {
        expect(CollectionListSortMode.values.length, 2);
      });

      test('должен содержать все режимы сортировки', () {
        expect(
          CollectionListSortMode.values,
          contains(CollectionListSortMode.createdDate),
        );
        expect(
          CollectionListSortMode.values,
          contains(CollectionListSortMode.alphabetical),
        );
      });
    });

    group('value', () {
      test('createdDate должен иметь значение "created_date"', () {
        expect(CollectionListSortMode.createdDate.value, 'created_date');
      });

      test('alphabetical должен иметь значение "alphabetical"', () {
        expect(CollectionListSortMode.alphabetical.value, 'alphabetical');
      });
    });

    group('fromString', () {
      test('должен вернуть createdDate для "created_date"', () {
        final CollectionListSortMode result =
            CollectionListSortMode.fromString('created_date');

        expect(result, CollectionListSortMode.createdDate);
      });

      test('должен вернуть alphabetical для "alphabetical"', () {
        final CollectionListSortMode result =
            CollectionListSortMode.fromString('alphabetical');

        expect(result, CollectionListSortMode.alphabetical);
      });

      test('должен вернуть createdDate для неизвестного значения', () {
        final CollectionListSortMode result =
            CollectionListSortMode.fromString('unknown');

        expect(result, CollectionListSortMode.createdDate);
      });

      test('должен вернуть createdDate для пустой строки', () {
        final CollectionListSortMode result =
            CollectionListSortMode.fromString('');

        expect(result, CollectionListSortMode.createdDate);
      });

      test('должен быть чувствительным к регистру', () {
        final CollectionListSortMode result =
            CollectionListSortMode.fromString('Alphabetical');

        expect(result, CollectionListSortMode.createdDate);
      });
    });

    group('полнота свойств', () {
      test('все значения value должны быть уникальными', () {
        final List<String> allValues = CollectionListSortMode.values
            .map((CollectionListSortMode m) => m.value)
            .toList();
        final Set<String> uniqueValues = allValues.toSet();

        expect(uniqueValues.length, allValues.length);
      });

      test('каждый режим должен иметь непустое value', () {
        for (final CollectionListSortMode mode
            in CollectionListSortMode.values) {
          expect(
            mode.value.isNotEmpty,
            isTrue,
            reason: '${mode.name} value должен быть непустым',
          );
        }
      });
    });
  });
}
