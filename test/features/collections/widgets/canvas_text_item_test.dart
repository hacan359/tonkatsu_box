import 'package:xerabora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/canvas_text_item.dart';
import 'package:xerabora/shared/models/canvas_item.dart';

void main() {
  group('CanvasTextItem', () {
    final DateTime testDate = DateTime(2024, 6, 15);

    CanvasItem createTextItem({
      Map<String, dynamic>? data,
      double? width,
    }) {
      return CanvasItem(
        id: 1,
        collectionId: 10,
        itemType: CanvasItemType.text,
        x: 100,
        y: 100,
        width: width,
        data: data,
        createdAt: testDate,
      );
    }

    Widget buildWidget(CanvasItem item) {
      return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: CanvasTextItem(item: item),
          ),
        ),
      );
    }

    testWidgets(
      'должен отображать текст из data.content',
      (WidgetTester tester) async {
        final CanvasItem item = createTextItem(
          data: <String, dynamic>{'content': 'Hello World', 'fontSize': 16.0},
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.text('Hello World'), findsOneWidget);
      },
    );

    testWidgets(
      'должен использовать fontSize из data',
      (WidgetTester tester) async {
        final CanvasItem item = createTextItem(
          data: <String, dynamic>{'content': 'Big Text', 'fontSize': 32.0},
        );

        await tester.pumpWidget(buildWidget(item));

        final Text textWidget = tester.widget<Text>(find.text('Big Text'));
        expect(textWidget.style?.fontSize, 32.0);
      },
    );

    testWidgets(
      'должен использовать fontSize 16 по умолчанию когда fontSize отсутствует',
      (WidgetTester tester) async {
        final CanvasItem item = createTextItem(
          data: <String, dynamic>{'content': 'Default Size'},
        );

        await tester.pumpWidget(buildWidget(item));

        final Text textWidget = tester.widget<Text>(find.text('Default Size'));
        expect(textWidget.style?.fontSize, 16.0);
      },
    );

    testWidgets(
      'должен отображать пустую строку когда data null',
      (WidgetTester tester) async {
        final CanvasItem item = createTextItem(data: null);

        await tester.pumpWidget(buildWidget(item));

        // Пустой Text виджет существует
        expect(find.byType(Text), findsOneWidget);
      },
    );

    testWidgets(
      'должен рендерить текст при заданном width',
      (WidgetTester tester) async {
        final CanvasItem item = createTextItem(
          data: <String, dynamic>{'content': 'Test'},
          width: 300,
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.text('Test'), findsOneWidget);
      },
    );

    testWidgets(
      'должен рендерить текст без явного width',
      (WidgetTester tester) async {
        final CanvasItem item = createTextItem(
          data: <String, dynamic>{'content': 'Default Width'},
          width: null,
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.text('Default Width'), findsOneWidget);
      },
    );

    testWidgets(
      'должен иметь padding 8',
      (WidgetTester tester) async {
        final CanvasItem item = createTextItem(
          data: <String, dynamic>{'content': 'Padded'},
        );

        await tester.pumpWidget(buildWidget(item));

        final Padding padding = tester.widget<Padding>(
          find.ancestor(
            of: find.text('Padded'),
            matching: find.byType(Padding),
          ).first,
        );
        expect(padding.padding, const EdgeInsets.all(8));
      },
    );

    testWidgets(
      'должен отображать текст без фона',
      (WidgetTester tester) async {
        final CanvasItem item = createTextItem(
          data: <String, dynamic>{'content': 'No Background'},
        );

        await tester.pumpWidget(buildWidget(item));

        // Виджет использует Padding, а не Container с декорацией
        expect(
          find.ancestor(
            of: find.text('No Background'),
            matching: find.byType(Padding),
          ),
          findsWidgets,
        );
        // Нет Container с BoxDecoration (фоном)
        final Finder containerFinder = find.ancestor(
          of: find.text('No Background'),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is Container && widget.decoration != null,
          ),
        );
        expect(containerFinder, findsNothing);
      },
    );
  });
}
