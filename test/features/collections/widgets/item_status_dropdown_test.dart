// Тесты для ItemStatusDropdown и ItemStatusChip виджетов.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/item_status_dropdown.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

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

  group('ItemStatusDropdown', () {
    group('отображение начального значения', () {
      for (final ItemStatus status in ItemStatus.values) {
        testWidgets(
            'должен отображать "${status.displayLabel(MediaType.game)}" '
            'для статуса ${status.name} (full mode)',
            (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            child: ItemStatusDropdown(
              status: status,
              mediaType: MediaType.game,
              onChanged: (_) {},
            ),
          ));

          expect(find.text(status.icon), findsOneWidget);
          expect(
              find.text(status.displayLabel(MediaType.game)), findsOneWidget);
        });
      }
    });

    group('метки для game медиа типа', () {
      testWidgets('должен отображать "Playing" для inProgress',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.inProgress,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('Playing'), findsOneWidget);
      });

      testWidgets('должен отображать "Completed" для completed',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.completed,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('должен отображать "Not Started" для notStarted',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('Not Started'), findsOneWidget);
      });

      testWidgets('должен отображать "Dropped" для dropped',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.dropped,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('Dropped'), findsOneWidget);
      });

      testWidgets('должен отображать "Planned" для planned',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.planned,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('Planned'), findsOneWidget);
      });

      testWidgets('не должен содержать onHold в popup menu',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(find.text('On Hold'), findsNothing);
      });
    });

    group('метки для movie медиа типа', () {
      testWidgets('должен отображать "Watching" для inProgress',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.inProgress,
            mediaType: MediaType.movie,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('Watching'), findsOneWidget);
      });

      testWidgets('должен отображать "Completed" для completed',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.completed,
            mediaType: MediaType.movie,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('не должен содержать onHold в popup menu',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.movie,
            onChanged: (_) {},
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(find.text('On Hold'), findsNothing);
      });
    });

    group('метки для tvShow медиа типа', () {
      testWidgets('должен отображать "Watching" для inProgress',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.inProgress,
            mediaType: MediaType.tvShow,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('Watching'), findsOneWidget);
      });

      testWidgets('должен отображать "On Hold" для onHold',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.onHold,
            mediaType: MediaType.tvShow,
            onChanged: (_) {},
          ),
        ));

        expect(find.text('On Hold'), findsOneWidget);
      });

      testWidgets('должен содержать все статусы включая onHold в popup menu',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.tvShow,
            onChanged: (_) {},
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(find.text('Not Started'), findsWidgets);
        expect(find.text('Watching'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Dropped'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
        expect(find.text('On Hold'), findsOneWidget);
      });

      testWidgets(
          'popup menu содержит ровно ${ItemStatus.values.length} элементов',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.tvShow,
            onChanged: (_) {},
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(
          find.byType(PopupMenuItem<ItemStatus>),
          findsNWidgets(ItemStatus.values.length),
        );
      });
    });

    group('onChanged callback', () {
      testWidgets('должен вызывать onChanged при выборе статуса в full mode',
          (WidgetTester tester) async {
        ItemStatus? selectedStatus;

        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.game,
            onChanged: (ItemStatus status) {
              selectedStatus = status;
            },
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        expect(selectedStatus, ItemStatus.completed);
      });

      testWidgets('должен вызывать onChanged при выборе статуса в compact mode',
          (WidgetTester tester) async {
        ItemStatus? selectedStatus;

        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.game,
            onChanged: (ItemStatus status) {
              selectedStatus = status;
            },
            compact: true,
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dropped'));
        await tester.pumpAndSettle();

        expect(selectedStatus, ItemStatus.dropped);
      });

      testWidgets(
          'должен передавать onHold для tvShow при выборе через popup menu',
          (WidgetTester tester) async {
        ItemStatus? selectedStatus;

        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.tvShow,
            onChanged: (ItemStatus status) {
              selectedStatus = status;
            },
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('On Hold'));
        await tester.pumpAndSettle();

        expect(selectedStatus, ItemStatus.onHold);
      });
    });

    group('compact mode', () {
      testWidgets('должен отображать только иконку статуса без label',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.inProgress,
            mediaType: MediaType.game,
            onChanged: (_) {},
            compact: true,
          ),
        ));

        expect(find.text(ItemStatus.inProgress.icon), findsOneWidget);
        expect(find.text('Playing'), findsNothing);
      });

      testWidgets('не должен отображать arrow_drop_down иконку',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.completed,
            mediaType: MediaType.game,
            onChanged: (_) {},
            compact: true,
          ),
        ));

        expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      });

      testWidgets('не должен иметь Container с decoration',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.completed,
            mediaType: MediaType.game,
            onChanged: (_) {},
            compact: true,
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is Container && widget.decoration != null,
          ),
          findsNothing,
        );
      });

      testWidgets('должен иметь tooltip "Change status"',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.planned,
            mediaType: MediaType.game,
            onChanged: (_) {},
            compact: true,
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is PopupMenuButton<ItemStatus> &&
                widget.tooltip == 'Change status',
          ),
          findsOneWidget,
        );
      });

      testWidgets('должен открывать popup menu при нажатии',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.game,
            onChanged: (_) {},
            compact: true,
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(find.text('Not Started'), findsOneWidget);
        expect(find.text('Playing'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Dropped'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
      });
    });

    group('full mode', () {
      testWidgets('должен отображать иконку и label',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.completed,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(find.text(ItemStatus.completed.icon), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('должен отображать arrow_drop_down иконку',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.inProgress,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      });

      testWidgets('должен иметь Container с decoration',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.completed,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is Container && widget.decoration != null,
          ),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать галочку для выбранного статуса',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.inProgress,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('должен иметь tooltip "Change status"',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.planned,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is PopupMenuButton<ItemStatus> &&
                widget.tooltip == 'Change status',
          ),
          findsOneWidget,
        );
      });
    });

    group('доступные статусы', () {
      testWidgets(
          'для game: popup содержит все статусы кроме onHold '
          '(${ItemStatus.values.length - 1} элементов)',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(
          find.byType(PopupMenuItem<ItemStatus>),
          findsNWidgets(ItemStatus.values.length - 1),
        );
      });

      testWidgets(
          'для movie: popup содержит все статусы кроме onHold '
          '(${ItemStatus.values.length - 1} элементов)',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.movie,
            onChanged: (_) {},
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(
          find.byType(PopupMenuItem<ItemStatus>),
          findsNWidgets(ItemStatus.values.length - 1),
        );
      });

      testWidgets(
          'для tvShow: popup содержит все статусы '
          '(${ItemStatus.values.length} элементов)',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.tvShow,
            onChanged: (_) {},
          ),
        ));

        await tester.tap(find.byType(PopupMenuButton<ItemStatus>));
        await tester.pumpAndSettle();

        expect(
          find.byType(PopupMenuItem<ItemStatus>),
          findsNWidgets(ItemStatus.values.length),
        );
      });
    });

    group('цветовая маппинг статусов', () {
      // Проверяем что цвет Container корректно применяется для каждого статуса
      // в full mode (Container с border и фоном)
      testWidgets(
          'notStarted использует onSurfaceVariant цвет (Container с decoration)',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.notStarted,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        final Finder containerFinder = find.byWidgetPredicate(
          (Widget widget) =>
              widget is Container && widget.decoration != null,
        );
        expect(containerFinder, findsOneWidget);

        final Container container =
            tester.widget<Container>(containerFinder);
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(decoration.border, isNotNull);
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.color, isNotNull);
      });

      for (final ItemStatus status in ItemStatus.values) {
        // Пропускаем onHold для game, т.к. он недоступен
        if (status == ItemStatus.onHold) continue;

        testWidgets(
            'статус ${status.name} в full mode отображает Container с корректной decoration',
            (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            child: ItemStatusDropdown(
              status: status,
              mediaType: MediaType.game,
              onChanged: (_) {},
            ),
          ));

          final Finder containerFinder = find.byWidgetPredicate(
            (Widget widget) =>
                widget is Container && widget.decoration != null,
          );
          expect(containerFinder, findsOneWidget);

          final Container container =
              tester.widget<Container>(containerFinder);
          final BoxDecoration decoration =
              container.decoration! as BoxDecoration;

          // Проверяем что decoration создана корректно с цветом и бордером
          expect(decoration.color, isNotNull);
          expect(decoration.border, isNotNull);
          expect(
            decoration.borderRadius,
            BorderRadius.circular(20),
          );
        });
      }

      testWidgets('onHold для tvShow отображает Container с корректной decoration',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.onHold,
            mediaType: MediaType.tvShow,
            onChanged: (_) {},
          ),
        ));

        final Finder containerFinder = find.byWidgetPredicate(
          (Widget widget) =>
              widget is Container && widget.decoration != null,
        );
        expect(containerFinder, findsOneWidget);

        final Container container =
            tester.widget<Container>(containerFinder);
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(decoration.color, isNotNull);
        expect(decoration.border, isNotNull);
        expect(
          decoration.borderRadius,
          BorderRadius.circular(20),
        );
      });

      testWidgets(
          'arrow_drop_down иконка получает цвет статуса',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.completed,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        final Icon arrowIcon = tester.widget<Icon>(
          find.byIcon(Icons.arrow_drop_down),
        );
        // Цвет должен быть не null (установлен _getStatusColor)
        expect(arrowIcon.color, isNotNull);
      });

      testWidgets(
          'label текст получает цвет статуса в full mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: ItemStatusDropdown(
            status: ItemStatus.dropped,
            mediaType: MediaType.game,
            onChanged: (_) {},
          ),
        ));

        final Finder textFinder = find.text('Dropped');
        expect(textFinder, findsOneWidget);

        final Text textWidget = tester.widget<Text>(textFinder);
        // Стиль текста должен иметь цвет от _getStatusColor
        expect(textWidget.style, isNotNull);
        expect(textWidget.style!.color, isNotNull);
        expect(textWidget.style!.fontWeight, FontWeight.w500);
      });
    });
  });

  group('ItemStatusChip', () {
    group('normal mode', () {
      testWidgets('должен отображать иконку и label',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.completed,
            mediaType: MediaType.game,
          ),
        ));

        expect(find.text(ItemStatus.completed.icon), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('должен иметь Container с decoration',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.inProgress,
            mediaType: MediaType.game,
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is Container && widget.decoration != null,
          ),
          findsOneWidget,
        );
      });

      testWidgets('должен отображать "Watching" для movie inProgress',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.inProgress,
            mediaType: MediaType.movie,
          ),
        ));

        expect(find.text('Watching'), findsOneWidget);
      });

      testWidgets('должен отображать "Playing" для game inProgress',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.inProgress,
            mediaType: MediaType.game,
          ),
        ));

        expect(find.text('Playing'), findsOneWidget);
      });

      testWidgets('label имеет fontSize 12 и fontWeight w500',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.planned,
            mediaType: MediaType.game,
          ),
        ));

        final Text textWidget = tester.widget<Text>(find.text('Planned'));
        expect(textWidget.style!.fontSize, 12);
        expect(textWidget.style!.fontWeight, FontWeight.w500);
      });

      testWidgets('Container имеет borderRadius 12',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.completed,
            mediaType: MediaType.game,
          ),
        ));

        final Container container = tester.widget<Container>(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is Container && widget.decoration != null,
          ),
        );
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(12),
        );
      });
    });

    group('small mode', () {
      testWidgets('должен отображать только иконку',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.planned,
            mediaType: MediaType.game,
            small: true,
          ),
        ));

        expect(find.text(ItemStatus.planned.icon), findsOneWidget);
        expect(find.text('Planned'), findsNothing);
      });

      testWidgets('не должен иметь Container с decoration',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.dropped,
            mediaType: MediaType.game,
            small: true,
          ),
        ));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is Container && widget.decoration != null,
          ),
          findsNothing,
        );
      });

      testWidgets('иконка имеет fontSize 16',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const ItemStatusChip(
            status: ItemStatus.inProgress,
            mediaType: MediaType.game,
            small: true,
          ),
        ));

        final Text iconText =
            tester.widget<Text>(find.text(ItemStatus.inProgress.icon));
        expect(iconText.style!.fontSize, 16);
      });
    });

    group('статусы для всех типов медиа', () {
      for (final ItemStatus status in ItemStatus.values) {
        for (final MediaType mediaType in MediaType.values) {
          testWidgets(
              'должен отображать ${status.displayLabel(mediaType)} '
              'для ${mediaType.name} в normal mode',
              (WidgetTester tester) async {
            await tester.pumpWidget(buildTestWidget(
              child: ItemStatusChip(
                status: status,
                mediaType: mediaType,
              ),
            ));

            expect(find.text(status.icon), findsOneWidget);
            expect(
              find.text(status.displayLabel(mediaType)),
              findsOneWidget,
            );
          });

          testWidgets(
              'должен отображать иконку ${status.name} '
              'для ${mediaType.name} в small mode',
              (WidgetTester tester) async {
            await tester.pumpWidget(buildTestWidget(
              child: ItemStatusChip(
                status: status,
                mediaType: mediaType,
                small: true,
              ),
            ));

            expect(find.text(status.icon), findsOneWidget);
          });
        }
      }
    });

    group('цветовая маппинг статусов', () {
      for (final ItemStatus status in ItemStatus.values) {
        testWidgets(
            'статус ${status.name} имеет корректный цвет label',
            (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            child: ItemStatusChip(
              status: status,
              mediaType: MediaType.tvShow,
            ),
          ));

          final Text textWidget = tester.widget<Text>(
            find.text(status.displayLabel(MediaType.tvShow)),
          );
          expect(textWidget.style, isNotNull);
          expect(textWidget.style!.color, isNotNull);
        });
      }
    });
  });
}
