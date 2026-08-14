import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/widgets/tag_picker_dialog.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockGlobalTagDao mockDao;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDao = MockGlobalTagDao();
    when(() => mockDao.getAll()).thenAnswer(
      (_) async => <Tag>[
        createTestTag(id: 1, name: 'Alpha'),
        createTestTag(id: 2, name: 'Beta', sortOrder: 1),
      ],
    );
    when(() => mockDao.getAllItemTags())
        .thenAnswer((_) async => <int, List<int>>{});
  });

  Future<Set<int>? Function()> pumpAndOpen(
    WidgetTester tester, {
    Set<int> initialSelection = const <int>{},
  }) async {
    Set<int>? result;
    bool closed = false;
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            result = await TagPickerDialog.show(
              context,
              initialSelection: initialSelection,
            );
            closed = true;
          },
          child: const Text('open'),
        ),
      ),
      overrides: <Override>[
        globalTagDaoProvider.overrideWithValue(mockDao),
      ],
      wrapInScaffold: true,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () {
      expect(closed, isTrue, reason: 'dialog should have been popped');
      return result;
    };
  }

  group('TagPickerDialog', () {
    testWidgets('should render rows without exceptions', (
      WidgetTester tester,
    ) async {
      await pumpAndOpen(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('should pre-check the initial selection', (
      WidgetTester tester,
    ) async {
      await pumpAndOpen(tester, initialSelection: <int>{1});
      final Iterable<Checkbox> boxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(
        boxes.map((Checkbox c) => c.value).toList(),
        <bool>[true, false],
      );
    });

    testWidgets('should return the toggled selection on apply', (
      WidgetTester tester,
    ) async {
      final Set<int>? Function() result =
          await pumpAndOpen(tester, initialSelection: <int>{1});

      // Row tap toggles Beta on; the checkbox toggles Alpha off.
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result(), <int>{2});
    });

    testWidgets('should create and select a tag from the create row', (
      WidgetTester tester,
    ) async {
      when(
        () => mockDao.create(
          any(),
          color: any(named: 'color'),
          textColor: any(named: 'textColor'),
        ),
      ).thenAnswer(
        (_) async => createTestTag(id: 9, name: 'Horror', sortOrder: 2),
      );
      final Set<int>? Function() result = await pumpAndOpen(tester);

      await tester.enterText(find.byType(TextField), 'Horror');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(ListTile, Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      verify(
        () => mockDao.create(
          'Horror',
          color: any(named: 'color'),
          textColor: any(named: 'textColor'),
        ),
      ).called(1);
      expect(result(), <int>{9});
    });

    testWidgets('should return null when dismissed via cancel', (
      WidgetTester tester,
    ) async {
      final Set<int>? Function() result =
          await pumpAndOpen(tester, initialSelection: <int>{1});

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      ));
      await tester.pumpAndSettle();

      expect(result(), isNull);
    });
  });
}
