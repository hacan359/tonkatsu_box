import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/data/repositories/wishlist_repository.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockWishlistDao mockWishlistDao;
  late WishlistRepository repository;

  setUp(() {
    mockWishlistDao = MockWishlistDao();
    repository = WishlistRepository(wishlistDao: mockWishlistDao);
  });

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  final WishlistItem testItem = WishlistItem(
    id: 1,
    text: 'Chrono Trigger',
    mediaTypeHint: MediaType.game,
    note: 'SNES',
    createdAt: DateTime(2024, 6, 15),
  );

  group('WishlistRepository', () {
    group('add', () {
      test('должен делегировать в DatabaseService.addWishlistItem', () async {
        when(
          () => mockWishlistDao.addWishlistItem(
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async => testItem);

        final WishlistItem result = await repository.add(
          text: 'Chrono Trigger',
          mediaTypeHint: MediaType.game,
          note: 'SNES',
        );

        expect(result, testItem);
        verify(
          () => mockWishlistDao.addWishlistItem(
            text: 'Chrono Trigger',
            mediaTypeHint: MediaType.game,
            note: 'SNES',
          ),
        ).called(1);
      });

      test('должен передавать null для опциональных полей', () async {
        when(
          () => mockWishlistDao.addWishlistItem(
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async => testItem);

        await repository.add(text: 'Test');

        verify(
          () => mockWishlistDao.addWishlistItem(
            text: 'Test',
            mediaTypeHint: null,
            note: null,
          ),
        ).called(1);
      });
    });

    group('addWishlistItemsBatch', () {
      test('делегирует в WishlistDao.addWishlistItemsBatch', () async {
        when(() => mockWishlistDao.addWishlistItemsBatch(any()))
            .thenAnswer((_) async => 2);

        final int count = await repository.addWishlistItemsBatch(
          <Map<String, dynamic>>[
            <String, dynamic>{'text': 'A'},
            <String, dynamic>{'text': 'B'},
          ],
        );

        expect(count, 2);
        verify(() => mockWishlistDao.addWishlistItemsBatch(any())).called(1);
      });
    });

    group('getAll', () {
      test('должен делегировать с includeResolved=true по умолчанию',
          () async {
        when(
          () => mockWishlistDao.getWishlistItemsFiltered(includeResolved: true),
        ).thenAnswer((_) async => <WishlistItem>[testItem]);

        final List<WishlistItem> result = await repository.getAll();

        expect(result, <WishlistItem>[testItem]);
        verify(() => mockWishlistDao.getWishlistItemsFiltered(includeResolved: true)).called(1);
      });

      test('должен передавать includeResolved=false', () async {
        when(
          () => mockWishlistDao.getWishlistItemsFiltered(includeResolved: false),
        ).thenAnswer((_) async => <WishlistItem>[]);

        await repository.getAll(includeResolved: false);

        verify(() => mockWishlistDao.getWishlistItemsFiltered(includeResolved: false)).called(1);
      });
    });

    group('getCount', () {
      test('должен делегировать с onlyActive=true по умолчанию', () async {
        when(
          () => mockWishlistDao.getWishlistItemCount(onlyActive: true),
        ).thenAnswer((_) async => 5);

        final int count = await repository.getCount();

        expect(count, 5);
        verify(() => mockWishlistDao.getWishlistItemCount(onlyActive: true)).called(1);
      });

      test('должен передавать onlyActive=false', () async {
        when(
          () => mockWishlistDao.getWishlistItemCount(onlyActive: false),
        ).thenAnswer((_) async => 10);

        final int count = await repository.getCount(onlyActive: false);

        expect(count, 10);
      });
    });

    group('update', () {
      test('должен делегировать обновление текста', () async {
        when(
          () => mockWishlistDao.updateWishlistItem(
            any(),
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            clearMediaTypeHint: any(named: 'clearMediaTypeHint'),
            note: any(named: 'note'),
            clearNote: any(named: 'clearNote'),
          ),
        ).thenAnswer((_) async {});

        await repository.update(1, text: 'New Title');

        verify(
          () => mockWishlistDao.updateWishlistItem(
            1,
            text: 'New Title',
            mediaTypeHint: null,
            clearMediaTypeHint: false,
            note: null,
            clearNote: false,
          ),
        ).called(1);
      });

      test('должен передавать clearMediaTypeHint', () async {
        when(
          () => mockWishlistDao.updateWishlistItem(
            any(),
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            clearMediaTypeHint: any(named: 'clearMediaTypeHint'),
            note: any(named: 'note'),
            clearNote: any(named: 'clearNote'),
          ),
        ).thenAnswer((_) async {});

        await repository.update(1, clearMediaTypeHint: true);

        verify(
          () => mockWishlistDao.updateWishlistItem(
            1,
            text: null,
            mediaTypeHint: null,
            clearMediaTypeHint: true,
            note: null,
            clearNote: false,
          ),
        ).called(1);
      });
    });

    group('resolve', () {
      test('должен делегировать в resolveWishlistItem', () async {
        when(() => mockWishlistDao.resolveWishlistItem(any()))
            .thenAnswer((_) async {});

        await repository.resolve(1);

        verify(() => mockWishlistDao.resolveWishlistItem(1)).called(1);
      });
    });

    group('unresolve', () {
      test('должен делегировать в unresolveWishlistItem', () async {
        when(() => mockWishlistDao.unresolveWishlistItem(any()))
            .thenAnswer((_) async {});

        await repository.unresolve(1);

        verify(() => mockWishlistDao.unresolveWishlistItem(1)).called(1);
      });
    });

    group('delete', () {
      test('должен делегировать в deleteWishlistItem', () async {
        when(() => mockWishlistDao.deleteWishlistItem(any()))
            .thenAnswer((_) async {});

        await repository.delete(1);

        verify(() => mockWishlistDao.deleteWishlistItem(1)).called(1);
      });
    });

    group('clearResolved', () {
      test('должен делегировать и вернуть количество удалённых', () async {
        when(() => mockWishlistDao.clearResolvedWishlistItems())
            .thenAnswer((_) async => 3);

        final int count = await repository.clearResolved();

        expect(count, 3);
        verify(() => mockWishlistDao.clearResolvedWishlistItems()).called(1);
      });
    });
  });
}
