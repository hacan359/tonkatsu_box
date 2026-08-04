import 'package:core/models/tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/widgets/item_tags_section.dart';

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
        createTestTag(id: 3, name: 'Gamma', sortOrder: 2),
      ],
    );
    when(() => mockDao.setItemTagPositions(any(), any()))
        .thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester, {
    required List<int> itemOrder,
  }) async {
    when(() => mockDao.getAllItemTags()).thenAnswer(
      (_) async => <int, List<int>>{7: itemOrder},
    );
    await tester.pumpApp(
      const ItemTagsSection(itemId: 7, isEditable: true),
      overrides: <Override>[
        globalTagDaoProvider.overrideWithValue(mockDao),
      ],
      wrapInScaffold: true,
    );
  }

  group('ItemTagsSection', () {
    testWidgets('renders chips in the per-item order', (
      WidgetTester tester,
    ) async {
      await pump(tester, itemOrder: <int>[3, 1, 2]);

      final double gammaX = tester.getCenter(find.text('Gamma')).dx;
      final double alphaX = tester.getCenter(find.text('Alpha')).dx;
      final double betaX = tester.getCenter(find.text('Beta')).dx;
      expect(gammaX, lessThan(alphaX));
      expect(alphaX, lessThan(betaX));
    });

    testWidgets('dragging a chip onto another persists the new order', (
      WidgetTester tester,
    ) async {
      await pump(tester, itemOrder: <int>[1, 2, 3]);

      await tester.drag(
        find.text('Alpha'),
        tester.getCenter(find.text('Gamma')) -
            tester.getCenter(find.text('Alpha')),
      );
      await tester.pumpAndSettle();

      verify(() => mockDao.setItemTagPositions(7, <int>[2, 3, 1]))
          .called(1);
      final double alphaX = tester.getCenter(find.text('Alpha')).dx;
      final double betaX = tester.getCenter(find.text('Beta')).dx;
      expect(betaX, lessThan(alphaX));
    });

    testWidgets('dragging backward inserts before the target chip', (
      WidgetTester tester,
    ) async {
      await pump(tester, itemOrder: <int>[1, 2, 3]);

      await tester.drag(
        find.text('Gamma'),
        tester.getCenter(find.text('Alpha')) -
            tester.getCenter(find.text('Gamma')),
      );
      await tester.pumpAndSettle();

      verify(() => mockDao.setItemTagPositions(7, <int>[3, 1, 2]))
          .called(1);
    });

    testWidgets('single tag renders without exceptions', (
      WidgetTester tester,
    ) async {
      await pump(tester, itemOrder: <int>[2]);

      expect(find.text('Beta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
