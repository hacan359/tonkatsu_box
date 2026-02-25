// Widget tests for MediaDetailsSheet.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/widgets/media_details_sheet.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  // Helper to build the test widget that opens MediaDetailsSheet
  // as a modal bottom sheet.
  Widget buildTestApp({
    required String title,
    IconData icon = Icons.movie,
    String? overview,
    int? year,
    String? rating,
    List<String>? genres,
    String? extraInfo,
    String? posterUrl,
    VoidCallback? onAddToCollection,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MediaDetailsSheet(
                    title: title,
                    icon: icon,
                    overview: overview,
                    year: year,
                    rating: rating,
                    genres: genres,
                    extraInfo: extraInfo,
                    posterUrl: posterUrl,
                    onAddToCollection: onAddToCollection,
                  ),
                );
              },
              child: const Text('Open Sheet'),
            );
          },
        ),
      ),
    );
  }

  // Opens the bottom sheet and lets animations settle.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
  }

  // Opens the bottom sheet with multiple pump() calls instead of
  // pumpAndSettle, to avoid timeout from infinite animations
  // like CircularProgressIndicator inside CachedNetworkImage.
  Future<void> openSheetWithPump(WidgetTester tester) async {
    await tester.tap(find.text('Open Sheet'));
    // Pump several frames to let the sheet animate in.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('MediaDetailsSheet', () {
    testWidgets('renders title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'Inception'),
      );
      await openSheet(tester);

      expect(find.text('Inception'), findsOneWidget);
    });

    testWidgets('shows poster when posterUrl provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          title: 'With Poster',
          posterUrl: 'https://example.com/poster.jpg',
        ),
      );
      await openSheetWithPump(tester);

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('does not show poster when posterUrl is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'No Poster'),
      );
      await openSheet(tester);

      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('shows genres as Chip widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          title: 'Genre Movie',
          genres: <String>['Action', 'Sci-Fi', 'Drama'],
        ),
      );
      await openSheet(tester);

      expect(find.byType(Chip), findsNWidgets(3));
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
    });

    testWidgets('does not show genre chips when genres is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'No Genres'),
      );
      await openSheet(tester);

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('does not show genre chips when genres list is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'Empty Genres', genres: <String>[]),
      );
      await openSheet(tester);

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows year chip', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'Year Movie', year: 2023),
      );
      await openSheet(tester);

      expect(find.text('2023'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows rating chip', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'Rated Movie', rating: '8.5'),
      );
      await openSheet(tester);

      expect(find.text('8.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('shows add button when onAddToCollection provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          title: 'Addable',
          onAddToCollection: () {},
        ),
      );
      await openSheet(tester);

      // FilledButton.icon is used; look for the localized text.
      expect(
        find.text('Add to Collection'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('hides add button when onAddToCollection is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'Not Addable'),
      );
      await openSheet(tester);

      expect(find.text('Add to Collection'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets(
        'calls onAddToCollection and pops navigator when button tapped',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          title: 'Tap Test',
          onAddToCollection: () {
            callbackCalled = true;
          },
        ),
      );
      await openSheet(tester);

      // Sheet is visible.
      expect(find.text('Tap Test'), findsOneWidget);

      await tester.tap(find.text('Add to Collection'));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
      // Sheet should be popped (title no longer visible in the sheet).
      expect(find.text('Tap Test'), findsNothing);
    });

    testWidgets('shows overview text', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          title: 'Overview Movie',
          overview: 'A great movie about dreams within dreams.',
        ),
      );
      await openSheet(tester);

      expect(find.text('Description'), findsOneWidget);
      expect(
        find.text('A great movie about dreams within dreams.'),
        findsOneWidget,
      );
    });

    testWidgets('does not show overview section when overview is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'No Overview'),
      );
      await openSheet(tester);

      expect(find.text('Description'), findsNothing);
    });

    testWidgets('shows extraInfo chip', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          title: 'Extra Info Movie',
          icon: Icons.tv,
          extraInfo: '8 Seasons',
        ),
      );
      await openSheet(tester);

      expect(find.text('8 Seasons'), findsOneWidget);
      // The extraInfo chip uses the same icon as the sheet's icon prop.
      expect(find.byIcon(Icons.tv), findsWidgets);
    });

    testWidgets('does not show extraInfo when null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(title: 'No Extra'),
      );
      await openSheet(tester);

      expect(find.text('No Extra'), findsOneWidget);
    });

    testWidgets('renders all fields together', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          title: 'Full Movie',
          icon: Icons.movie,
          overview: 'An amazing story.',
          year: 2024,
          rating: '9.1',
          genres: <String>['Action', 'Adventure'],
          extraInfo: '2h 30m',
          posterUrl: 'https://example.com/full.jpg',
          onAddToCollection: () {},
        ),
      );
      // Use openSheetWithPump because CachedNetworkImage has
      // a CircularProgressIndicator placeholder that prevents
      // pumpAndSettle from completing.
      await openSheetWithPump(tester);

      expect(find.text('Full Movie'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('9.1'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);
      expect(find.text('2h 30m'), findsOneWidget);
      expect(find.text('An amazing story.'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });
}
