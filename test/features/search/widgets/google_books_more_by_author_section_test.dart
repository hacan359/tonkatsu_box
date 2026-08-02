// Widget tests for GoogleBooksMoreByAuthorSection — render / exclude self /
// empty / copy-on-tap. Display-only strip; it never adds books.

import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/google_books_api.dart';
import 'package:tonkatsu_box/features/search/widgets/google_books_more_by_author_section.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/widgets/media_poster_card.dart';

import '../../../helpers/test_helpers.dart';

Future<void> pumpUntilResolved(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Book gbook({required String id, required String title}) => createTestBook(
      id: id,
      source: DataSource.googleBooks,
      nativeId: 'gb_$id',
      title: title,
    );

void main() {
  setUpAll(registerAllFallbacks);

  late MockGoogleBooksApi mockApi;

  setUp(() {
    mockApi = MockGoogleBooksApi();
  });

  void stub(List<Book> result) {
    when(() => mockApi.searchVolumes(
          any(),
          startIndex: any(named: 'startIndex'),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => (result, false));
  }

  Widget build({String author = 'Frank Herbert'}) {
    return ProviderScope(
      overrides: <Override>[
        googleBooksApiProvider.overrideWithValue(mockApi),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoogleBooksMoreByAuthorSection(
              author: author,
              excludeNativeId: 'gb_self',
            ),
          ),
        ),
      ),
    );
  }

  group('GoogleBooksMoreByAuthorSection', () {
    testWidgets('renders other books by the author',
        (WidgetTester tester) async {
      stub(<Book>[
        gbook(id: '1', title: 'Dune'),
        gbook(id: '2', title: 'Hyperion'),
      ]);

      await tester.pumpWidget(build());
      await pumpUntilResolved(tester);

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Hyperion'), findsOneWidget);
    });

    testWidgets('drops the volume the sheet was opened for',
        (WidgetTester tester) async {
      stub(<Book>[
        gbook(id: 'self', title: 'This One'),
        gbook(id: '1', title: 'Dune'),
      ]);

      await tester.pumpWidget(build());
      await pumpUntilResolved(tester);

      expect(find.text('This One'), findsNothing);
      expect(find.text('Dune'), findsOneWidget);
    });

    testWidgets('hides itself when the author has no other books',
        (WidgetTester tester) async {
      stub(<Book>[]);

      await tester.pumpWidget(build());
      await pumpUntilResolved(tester);

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('copies the title to the clipboard on tap',
        (WidgetTester tester) async {
      stub(<Book>[gbook(id: '1', title: 'Dune')]);

      await tester.pumpWidget(build());
      await pumpUntilResolved(tester);

      await tester.tap(find.byType(MediaPosterCard).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Title copied'), findsOneWidget);
    });

    testWidgets('strips embedded quotes from the author query',
        (WidgetTester tester) async {
      stub(<Book>[gbook(id: '1', title: 'Dune')]);

      await tester.pumpWidget(build(author: 'Ann "Tiptree" Sheldon'));
      await pumpUntilResolved(tester);

      final List<String> queries = verify(
        () => mockApi.searchVolumes(
          captureAny(),
          startIndex: any(named: 'startIndex'),
          maxResults: any(named: 'maxResults'),
        ),
      ).captured.cast<String>();
      expect(queries.first, 'inauthor:"Ann Tiptree Sheldon"');
    });
  });
}
