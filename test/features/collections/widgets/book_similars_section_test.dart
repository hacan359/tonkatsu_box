// Widget tests for BookSimilarsSection — render / empty / error / owned badge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/fantlab_api.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/book_similars_section.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/book.dart';
import 'package:tonkatsu_box/shared/models/collected_item_info.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

import '../../../helpers/test_helpers.dart';

/// Pumps a few frames so the FutureProvider resolves without waiting on the
/// shimmer's infinite animation.
Future<void> pumpUntilResolved(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Book fantlabBook({required String id, required String title}) => createTestBook(
      id: id,
      source: DataSource.fantlab,
      nativeId: id,
      title: title,
    );

void main() {
  setUpAll(registerAllFallbacks);

  late MockFantlabApi mockApi;

  setUp(() {
    mockApi = MockFantlabApi();
  });

  Widget build({
    Map<int, List<CollectedItemInfo>> ownedIds =
        const <int, List<CollectedItemInfo>>{},
  }) {
    return ProviderScope(
      overrides: <Override>[
        fantlabApiProvider.overrideWithValue(mockApi),
        collectedBookIdsProvider.overrideWith((Ref ref) async => ownedIds),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookSimilarsSection(workId: '3104'),
          ),
        ),
      ),
    );
  }

  group('BookSimilarsSection', () {
    testWidgets('renders the similar books returned by Fantlab',
        (WidgetTester tester) async {
      when(() => mockApi.getSimilars('3104')).thenAnswer(
        (_) async => <Book>[
          fantlabBook(id: '1', title: 'Eden'),
          fantlabBook(id: '2', title: 'Fiasco'),
        ],
      );

      await tester.pumpWidget(build());
      await pumpUntilResolved(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Eden'), findsOneWidget);
      expect(find.text('Fiasco'), findsOneWidget);
    });

    testWidgets('hides itself when there are no similar books',
        (WidgetTester tester) async {
      when(() => mockApi.getSimilars('3104'))
          .thenAnswer((_) async => <Book>[]);

      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('hides itself when the request fails',
        (WidgetTester tester) async {
      when(() => mockApi.getSimilars('3104'))
          .thenThrow(Exception('network down'));

      await tester.pumpWidget(build());
      await pumpUntilResolved(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('marks a similar book already in a collection as owned',
        (WidgetTester tester) async {
      when(() => mockApi.getSimilars('3104')).thenAnswer(
        (_) async => <Book>[
          fantlabBook(id: '1', title: 'Eden'),
          fantlabBook(id: '2', title: 'Fiasco'),
        ],
      );

      await tester.pumpWidget(
        build(
          ownedIds: <int, List<CollectedItemInfo>>{
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

      // One of the two cards (the owned one) shows the in-collection badge.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not mark a similar book owned from another provider',
        (WidgetTester tester) async {
      when(() => mockApi.getSimilars('3104')).thenAnswer(
        (_) async => <Book>[fantlabBook(id: '1', title: 'Eden')],
      );

      await tester.pumpWidget(
        build(
          ownedIds: <int, List<CollectedItemInfo>>{
            // Same numeric id, different provider — a different book.
            1: <CollectedItemInfo>[
              const CollectedItemInfo(
                recordId: 1,
                collectionId: 1,
                collectionName: 'Read',
                source: DataSource.openLibrary,
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
