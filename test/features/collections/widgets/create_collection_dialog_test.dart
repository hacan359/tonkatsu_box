import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/create_collection_dialog.dart';
import 'package:xerabora/l10n/app_localizations.dart';

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

  group('CreateCollectionResult', () {
    test('должен создавать экземпляр с полями', () {
      const CreateCollectionResult result = CreateCollectionResult(
        name: 'Test',
        author: 'Author',
      );

      expect(result.name, 'Test');
      expect(result.author, 'Author');
    });
  });

  group('CreateCollectionDialog', () {
    testWidgets('должен отображать заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      expect(find.text('New Collection'), findsOneWidget);
    });

    testWidgets('должен отображать поля ввода', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      expect(find.text('Collection Name'), findsOneWidget);
      expect(find.text('Author'), findsOneWidget);
    });

    testWidgets('должен отображать кнопки Cancel и Create', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('должен заполнять автора по умолчанию', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(defaultAuthor: 'DefaultUser'),
      ));

      expect(find.text('DefaultUser'), findsOneWidget);
    });

    testWidgets('должен показывать ошибку для пустого названия', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets('должен показывать ошибку для короткого названия', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      await tester.enterText(find.byType(TextFormField).first, 'A');
      await tester.enterText(find.byType(TextFormField).last, 'Author');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('должен показывать ошибку для пустого автора', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const CreateCollectionDialog(),
      ));

      await tester.enterText(find.byType(TextFormField).first, 'Collection');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an author name'), findsOneWidget);
    });

    testWidgets('должен закрываться при нажатии Cancel', (WidgetTester tester) async {
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

    testWidgets('должен возвращать результат при успешном создании', (WidgetTester tester) async {
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

      await tester.enterText(find.byType(TextFormField).first, 'My Collection');
      await tester.enterText(find.byType(TextFormField).last, 'Test Author');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'My Collection');
      expect(result!.author, 'Test Author');
    });

    testWidgets('должен обрезать пробелы в названии и авторе', (WidgetTester tester) async {
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

      await tester.enterText(find.byType(TextFormField).first, '  Trimmed Name  ');
      await tester.enterText(find.byType(TextFormField).last, '  Trimmed Author  ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(result!.name, 'Trimmed Name');
      expect(result!.author, 'Trimmed Author');
    });

    testWidgets('статический метод show должен передавать defaultAuthor', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                await CreateCollectionDialog.show(
                  context,
                  defaultAuthor: 'PrefilledAuthor',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('PrefilledAuthor'), findsOneWidget);
    });
  });

  group('RenameCollectionDialog', () {
    testWidgets('должен отображать заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Test'),
      ));

      expect(find.text('Rename Collection'), findsOneWidget);
    });

    testWidgets('должен заполнять текущее название', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Current Name'),
      ));

      expect(find.text('Current Name'), findsOneWidget);
    });

    testWidgets('должен отображать кнопки Cancel и Rename', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Test'),
      ));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('должен показывать ошибку для пустого названия', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Old'),
      ));

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets('должен показывать ошибку для короткого названия', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const RenameCollectionDialog(currentName: 'Old Name'),
      ));

      await tester.enterText(find.byType(TextFormField), 'X');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('должен закрываться при нажатии Cancel', (WidgetTester tester) async {
      String? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await RenameCollectionDialog.show(context, 'Old');
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

    testWidgets('должен возвращать новое название при успешном переименовании', (WidgetTester tester) async {
      String? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await RenameCollectionDialog.show(context, 'Old Name');
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

    testWidgets('должен обрезать пробелы в названии', (WidgetTester tester) async {
      String? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await RenameCollectionDialog.show(context, 'Old');
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

  group('DeleteCollectionDialog', () {
    testWidgets('должен отображать заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const DeleteCollectionDialog(collectionName: 'Test'),
      ));

      expect(find.text('Delete Collection?'), findsOneWidget);
    });

    testWidgets('должен отображать название коллекции в тексте', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const DeleteCollectionDialog(collectionName: 'My Collection'),
      ));

      // Текст содержит название коллекции
      expect(find.textContaining('My Collection'), findsOneWidget);
    });

    testWidgets('должен отображать предупреждение', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const DeleteCollectionDialog(collectionName: 'Test'),
      ));

      // Диалог содержит контент с предупреждением
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('должен отображать кнопки Cancel и Delete', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const DeleteCollectionDialog(collectionName: 'Test'),
      ));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('должен возвращать false при нажатии Cancel', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await DeleteCollectionDialog.show(context, 'Test');
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

      expect(result, false);
    });

    testWidgets('должен возвращать true при нажатии Delete', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await DeleteCollectionDialog.show(context, 'Test');
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('должен возвращать false при закрытии без выбора', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await DeleteCollectionDialog.show(context, 'Test');
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Нажимаем за пределами диалога (это закроет его)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, false);
    });
  });
}
