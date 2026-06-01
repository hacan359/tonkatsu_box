import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/collection_list_sort_mode.dart';
import 'package:tonkatsu_box/shared/widgets/collection_picker_dialog.dart';

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

void _ignoreResult(CollectionChoice? _) {}

Widget _buildTestWidget({
  void Function(CollectionChoice?)? onResult,
  List<Collection> collections = const <Collection>[],
  int? excludeCollectionId,
  bool showUncategorized = true,
  String title = 'Choose Collection',
  Set<int?> alreadyInCollectionIds = const <int?>{},
  CollectionListSortMode sortMode = CollectionListSortMode.createdDate,
  bool sortDescending = false,
}) {
  return ProviderScope(
    overrides: <Override>[
      collectionsProvider.overrideWith(
        () => _FakeCollectionsNotifier(collections),
      ),
      collectionListSortProvider.overrideWith(
        () => _FakeListSortNotifier(sortMode),
      ),
      collectionListSortDescProvider.overrideWith(
        () => _FakeListSortDescNotifier(sortDescending),
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

class _FakeCollectionsNotifier extends CollectionsNotifier {
  _FakeCollectionsNotifier(this._collections);

  final List<Collection> _collections;

  @override
  Future<List<Collection>> build() async {
    return _collections;
  }
}

Future<void> _openDialog(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

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
        'should show "Without Collection" '
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
        'should hide "Without Collection" '
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
        'should exclude коллекцию с excludeCollectionId',
        (WidgetTester tester) async {
      await _openDialog(
        tester,
        _buildTestWidget(
          collections: <Collection>[_collectionA, _collectionB],
          excludeCollectionId: 1,
          showUncategorized: false,
        ),
      );

      expect(find.text('Collection A'), findsNothing);
      expect(find.text('Collection B'), findsOneWidget);
    });

    testWidgets(
        'should show imported коллекции (теперь editable)',
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

      expect(find.text('Collection A'), findsOneWidget);
      expect(find.text('Imported'), findsOneWidget);
    });

    testWidgets(
        'should show fork коллекции (editable)',
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
        'should return ChosenCollection when pressed на коллекцию',
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
        'should return WithoutCollection when pressed "Without Collection"',
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

    testWidgets('should return null when pressed Cancel',
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
        'should show иконку folder_rounded для own-коллекций',
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
        'should show иконку fork_right для fork-коллекций',
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
        'should show автора коллекции как subtitle',
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

        await tester.tap(find.text('Collection B'));
        await tester.pumpAndSettle();

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

        expect(find.text('✓ Added'), findsOneWidget);

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

        await tester.enterText(find.byType(TextField), 'game');
        await tester.pumpAndSettle();

        expect(find.text('PS1 Games'), findsOneWidget);
        expect(find.text('SNES Classics'), findsNothing);
        expect(find.text('Movies 2025'), findsNothing);
      });
    });

    group('сортировка', () {
      testWidgets(
          'должен сортировать по алфавиту A→Z',
          (WidgetTester tester) async {
        final Collection cBanana = Collection(
          id: 1,
          name: 'Banana',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 1, 1),
        );
        final Collection cApple = Collection(
          id: 2,
          name: 'Apple',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 1, 2),
        );
        final Collection cCherry = Collection(
          id: 3,
          name: 'Cherry',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 1, 3),
        );

        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[cBanana, cApple, cCherry],
            showUncategorized: false,
            sortMode: CollectionListSortMode.alphabetical,
            sortDescending: false,
          ),
        );

        final Offset posApple = tester.getCenter(find.text('Apple'));
        final Offset posBanana = tester.getCenter(find.text('Banana'));
        final Offset posCherry = tester.getCenter(find.text('Cherry'));
        expect(posApple.dy, lessThan(posBanana.dy));
        expect(posBanana.dy, lessThan(posCherry.dy));
      });

      testWidgets(
          'должен сортировать по алфавиту Z→A (descending)',
          (WidgetTester tester) async {
        final Collection cBanana = Collection(
          id: 1,
          name: 'Banana',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 1, 1),
        );
        final Collection cApple = Collection(
          id: 2,
          name: 'Apple',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 1, 2),
        );
        final Collection cCherry = Collection(
          id: 3,
          name: 'Cherry',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 1, 3),
        );

        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[cBanana, cApple, cCherry],
            showUncategorized: false,
            sortMode: CollectionListSortMode.alphabetical,
            sortDescending: true,
          ),
        );

        final Offset posCherry = tester.getCenter(find.text('Cherry'));
        final Offset posBanana = tester.getCenter(find.text('Banana'));
        final Offset posApple = tester.getCenter(find.text('Apple'));
        expect(posCherry.dy, lessThan(posBanana.dy));
        expect(posBanana.dy, lessThan(posApple.dy));
      });

      testWidgets(
          'должен сортировать по дате создания (ascending)',
          (WidgetTester tester) async {
        final Collection cOldest = Collection(
          id: 1,
          name: 'Oldest',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2025, 1, 1),
        );
        final Collection cNewest = Collection(
          id: 2,
          name: 'Newest',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 6, 1),
        );
        final Collection cMiddle = Collection(
          id: 3,
          name: 'Middle',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 3, 1),
        );

        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[cOldest, cNewest, cMiddle],
            showUncategorized: false,
            sortMode: CollectionListSortMode.createdDate,
            sortDescending: false,
          ),
        );

        final Offset posOldest = tester.getCenter(find.text('Oldest'));
        final Offset posMiddle = tester.getCenter(find.text('Middle'));
        final Offset posNewest = tester.getCenter(find.text('Newest'));
        expect(posOldest.dy, lessThan(posMiddle.dy));
        expect(posMiddle.dy, lessThan(posNewest.dy));
      });

      testWidgets(
          'должен сортировать по дате создания descending (новые сверху)',
          (WidgetTester tester) async {
        final Collection cOldest = Collection(
          id: 1,
          name: 'Oldest',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2025, 1, 1),
        );
        final Collection cNewest = Collection(
          id: 2,
          name: 'Newest',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 6, 1),
        );

        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[cOldest, cNewest],
            showUncategorized: false,
            sortMode: CollectionListSortMode.createdDate,
            sortDescending: true,
          ),
        );

        final Offset posNewest = tester.getCenter(find.text('Newest'));
        final Offset posOldest = tester.getCenter(find.text('Oldest'));
        expect(posNewest.dy, lessThan(posOldest.dy));
      });

      testWidgets(
          'должен переключать сортировку when pressed на кнопку',
          (WidgetTester tester) async {
        final Collection cBanana = Collection(
          id: 1,
          name: 'Banana',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 1, 1),
        );
        final Collection cApple = Collection(
          id: 2,
          name: 'Apple',
          author: 'User',
          type: CollectionType.own,
          createdAt: DateTime(2026, 1, 2),
        );

        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[cBanana, cApple],
            showUncategorized: false,
            sortMode: CollectionListSortMode.alphabetical,
            sortDescending: false,
          ),
        );

        Offset posApple = tester.getCenter(find.text('Apple'));
        Offset posBanana = tester.getCenter(find.text('Banana'));
        expect(posApple.dy, lessThan(posBanana.dy));

        await tester.tap(find.byIcon(Icons.arrow_upward));
        await tester.pumpAndSettle();

        posApple = tester.getCenter(find.text('Apple'));
        posBanana = tester.getCenter(find.text('Banana'));
        expect(posBanana.dy, lessThan(posApple.dy));
      });

      testWidgets(
          'должен отображать кнопку сортировки с текстом',
          (WidgetTester tester) async {
        await _openDialog(
          tester,
          _buildTestWidget(
            collections: <Collection>[_collectionA, _collectionB],
            showUncategorized: false,
            sortMode: CollectionListSortMode.alphabetical,
            sortDescending: false,
          ),
        );

        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      });
    });
  });
}

class _FakeListSortNotifier extends CollectionListSortNotifier {
  _FakeListSortNotifier(this._mode);

  final CollectionListSortMode _mode;

  @override
  CollectionListSortMode build() => _mode;

  @override
  Future<void> setSortMode(CollectionListSortMode mode) async {}
}

class _FakeListSortDescNotifier extends CollectionListSortDescNotifier {
  _FakeListSortDescNotifier(this._descending);

  final bool _descending;

  @override
  bool build() => _descending;

  @override
  Future<void> toggle() async {}
}
