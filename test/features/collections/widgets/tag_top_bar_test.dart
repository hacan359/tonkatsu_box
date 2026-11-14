import 'package:core/models/tag.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/tag_top_bar.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('TagTopBar', () {
    final List<Tag> tags0 = <Tag>[
      createTestTag(id: 1, name: 'RPG', color: 0xFFE57373),
      createTestTag(id: 2, name: 'Soulslike', color: 0xFF9575CD),
      createTestTag(id: 3, name: 'Colorless'),
    ];
    final Map<int, int> counts = <int, int>{1: 7, 2: 4};

    // Enough tags to cross the search threshold.
    final List<Tag> manyTags = <Tag>[
      for (int i = 1; i <= 9; i++) createTestTag(id: i, name: 'Tag $i'),
      createTestTag(id: 10, name: 'Soulslike'),
    ];

    Future<void> pumpBar(
      WidgetTester tester, {
      List<Tag>? tags,
      Set<int> selectedTagIds = const <int>{},
      bool groupByTags = false,
      ValueChanged<int?>? onTagToggled,
      VoidCallback? onGroupToggled,
    }) {
      return tester.pumpApp(
        TagTopBar(
          tags: tags ?? tags0,
          counts: counts,
          selectedTagIds: selectedTagIds,
          groupByTags: groupByTags,
          onTagToggled: onTagToggled ?? (int? _) {},
          onGroupToggled: onGroupToggled ?? () {},
        ),
        wrapInScaffold: true,
      );
    }

    testWidgets('should render every tag with its count without exceptions', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('RPG'), findsOneWidget);
      expect(find.text('Soulslike'), findsOneWidget);
      expect(find.text('Colorless'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets(
      'should call onTagToggled with the tag id when a chip is tapped',
      (WidgetTester tester) async {
        final List<int?> toggled = <int?>[];
        await pumpBar(tester, onTagToggled: toggled.add);

        await tester.tap(find.text('Soulslike'));
        await tester.pump();

        expect(toggled, <int?>[2]);
      },
    );

    testWidgets('should call onGroupToggled when the group chip is tapped', (
      WidgetTester tester,
    ) async {
      int groupCalls = 0;
      await pumpBar(tester, onGroupToggled: () => groupCalls++);

      await tester.tap(find.byKey(const ValueKey<String>('tagTopBarGroup')));
      await tester.pump();

      expect(groupCalls, 1);
    });

    testWidgets('should hide the reset chip when nothing is selected', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester);

      expect(
        find.byKey(const ValueKey<String>('tagTopBarReset')),
        findsNothing,
      );
    });

    testWidgets('should call onTagToggled with null when reset is tapped', (
      WidgetTester tester,
    ) async {
      final List<int?> toggled = <int?>[];
      await pumpBar(
        tester,
        selectedTagIds: <int>{1, 2},
        onTagToggled: toggled.add,
      );

      await tester.tap(find.byKey(const ValueKey<String>('tagTopBarReset')));
      await tester.pump();

      expect(toggled, <int?>[null]);
    });

    group('search', () {
      const ValueKey<String> chip = ValueKey<String>('tagTopBarSearch');
      const ValueKey<String> field = ValueKey<String>('tagTopBarSearchField');
      const ValueKey<String> clear = ValueKey<String>('tagTopBarSearchClear');

      testWidgets('should hide the search chip below the tag threshold', (
        WidgetTester tester,
      ) async {
        await pumpBar(tester);

        expect(find.byKey(chip), findsNothing);
      });

      testWidgets('should open the field from the chip and filter tags', (
        WidgetTester tester,
      ) async {
        await pumpBar(tester, tags: manyTags);
        expect(find.byKey(chip), findsOneWidget);

        await tester.tap(find.byKey(chip));
        await tester.pumpAndSettle();
        expect(find.byKey(field), findsOneWidget);
        expect(find.byKey(chip), findsNothing);

        await tester.enterText(find.byKey(field), 'souls');
        await tester.pump();

        expect(find.text('Soulslike'), findsOneWidget);
        expect(find.text('Tag 1'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should keep selected tags visible while filtering', (
        WidgetTester tester,
      ) async {
        await pumpBar(tester, tags: manyTags, selectedTagIds: <int>{1});

        await tester.tap(find.byKey(chip));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(field), 'souls');
        await tester.pump();

        expect(find.text('Tag 1'), findsOneWidget);
        expect(find.text('Tag 2'), findsNothing);
      });

      testWidgets('should show the empty hint when nothing matches', (
        WidgetTester tester,
      ) async {
        await pumpBar(tester, tags: manyTags);

        await tester.tap(find.byKey(chip));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(field), 'zzz');
        await tester.pump();

        expect(find.text('No tags'), findsOneWidget);
      });

      testWidgets('should clear the query first and close on a second tap', (
        WidgetTester tester,
      ) async {
        await pumpBar(tester, tags: manyTags);

        await tester.tap(find.byKey(chip));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(field), 'souls');
        await tester.pump();

        await tester.tap(find.byKey(clear));
        await tester.pump();
        expect(find.byKey(field), findsOneWidget);
        expect(find.text('Tag 1'), findsOneWidget);

        await tester.tap(find.byKey(clear));
        await tester.pump();
        expect(find.byKey(field), findsNothing);
        expect(find.byKey(chip), findsOneWidget);
      });

      testWidgets(
        'should fold back into the chip when an empty field loses focus',
        (WidgetTester tester) async {
          await pumpBar(tester, tags: manyTags);

          await tester.tap(find.byKey(chip));
          await tester.pumpAndSettle();
          expect(find.byKey(field), findsOneWidget);

          FocusManager.instance.primaryFocus?.unfocus();
          // The focus change lands in a microtask, the rebuild a frame later.
          await tester.pumpAndSettle();

          expect(find.byKey(field), findsNothing);
          expect(find.byKey(chip), findsOneWidget);
        },
      );
    });
  });
}
