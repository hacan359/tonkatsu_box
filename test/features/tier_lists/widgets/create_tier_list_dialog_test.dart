// Виджет-тесты для CreateTierListDialog.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/tier_lists/widgets/create_tier_list_dialog.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/tier_list.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late MockTierListDao mockTierListDao;
  late MockCollectionRepository mockCollectionRepository;

  setUp(() {
    mockTierListDao = MockTierListDao();
    mockCollectionRepository = MockCollectionRepository();

    when(() => mockTierListDao.getAllTierLists())
        .thenAnswer((_) async => <TierList>[]);
    when(() => mockCollectionRepository.getAll())
        .thenAnswer((_) async => <Collection>[
              createTestCollection(id: 1, name: 'Collection A'),
              createTestCollection(id: 2, name: 'Collection B'),
            ]);
  });

  List<Override> buildOverrides() {
    return <Override>[
      tierListDaoProvider.overrideWithValue(mockTierListDao),
      collectionRepositoryProvider.overrideWithValue(mockCollectionRepository),
    ];
  }

  group('CreateTierListDialog', () {
    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpApp(
        const CreateTierListDialog(),
        overrides: buildOverrides(),
      );

      expect(find.byType(CreateTierListDialog), findsOneWidget);
    });

    testWidgets('should have name text field', (WidgetTester tester) async {
      await tester.pumpApp(
        const CreateTierListDialog(),
        overrides: buildOverrides(),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
        'should have radio buttons for scope when no preselectedCollectionId',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const CreateTierListDialog(),
        overrides: buildOverrides(),
      );

      // Radio buttons are shown for scope selection.
      expect(find.byType(Radio<bool>), findsWidgets);
    });

    testWidgets(
        'should not show radio buttons when preselectedCollectionId is set',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const CreateTierListDialog(preselectedCollectionId: 1),
        overrides: buildOverrides(),
      );

      expect(find.byType(Radio<bool>), findsNothing);
    });

    testWidgets('should not submit when name is empty',
        (WidgetTester tester) async {
      when(() => mockTierListDao.createTierList(
            any(),
            collectionId: any(named: 'collectionId'),
          )).thenAnswer((_) async => createTestTierList(id: 1, name: 'Test'));

      await tester.pumpApp(
        const CreateTierListDialog(),
        overrides: buildOverrides(),
      );

      // Tap the create/submit button without entering any text.
      final Finder textButtons = find.byType(TextButton);
      expect(textButtons, findsNWidgets(2));

      // Tap the last TextButton (Create action).
      await tester.tap(textButtons.last);
      await tester.pumpAndSettle();

      // createTierList should NOT have been called because name is empty.
      verifyNever(() => mockTierListDao.createTierList(
            any(),
            collectionId: any(named: 'collectionId'),
          ));
    });
  });
}
