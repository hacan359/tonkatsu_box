import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/widgets/tag_management_dialog.dart';

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
    when(() => mockDao.getAllItemTags()).thenAnswer(
      (_) async => <int, List<int>>{
        10: <int>[1],
        11: <int>[1],
      },
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpApp(
      const TagManagementDialog(),
      overrides: <Override>[
        globalTagDaoProvider.overrideWithValue(mockDao),
      ],
    );
  }

  group('TagManagementDialog', () {
    testWidgets('should render every tag row without exceptions', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('should show usage counts from the item links', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.text('· 2'), findsOneWidget);
    });

    testWidgets('should create a tag from the search query on Enter', (
      WidgetTester tester,
    ) async {
      when(
        () => mockDao.create(
          any(),
          color: any(named: 'color'),
          textColor: any(named: 'textColor'),
        ),
      ).thenAnswer(
        (_) async => createTestTag(id: 9, name: 'fresh', sortOrder: 2),
      );

      await pump(tester);
      await tester.enterText(find.byType(TextField), 'fresh');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(
        () => mockDao.create(
          'fresh',
          color: null,
          textColor: any(named: 'textColor'),
        ),
      ).called(1);
      expect(find.text('fresh'), findsOneWidget);
    });

    testWidgets('should not hit the DAO when creating a duplicate name', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'ALPHA');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verifyNever(
        () => mockDao.create(
          any(),
          color: any(named: 'color'),
          textColor: any(named: 'textColor'),
        ),
      );
    });
  });
}
