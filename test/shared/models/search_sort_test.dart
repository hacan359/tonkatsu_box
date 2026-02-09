import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/search_sort.dart';

void main() {
  group('SearchSortField', () {
    test('has 3 values', () {
      expect(SearchSortField.values.length, 3);
      expect(SearchSortField.values, contains(SearchSortField.relevance));
      expect(SearchSortField.values, contains(SearchSortField.date));
      expect(SearchSortField.values, contains(SearchSortField.rating));
    });
  });

  group('SearchSortOrder', () {
    test('has 2 values', () {
      expect(SearchSortOrder.values.length, 2);
      expect(SearchSortOrder.values, contains(SearchSortOrder.ascending));
      expect(SearchSortOrder.values, contains(SearchSortOrder.descending));
    });
  });

  group('SearchSort', () {
    test('creates default sort (relevance, descending)', () {
      const SearchSort sort = SearchSort();

      expect(sort.field, SearchSortField.relevance);
      expect(sort.order, SearchSortOrder.descending);
    });

    test('creates with custom values', () {
      const SearchSort sort = SearchSort(
        field: SearchSortField.date,
        order: SearchSortOrder.ascending,
      );

      expect(sort.field, SearchSortField.date);
      expect(sort.order, SearchSortOrder.ascending);
    });

    test('defaultSort matches default constructor', () {
      expect(SearchSort.defaultSort, const SearchSort());
    });

    test('isDefault returns true for relevance sort', () {
      const SearchSort sort = SearchSort();
      expect(sort.isDefault, isTrue);
    });

    test('isDefault returns true for relevance ascending', () {
      const SearchSort sort = SearchSort(
        field: SearchSortField.relevance,
        order: SearchSortOrder.ascending,
      );
      expect(sort.isDefault, isTrue);
    });

    test('isDefault returns false for date sort', () {
      const SearchSort sort = SearchSort(field: SearchSortField.date);
      expect(sort.isDefault, isFalse);
    });

    test('isDefault returns false for rating sort', () {
      const SearchSort sort = SearchSort(field: SearchSortField.rating);
      expect(sort.isDefault, isFalse);
    });

    group('copyWith', () {
      test('copies with new field', () {
        const SearchSort original = SearchSort();
        final SearchSort copy = original.copyWith(field: SearchSortField.date);

        expect(copy.field, SearchSortField.date);
        expect(copy.order, SearchSortOrder.descending);
      });

      test('copies with new order', () {
        const SearchSort original = SearchSort();
        final SearchSort copy =
            original.copyWith(order: SearchSortOrder.ascending);

        expect(copy.field, SearchSortField.relevance);
        expect(copy.order, SearchSortOrder.ascending);
      });

      test('copies with both fields changed', () {
        const SearchSort original = SearchSort();
        final SearchSort copy = original.copyWith(
          field: SearchSortField.rating,
          order: SearchSortOrder.ascending,
        );

        expect(copy.field, SearchSortField.rating);
        expect(copy.order, SearchSortOrder.ascending);
      });

      test('returns identical values when no params', () {
        const SearchSort original = SearchSort(
          field: SearchSortField.date,
          order: SearchSortOrder.ascending,
        );
        final SearchSort copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('toggleOrder', () {
      test('toggles from descending to ascending', () {
        const SearchSort sort = SearchSort(
          field: SearchSortField.date,
          order: SearchSortOrder.descending,
        );
        final SearchSort toggled = sort.toggleOrder();

        expect(toggled.field, SearchSortField.date);
        expect(toggled.order, SearchSortOrder.ascending);
      });

      test('toggles from ascending to descending', () {
        const SearchSort sort = SearchSort(
          field: SearchSortField.rating,
          order: SearchSortOrder.ascending,
        );
        final SearchSort toggled = sort.toggleOrder();

        expect(toggled.field, SearchSortField.rating);
        expect(toggled.order, SearchSortOrder.descending);
      });

      test('preserves field when toggling', () {
        const SearchSort sort = SearchSort(field: SearchSortField.relevance);
        final SearchSort toggled = sort.toggleOrder();

        expect(toggled.field, SearchSortField.relevance);
      });
    });

    group('equality', () {
      test('same values are equal', () {
        const SearchSort a = SearchSort(
          field: SearchSortField.date,
          order: SearchSortOrder.ascending,
        );
        const SearchSort b = SearchSort(
          field: SearchSortField.date,
          order: SearchSortOrder.ascending,
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different field not equal', () {
        const SearchSort a = SearchSort(field: SearchSortField.date);
        const SearchSort b = SearchSort(field: SearchSortField.rating);

        expect(a, isNot(b));
      });

      test('different order not equal', () {
        const SearchSort a = SearchSort(
          field: SearchSortField.date,
          order: SearchSortOrder.ascending,
        );
        const SearchSort b = SearchSort(
          field: SearchSortField.date,
          order: SearchSortOrder.descending,
        );

        expect(a, isNot(b));
      });

      test('identical instance is equal', () {
        const SearchSort sort = SearchSort();
        expect(sort == sort, isTrue);
      });
    });

    test('toString returns readable format', () {
      const SearchSort sort = SearchSort(
        field: SearchSortField.date,
        order: SearchSortOrder.ascending,
      );

      expect(
        sort.toString(),
        'SearchSort(SearchSortField.date, SearchSortOrder.ascending)',
      );
    });
  });
}
