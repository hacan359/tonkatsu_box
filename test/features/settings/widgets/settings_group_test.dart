// Тесты для SettingsGroup — плоская группа настроек.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';

void main() {
  Widget createWidget({String? title, List<Widget>? children}) {
    return MaterialApp(
      home: Scaffold(
        body: SettingsGroup(
          title: title,
          children: children ?? const <Widget>[
            Text('Child 1'),
            Text('Child 2'),
          ],
        ),
      ),
    );
  }

  group('SettingsGroup', () {
    group('Rendering', () {
      testWidgets('renders children without title',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Child 1'), findsOneWidget);
        expect(find.text('Child 2'), findsOneWidget);
      });

      testWidgets('renders uppercase title when provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'profile'));

        expect(find.text('PROFILE'), findsOneWidget);
      });

      testWidgets('does not render title when null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // No uppercase text — title is null
        expect(find.text('PROFILE'), findsNothing);
      });

      testWidgets('renders empty list without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(children: const <Widget>[]));

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders single child without divider',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          children: const <Widget>[Text('Only child')],
        ));

        expect(find.text('Only child'), findsOneWidget);
        // No dividers for single child
        expect(find.byType(Divider), findsNothing);
      });
    });

    group('Dividers', () {
      testWidgets('shows dividers between children',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          children: const <Widget>[
            Text('Child 1'),
            Text('Child 2'),
            Text('Child 3'),
          ],
        ));

        // 2 dividers for 3 children
        expect(find.byType(Divider), findsNWidgets(2));
      });
    });
  });
}
