import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/dialogs/add_image_dialog.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

void main() {
  group('AddImageDialog', () {
    Widget buildTestApp({
      required void Function(Map<String, dynamic>? result) onResult,
      String? initialUrl,
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
                      await AddImageDialog.show(
                    context,
                    initialUrl: initialUrl,
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
      'should show заголовок "Add Image" для нового элемента',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Add Image'), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      },
    );

    testWidgets(
      'should show заголовок "Edit Image" когда initialUrl указан',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(
          onResult: (_) {},
          initialUrl: 'https://example.com/image.png',
        ));
        await tester.tap(find.text('Open'));
        // CachedNetworkImage spins a CircularProgressIndicator forever,
        // so pumpAndSettle hangs — use pump() instead.
        await tester.pump();
        await tester.pump();

        expect(find.text('Edit Image'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      },
    );

    testWidgets(
      'should show SegmentedButton с "From URL" и "From File" для нового элемента',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (Widget widget) => widget.runtimeType.toString().startsWith('SegmentedButton'),
          ),
          findsOneWidget,
        );
        expect(find.text('From URL'), findsOneWidget);
        expect(find.text('From File'), findsOneWidget);
      },
    );

    testWidgets(
      'не should show SegmentedButton когда initialUrl указан',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(
          onResult: (_) {},
          initialUrl: 'https://example.com/image.png',
        ));
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump();

        expect(
          find.byWidgetPredicate(
            (Widget widget) => widget.runtimeType.toString().startsWith('SegmentedButton'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'should show TextField с лейблом "Image URL" в режиме URL',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Image URL'), findsOneWidget);
      },
    );

    testWidgets(
      'должен отключить кнопку Add когда URL пустой',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final FilledButton addButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(addButton.onPressed, isNull);
      },
    );

    testWidgets(
      'должен отключить кнопку Add когда URL не начинается с http:// или https://',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'ftp://example.com/image.png',
        );
        await tester.pumpAndSettle();

        final FilledButton addButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(addButton.onPressed, isNull);
      },
    );

    testWidgets(
      'должен включить кнопку Add когда URL начинается с https://',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'https://example.com/image.png',
        );
        await tester.pump();
        await tester.pump();

        final FilledButton addButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(addButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'должен включить кнопку Add когда URL начинается с http://',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'http://example.com/image.png',
        );
        await tester.pump();
        await tester.pump();

        final FilledButton addButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(addButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'should return map с url when pressed Add с валидным URL',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'https://example.com/image.png',
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!['url'], 'https://example.com/image.png');
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
      'должен заполнить initialUrl в TextField',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(
          onResult: (_) {},
          initialUrl: 'https://example.com/image.png',
        ));
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump();

        final TextField textField = tester.widget<TextField>(
          find.byType(TextField),
        );
        expect(textField.controller?.text, 'https://example.com/image.png');
      },
    );

    testWidgets(
      'should show кнопку "Choose File" в режиме файла',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(onResult: (_) {}));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('From File'));
        await tester.pumpAndSettle();

        expect(find.text('Choose File'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'должен обрезать пробелы в URL при submit',
      (WidgetTester tester) async {
        Map<String, dynamic>? result;

        await tester.pumpWidget(buildTestApp(
          onResult: (Map<String, dynamic>? r) => result = r,
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          '  https://example.com/image.png  ',
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!['url'], 'https://example.com/image.png');
      },
    );
  });
}
