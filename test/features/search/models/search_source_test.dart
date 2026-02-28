import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/shared/models/media_type.dart';

void main() {
  group('FilterOption', () {
    test('creates with required fields', () {
      const FilterOption option = FilterOption(
        id: 'action',
        label: 'Action',
        value: 28,
      );

      expect(option.id, 'action');
      expect(option.label, 'Action');
      expect(option.value, 28);
      expect(option.icon, isNull);
    });

    test('creates with icon', () {
      const FilterOption option = FilterOption(
        id: 'test',
        label: 'Test',
        icon: Icons.star,
        value: 'val',
      );

      expect(option.icon, Icons.star);
    });

    test('creates with null value', () {
      const FilterOption option = FilterOption(
        id: 'any',
        label: 'All',
      );

      expect(option.value, isNull);
    });

    test('equality is based on id only', () {
      const FilterOption a = FilterOption(
        id: 'genre',
        label: 'Genre A',
        value: 1,
      );
      const FilterOption b = FilterOption(
        id: 'genre',
        label: 'Genre B',
        value: 2,
      );
      const FilterOption c = FilterOption(
        id: 'other',
        label: 'Genre A',
        value: 1,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is based on id', () {
      const FilterOption a = FilterOption(id: 'x', label: 'X');
      const FilterOption b = FilterOption(id: 'x', label: 'Y', value: 42);

      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns readable format', () {
      const FilterOption option = FilterOption(
        id: 'action',
        label: 'Action',
      );

      expect(option.toString(), 'FilterOption(action, Action)');
    });

    test('can be used in Set correctly', () {
      const FilterOption a = FilterOption(id: 'a', label: 'A');
      const FilterOption a2 = FilterOption(id: 'a', label: 'A2');
      const FilterOption b = FilterOption(id: 'b', label: 'B');

      final Set<FilterOption> set = <FilterOption>{a, a2, b};
      expect(set.length, 2);
    });
  });

  group('BrowseSortOption', () {
    test('creates with required fields', () {
      const BrowseSortOption option = BrowseSortOption(
        id: 'popular',
        apiValue: 'popularity.desc',
      );

      expect(option.id, 'popular');
      expect(option.apiValue, 'popularity.desc');
    });

    test('equality is based on id', () {
      const BrowseSortOption a = BrowseSortOption(
        id: 'pop',
        apiValue: 'popularity.desc',
      );
      const BrowseSortOption b = BrowseSortOption(
        id: 'pop',
        apiValue: 'other',
      );
      const BrowseSortOption c = BrowseSortOption(
        id: 'new',
        apiValue: 'popularity.desc',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is based on id', () {
      const BrowseSortOption a = BrowseSortOption(
        id: 'x',
        apiValue: 'x',
      );
      const BrowseSortOption b = BrowseSortOption(
        id: 'x',
        apiValue: 'y',
      );

      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('BrowseResult', () {
    test('creates with required fields', () {
      const BrowseResult result = BrowseResult(
        items: <Object>[],
        mediaType: MediaType.movie,
      );

      expect(result.items, isEmpty);
      expect(result.mediaType, MediaType.movie);
      expect(result.hasMore, isFalse);
      expect(result.totalPages, 1);
      expect(result.currentPage, 1);
    });

    test('creates with all fields', () {
      const BrowseResult result = BrowseResult(
        items: <Object>['item1', 'item2'],
        mediaType: MediaType.game,
        hasMore: true,
        totalPages: 5,
        currentPage: 2,
      );

      expect(result.items, hasLength(2));
      expect(result.mediaType, MediaType.game);
      expect(result.hasMore, isTrue);
      expect(result.totalPages, 5);
      expect(result.currentPage, 2);
    });

    test('creates with tvShow media type', () {
      const BrowseResult result = BrowseResult(
        items: <Object>[],
        mediaType: MediaType.tvShow,
        hasMore: true,
      );

      expect(result.mediaType, MediaType.tvShow);
      expect(result.hasMore, isTrue);
    });

    test('creates with animation media type', () {
      const BrowseResult result = BrowseResult(
        items: <Object>[],
        mediaType: MediaType.animation,
      );

      expect(result.mediaType, MediaType.animation);
    });
  });

  group('SearchFilter (abstract)', () {
    test('subclass implements all required members', () {
      final _TestFilter filter = _TestFilter();

      expect(filter.key, 'test');
      expect(filter.allOption.id, 'all');
    });

    test('cacheKey defaults to key', () {
      final _TestFilter filter = _TestFilter();

      expect(filter.cacheKey, filter.key);
      expect(filter.cacheKey, 'test');
    });
  });

  group('SearchSource (abstract)', () {
    test('defaultSort returns first sort option', () {
      final SearchSource source = _TestSource();

      expect(
        source.defaultSort.id,
        source.sortOptions.first.id,
      );
    });

    test('subclass implements all required members', () {
      final SearchSource source = _TestSource();

      expect(source.id, 'test_source');
      expect(source.icon, Icons.star);
      expect(source.supportsBrowse, isTrue);
      expect(source.filters, hasLength(1));
      expect(source.sortOptions, hasLength(2));
    });
  });
}

// -- Test doubles --

class _TestFilter extends SearchFilter {
  @override
  String get key => 'test';

  @override
  String placeholder(dynamic l) => 'Test';

  @override
  FilterOption get allOption => const FilterOption(
        id: 'all',
        label: 'All',
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, dynamic l) async {
    return const <FilterOption>[];
  }
}

class _TestSource extends SearchSource {
  @override
  String get id => 'test_source';

  @override
  String label(dynamic l) => 'Test Source';

  @override
  IconData get icon => Icons.star;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[_TestFilter()];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'a', apiValue: 'a'),
        BrowseSortOption(id: 'b', apiValue: 'b'),
      ];

  @override
  String searchHint(dynamic l) => 'Search...';

  @override
  Future<BrowseResult> browse(
    Ref ref, {
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    return const BrowseResult(items: <Object>[], mediaType: MediaType.movie);
  }

  @override
  Future<BrowseResult> search(
    Ref ref, {
    required String query,
    required int page,
  }) async {
    return const BrowseResult(items: <Object>[], mediaType: MediaType.movie);
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
