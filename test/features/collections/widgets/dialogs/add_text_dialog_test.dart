import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/dialogs/add_text_dialog.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  group('AddTextDialog', () {
    Widget buildTestApp({
      required void Function(Map<String, dynamic>? result) onResult,
      String? initialContent,
      double? initialFontSize,
    }) {
      return MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  final Map<String, dynamic>? result =
                      await AddTextDialog.show(
                    context,
                    initialContent: initialContent,
                    initialFontSize: initialFontSize,
                  );
                  onResult(result);
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
    }

    testWidgets(
      'должен показать заголовок "Add Text" для нового элемента',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Add Text'), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      },
    );

    testWidgets(
      'должен показать заголовок "Edit Text" при редактировании',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(
          onResult: (_) {},
          initialContent: 'Existing text',
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Text'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      },
    );

    testWidgets(
      'должен заполнить initial content',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(
          onResult: (_) {},
          initialContent: 'Hello World',
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Hello World'), findsOneWidget);
      },
    );

    testWidgets(
      'должен вернуть данные при нажатии Add',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'New Text',
        );
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!['content'], 'New Text');
        expect(result!['fontSize'], 16.0); // default Medium
      },
    );

    testWidgets(
      'должен вернуть null при нажатии Cancel',
      (WidgetTester tester) async {
        Map<String, dynamic>? result = <String, dynamic>{'marker': true};

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(result, isNull);
      },
    );

    testWidgets(
      'не должен submit когда текст пустой',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Поле пустое, нажимаем Add
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        // Диалог всё ещё открыт (submit не сработал)
        expect(find.text('Add Text'), findsOneWidget);
        expect(result, isNull);
      },
    );

    testWidgets(
      'должен обрезать пробелы в тексте',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          '  Trimmed Text  ',
        );
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(result!['content'], 'Trimmed Text');
      },
    );

    testWidgets(
      'должен иметь dropdown с 4 вариантами размера шрифта',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(DropdownButtonFormField<double>), findsOneWidget);
      },
    );

    testWidgets(
      'должен сбрасывать нестандартный initialFontSize на 16',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
          initialContent: 'Test',
          initialFontSize: 99.0, // Нестандартный размер
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(result!['fontSize'], 16.0); // Сброшен на default
      },
    );

    testWidgets(
      'должен использовать initialFontSize если он валидный',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
          initialContent: 'Test',
          initialFontSize: 32.0, // Title
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(result!['fontSize'], 32.0);
      },
    );
  });
}
