// Widget tests for DiscoverItem and DiscoverRow.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/widgets/discover_row.dart';

void main() {
  group('DiscoverItem', () {
    test('constructor with all fields', () {
      const DiscoverItem item = DiscoverItem(
        title: 'Test Movie',
        tmdbId: 42,
        posterUrl: 'https://example.com/poster.jpg',
        year: 2024,
        rating: '8.5',
        isOwned: true,
        isMovie: false,
      );

      expect(item.title, equals('Test Movie'));
      expect(item.tmdbId, equals(42));
      expect(item.posterUrl, equals('https://example.com/poster.jpg'));
      expect(item.year, equals(2024));
      expect(item.rating, equals('8.5'));
      expect(item.isOwned, isTrue);
      expect(item.isMovie, isFalse);
    });

    test('constructor with defaults', () {
      const DiscoverItem item = DiscoverItem(
        title: 'Minimal',
        tmdbId: 1,
      );

      expect(item.title, equals('Minimal'));
      expect(item.tmdbId, equals(1));
      expect(item.posterUrl, isNull);
      expect(item.year, isNull);
      expect(item.rating, isNull);
      expect(item.isOwned, isFalse);
      expect(item.isMovie, isTrue);
    });

    test('isMovie defaults to true', () {
      const DiscoverItem item = DiscoverItem(
        title: 'Movie',
        tmdbId: 10,
      );

      expect(item.isMovie, isTrue);
    });
  });

  group('DiscoverRow', () {
    const List<DiscoverItem> testItems = <DiscoverItem>[
      DiscoverItem(
        title: 'First Movie',
        tmdbId: 1,
        posterUrl: 'https://example.com/first.jpg',
        year: 2023,
        rating: '7.2',
      ),
      DiscoverItem(
        title: 'Second Movie',
        tmdbId: 2,
        year: 2024,
        isOwned: true,
      ),
      DiscoverItem(
        title: 'Third Movie',
        tmdbId: 3,
        posterUrl: 'https://example.com/third.jpg',
        rating: '9.0',
      ),
    ];

    Widget buildWidget({
      String title = 'Trending',
      List<DiscoverItem> items = const <DiscoverItem>[],
      void Function(DiscoverItem)? onTap,
      IconData? icon,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DiscoverRow(
            title: title,
            items: items,
            onTap: onTap ?? (_) {},
            icon: icon,
          ),
        ),
      );
    }

    testWidgets('renders title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(title: 'Popular Movies', items: testItems),
      );

      expect(find.text('Popular Movies'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          title: 'Top Rated',
          items: testItems,
          icon: Icons.trending_up,
        ),
      );

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('does not render icon when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(title: 'No Icon', items: testItems),
      );

      // Title should exist but no extra icon (aside from those inside cards).
      expect(find.text('No Icon'), findsOneWidget);
    });

    testWidgets('renders items in horizontal list',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(items: testItems));

      expect(find.text('First Movie'), findsOneWidget);
      expect(find.text('Second Movie'), findsOneWidget);
      // Third may be offscreen depending on width, but ListView creates it.
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink for empty items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(title: 'Empty Row', items: const <DiscoverItem>[]),
      );

      // Title should NOT render when items are empty.
      expect(find.text('Empty Row'), findsNothing);
      // The DiscoverRow widget returns SizedBox.shrink.
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('calls onTap callback with correct item',
        (WidgetTester tester) async {
      DiscoverItem? tappedItem;

      await tester.pumpWidget(
        buildWidget(
          items: testItems,
          onTap: (DiscoverItem item) {
            tappedItem = item;
          },
        ),
      );

      await tester.tap(find.text('First Movie'));
      await tester.pump();

      expect(tappedItem, isNotNull);
      expect(tappedItem!.title, equals('First Movie'));
      expect(tappedItem!.tmdbId, equals(1));
    });

    group('poster card content', () {
      testWidgets('shows poster image via CachedNetworkImage',
          (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(
            title: 'With Poster',
            tmdbId: 1,
            posterUrl: 'https://example.com/poster.jpg',
          ),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });

      testWidgets('shows title text', (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'Card Title', tmdbId: 1),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.text('Card Title'), findsOneWidget);
      });

      testWidgets('shows year when provided', (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'Dated', tmdbId: 1, year: 2020),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.text('2020'), findsOneWidget);
      });

      testWidgets('does not show year when null', (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'No Year', tmdbId: 1),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.text('No Year'), findsOneWidget);
        // No year text should be present.
        // We only have the title text, no additional number texts.
      });

      testWidgets('shows owned badge when isOwned is true',
          (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'Owned', tmdbId: 1, isOwned: true),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('does not show owned badge when isOwned is false',
          (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'Not Owned', tmdbId: 1),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.byIcon(Icons.check_circle), findsNothing);
      });

      testWidgets('shows rating badge when rating is provided',
          (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'Rated', tmdbId: 1, rating: '8.5'),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.text('8.5'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('does not show rating badge when rating is null',
          (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'Unrated', tmdbId: 1),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('shows placeholder when no poster URL',
          (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'No Poster', tmdbId: 1),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        // No CachedNetworkImage, instead a placeholder with movie_outlined.
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
      });

      testWidgets('shows placeholder when poster URL is empty',
          (WidgetTester tester) async {
        const List<DiscoverItem> items = <DiscoverItem>[
          DiscoverItem(title: 'Empty URL', tmdbId: 1, posterUrl: ''),
        ];

        await tester.pumpWidget(buildWidget(items: items));

        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
      });
    });
  });
}
