import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/widgets/tag_picker_dialog.dart';
import 'package:tonkatsu_box/shared/models/tag.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockGlobalTagDao mockDao;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDao = MockGlobalTagDao();
    when(() => mockDao.getAll()).thenAnswer(
      (_) async => <Tag>[
        createTestTag(id: 1, name: 'Action'),
        createTestTag(id: 2, name: 'Adventure', sortOrder: 1),
      ],
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    Set<int> initialSelection = const <int>{},
  }) async {
    await tester.pumpApp(
      TagPickerDialog(initialSelection: initialSelection),
      overrides: <Override>[
        globalTagDaoProvider.overrideWithValue(mockDao),
      ],
    );
  }

  Finder createTile() => find.widgetWithIcon(ListTile, Icons.add);

  group('TagPickerDialog', () {
    testWidgets('shows every tag when the search is empty', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(createTile(), findsNothing);
    });

    testWidgets('typing filters the list case-insensitively', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'venture');
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);
    });

    testWidgets('a query with no exact match offers the create row', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'Horror');
      await tester.pumpAndSettle();

      expect(createTile(), findsOneWidget);
    });

    testWidgets('an exact match (any case) hides the create row', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'aCtIoN');
      await tester.pumpAndSettle();

      expect(createTile(), findsNothing);
    });

    testWidgets('tapping the create row creates and selects the tag', (
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
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'Horror');
      await tester.pumpAndSettle();
      await tester.tap(createTile());
      await tester.pumpAndSettle();

      verify(
        () => mockDao.create(
          'Horror',
          color: any(named: 'color'),
          textColor: any(named: 'textColor'),
        ),
      ).called(1);
      // Search cleared, new tag listed and checked.
      final CheckboxListTile horror = tester.widget(
        find.ancestor(
          of: find.text('Horror'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(horror.value, isTrue);
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
    });

    testWidgets('applying returns the selected ids', (
      WidgetTester tester,
    ) async {
      Set<int>? result;
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () async {
              result = await TagPickerDialog.show(
                context,
                initialSelection: <int>{1},
              );
            },
            child: const SizedBox.shrink(),
          ),
        ),
        overrides: <Override>[
          globalTagDaoProvider.overrideWithValue(mockDao),
        ],
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('Adventure'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, <int>{1, 2});
    });
  });
}
