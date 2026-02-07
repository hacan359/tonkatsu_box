import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/canvas_context_menu.dart';
import 'package:xerabora/shared/models/canvas_item.dart';

void main() {
  group('CanvasContextMenu', () {
    Widget buildTestApp({required Widget child}) {
      return MaterialApp(home: Scaffold(body: child));
    }

    group('showCanvasMenu', () {
      testWidgets(
        'должен показать меню с пунктами Add Text, Add Image, Add Link',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showCanvasMenu(
                      context,
                      position: const Offset(100, 100),
                      onAddText: () {},
                      onAddImage: () {},
                      onAddLink: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();

          expect(find.text('Add Text'), findsOneWidget);
          expect(find.text('Add Image'), findsOneWidget);
          expect(find.text('Add Link'), findsOneWidget);
        },
      );

      testWidgets(
        'должен вызвать onAddText при выборе Add Text',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showCanvasMenu(
                      context,
                      position: const Offset(100, 100),
                      onAddText: () => called = true,
                      onAddImage: () {},
                      onAddLink: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Add Text'));
          await tester.pumpAndSettle();

          expect(called, true);
        },
      );

      testWidgets(
        'должен вызвать onAddImage при выборе Add Image',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showCanvasMenu(
                      context,
                      position: const Offset(100, 100),
                      onAddText: () {},
                      onAddImage: () => called = true,
                      onAddLink: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Add Image'));
          await tester.pumpAndSettle();

          expect(called, true);
        },
      );

      testWidgets(
        'должен вызвать onAddLink при выборе Add Link',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showCanvasMenu(
                      context,
                      position: const Offset(100, 100),
                      onAddText: () {},
                      onAddImage: () {},
                      onAddLink: () => called = true,
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Add Link'));
          await tester.pumpAndSettle();

          expect(called, true);
        },
      );

      testWidgets(
        'должен показать пункт Find images когда onFindImages передан',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showCanvasMenu(
                      context,
                      position: const Offset(100, 100),
                      onAddText: () {},
                      onAddImage: () {},
                      onAddLink: () {},
                      onFindImages: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();

          expect(find.text('Find images...'), findsOneWidget);
        },
      );

      testWidgets(
        'не должен показывать Find images когда onFindImages не передан',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showCanvasMenu(
                      context,
                      position: const Offset(100, 100),
                      onAddText: () {},
                      onAddImage: () {},
                      onAddLink: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();

          expect(find.text('Find images...'), findsNothing);
        },
      );

      testWidgets(
        'должен вызвать onFindImages при выборе Find images',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showCanvasMenu(
                      context,
                      position: const Offset(100, 100),
                      onAddText: () {},
                      onAddImage: () {},
                      onAddLink: () {},
                      onFindImages: () => called = true,
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Find images...'));
          await tester.pumpAndSettle();

          expect(called, true);
        },
      );

      testWidgets(
        'должен ничего не делать при закрытии меню без выбора',
        (WidgetTester tester) async {
          bool textCalled = false;
          bool imageCalled = false;
          bool linkCalled = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showCanvasMenu(
                      context,
                      position: const Offset(100, 100),
                      onAddText: () => textCalled = true,
                      onAddImage: () => imageCalled = true,
                      onAddLink: () => linkCalled = true,
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();

          // Закрываем тапом вне меню
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();

          expect(textCalled, false);
          expect(imageCalled, false);
          expect(linkCalled, false);
        },
      );
    });

    group('showItemMenu', () {
      testWidgets(
        'должен показать Edit для типа text',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.text,
                      onEdit: () {},
                      onDelete: () {},
                      onBringToFront: () {},
                      onSendToBack: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();

          expect(find.text('Edit'), findsOneWidget);
          expect(find.text('Delete'), findsOneWidget);
          expect(find.text('Bring to Front'), findsOneWidget);
          expect(find.text('Send to Back'), findsOneWidget);
        },
      );

      testWidgets(
        'не должен показывать Edit для типа game',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.game,
                      onDelete: () {},
                      onBringToFront: () {},
                      onSendToBack: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();

          expect(find.text('Edit'), findsNothing);
          expect(find.text('Delete'), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать Edit для типов image и link',
        (WidgetTester tester) async {
          for (final CanvasItemType type in <CanvasItemType>[
            CanvasItemType.image,
            CanvasItemType.link,
          ]) {
            await tester.pumpWidget(buildTestApp(
              child: Builder(
                builder: (BuildContext context) {
                  return ElevatedButton(
                    onPressed: () {
                      CanvasContextMenu.showItemMenu(
                        context,
                        position: const Offset(100, 100),
                        itemType: type,
                        onEdit: () {},
                        onDelete: () {},
                        onBringToFront: () {},
                        onSendToBack: () {},
                      );
                    },
                    child: const Text('Open Menu'),
                  );
                },
              ),
            ));

            await tester.tap(find.text('Open Menu'));
            await tester.pumpAndSettle();

            expect(find.text('Edit'), findsOneWidget,
                reason: 'Edit should be shown for $type');

            // Close menu
            await tester.tapAt(const Offset(10, 10));
            await tester.pumpAndSettle();
          }
        },
      );

      testWidgets(
        'должен вызвать onEdit при выборе Edit',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.text,
                      onEdit: () => called = true,
                      onDelete: () {},
                      onBringToFront: () {},
                      onSendToBack: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Edit'));
          await tester.pumpAndSettle();

          expect(called, true);
        },
      );

      testWidgets(
        'должен показать диалог подтверждения при выборе Delete',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.text,
                      onDelete: () {},
                      onBringToFront: () {},
                      onSendToBack: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          expect(find.text('Delete element'), findsOneWidget);
          expect(
            find.text('Are you sure you want to delete this element?'),
            findsOneWidget,
          );
          expect(find.text('Cancel'), findsOneWidget);
        },
      );

      testWidgets(
        'должен вызвать onDelete при подтверждении удаления',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.text,
                      onDelete: () => called = true,
                      onBringToFront: () {},
                      onSendToBack: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          // Подтверждаем удаление (FilledButton 'Delete' в диалоге)
          await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
          await tester.pumpAndSettle();

          expect(called, true);
        },
      );

      testWidgets(
        'не должен вызывать onDelete при отмене удаления',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.text,
                      onDelete: () => called = true,
                      onBringToFront: () {},
                      onSendToBack: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          // Отменяем удаление
          await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
          await tester.pumpAndSettle();

          expect(called, false);
        },
      );

      testWidgets(
        'должен вызвать onBringToFront при выборе Bring to Front',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.game,
                      onDelete: () {},
                      onBringToFront: () => called = true,
                      onSendToBack: () {},
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Bring to Front'));
          await tester.pumpAndSettle();

          expect(called, true);
        },
      );

      testWidgets(
        'должен вызвать onSendToBack при выборе Send to Back',
        (WidgetTester tester) async {
          bool called = false;

          await tester.pumpWidget(buildTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.game,
                      onDelete: () {},
                      onBringToFront: () {},
                      onSendToBack: () => called = true,
                    );
                  },
                  child: const Text('Open Menu'),
                );
              },
            ),
          ));

          await tester.tap(find.text('Open Menu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Send to Back'));
          await tester.pumpAndSettle();

          expect(called, true);
        },
      );
    });
  });
}
