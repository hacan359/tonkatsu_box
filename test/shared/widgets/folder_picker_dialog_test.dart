import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tonkatsu_box/shared/widgets/folder_picker_dialog.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('folder_picker_test');
    Directory(p.join(tempDir.path, 'alpha')).createSync();
    Directory(p.join(tempDir.path, 'beta', 'nested'))
        .createSync(recursive: true);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String? Function()> pumpPicker(
    WidgetTester tester, {
    List<FolderPickerRoot>? roots,
  }) async {
    String? result;
    bool done = false;
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) => Center(
          child: OutlinedButton(
            onPressed: () async {
              result = await FolderPickerDialog.show(
                context,
                roots: roots ??
                    <FolderPickerRoot>[
                      FolderPickerRoot(path: tempDir.path, label: 'root'),
                    ],
                title: 'pick',
              );
              done = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
      wrapInScaffold: true,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => done ? result : throw StateError('dialog still open');
  }

  group('FolderPickerDialog', () {
    testWidgets('renders without exception', (WidgetTester tester) async {
      await pumpPicker(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(FolderPickerDialog), findsOneWidget);
    });

    testWidgets('renders without exception on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPicker(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('select at root returns the root path',
        (WidgetTester tester) async {
      final String? Function() result = await pumpPicker(tester);

      await tester.tap(find.byKey(const ValueKey<String>(
        'folder-picker-select',
      )));
      await tester.pumpAndSettle();

      expect(result(), tempDir.path);
    });

    testWidgets('navigates into a subfolder and selects it',
        (WidgetTester tester) async {
      final String? Function() result = await pumpPicker(tester);

      await tester.tap(find.text('alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>(
        'folder-picker-select',
      )));
      await tester.pumpAndSettle();

      expect(result(), p.join(tempDir.path, 'alpha'));
    });

    testWidgets('".." goes back up and is absent at the root',
        (WidgetTester tester) async {
      final String? Function() result = await pumpPicker(tester);
      const ValueKey<String> upKey = ValueKey<String>('folder-picker-up');

      expect(find.byKey(upKey), findsNothing);

      await tester.tap(find.text('beta'));
      await tester.pumpAndSettle();
      expect(find.byKey(upKey), findsOneWidget);

      await tester.tap(find.byKey(upKey));
      await tester.pumpAndSettle();
      expect(find.byKey(upKey), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>(
        'folder-picker-select',
      )));
      await tester.pumpAndSettle();
      expect(result(), tempDir.path);
    });

    testWidgets('creates a folder and enters it',
        (WidgetTester tester) async {
      final String? Function() result = await pumpPicker(tester);

      await tester.tap(find.byKey(const ValueKey<String>(
        'folder-picker-new',
      )));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'gamma');
      await tester.tap(find.byKey(const ValueKey<String>(
        'folder-picker-create-confirm',
      )));
      await tester.pumpAndSettle();

      final String created = p.join(tempDir.path, 'gamma');
      expect(Directory(created).existsSync(), isTrue);

      await tester.tap(find.byKey(const ValueKey<String>(
        'folder-picker-select',
      )));
      await tester.pumpAndSettle();
      expect(result(), created);
    });

    testWidgets('rejects an invalid folder name',
        (WidgetTester tester) async {
      await pumpPicker(tester);

      await tester.tap(find.byKey(const ValueKey<String>(
        'folder-picker-new',
      )));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'bad/name');
      await tester.tap(find.byKey(const ValueKey<String>(
        'folder-picker-create-confirm',
      )));
      await tester.pumpAndSettle();

      expect(Directory(p.join(tempDir.path, 'bad')).existsSync(), isFalse);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('dismissing returns null', (WidgetTester tester) async {
      final String? Function() result = await pumpPicker(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(result(), isNull);
    });

    group('multiple roots', () {
      late List<FolderPickerRoot> roots;

      setUp(() {
        Directory(p.join(tempDir.path, 'internal', 'docs'))
            .createSync(recursive: true);
        Directory(p.join(tempDir.path, 'sdcard')).createSync();
        roots = <FolderPickerRoot>[
          FolderPickerRoot(
            path: p.join(tempDir.path, 'internal'),
            label: 'Internal',
          ),
          FolderPickerRoot(
            path: p.join(tempDir.path, 'sdcard'),
            label: 'SD',
            removable: true,
          ),
        ];
      });

      testWidgets('opens on the volume list with select disabled',
          (WidgetTester tester) async {
        await pumpPicker(tester, roots: roots);

        expect(find.text('Internal'), findsOneWidget);
        expect(find.text('SD'), findsOneWidget);
        final FilledButton select = tester.widget<FilledButton>(
          find.byKey(const ValueKey<String>('folder-picker-select')),
        );
        expect(select.onPressed, isNull);
      });

      testWidgets('enters a volume and selects a folder inside it',
          (WidgetTester tester) async {
        final String? Function() result =
            await pumpPicker(tester, roots: roots);

        await tester.tap(find.text('Internal'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('docs'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>(
          'folder-picker-select',
        )));
        await tester.pumpAndSettle();

        expect(result(), p.join(tempDir.path, 'internal', 'docs'));
      });

      testWidgets('".." from a volume root returns to the volume list',
          (WidgetTester tester) async {
        await pumpPicker(tester, roots: roots);
        const ValueKey<String> upKey = ValueKey<String>('folder-picker-up');

        await tester.tap(find.text('SD'));
        await tester.pumpAndSettle();
        expect(find.byKey(upKey), findsOneWidget);

        await tester.tap(find.byKey(upKey));
        await tester.pumpAndSettle();

        expect(find.text('Internal'), findsOneWidget);
        expect(find.text('SD'), findsOneWidget);
        expect(find.byKey(upKey), findsNothing);
      });
    });
  });
}
