import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для showCollectionPickerDialog.
//
// Диалог выбора коллекции: отображает список коллекций,
// опцию "Without Collection", фильтр, маркировку дублей и кнопку Cancel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/widgets/collection_picker_dialog.dart';

/// Тестовые коллекции.
final DateTime _testDate = DateTime(2026, 1, 1);

final Collection _collectionA = Collection(
  id: 1,
  name: 'Collection A',
  author: 'Author A',
  type: CollectionType.own,
  createdAt: _testDate,
);

final Collection _collectionB = Collection(
  id: 2,
  name: 'Collection B',
  author: 'Author B',
  type: CollectionType.own,
  createdAt: _testDate,
);

final Collection _collectionFork = Collection(
  id: 3,
  name: 'Forked',
  author: 'Author C',
  type: CollectionType.fork,
  createdAt: _testDate,
);

final Collection _collectionImported = Collection(
  id: 4,
  name: 'Imported',
  author: 'Author D',
  type: CollectionType.imported,
  createdAt: _testDate,
);

/// Виджет-обёртка для вызова showCollectionPickerDialog из теста.
///
/// Наблюдает [collectionsProvider] при сборке (для его инициализации),
/// а при нажатии кнопки показывает диалог.
class _DialogTester extends ConsumerWidget {
  const _DialogTester({
    required this.onResult,
    this.excludeCollectionId,
    this.showUncategorized = true,
    this.title = 'Choose Collection',
    this.alreadyInCollectionIds = const <int?>{},
  });

  final void Function(CollectionChoice?) onResult;
  final int? excludeCollectionId;
  final bool showUncategorized;
  final String title;
  final Set<int?> alreadyInCollectionIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Наблюдаем за провайдером, чтобы он инициализировался при pump.
    ref.watch(collectionsProvider);

    return ElevatedButton(
      onPressed: () async {
        final CollectionChoice? choice = await showCollectionPickerDialog(
          context: context,
          ref: ref,
          excludeCollectionId: excludeCollectionId,
          showUncategorized: showUncategorized,
          title: title,
          alreadyInCollectionIds: alreadyInCollectionIds,
        );
        onResult(choice);
      },
      child: const Text('Open'),
    );
  }
}

/// No-op callback для тестов, где результат диалога не проверяется.
void _ignoreResult(CollectionChoice? _) {}

/// Строит тестовый виджет с ProviderScope и переопределённым
/// collectionsProvider.
Widget _buildTestWidget({
  void Function(CollectionChoice?)? onResult,
  List<Collection> collections = const <Collection>[],
  int? excludeCollectionId,
  bool showUncategorized = true,
  String title = 'Choose Collection',
  Set<int?> alreadyInCollectionIds = const <int?>{},
}) {
  return ProviderScope(
    overrides: <Override>[
      collectionsProvider.overrideWith(
        () => _FakeCollectionsNotifier(collections),
      ),
    ],
    child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: _DialogTester(
          onResult: onResult ?? _ignoreResult,
          excludeCollectionId: excludeCollectionId,
          showUncategorized: showUncategorized,
          title: title,
          alreadyInCollectionIds: alreadyInCollectionIds,
        ),
      ),
    ),
  );
}

/// Фейковый notifier для collectionsProvider.
class _FakeCollectionsNotifier extends CollectionsNotifier {
  _FakeCollectionsNotifier(this._collections);

  final List<Collection> _collections;

  @override
  Future<List<Collection>> build() async {
    return _collections;
  }
}

/// Открывает тестовый виджет, ждёт инициализации провайдера
/// и открывает диалог.
Future<void> _openDialog(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  // Ждём завершения async build провайдера.
  await tester.pumpAndSettle();

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// Генерирует список коллекций заданной длины.
List<Collection> _generateCollections(int count) {
  return List<Collection>.generate(count, (int i) {
    return Collection(
      id: i + 1,
      name: 'Collection ${i + 1}',
      author: 'Author ${i + 1}',
      type: CollectionType.own,
      createdAt: _testDate,
    );
  });
}

void main() {
  group('showCollectionPickerDialog', () {
    testWidgets('должен отображать заголовок', (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionA],
          title: 'Move to Collection',
        ),
      );

      expect(find.text('Move to Collection'), findsOneWidget);
    });

    testWidgets(
        'должен показывать "Without Collection" '
        'когда showUncategorized == true', (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionA],
          showUncategorized: true,
        ),
      );

      expect(find.text('Without Collection'), findsOneWidget);
      expect(find.text('Uncategorized'), findsOneWidget);
    });

    testWidgets(
        'должен скрывать "Without Collection" '
        'когда showUncategorized == false', (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionA],
          showUncategorized: false,
        ),
      );

      expect(find.text('Without Collection'), findsNothing);
      expect(find.text('Uncategorized'), findsNothing);
    });

    testWidgets(
        'должен исключать коллекцию с excludeCollectionId',
        (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionA, _collectionB],
          excludeCollectionId: 1,
          showUncategorized: false,
        ),
      );

      // Collection A (id=1) должна быть скрыта.
      expect(find.text('Collection A'), findsNothing);
      // Collection B (id=2) должна быть видна.
      expect(find.text('Collection B'), findsOneWidget);
    });

    testWidgets(
        'должен показывать imported коллекции (теперь editable)',
        (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[
            _collectionA,
            _collectionImported,
          ],
          showUncategorized: false,
        ),
      );

      // Own коллекция видна.
      expect(find.text('Collection A'), findsOneWidget);
      // Imported теперь editable и видна.
      expect(find.text('Imported'), findsOneWidget);
    });

    testWidgets(
        'должен показывать fork коллекции (editable)',
        (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionFork],
          showUncategorized: false,
        ),
      );

      expect(find.text('Forked'), findsOneWidget);
    });

    testWidgets(
        'должен возвращать ChosenCollection при нажатии на коллекцию',
        (WidgetTester tester) async {
      CollectionChoice? result;

      await _openDialog(
        tester,
        _buildTestWidget(
          onResult: (CollectionChoice? r) => result = r,
          collections: <Collection>[_collectionA, _collectionB],
          showUncategorized: false,
        ),
      );

      await tester.tap(find.text('Collection B'));
      await tester.pumpAndSettle();

      expect(result, isA<ChosenCollection>());
      final ChosenCollection chosen = result! as ChosenCollection;
      expect(chosen.collection.id, 2);
      expect(chosen.collection.name, 'Collection B');
    });

    testWidgets(
        'должен возвращать WithoutCollection при нажатии "Without Collection"',
        (WidgetTester tester) async {
      CollectionChoice? result;

      await _openDialog(
        tester,
        _buildTestWidget(
          onResult: (CollectionChoice? r) => result = r,
          collections: <Collection>[_collectionA],
          showUncategorized: true,
        ),
      );

      await tester.tap(find.text('Without Collection'));
      await tester.pumpAndSettle();

      expect(result, isA<WithoutCollection>());
    });

    testWidgets('должен возвращать null при нажатии Cancel',
        (WidgetTester tester) async {
      CollectionChoice? result;
      bool called = false;

      await _openDialog(
        tester,
        _buildTestWidget(
          onResult: (CollectionChoice? r) {
            called = true;
            result = r;
          },
          collections: <Collection>[_collectionA],
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
    });

    testWidgets(
        'должен показывать иконку folder_rounded для own-коллекций',
        (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionA],
          showUncategorized: false,
        ),
      );

      expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
    });

    testWidgets(
        'должен показывать иконку fork_right для fork-коллекций',
        (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionFork],
          showUncategorized: false,
        ),
      );

      expect(find.byIcon(Icons.fork_right), findsOneWidget);
    });

    testWidgets(
        'должен показывать автора коллекции как subtitle',
        (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionA],
          showUncategorized: false,
        ),
      );

      expect(find.text('Author A'), findsOneWidget);
    });

    // ==================== Duplicate detection ====================

    group('маркировка дублей', () {
      testWidgets(
          'disabled коллекция показывает бейдж "✓ Added"',
          (WidgetTester tester) async {
        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[_collectionA, _collectionB],
            showUncategorized: false,
            alreadyInCollectionIds: <int?>{2},
          ),
        );

        expect(find.text('✓ Added'), findsOneWidget);
      });

      testWidgets(
          'disabled коллекция не реагирует на нажатие',
          (WidgetTester tester) async {
        CollectionChoice? result;
        bool called = false;

        await _openDialog(
          tester,
          _buildTestWidget(
            onResult: (CollectionChoice? r) {
              called = true;
              result = r;
            },
            collections: <Collection>[_collectionA, _collectionB],
            showUncategorized: false,
            alreadyInCollectionIds: <int?>{2},
          ),
        );

        // Пытаемся нажать на disabled коллекцию
        await tester.tap(find.text('Collection B'));
        await tester.pumpAndSettle();

        // Диалог не должен закрыться
        expect(called, isFalse);
        expect(result, isNull);
      });

      testWidgets(
          'Uncategorized disabled и показывает бейдж когда null в alreadyInCollectionIds',
          (WidgetTester tester) async {
        bool called = false;

        await _openDialog(
          tester,
          _buildTestWidget(
            onResult: (CollectionChoice? r) => called = true,
            collections: <Collection>[_collectionA],
            showUncategorized: true,
            alreadyInCollectionIds: <int?>{null},
          ),
        );

        // Бейдж "✓ Added" должен отображаться
        expect(find.text('✓ Added'), findsOneWidget);

        // Нажатие не должно закрыть диалог
        await tester.tap(find.text('Without Collection'));
        await tester.pumpAndSettle();

        expect(called, isFalse);
      });

      testWidgets(
          'Uncategorized активен когда null НЕ в alreadyInCollectionIds',
          (WidgetTester tester) async {
        CollectionChoice? result;

        await _openDialog(
          tester,
          _buildTestWidget(
            onResult: (CollectionChoice? r) => result = r,
            collections: <Collection>[_collectionA],
            showUncategorized: true,
            alreadyInCollectionIds: <int?>{1},
          ),
        );

        await tester.tap(find.text('Without Collection'));
        await tester.pumpAndSettle();

        expect(result, isA<WithoutCollection>());
      });

      testWidgets(
          'disabled коллекции отображаются ниже активных',
          (WidgetTester tester) async {
        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[_collectionA, _collectionB],
            showUncategorized: false,
            alreadyInCollectionIds: <int?>{1},
          ),
        );

        // Collection B (available) should be before Collection A (disabled)
        final Offset posB = tester.getCenter(find.text('Collection B'));
        final Offset posA = tester.getCenter(find.text('Collection A'));
        expect(posB.dy, lessThan(posA.dy));
      });

      testWidgets(
          'footer показывает счётчик при наличии дублей',
          (WidgetTester tester) async {
        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[_collectionA, _collectionB],
            showUncategorized: false,
            alreadyInCollectionIds: <int?>{1, 2},
          ),
        );

        expect(find.textContaining('2'), findsWidgets);
      });

      testWidgets(
          'footer не показывает счётчик без дублей',
          (WidgetTester tester) async {
        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[_collectionA],
            showUncategorized: false,
          ),
        );

        // Only Cancel button in footer, no counter text
        expect(find.text('Cancel'), findsOneWidget);
      });
    });

    // ==================== Filter ====================

    group('фильтр', () {
      testWidgets(
          'поле фильтра показывается при >= 5 коллекций',
          (WidgetTester tester) async {
        await _openDialog(
          tester,
          _buildTestWidget(
            collections: _generateCollections(5),
            showUncategorized: false,
          ),
        );

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets(
          'поле фильтра скрыто при < 5 коллекций',
          (WidgetTester tester) async {
        await _openDialog(
          tester,
          _buildTestWidget(
            collections: _generateCollections(4),
            showUncategorized: false,
          ),
        );

        expect(find.byIcon(Icons.search), findsNothing);
      });

      testWidgets(
          'фильтр скрывает несоответствующие коллекции',
          (WidgetTester tester) async {
        final List<Collection> collections = <Collection>[
          Collection(
            id: 1,
            name: 'SNES Classics',
            author: 'User',
            type: CollectionType.own,
            createdAt: _testDate,
          ),
          Collection(
            id: 2,
            name: 'PS1 Games',
            author: 'User',
            type: CollectionType.own,
            createdAt: _testDate,
          ),
          Collection(
            id: 3,
            name: 'Movies 2025',
            author: 'User',
            type: CollectionType.own,
            createdAt: _testDate,
          ),
          Collection(
            id: 4,
            name: 'Anime',
            author: 'User',
            type: CollectionType.own,
            createdAt: _testDate,
          ),
          Collection(
            id: 5,
            name: 'Visual Novels',
            author: 'User',
            type: CollectionType.own,
            createdAt: _testDate,
          ),
        ];

        await _openDialog(
          tester,
          _buildTestWidget(
            collections: collections,
            showUncategorized: false,
          ),
        );

        // Enter filter text
        await tester.enterText(find.byType(TextField), 'game');
        await tester.pumpAndSettle();

        // Only PS1 Games matches
        expect(find.text('PS1 Games'), findsOneWidget);
        expect(find.text('SNES Classics'), findsNothing);
        expect(find.text('Movies 2025'), findsNothing);
      });
    });
  });
}
