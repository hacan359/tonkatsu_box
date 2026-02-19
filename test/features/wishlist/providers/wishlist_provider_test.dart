import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/data/repositories/wishlist_repository.dart';
import 'package:xerabora/features/wishlist/providers/wishlist_provider.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}

void main() {
  late MockWishlistRepository mockRepo;

  setUp(() {
    mockRepo = MockWishlistRepository();
  });

  setUpAll(() {
    registerFallbackValue(MediaType.game);
  });

  ProviderContainer createContainer({
    List<Override> extraOverrides = const <Override>[],
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        wishlistRepositoryProvider.overrideWithValue(mockRepo),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pump([int times = 5]) async {
    for (int i = 0; i < times; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  final WishlistItem item1 = WishlistItem(
    id: 1,
    text: 'Chrono Trigger',
    mediaTypeHint: MediaType.game,
    createdAt: DateTime(2024, 6, 15),
  );

  final WishlistItem item2 = WishlistItem(
    id: 2,
    text: 'The Matrix',
    mediaTypeHint: MediaType.movie,
    createdAt: DateTime(2024, 6, 16),
  );

  final WishlistItem resolvedItem = WishlistItem(
    id: 3,
    text: 'Resolved Game',
    isResolved: true,
    createdAt: DateTime(2024, 6, 10),
    resolvedAt: DateTime(2024, 6, 20),
  );

  group('WishlistNotifier', () {
    group('build', () {
      test('должен загружать элементы из репозитория', () async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, item2]);

        final ProviderContainer container = createContainer();
        container.read(wishlistProvider);
        await pump();

        final AsyncValue<List<WishlistItem>> state =
            container.read(wishlistProvider);
        expect(state.valueOrNull, <WishlistItem>[item1, item2]);
      });

      test('должен возвращать пустой список если БД пуста', () async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[]);

        final ProviderContainer container = createContainer();
        container.read(wishlistProvider);
        await pump();

        final List<WishlistItem>? items =
            container.read(wishlistProvider).valueOrNull;
        expect(items, isEmpty);
      });
    });

    group('add', () {
      test('должен добавлять элемент и обновлять state', () async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[]);
        when(
          () => mockRepo.add(
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async => item1);

        final ProviderContainer container = createContainer();
        container.read(wishlistProvider);
        await pump();

        final WishlistItem result = await container
            .read(wishlistProvider.notifier)
            .add(text: 'Chrono Trigger', mediaTypeHint: MediaType.game);

        expect(result, item1);
        final List<WishlistItem>? items =
            container.read(wishlistProvider).valueOrNull;
        expect(items, contains(item1));
      });
    });

    group('resolve', () {
      test('должен пометить элемент resolved и пересортировать', () async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, item2]);
        when(() => mockRepo.resolve(any())).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.read(wishlistProvider);
        await pump();

        await container.read(wishlistProvider.notifier).resolve(1);

        final List<WishlistItem>? items =
            container.read(wishlistProvider).valueOrNull;
        expect(items, isNotNull);
        // item1 resolved → в конце списка
        final WishlistItem resolved =
            items!.firstWhere((WishlistItem i) => i.id == 1);
        expect(resolved.isResolved, true);
        expect(resolved.resolvedAt, isNotNull);
        // resolved должен быть после unresolvedexpect(items.last.id, 1);
      });
    });

    group('unresolve', () {
      test('должен снять отметку resolved', () async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, resolvedItem]);
        when(() => mockRepo.unresolve(any())).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.read(wishlistProvider);
        await pump();

        await container.read(wishlistProvider.notifier).unresolve(3);

        final List<WishlistItem>? items =
            container.read(wishlistProvider).valueOrNull;
        final WishlistItem unresolved =
            items!.firstWhere((WishlistItem i) => i.id == 3);
        expect(unresolved.isResolved, false);
        expect(unresolved.resolvedAt, null);
      });
    });

    group('update', () {
      test('должен обновлять текст элемента', () async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1]);
        when(
          () => mockRepo.update(
            any(),
            text: any(named: 'text'),
            mediaTypeHint: any(named: 'mediaTypeHint'),
            clearMediaTypeHint: any(named: 'clearMediaTypeHint'),
            note: any(named: 'note'),
            clearNote: any(named: 'clearNote'),
          ),
        ).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.read(wishlistProvider);
        await pump();

        await container
            .read(wishlistProvider.notifier)
            .updateItem(1, text: 'New Title');

        final List<WishlistItem>? items =
            container.read(wishlistProvider).valueOrNull;
        expect(items!.first.text, 'New Title');
      });
    });

    group('delete', () {
      test('должен удалять элемент из state', () async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => <WishlistItem>[item1, item2]);
        when(() => mockRepo.delete(any())).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        container.read(wishlistProvider);
        await pump();

        await container.read(wishlistProvider.notifier).delete(1);

        final List<WishlistItem>? items =
            container.read(wishlistProvider).valueOrNull;
        expect(items!.length, 1);
        expect(items.first.id, 2);
      });
    });

    group('clearResolved', () {
      test('должен удалить все resolved и вернуть count', () async {
        when(() => mockRepo.getAll()).thenAnswer(
          (_) async => <WishlistItem>[item1, item2, resolvedItem],
        );
        when(() => mockRepo.clearResolved()).thenAnswer((_) async => 1);

        final ProviderContainer container = createContainer();
        container.read(wishlistProvider);
        await pump();

        final int count =
            await container.read(wishlistProvider.notifier).clearResolved();

        expect(count, 1);
        final List<WishlistItem>? items =
            container.read(wishlistProvider).valueOrNull;
        expect(items!.length, 2);
        expect(
          items.any((WishlistItem i) => i.isResolved),
          false,
        );
      });
    });
  });

  group('activeWishlistCountProvider', () {
    test('должен считать только активные элементы', () async {
      when(() => mockRepo.getAll()).thenAnswer(
        (_) async => <WishlistItem>[item1, item2, resolvedItem],
      );

      final ProviderContainer container = createContainer();
      container.read(wishlistProvider);
      await pump();

      final int count = container.read(activeWishlistCountProvider);
      expect(count, 2);
    });

    test('должен возвращать 0 при пустом списке', () async {
      when(() => mockRepo.getAll())
          .thenAnswer((_) async => <WishlistItem>[]);

      final ProviderContainer container = createContainer();
      container.read(wishlistProvider);
      await pump();

      final int count = container.read(activeWishlistCountProvider);
      expect(count, 0);
    });

    test('должен возвращать 0 пока данные загружаются', () {
      when(() => mockRepo.getAll()).thenAnswer(
        (_) async => <WishlistItem>[item1],
      );

      final ProviderContainer container = createContainer();
      // Не ждём pump — данные ещё загружаются
      final int count = container.read(activeWishlistCountProvider);
      expect(count, 0);
    });
  });
}
