// Тесты для MarkdownToolbar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/markdown_toolbar.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildToolbar() {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Column(
          children: <Widget>[
            MarkdownToolbar(controller: controller),
            TextField(controller: controller),
          ],
        ),
      ),
    );
  }

  group('MarkdownToolbar', () {
    group('кнопки', () {
      testWidgets('должен показывать 3 кнопки: Bold, Italic, Link',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildToolbar());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.format_bold), findsOneWidget);
        expect(find.byIcon(Icons.format_italic), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
      });
    });

    group('wrapSelection', () {
      test('должен вставлять маркеры на позицию курсора (collapsed)', () {
        controller.text = 'hello world';
        controller.selection = const TextSelection.collapsed(offset: 5);

        MarkdownToolbar.wrapSelection(controller, '**');

        expect(controller.text, 'hello**** world');
        expect(controller.selection.baseOffset, 7);
        expect(controller.selection.isCollapsed, true);
      });

      test('должен оборачивать выделенный текст', () {
        controller.text = 'hello world';
        controller.selection =
            const TextSelection(baseOffset: 6, extentOffset: 11);

        MarkdownToolbar.wrapSelection(controller, '**');

        expect(controller.text, 'hello **world**');
        expect(controller.selection.baseOffset, 8);
        expect(controller.selection.extentOffset, 13);
      });

      test('должен оборачивать * для italic', () {
        controller.text = 'some text';
        controller.selection =
            const TextSelection(baseOffset: 5, extentOffset: 9);

        MarkdownToolbar.wrapSelection(controller, '*');

        expect(controller.text, 'some *text*');
      });

      test('не должен ничего делать при невалидном selection', () {
        controller.text = 'hello';
        // Selection по умолчанию невалидна.
        controller.selection = const TextSelection.collapsed(offset: -1);

        MarkdownToolbar.wrapSelection(controller, '**');

        expect(controller.text, 'hello');
      });
    });

    group('insertLink', () {
      testWidgets('должен открывать диалог вставки ссылки',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildToolbar());
        await tester.pumpAndSettle();

        // Фокусируем TextField чтобы controller имел валидный selection.
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.link));
        await tester.pumpAndSettle();

        // Диалог с полями Text и URL.
        expect(find.text('Insert link'), findsOneWidget);
        expect(find.text('URL'), findsOneWidget);
      });

      testWidgets('должен вставлять markdown-ссылку при подтверждении',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildToolbar());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.link));
        await tester.pumpAndSettle();

        // Находим поля внутри AlertDialog.
        final Finder dialogFields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        expect(dialogFields, findsNWidgets(2));

        await tester.enterText(dialogFields.first, 'Guide');
        await tester.enterText(dialogFields.last, 'https://example.com');

        await tester.tap(find.text('Insert'));
        await tester.pumpAndSettle();

        expect(controller.text, '[Guide](https://example.com)');
      });

      testWidgets('не должен вставлять при отмене',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildToolbar());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.link));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(controller.text, isEmpty);
      });

      testWidgets('не должен вставлять при пустом URL',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildToolbar());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.link));
        await tester.pumpAndSettle();

        // Вводим только текст, без URL.
        final Finder dialogFields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(dialogFields.first, 'Guide');

        await tester.tap(find.text('Insert'));
        await tester.pumpAndSettle();

        expect(controller.text, isEmpty);
      });
    });
  });
}
