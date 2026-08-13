import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/tag_top_bar.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('TagTopBar', () {
    final List<Tag> tags = <Tag>[
      createTestTag(id: 1, name: 'RPG', color: 0xFFE57373),
      createTestTag(id: 2, name: 'Soulslike', color: 0xFF9575CD),
      createTestTag(id: 3, name: 'Colorless'),
    ];
    final Map<int, int> counts = <int, int>{1: 7, 2: 4};

    Future<void> pumpBar(
      WidgetTester tester, {
      Set<int> selectedTagIds = const <int>{},
      bool groupByTags = false,
      ValueChanged<int?>? onTagToggled,
      VoidCallback? onGroupToggled,
    }) {
      return tester.pumpApp(
        TagTopBar(
          tags: tags,
          counts: counts,
          selectedTagIds: selectedTagIds,
          groupByTags: groupByTags,
          onTagToggled: onTagToggled ?? (int? _) {},
          onGroupToggled: onGroupToggled ?? () {},
        ),
        wrapInScaffold: true,
      );
    }

    testWidgets('should render every tag with its count without exceptions',
        (WidgetTester tester) async {
      await pumpBar(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('RPG'), findsOneWidget);
      expect(find.text('Soulslike'), findsOneWidget);
      expect(find.text('Colorless'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('should call onTagToggled with the tag id when a chip is tapped',
        (WidgetTester tester) async {
      final List<int?> toggled = <int?>[];
      await pumpBar(tester, onTagToggled: toggled.add);

      await tester.tap(find.text('Soulslike'));
      await tester.pump();

      expect(toggled, <int?>[2]);
    });

    testWidgets('should call onGroupToggled when the group chip is tapped',
        (WidgetTester tester) async {
      int groupCalls = 0;
      await pumpBar(tester, onGroupToggled: () => groupCalls++);

      await tester.tap(find.byKey(const ValueKey<String>('tagTopBarGroup')));
      await tester.pump();

      expect(groupCalls, 1);
    });

    testWidgets('should hide the reset chip when nothing is selected',
        (WidgetTester tester) async {
      await pumpBar(tester);

      expect(
        find.byKey(const ValueKey<String>('tagTopBarReset')),
        findsNothing,
      );
    });

    testWidgets('should call onTagToggled with null when reset is tapped',
        (WidgetTester tester) async {
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
  });
}
