import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/wishlist_repository.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;
  late WishlistRepository repository;

  setUp(() {
    mockDb = MockDatabaseService();
    repository = WishlistRepository(db: mockDb);
  });

  setUpAll(() {
    registerFallbackValue(MediaType.game);
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
          () => mockDb.addWishlistItem(
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
          () => mockDb.addWishlistItem(
            text: 'Chrono Trigger',
            mediaTypeHint: MediaType.game,
            note: 'SNES',
          ),
        ).called(1);
      });

      test('должен передавать null для опциональных полей', () async {
        when(
          () => mockDb.addWishlistItem(
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async => testItem);

        await repository.add(text: 'Test');

        verify(
          () => mockDb.addWishlistItem(
            text: 'Test',
            mediaTypeHint: null,
            note: null,
          ),
        ).called(1);
      });
    });

    group('getAll', () {
      test('должен делегировать с includeResolved=true по умолчанию',
          () async {
        when(
          () => mockDb.getWishlistItems(includeResolved: true),
        ).thenAnswer((_) async => <WishlistItem>[testItem]);

        final List<WishlistItem> result = await repository.getAll();

        expect(result, <WishlistItem>[testItem]);
        verify(() => mockDb.getWishlistItems(includeResolved: true)).called(1);
      });

      test('должен передавать includeResolved=false', () async {
        when(
          () => mockDb.getWishlistItems(includeResolved: false),
        ).thenAnswer((_) async => <WishlistItem>[]);

        await repository.getAll(includeResolved: false);

        verify(() => mockDb.getWishlistItems(includeResolved: false)).called(1);
      });
    });

    group('getCount', () {
      test('должен делегировать с onlyActive=true по умолчанию', () async {
        when(
          () => mockDb.getWishlistItemCount(onlyActive: true),
        ).thenAnswer((_) async => 5);

        final int count = await repository.getCount();

        expect(count, 5);
        verify(() => mockDb.getWishlistItemCount(onlyActive: true)).called(1);
      });

      test('должен передавать onlyActive=false', () async {
        when(
          () => mockDb.getWishlistItemCount(onlyActive: false),
        ).thenAnswer((_) async => 10);

        final int count = await repository.getCount(onlyActive: false);

        expect(count, 10);
      });
    });

    group('update', () {
      test('должен делегировать обновление текста', () async {
        when(
          () => mockDb.updateWishlistItem(
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
          () => mockDb.updateWishlistItem(
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
          () => mockDb.updateWishlistItem(
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
          () => mockDb.updateWishlistItem(
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
        when(() => mockDb.resolveWishlistItem(any()))
            .thenAnswer((_) async {});

        await repository.resolve(1);

        verify(() => mockDb.resolveWishlistItem(1)).called(1);
      });
    });

    group('unresolve', () {
      test('должен делегировать в unresolveWishlistItem', () async {
        when(() => mockDb.unresolveWishlistItem(any()))
            .thenAnswer((_) async {});

        await repository.unresolve(1);

        verify(() => mockDb.unresolveWishlistItem(1)).called(1);
      });
    });

    group('delete', () {
      test('должен делегировать в deleteWishlistItem', () async {
        when(() => mockDb.deleteWishlistItem(any()))
            .thenAnswer((_) async {});

        await repository.delete(1);

        verify(() => mockDb.deleteWishlistItem(1)).called(1);
      });
    });

    group('clearResolved', () {
      test('должен делегировать и вернуть количество удалённых', () async {
        when(() => mockDb.clearResolvedWishlistItems())
            .thenAnswer((_) async => 3);

        final int count = await repository.clearResolved();

        expect(count, 3);
        verify(() => mockDb.clearResolvedWishlistItems()).called(1);
      });
    });
  });
}
