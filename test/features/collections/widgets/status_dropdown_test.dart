import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/status_dropdown.dart';
import 'package:xerabora/shared/models/collection_game.dart';

void main() {
  Widget buildTestWidget({
    required Widget child,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('StatusDropdown', () {
    group('compact mode', () {
      testWidgets('должен отображать только иконку статуса', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.playing,
            onChanged: (_) {},
            compact: true,
          ),
        ));

        expect(find.text('🎮'), findsOneWidget);
        expect(find.text('Playing'), findsNothing);
      });

      testWidgets('должен открывать popup menu при нажатии', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.notStarted,
            onChanged: (_) {},
            compact: true,
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<GameStatus>));
        await tester.pumpAndSettle();

        // Проверяем что все статусы отображаются в меню
        expect(find.text('Not Started'), findsOneWidget);
        expect(find.text('Playing'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Dropped'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
      });

      testWidgets('должен вызывать onChanged при выборе статуса', (WidgetTester tester) async {
        GameStatus? selectedStatus;

        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.notStarted,
            onChanged: (GameStatus status) {
              selectedStatus = status;
            },
            compact: true,
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<GameStatus>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        expect(selectedStatus, GameStatus.completed);
      });

      testWidgets('должен иметь tooltip', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.playing,
            onChanged: (_) {},
            compact: true,
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is PopupMenuButton<GameStatus> &&
                widget.tooltip == 'Change status',
          ),
          findsOneWidget,
        );
      });
    });

    group('full mode', () {
      testWidgets('должен отображать иконку и label', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.completed,
            onChanged: (_) {},
            compact: false,
          ),
        ));

        expect(find.text('✅'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('должен отображать arrow_drop_down иконку', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.playing,
            onChanged: (_) {},
            compact: false,
          ),
        ));

        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      });

      testWidgets('должен открывать popup menu при нажатии', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.notStarted,
            onChanged: (_) {},
            compact: false,
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<GameStatus>));
        await tester.pumpAndSettle();

        // Проверяем все статусы
        for (final GameStatus status in GameStatus.values) {
          expect(find.text(status.label), findsWidgets);
        }
      });

      testWidgets('должен показывать галочку для выбранного статуса', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.playing,
            onChanged: (_) {},
            compact: false,
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<GameStatus>));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('должен вызывать onChanged при выборе', (WidgetTester tester) async {
        GameStatus? selectedStatus;

        await tester.pumpWidget(buildTestWidget(
          child: StatusDropdown(
            status: GameStatus.notStarted,
            onChanged: (GameStatus status) {
              selectedStatus = status;
            },
            compact: false,
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<GameStatus>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dropped'));
        await tester.pumpAndSettle();

        expect(selectedStatus, GameStatus.dropped);
      });
    });

    group('статусы', () {
      for (final GameStatus status in GameStatus.values) {
        testWidgets('должен отображать ${status.label} в compact mode', (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            child: StatusDropdown(
              status: status,
              onChanged: (_) {},
              compact: true,
            ),
          ));

          expect(find.text(status.icon), findsOneWidget);
        });

        testWidgets('должен отображать ${status.label} в full mode', (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            child: StatusDropdown(
              status: status,
              onChanged: (_) {},
              compact: false,
            ),
          ));

          expect(find.text(status.icon), findsOneWidget);
          expect(find.text(status.label), findsOneWidget);
        });
      }
    });
  });

  group('StatusChip', () {
    group('normal mode', () {
      testWidgets('должен отображать иконку и label', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const StatusChip(
            status: GameStatus.completed,
            small: false,
          ),
        ));

        expect(find.text('✅'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('должен иметь Container с decoration', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const StatusChip(
            status: GameStatus.playing,
            small: false,
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) => widget is Container && widget.decoration != null,
          ),
          findsOneWidget,
        );
      });
    });

    group('small mode', () {
      testWidgets('должен отображать только иконку', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const StatusChip(
            status: GameStatus.planned,
            small: true,
          ),
        ));

        expect(find.text('📋'), findsOneWidget);
        expect(find.text('Planned'), findsNothing);
      });

      testWidgets('не должен иметь Container с decoration', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const StatusChip(
            status: GameStatus.dropped,
            small: true,
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) => widget is Container && widget.decoration != null,
          ),
          findsNothing,
        );
      });
    });

    group('статусы', () {
      for (final GameStatus status in GameStatus.values) {
        testWidgets('должен отображать ${status.label} в normal mode', (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            child: StatusChip(
              status: status,
              small: false,
            ),
          ));

          expect(find.text(status.icon), findsOneWidget);
          expect(find.text(status.label), findsOneWidget);
        });

        testWidgets('должен отображать ${status.label} в small mode', (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            child: StatusChip(
              status: status,
              small: true,
            ),
          ));

          expect(find.text(status.icon), findsOneWidget);
        });
      }
    });
  });
}
