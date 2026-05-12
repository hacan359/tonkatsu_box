import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';

void main() {
  Widget createWidget({
    String? title,
    String? subtitle,
    List<Widget>? children,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SettingsGroup(
          title: title,
          subtitle: subtitle,
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
        expect(find.byType(Divider), findsNothing);
      });
    });

    group('Subtitle', () {
      testWidgets('renders subtitle when provided with title',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          title: 'profile',
          subtitle: 'Author name for collections',
        ));

        expect(find.text('PROFILE'), findsOneWidget);
        expect(find.text('Author name for collections'), findsOneWidget);
      });

      testWidgets('does not render subtitle when null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(title: 'profile'));

        expect(find.text('PROFILE'), findsOneWidget);
        expect(find.text('Author name for collections'), findsNothing);
      });

      testWidgets('does not render subtitle when title is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          subtitle: 'Should not appear',
        ));

        expect(find.text('Should not appear'), findsNothing);
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

        expect(find.byType(Divider), findsNWidgets(2));
      });
    });
  });
}
