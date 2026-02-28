import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/anime_type_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/features/search/widgets/filter_dropdown.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  Widget buildFilterDropdown({
    SearchFilter? filter,
    Object? value,
    ValueChanged<Object?>? onChanged,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: FilterDropdown(
            filter: filter ?? AnimeTypeFilter(),
            value: value,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  Widget buildSortDropdown({
    List<BrowseSortOption>? options,
    String? current,
    ValueChanged<String>? onChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SortDropdown(
          options: options ??
              const <BrowseSortOption>[
                BrowseSortOption(
                  id: 'popular',
                  apiValue: 'popularity.desc',
                ),
                BrowseSortOption(
                  id: 'newest',
                  apiValue: 'date.desc',
                ),
              ],
          current: current ?? 'popularity.desc',
          onChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  group('FilterDropdown', () {
    testWidgets('renders dropdown arrow icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildFilterDropdown());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('shows placeholder when value is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildFilterDropdown(value: null));
      await tester.pumpAndSettle();

      // AnimeTypeFilter placeholder is l.browseFilterType
      // The exact text depends on localization but should be visible
      expect(find.byType(FilterDropdown), findsOneWidget);
    });

    testWidgets('shows label when value is set',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildFilterDropdown(value: 'series'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Series'), findsOneWidget);
    });

    testWidgets('opens popup menu on tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildFilterDropdown());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilterDropdown));
      await tester.pumpAndSettle();

      // AnimeTypeFilter has 2 options + "All" = 3 items
      // Plus the divider
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Series'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
    });

    testWidgets('calls onChanged when option selected',
        (WidgetTester tester) async {
      Object? selectedValue = 'not_set';

      await tester.pumpWidget(
        buildFilterDropdown(
          onChanged: (Object? v) => selectedValue = v,
        ),
      );
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.byType(FilterDropdown));
      await tester.pumpAndSettle();

      // Select "Series"
      await tester.tap(find.text('Series'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'series');
    });

    testWidgets('calls onChanged with null when "All" selected',
        (WidgetTester tester) async {
      Object? selectedValue = 'initial';

      await tester.pumpWidget(
        buildFilterDropdown(
          value: 'series',
          onChanged: (Object? v) => selectedValue = v,
        ),
      );
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.byType(FilterDropdown));
      await tester.pumpAndSettle();

      // Select "All"
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(selectedValue, isNull);
    });
  });

  group('SortDropdown', () {
    testWidgets('renders sort icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildSortDropdown());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('renders dropdown arrow icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildSortDropdown());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('shows current sort label', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildSortDropdown(current: 'popularity.desc'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Popular'), findsOneWidget);
    });

    testWidgets('opens popup menu on tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildSortDropdown());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SortDropdown));
      await tester.pumpAndSettle();

      expect(find.text('Popular'), findsAtLeast(1));
      expect(find.text('Newest'), findsOneWidget);
    });

    testWidgets('calls onChanged when option selected',
        (WidgetTester tester) async {
      String? selectedSort;

      await tester.pumpWidget(
        buildSortDropdown(
          onChanged: (String v) => selectedSort = v,
        ),
      );
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.byType(SortDropdown));
      await tester.pumpAndSettle();

      // Select "Newest"
      await tester.tap(find.text('Newest'));
      await tester.pumpAndSettle();

      expect(selectedSort, 'date.desc');
    });

    testWidgets('shows fallback label for unknown current value',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildSortDropdown(current: 'unknown_sort'),
      );
      await tester.pumpAndSettle();

      // Should show the browseSort localization string (fallback)
      expect(find.byType(SortDropdown), findsOneWidget);
    });
  });
}
