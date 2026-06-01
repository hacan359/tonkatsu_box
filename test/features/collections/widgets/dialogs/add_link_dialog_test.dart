import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/dialogs/add_link_dialog.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

void main() {
  group('AddLinkDialog', () {
    Widget buildTestApp({
      required void Function(Map<String, dynamic>? result) onResult,
      String? initialUrl,
      String? initialLabel,
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
      'should show заголовок "Add Link" для нового элемента',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Add Link'), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      },
    );

    testWidgets(
      'should show заголовок "Edit Link" при редактировании',
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

        final TextField urlField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(urlField.controller?.text, 'https://example.com');
        expect(find.text('My Site'), findsOneWidget);
      },
    );

    testWidgets(
      'should return url и label when pressed Add',
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
      'should use URL как label если label пустой',
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
      'should return null when pressed Cancel',
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

        await tester.enterText(
          find.byType(TextField).first,
          'not-a-url',
        );
        await tester.pumpAndSettle();

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
      'should show 2 TextField — URL и Label',
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
