// Тесты для MediaFilterSheet.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/features/search/widgets/media_filter_sheet.dart';

void main() {
  const List<TmdbGenre> testGenres = <TmdbGenre>[
    TmdbGenre(id: 28, name: 'Action'),
    TmdbGenre(id: 12, name: 'Adventure'),
    TmdbGenre(id: 18, name: 'Drama'),
    TmdbGenre(id: 35, name: 'Comedy'),
  ];

  Widget buildTestWidget({
    List<TmdbGenre> genres = testGenres,
    int? selectedYear,
    List<int> selectedGenreIds = const <int>[],
    void Function({int? year, required List<int> genreIds})? onApply,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MediaFilterSheet(
          genres: genres,
          selectedYear: selectedYear,
          selectedGenreIds: selectedGenreIds,
          onApply: onApply ??
              ({int? year, required List<int> genreIds}) {},
        ),
      ),
    );
  }

  group('MediaFilterSheet', () {
    group('Render', () {
      testWidgets('should show title', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Filters'), findsOneWidget);
      });

      testWidgets('should show Release Year section', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Release Year'), findsOneWidget);
      });

      testWidgets('should show Genres section', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Genres'), findsOneWidget);
      });

      testWidgets('should show genre chips', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Action'), findsOneWidget);
        expect(find.text('Adventure'), findsOneWidget);
        expect(find.text('Drama'), findsOneWidget);
        expect(find.text('Comedy'), findsOneWidget);
      });

      testWidgets('should show Cancel and Apply buttons',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Apply'), findsOneWidget);
      });

      testWidgets('should show year hint', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('e.g. 2024'), findsOneWidget);
      });

      testWidgets('should show empty genres message when no genres',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(genres: const <TmdbGenre>[]),
        );
        await tester.pumpAndSettle();

        expect(find.text('No genres available'), findsOneWidget);
      });
    });

    group('Initial State', () {
      testWidgets('should show selected year', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedYear: 2024));
        await tester.pumpAndSettle();

        expect(find.text('2024'), findsOneWidget);
      });

      testWidgets('should show Clear All when year is set',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedYear: 2024));
        await tester.pumpAndSettle();

        expect(find.text('Clear All'), findsOneWidget);
      });

      testWidgets('should not show Clear All when empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Clear All'), findsNothing);
      });
    });

    group('Genre Selection', () {
      testWidgets('should toggle genre on tap', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Тапаем на Action
        await tester.tap(find.text('Action'));
        await tester.pumpAndSettle();

        // FilterChip должен стать selected — Clear All появляется
        expect(find.text('Clear All'), findsOneWidget);
      });

      testWidgets('should show selected genres from initial state',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(selectedGenreIds: const <int>[28, 18]),
        );
        await tester.pumpAndSettle();

        // Clear All должен быть виден
        expect(find.text('Clear All'), findsOneWidget);
      });
    });

    group('Clear All', () {
      testWidgets('should clear genres and year', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            selectedYear: 2024,
            selectedGenreIds: const <int>[28],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear All'));
        await tester.pumpAndSettle();

        // Clear All скрывается после очистки
        expect(find.text('Clear All'), findsNothing);
      });
    });

    group('Apply', () {
      testWidgets('should call onApply with selected values',
          (WidgetTester tester) async {
        int? appliedYear;
        List<int>? appliedGenres;

        await tester.pumpWidget(
          buildTestWidget(
            selectedYear: 2024,
            selectedGenreIds: const <int>[28, 18],
            onApply: ({int? year, required List<int> genreIds}) {
              appliedYear = year;
              appliedGenres = genreIds;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        expect(appliedYear, 2024);
        expect(appliedGenres, <int>[28, 18]);
      });

      testWidgets('should call onApply with null year when empty',
          (WidgetTester tester) async {
        int? appliedYear;
        bool yearWasNull = false;

        await tester.pumpWidget(
          buildTestWidget(
            onApply: ({int? year, required List<int> genreIds}) {
              appliedYear = year;
              yearWasNull = year == null;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        expect(appliedYear, isNull);
        expect(yearWasNull, isTrue);
      });

      testWidgets('should call onApply with empty genres when none selected',
          (WidgetTester tester) async {
        List<int>? appliedGenres;

        await tester.pumpWidget(
          buildTestWidget(
            onApply: ({int? year, required List<int> genreIds}) {
              appliedGenres = genreIds;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        expect(appliedGenres, isEmpty);
      });
    });

    group('Year Validation', () {
      testWidgets('should return null for invalid year',
          (WidgetTester tester) async {
        int? appliedYear;
        bool yearWasNull = false;

        await tester.pumpWidget(
          buildTestWidget(
            onApply: ({int? year, required List<int> genreIds}) {
              appliedYear = year;
              yearWasNull = year == null;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Вводим невалидный год
        final Finder yearField = find.byType(TextField);
        await tester.enterText(yearField, '123');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        // 123 < 1900, поэтому null
        expect(appliedYear, isNull);
        expect(yearWasNull, isTrue);
      });

      testWidgets('should accept valid year',
          (WidgetTester tester) async {
        int? appliedYear;

        await tester.pumpWidget(
          buildTestWidget(
            onApply: ({int? year, required List<int> genreIds}) {
              appliedYear = year;
            },
          ),
        );
        await tester.pumpAndSettle();

        final Finder yearField = find.byType(TextField);
        await tester.enterText(yearField, '2020');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        expect(appliedYear, 2020);
      });
    });
  });
}
