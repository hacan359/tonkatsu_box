import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/activity_dates_section.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('ActivityDatesSection', () {
    setUpAll(() => registerAllFallbacks());

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 1, 15),
          isEditable: true,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display title', (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 1, 15),
          isEditable: false,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Activity Dates'), findsOneWidget);
    });

    testWidgets('should display added date', (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 3, 10),
          isEditable: false,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Mar 10, 2025'), findsOneWidget);
    });

    testWidgets('should display em dash for null dates', (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 1, 15),
          isEditable: false,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );

      // Started and Completed should show em dash when null
      expect(find.text('\u2014'), findsNWidgets(2));
    });

    testWidgets('should display started and completed dates when set',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 1, 15),
          startedAt: DateTime(2025, 2, 1),
          completedAt: DateTime(2025, 3, 10),
          isEditable: false,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Feb 1, 2025'), findsOneWidget);
      expect(find.text('Mar 10, 2025'), findsOneWidget);
    });

    testWidgets('should display last activity date when set',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 1, 15),
          lastActivityAt: DateTime(2025, 4, 5),
          isEditable: false,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Apr 5, 2025'), findsOneWidget);
    });

    testWidgets('should not display last activity when null',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 1, 15),
          isEditable: false,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );

      // Last Activity label should not be present
      expect(find.text('Last Activity'), findsNothing);
    });

    testWidgets('should display completion time when set',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 1, 15),
          completionTime: const Duration(days: 14),
          isEditable: false,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Completed in 2 weeks'), findsOneWidget);
    });

    testWidgets('should not display completion time when null',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ActivityDatesSection(
          addedAt: DateTime(2025, 1, 15),
          isEditable: false,
          onDateChanged: (String type, DateTime date) async {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Completed in'), findsNothing);
    });

    group('completion time formatting', () {
      testWidgets('should format less than a day', (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            completionTime: const Duration(hours: 5),
            isEditable: false,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        expect(find.text('Completed in less than a day'), findsOneWidget);
      });

      testWidgets('should format one day', (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            completionTime: const Duration(days: 1),
            isEditable: false,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        expect(find.text('Completed in 1 day'), findsOneWidget);
      });

      testWidgets('should format multiple days', (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            completionTime: const Duration(days: 5),
            isEditable: false,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        expect(find.text('Completed in 5 days'), findsOneWidget);
      });

      testWidgets('should format weeks', (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            completionTime: const Duration(days: 14),
            isEditable: false,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        expect(find.text('Completed in 2 weeks'), findsOneWidget);
      });

      testWidgets('should format months', (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            completionTime: const Duration(days: 60),
            isEditable: false,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        expect(find.text('Completed in 2 months'), findsOneWidget);
      });

      testWidgets('should format years', (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            completionTime: const Duration(days: 400),
            isEditable: false,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        expect(find.text('Completed in 1.1 years'), findsOneWidget);
      });
    });

    group('editable behavior', () {
      testWidgets('should show edit icons when editable', (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            isEditable: true,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        // Edit icons for Started and Completed
        expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      });

      testWidgets('should not show edit icons when not editable',
          (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            isEditable: false,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      });

      testWidgets('should wrap editable dates in InkWell', (WidgetTester tester) async {
        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            isEditable: true,
            onDateChanged: (String type, DateTime date) async {},
          ),
        );

        // InkWell for Started and Completed
        expect(find.byType(InkWell), findsNWidgets(2));
      });

      testWidgets('should call onDateChanged when date is tapped',
          (WidgetTester tester) async {
        String? calledType;
        DateTime? calledDate;

        await tester.pumpApp(
          ActivityDatesSection(
            addedAt: DateTime(2025, 1, 15),
            isEditable: true,
            onDateChanged: (String type, DateTime date) async {
              calledType = type;
              calledDate = date;
            },
          ),
        );

        // Tap the first InkWell (Started)
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        // DatePicker should appear
        expect(find.text('SELECT DATE'), findsOneWidget);

        // Pick a date
        await tester.tap(find.text('15'));
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(calledType, equals('started'));
        expect(calledDate, isNotNull);
      });
    });
  });
}
