import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/book.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/widgets/book_carousel.dart';
import 'package:tonkatsu_box/shared/widgets/media_poster_card.dart';

import '../../helpers/test_helpers.dart';

Book gbook({required String id, required String title}) => createTestBook(
      id: id,
      source: DataSource.googleBooks,
      nativeId: 'gb_$id',
      title: title,
    );

Widget host(Widget child) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('BookCarousel', () {
    testWidgets('renders one card per book', (WidgetTester tester) async {
      await tester.pumpWidget(host(BookCarousel(
        books: <Book>[
          gbook(id: '1', title: 'Dune'),
          gbook(id: '2', title: 'Hyperion'),
        ],
        onTap: (_) {},
      )));
      await tester.pump();

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Hyperion'), findsOneWidget);
    });

    testWidgets('calls onTap with the tapped book', (WidgetTester tester) async {
      Book? tapped;
      await tester.pumpWidget(host(BookCarousel(
        books: <Book>[gbook(id: '1', title: 'Dune')],
        onTap: (Book b) => tapped = b,
      )));
      await tester.pump();

      await tester.tap(find.byType(MediaPosterCard).first);
      expect(tapped?.title, 'Dune');
    });

    testWidgets('marks an owned book with the in-collection badge',
        (WidgetTester tester) async {
      final Book owned = gbook(id: '1', title: 'Dune');
      await tester.pumpWidget(host(BookCarousel(
        books: <Book>[owned, gbook(id: '2', title: 'Hyperion')],
        ownedKeys: <(DataSource, int)>{(owned.source, owned.externalIdInt)},
        onTap: (_) {},
      )));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not mark a book whose id is owned from another provider',
        (WidgetTester tester) async {
      final Book fantlab = createTestBook(
        id: '3104',
        source: DataSource.fantlab,
        nativeId: '3104',
        title: 'Trudno byt bogom',
      );
      await tester.pumpWidget(host(BookCarousel(
        books: <Book>[fantlab],
        ownedKeys: <(DataSource, int)>{
          (DataSource.openLibrary, fantlab.externalIdInt),
        },
        onTap: (_) {},
      )));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('appends a trailing spinner while loading more',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(BookCarousel(
        books: <Book>[gbook(id: '1', title: 'Dune')],
        onTap: (_) {},
        loadingMore: true,
      )));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('wraps a card in a tooltip when tooltipOf returns text',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(BookCarousel(
        books: <Book>[gbook(id: '1', title: 'Dune')],
        onTap: (_) {},
        tooltipOf: (_) => 'A desert planet.',
      )));
      await tester.pump();

      expect(find.byTooltip('A desert planet.'), findsOneWidget);
    });
  });
}
