import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/create_collection_dialog.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    required Widget child,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('CreateCollectionDialog', () {
    testWidgets('должен отображать заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      expect(find.text('New Collection'), findsOneWidget);
    });

    testWidgets('должен отображать поле ввода названия',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      expect(find.text('Collection Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('должен отображать кнопки Cancel и Create',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('should show ошибку для пустого названия',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets('should show ошибку для короткого названия',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      await tester.enterText(find.byType(TextFormField), 'A');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(
          find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('должен закрываться when pressed Cancel',
        (WidgetTester tester) async {
      CreateCollectionResult? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await CreateCollectionDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('should return название при успешном создании',
        (WidgetTester tester) async {
      CreateCollectionResult? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await CreateCollectionDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'My Collection');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(result?.name, 'My Collection');
    });

    testWidgets('должен обрезать пробелы в названии',
        (WidgetTester tester) async {
      CreateCollectionResult? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await CreateCollectionDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '  Trimmed Name  ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(result?.name, 'Trimmed Name');
    });
  });

  group('RenameCollectionDialog', () {
    testWidgets('должен отображать заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Test'),
      ));

      expect(find.text('Rename Collection'), findsOneWidget);
    });

    testWidgets('должен заполнять текущее название',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Current Name'),
      ));

      expect(find.text('Current Name'), findsOneWidget);
    });

    testWidgets('должен отображать кнопки Cancel и Rename',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Test'),
      ));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('should show ошибку для пустого названия',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Old'),
      ));

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets('should show ошибку для короткого названия',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Old Name'),
      ));

      await tester.enterText(find.byType(TextFormField), 'X');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(
          find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('должен закрываться when pressed Cancel',
        (WidgetTester tester) async {
      String? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result =
                    await RenameCollectionDialog.show(context, 'Old');
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets(
        'should return новое название при успешном переименовании',
        (WidgetTester tester) async {
      String? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await RenameCollectionDialog.show(
                    context, 'Old Name');
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'New Name');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(result, 'New Name');
    });

    testWidgets('должен обрезать пробелы в названии',
        (WidgetTester tester) async {
      String? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result =
                    await RenameCollectionDialog.show(context, 'Old');
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '  Trimmed  ');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(result, 'Trimmed');
    });
  });
}
