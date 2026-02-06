import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/dialogs/add_link_dialog.dart';

void main() {
  group('AddLinkDialog', () {
    Widget buildTestApp({
      required void Function(Map<String, dynamic>? result) onResult,
      String? initialUrl,
      String? initialLabel,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  final Map<String, dynamic>? result =
                      await AddLinkDialog.show(
                    context,
                    initialUrl: initialUrl,
                    initialLabel: initialLabel,
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
      'должен показать заголовок "Add Link" для нового элемента',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Add Link'), findsOneWidget);
        // FilledButton disabled (no valid URL)
        expect(find.text('Add'), findsOneWidget);
      },
    );

    testWidgets(
      'должен показать заголовок "Edit Link" при редактировании',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(
          onResult: (_) {},
          initialUrl: 'https://example.com',
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Link'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      },
    );

    testWidgets(
      'должен заполнить initial URL и label',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(
          onResult: (_) {},
          initialUrl: 'https://example.com',
          initialLabel: 'My Site',
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // URL может быть в TextField и hint — проверяем через контроллер
        final TextField urlField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(urlField.controller?.text, 'https://example.com');
        expect(find.text('My Site'), findsOneWidget);
      },
    );

    testWidgets(
      'должен вернуть url и label при нажатии Add',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Вводим URL
        await tester.enterText(
          find.byType(TextField).first,
          'https://example.com',
        );
        await tester.pumpAndSettle();

        // Вводим label
        await tester.enterText(
          find.byType(TextField).last,
          'Example',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!['url'], 'https://example.com');
        expect(result!['label'], 'Example');
      },
    );

    testWidgets(
      'должен использовать URL как label если label пустой',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'https://example.com',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(result!['label'], 'https://example.com');
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
      'должен отключать кнопку Add когда URL невалидный',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Вводим невалидный URL
        await tester.enterText(
          find.byType(TextField).first,
          'not-a-url',
        );
        await tester.pumpAndSettle();

        // Кнопка Add disabled
        final FilledButton addButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(addButton.onPressed, isNull);
      },
    );

    testWidgets(
      'должен включать кнопку Add когда URL начинается с https://',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'https://example.com',
        );
        await tester.pumpAndSettle();

        final FilledButton addButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(addButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'должен включать кнопку Add когда URL начинается с http://',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'http://example.com',
        );
        await tester.pumpAndSettle();

        final FilledButton addButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(addButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'должен обрезать пробелы в URL и label',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          '  https://example.com  ',
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).last,
          '  My Label  ',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(result!['url'], 'https://example.com');
        expect(result!['label'], 'My Label');
      },
    );

    testWidgets(
      'должен показать 2 TextField — URL и Label',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text('URL'), findsOneWidget);
        expect(find.text('Label (optional)'), findsOneWidget);
      },
    );
  });
}
