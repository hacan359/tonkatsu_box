import 'package:core/models/book.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/google_books_api.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/google_books_similars_section.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

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
      subjects: const <String>['Fiction'],
    );

// Same book across tests so the cached similars provider captures stable input;
// only the mocked search result varies.
final Book _main = gbook(id: 'main', title: 'Dune');

void main() {
  setUpAll(registerAllFallbacks);

  late MockGoogleBooksApi mockApi;

  setUp(() {
    mockApi = MockGoogleBooksApi();
  });

  void stubSearch(List<Book> result) {
    when(() => mockApi.searchVolumes(
          any(),
          maxResults: any(named: 'maxResults'),
        )).thenAnswer((_) async => (result, false));
  }

  Widget build({
    Map<int, List<CollectedItemInfo>> ownedIds =
        const <int, List<CollectedItemInfo>>{},
    Book? book,
  }) {
    return ProviderScope(
      overrides: <Override>[
        googleBooksApiProvider.overrideWithValue(mockApi),
        collectedBookIdsProvider.overrideWith((Ref ref) async => ownedIds),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoogleBooksSimilarsSection(book: book ?? _main),
          ),
        ),
      ),
    );
  }

  group('GoogleBooksSimilarsSection', () {
    testWidgets('renders books from the category search',
        (WidgetTester tester) async {
      stubSearch(<Book>[
        gbook(id: '1', title: 'Eden'),
        gbook(id: '2', title: 'Fiasco'),
      ]);

      await tester.pumpWidget(build());
      await pumpUntilResolved(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Eden'), findsOneWidget);
      expect(find.text('Fiasco'), findsOneWidget);
    });

    testWidgets('hides itself when the search returns nothing',
        (WidgetTester tester) async {
      stubSearch(<Book>[]);

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('hides itself when the request fails',
        (WidgetTester tester) async {
      when(() => mockApi.searchVolumes(
            any(),
            maxResults: any(named: 'maxResults'),
          )).thenThrow(const GoogleBooksApiException('boom'));

      await tester.pumpWidget(build());
      await pumpUntilResolved(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('strips embedded quotes from the category query',
        (WidgetTester tester) async {
      final Book quoted = createTestBook(
        id: 'q',
        source: DataSource.googleBooks,
        nativeId: 'gb_quoted',
        title: 'Quoted',
        subjects: const <String>['Sci-"Fi"'],
      );
      stubSearch(<Book>[]);

      await tester.pumpWidget(build(book: quoted));
      await pumpUntilResolved(tester);

      final List<String> queries = verify(
        () => mockApi.searchVolumes(
          captureAny(),
          maxResults: any(named: 'maxResults'),
        ),
      ).captured.cast<String>();
      expect(queries.first, 'subject:"Sci-Fi"');
    });

    testWidgets('marks a similar book already in a collection as owned',
        (WidgetTester tester) async {
      stubSearch(<Book>[
        gbook(id: '1', title: 'Eden'),
        gbook(id: '2', title: 'Fiasco'),
      ]);

      await tester.pumpWidget(
        build(
          ownedIds: <int, List<CollectedItemInfo>>{
            1: <CollectedItemInfo>[
              const CollectedItemInfo(
                recordId: 1,
                collectionId: 1,
                collectionName: 'Read',
                source: DataSource.googleBooks,
              ),
            ],
          },
        ),
      );
      await pumpUntilResolved(tester);

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not mark a similar book owned from another provider',
        (WidgetTester tester) async {
      stubSearch(<Book>[gbook(id: '1', title: 'Eden')]);

      await tester.pumpWidget(
        build(
          ownedIds: <int, List<CollectedItemInfo>>{
            // Same numeric id from Fantlab — a different book.
            1: <CollectedItemInfo>[
              const CollectedItemInfo(
                recordId: 1,
                collectionId: 1,
                collectionName: 'Read',
                source: DataSource.fantlab,
              ),
            ],
          },
        ),
      );
      await pumpUntilResolved(tester);

      expect(find.byIcon(Icons.check), findsNothing);
    });
  });
}
