import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_table/table_filter.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('TableFilterDialog', () {
    final List<List<TableFilterRule>?> popped = <List<TableFilterRule>?>[];

    setUp(popped.clear);

    Future<void> pumpAndOpen(WidgetTester tester) async {
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              popped.add(await showDialog<List<TableFilterRule>>(
                context: context,
                builder: (BuildContext ctx) => const TableFilterDialog(
                  rules: <TableFilterRule>[],
                  columns: <String, String>{
                    'name': 'Name',
                    'status': 'Status',
                  },
                  enumOptions: <String, List<String>>{
                    'status': <String>['Playing', 'Done'],
                  },
                ),
              ));
            },
            child: const Text('open'),
          ),
        ),
        wrapInScaffold: true,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('should render without exceptions when opened',
        (WidgetTester tester) async {
      await pumpAndOpen(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(TableFilterDialog), findsOneWidget);
    });

    testWidgets('should render without exceptions on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpAndOpen(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(TableFilterDialog), findsOneWidget);
    });

    testWidgets('should pop the added rule on apply',
        (WidgetTester tester) async {
      await pumpAndOpen(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Zelda');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(TableFilterDialog), findsNothing);
      expect(popped, hasLength(1));
      final List<TableFilterRule> rules = popped.single!;
      expect(rules, hasLength(1));
      expect(rules.single.field, 'name');
      expect(rules.single.condition, TableFilterCondition.contains);
      expect(rules.single.value, 'Zelda');
    });
  });
}
