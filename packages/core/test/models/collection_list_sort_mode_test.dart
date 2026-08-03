import 'package:core/models/collection.dart';
import 'package:core/models/collection_list_sort_mode.dart';
import 'package:test/test.dart';

void main() {
  int nextId = 0;
  Collection collection(String name, DateTime createdAt) => Collection(
        id: ++nextId,
        name: name,
        author: 'User',
        type: CollectionType.own,
        createdAt: createdAt,
      );

  group('CollectionListSortMode', () {
    group('compare', () {
      final Collection older = collection('Older', DateTime(2025, 1, 1));
      final Collection newer = collection('Newer', DateTime(2026, 6, 1));

      test('createdDate без descending ставит новые выше', () {
        final List<Collection> sorted = <Collection>[older, newer]
          ..sort((Collection a, Collection b) => CollectionListSortMode
              .createdDate
              .compare(a, b, descending: false));

        expect(sorted.first, same(newer));
      });

      test('createdDate с descending ставит старые выше', () {
        final List<Collection> sorted = <Collection>[newer, older]
          ..sort((Collection a, Collection b) => CollectionListSortMode
              .createdDate
              .compare(a, b, descending: true));

        expect(sorted.first, same(older));
      });

      test('alphabetical сортирует A→Z, с descending — Z→A', () {
        final Collection apple = collection('Apple', DateTime(2026, 1, 1));
        final Collection banana = collection('banana', DateTime(2026, 1, 2));

        final List<Collection> asc = <Collection>[banana, apple]
          ..sort((Collection a, Collection b) => CollectionListSortMode
              .alphabetical
              .compare(a, b, descending: false));
        final List<Collection> desc = <Collection>[apple, banana]
          ..sort((Collection a, Collection b) => CollectionListSortMode
              .alphabetical
              .compare(a, b, descending: true));

        expect(asc.first, same(apple));
        expect(desc.first, same(banana));
      });
    });

    group('значения enum', () {
      test('should contain 2 значения', () {
        expect(CollectionListSortMode.values.length, 2);
      });

      test('should contain все режимы сортировки', () {
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
      test('should return createdDate для "created_date"', () {
        final CollectionListSortMode result =
            CollectionListSortMode.fromString('created_date');

        expect(result, CollectionListSortMode.createdDate);
      });

      test('should return alphabetical для "alphabetical"', () {
        final CollectionListSortMode result =
            CollectionListSortMode.fromString('alphabetical');

        expect(result, CollectionListSortMode.alphabetical);
      });

      test('should return createdDate для неизвестного значения', () {
        final CollectionListSortMode result =
            CollectionListSortMode.fromString('unknown');

        expect(result, CollectionListSortMode.createdDate);
      });

      test('should return createdDate для пустой строки', () {
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
