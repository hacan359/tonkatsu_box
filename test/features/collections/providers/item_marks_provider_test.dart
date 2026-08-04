import 'package:core/models/item_mark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/providers/item_marks_provider.dart';

import '../../../helpers/test_helpers.dart';

ItemMark _mark({
  int itemId = 1,
  String unitType = kUnitEpisode,
  int parent = 1,
  int unit = 3,
  bool fav = true,
  String? note,
}) {
  return ItemMark(
    id: 1,
    itemId: itemId,
    unitType: unitType,
    parentNumber: parent,
    unitNumber: unit,
    isFavorite: fav,
    userComment: note,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

void main() {
  late MockDatabaseService mockDb;
  late MockItemMarkDao mockDao;

  setUp(() {
    mockDb = MockDatabaseService();
    mockDao = MockItemMarkDao();
    when(() => mockDb.itemMarkDao).thenReturn(mockDao);
  });

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ItemMarksNotifier', () {
    test('build loads marks into a keyed map with counters', () async {
      when(() => mockDao.getMarksForItem(1)).thenAnswer((_) async =>
          <ItemMark>[
            _mark(unit: 3, fav: true, note: 'a'),
            _mark(unit: 4, fav: false, note: 'b'),
          ]);

      final ProviderContainer container = makeContainer();
      container.read(itemMarksProvider(1));
      await pumpEventQueue();

      final ItemMarksState state = container.read(itemMarksProvider(1));
      expect(state.isLiked(kUnitEpisode, 1, 3), isTrue);
      expect(state.isLiked(kUnitEpisode, 1, 4), isFalse);
      expect(state.likedCountOfType(kUnitEpisode), 1);
      expect(state.commentedCountOfType(kUnitEpisode), 2);
    });

    test('toggleFavorite writes the negated value and applies the merged mark',
        () async {
      when(() => mockDao.getMarksForItem(1))
          .thenAnswer((_) async => <ItemMark>[]);
      when(() => mockDao.setFavorite(any(), any(), any(), any(),
              isFavorite: any(named: 'isFavorite')))
          .thenAnswer((_) async => _mark(fav: true));

      final ProviderContainer container = makeContainer();
      container.read(itemMarksProvider(1));
      await pumpEventQueue();

      await container
          .read(itemMarksProvider(1).notifier)
          .toggleFavorite(kUnitEpisode, 1, 3);

      verify(() => mockDao.setFavorite(1, kUnitEpisode, 1, 3,
          isFavorite: true)).called(1);
      expect(
        container.read(itemMarksProvider(1)).isLiked(kUnitEpisode, 1, 3),
        isTrue,
      );
    });

    test('setComment delegates to the dao', () async {
      when(() => mockDao.getMarksForItem(1))
          .thenAnswer((_) async => <ItemMark>[]);
      when(() => mockDao.setComment(any(), any(), any(), any(), any()))
          .thenAnswer((_) async => _mark(note: 'hi'));

      final ProviderContainer container = makeContainer();
      container.read(itemMarksProvider(1));
      await pumpEventQueue();

      await container
          .read(itemMarksProvider(1).notifier)
          .setComment(kUnitEpisode, 1, 3, 'hi');

      verify(() => mockDao.setComment(1, kUnitEpisode, 1, 3, 'hi')).called(1);
    });

    test('a null DAO result removes the mark from state', () async {
      when(() => mockDao.getMarksForItem(1)).thenAnswer(
          (_) async => <ItemMark>[_mark(fav: false, note: 'old')]);
      when(() => mockDao.setComment(any(), any(), any(), any(), any()))
          .thenAnswer((_) async => null);

      final ProviderContainer container = makeContainer();
      container.read(itemMarksProvider(1));
      await pumpEventQueue();
      expect(
        container.read(itemMarksProvider(1)).noteFor(kUnitEpisode, 1, 3),
        'old',
      );

      await container
          .read(itemMarksProvider(1).notifier)
          .setComment(kUnitEpisode, 1, 3, '');

      expect(
        container.read(itemMarksProvider(1)).noteFor(kUnitEpisode, 1, 3),
        isNull,
      );
    });

    test('deleteMark delegates to the dao', () async {
      when(() => mockDao.getMarksForItem(1))
          .thenAnswer((_) async => <ItemMark>[]);
      when(() => mockDao.deleteMark(any(), any(), any(), any()))
          .thenAnswer((_) async {});

      final ProviderContainer container = makeContainer();
      container.read(itemMarksProvider(1));
      await pumpEventQueue();

      await container
          .read(itemMarksProvider(1).notifier)
          .deleteMark(kUnitSeason, 2, 0);

      verify(() => mockDao.deleteMark(1, kUnitSeason, 2, 0)).called(1);
    });
  });
}
