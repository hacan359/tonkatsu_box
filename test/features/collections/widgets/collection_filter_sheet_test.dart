import 'package:core/models/tag.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_filter_sheet.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('CollectionFilterSheet', () {
    const ValueKey<String> searchKey = ValueKey<String>('filterSheetTagSearch');

    final List<Tag> fewTags = <Tag>[
      createTestTag(id: 1, name: 'RPG'),
      createTestTag(id: 2, name: 'Soulslike'),
    ];
    final List<Tag> manyTags = <Tag>[
      for (int i = 1; i <= 9; i++) createTestTag(id: i, name: 'Tag $i'),
      createTestTag(id: 10, name: 'Soulslike'),
    ];

    Future<void> pumpSheet(
      WidgetTester tester, {
      required List<Tag> tags,
      Set<int> selectedTagIds = const <int>{},
      ValueChanged<int?>? onTagToggled,
    }) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpApp(
        CollectionFilterSheet(
          scrollController: controller,
          collectionId: 1,
          tags: tags,
          selectedTagIds: selectedTagIds,
          groupByTags: false,
          onTagToggled: onTagToggled ?? (int? _) {},
          onGroupToggled: () {},
        ),
        wrapInScaffold: true,
      );
    }

    group('tag search', () {
      testWidgets('should hide the field below the tag threshold', (
        WidgetTester tester,
      ) async {
        await pumpSheet(tester, tags: fewTags);

        expect(tester.takeException(), isNull);
        expect(find.byKey(searchKey), findsNothing);
        expect(find.text('RPG'), findsOneWidget);
      });

      testWidgets('should filter chips by the typed query', (
        WidgetTester tester,
      ) async {
        await pumpSheet(tester, tags: manyTags);
        expect(find.byKey(searchKey), findsOneWidget);

        await tester.enterText(find.byKey(searchKey), 'souls');
        await tester.pump();

        expect(find.text('Soulslike'), findsOneWidget);
        expect(find.text('Tag 1'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should keep selected tags visible while filtering', (
        WidgetTester tester,
      ) async {
        await pumpSheet(tester, tags: manyTags, selectedTagIds: <int>{1});

        await tester.enterText(find.byKey(searchKey), 'souls');
        await tester.pump();

        expect(find.text('Tag 1'), findsOneWidget);
        expect(find.text('Tag 2'), findsNothing);
      });

      testWidgets('should show the empty hint when nothing matches', (
        WidgetTester tester,
      ) async {
        await pumpSheet(tester, tags: manyTags);

        await tester.enterText(find.byKey(searchKey), 'zzz');
        await tester.pump();

        expect(find.text('No tags'), findsOneWidget);
      });

      testWidgets('should toggle a filtered chip through the callback', (
        WidgetTester tester,
      ) async {
        final List<int?> toggled = <int?>[];
        await pumpSheet(tester, tags: manyTags, onTagToggled: toggled.add);

        await tester.enterText(find.byKey(searchKey), 'souls');
        await tester.pump();
        await tester.tap(find.text('Soulslike'));
        await tester.pump();

        expect(toggled, <int?>[10]);
      });

      testWidgets('should clear the query from the suffix button', (
        WidgetTester tester,
      ) async {
        await pumpSheet(tester, tags: manyTags);

        await tester.enterText(find.byKey(searchKey), 'souls');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        expect(find.text('Tag 1'), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsNothing);
      });
    });
  });
}
