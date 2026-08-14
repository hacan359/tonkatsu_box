import 'package:core/models/tag.dart';
import 'package:core/models/tag_sort_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/providers/tag_sort_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/tag_search_list.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockGlobalTagDao mockDao;
  late List<bool> renderedReorderable;
  late List<String> created;
  late List<Tag> submitted;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDao = MockGlobalTagDao();
    renderedReorderable = <bool>[];
    created = <String>[];
    submitted = <Tag>[];
    when(() => mockDao.getAll()).thenAnswer(
      (_) async => <Tag>[
        createTestTag(id: 1, name: 'zebra'),
        createTestTag(id: 2, name: 'Action', sortOrder: 1),
        createTestTag(id: 3, name: 'indie', sortOrder: 2),
      ],
    );
    when(() => mockDao.getAllItemTags())
        .thenAnswer((_) async => <int, List<int>>{});
  });

  Future<void> pump(
    WidgetTester tester, {
    bool withCreate = true,
    bool withReorder = false,
  }) async {
    await tester.pumpApp(
      TagSearchList(
        onCreate: withCreate
            ? (String name) async {
                created.add(name);
              }
            : null,
        onSubmitExisting: submitted.add,
        onReorder: withReorder ? (List<int> ids) {} : null,
        rowBuilder: (Tag tag, int index, bool reorderable) {
          renderedReorderable.add(reorderable);
          return Text(tag.name, key: ValueKey<int>(tag.id));
        },
      ),
      overrides: <Override>[
        globalTagDaoProvider.overrideWithValue(mockDao),
      ],
      wrapInScaffold: true,
    );
  }

  group('TagSearchList', () {
    testWidgets('should render every tag in manual order by default', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('zebra'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('indie'), findsOneWidget);
    });

    testWidgets('should filter rows as the query is typed', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'act');
      await tester.pumpAndSettle();

      expect(find.text('Action'), findsOneWidget);
      expect(find.text('zebra'), findsNothing);
      expect(find.text('indie'), findsNothing);
    });

    testWidgets('should offer create only when no exact match exists', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      // Case-insensitive duplicate: no create tile appears.
      await tester.enterText(find.byType(TextField), 'ZEBRA');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);

      await tester.enterText(find.byType(TextField), 'fresh');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(created, <String>['fresh']);
    });

    testWidgets('should not offer create without an onCreate callback', (
      WidgetTester tester,
    ) async {
      await pump(tester, withCreate: false);
      await tester.enterText(find.byType(TextField), 'fresh');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('should select the exact match on Enter instead of creating',
        (WidgetTester tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'ZeBrA');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(created, isEmpty);
      expect(submitted.map((Tag t) => t.id), <int>[1]);
      // The field clears so the full list is visible again.
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('should create on Enter when nothing matches', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'fresh');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(created, <String>['fresh']);
      expect(submitted, isEmpty);
    });

    testWidgets('should reorder rows when the sort mode changes', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(TagSearchList)),
      );

      container
          .read(tagSortModeProvider.notifier)
          .setMode(TagSortMode.alphaAsc);
      await tester.pumpAndSettle();

      final double actionY = tester.getTopLeft(find.text('Action')).dy;
      final double indieY = tester.getTopLeft(find.text('indie')).dy;
      final double zebraY = tester.getTopLeft(find.text('zebra')).dy;
      expect(actionY, lessThan(indieY));
      expect(indieY, lessThan(zebraY));
    });

    testWidgets(
        'should mark rows reorderable only in the unfiltered manual view', (
      WidgetTester tester,
    ) async {
      await pump(tester, withReorder: true);
      expect(renderedReorderable, everyElement(isTrue));

      renderedReorderable.clear();
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pumpAndSettle();
      expect(renderedReorderable, isNotEmpty);
      expect(renderedReorderable, everyElement(isFalse));
    });

    testWidgets('should never mark rows reorderable without onReorder', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(renderedReorderable, everyElement(isFalse));
    });
  });
}
