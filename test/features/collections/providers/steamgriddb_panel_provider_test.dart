import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/steamgriddb_api.dart';
import 'package:xerabora/features/collections/providers/steamgriddb_panel_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/steamgriddb_game.dart';
import 'package:xerabora/shared/models/steamgriddb_image.dart';

// Моки
class MockSteamGridDbApi extends Mock implements SteamGridDbApi {}

const int testCollectionId = 10;

const SteamGridDbGame testGame = SteamGridDbGame(
  id: 123,
  name: 'Chrono Trigger',
  verified: true,
);

const SteamGridDbGame testGame2 = SteamGridDbGame(
  id: 456,
  name: 'Super Metroid',
);

const SteamGridDbImage testImage1 = SteamGridDbImage(
  id: 1,
  score: 10,
  style: 'alternate',
  url: 'https://example.com/grid1.png',
  thumb: 'https://example.com/grid1_thumb.png',
  width: 600,
  height: 900,
);

const SteamGridDbImage testImage2 = SteamGridDbImage(
  id: 2,
  score: 5,
  style: 'blurred',
  url: 'https://example.com/grid2.png',
  thumb: 'https://example.com/grid2_thumb.png',
  width: 460,
  height: 215,
);

const SettingsState settingsWithKey = SettingsState(
  steamGridDbApiKey: 'test-api-key',
);

const SettingsState settingsWithoutKey = SettingsState();

void main() {
  late MockSteamGridDbApi mockApi;

  setUp(() {
    mockApi = MockSteamGridDbApi();
  });

  ProviderContainer createContainer({
    SettingsState settings = settingsWithKey,
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        steamGridDbApiProvider.overrideWithValue(mockApi),
        settingsNotifierProvider.overrideWith(
          () => _FakeSettingsNotifier(settings),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SteamGridDbPanelState', () {
    test('should create with default values', () {
      const SteamGridDbPanelState state = SteamGridDbPanelState();

      expect(state.isOpen, false);
      expect(state.searchTerm, '');
      expect(state.searchResults, isEmpty);
      expect(state.selectedGame, isNull);
      expect(state.selectedImageType, SteamGridDbImageType.grids);
      expect(state.images, isEmpty);
      expect(state.isSearching, false);
      expect(state.isLoadingImages, false);
      expect(state.searchError, isNull);
      expect(state.imageError, isNull);
      expect(state.imageCache, isEmpty);
    });

    group('copyWith', () {
      test('should copy with changed isOpen', () {
        const SteamGridDbPanelState original = SteamGridDbPanelState();
        final SteamGridDbPanelState copy = original.copyWith(isOpen: true);

        expect(copy.isOpen, true);
        expect(copy.searchTerm, original.searchTerm);
      });

      test('should copy with changed selectedGame', () {
        const SteamGridDbPanelState original = SteamGridDbPanelState();
        final SteamGridDbPanelState copy =
            original.copyWith(selectedGame: testGame);

        expect(copy.selectedGame, testGame);
      });

      test('should clear selectedGame', () {
        final SteamGridDbPanelState withGame =
            const SteamGridDbPanelState().copyWith(selectedGame: testGame);
        final SteamGridDbPanelState cleared =
            withGame.copyWith(clearSelectedGame: true);

        expect(cleared.selectedGame, isNull);
      });

      test('should clear searchError', () {
        final SteamGridDbPanelState withError =
            const SteamGridDbPanelState().copyWith(searchError: 'Error');
        final SteamGridDbPanelState cleared =
            withError.copyWith(clearSearchError: true);

        expect(cleared.searchError, isNull);
      });

      test('should clear imageError', () {
        final SteamGridDbPanelState withError =
            const SteamGridDbPanelState().copyWith(imageError: 'Error');
        final SteamGridDbPanelState cleared =
            withError.copyWith(clearImageError: true);

        expect(cleared.imageError, isNull);
      });

      test('should preserve all values when no changes specified', () {
        final SteamGridDbPanelState original = const SteamGridDbPanelState(
          isOpen: true,
          searchTerm: 'test',
          searchResults: <SteamGridDbGame>[testGame],
          selectedImageType: SteamGridDbImageType.heroes,
          images: <SteamGridDbImage>[testImage1],
          isSearching: true,
          isLoadingImages: true,
          searchError: 'err',
          imageError: 'img err',
        ).copyWith(selectedGame: testGame);
        final SteamGridDbPanelState copy = original.copyWith();

        expect(copy.isOpen, original.isOpen);
        expect(copy.searchTerm, original.searchTerm);
        expect(copy.searchResults, original.searchResults);
        expect(copy.selectedGame, original.selectedGame);
        expect(copy.selectedImageType, original.selectedImageType);
        expect(copy.images, original.images);
        expect(copy.isSearching, original.isSearching);
        expect(copy.isLoadingImages, original.isLoadingImages);
        expect(copy.searchError, original.searchError);
        expect(copy.imageError, original.imageError);
        expect(copy.imageCache, original.imageCache);
      });

      test('should copy with all fields', () {
        const SteamGridDbPanelState original = SteamGridDbPanelState();
        final SteamGridDbPanelState copy = original.copyWith(
          isOpen: true,
          searchTerm: 'test',
          searchResults: const <SteamGridDbGame>[testGame],
          selectedGame: testGame,
          selectedImageType: SteamGridDbImageType.heroes,
          images: const <SteamGridDbImage>[testImage1],
          isSearching: true,
          isLoadingImages: true,
          searchError: 'search error',
          imageError: 'image error',
          imageCache: const <String, List<SteamGridDbImage>>{
            '123:grids': <SteamGridDbImage>[testImage1],
          },
        );

        expect(copy.isOpen, true);
        expect(copy.searchTerm, 'test');
        expect(copy.searchResults, hasLength(1));
        expect(copy.selectedGame, testGame);
        expect(copy.selectedImageType, SteamGridDbImageType.heroes);
        expect(copy.images, hasLength(1));
        expect(copy.isSearching, true);
        expect(copy.isLoadingImages, true);
        expect(copy.searchError, 'search error');
        expect(copy.imageError, 'image error');
        expect(copy.imageCache, hasLength(1));
      });
    });
  });

  group('SteamGridDbImageType', () {
    test('should have correct labels', () {
      expect(SteamGridDbImageType.grids.label, 'Grids');
      expect(SteamGridDbImageType.heroes.label, 'Heroes');
      expect(SteamGridDbImageType.logos.label, 'Logos');
      expect(SteamGridDbImageType.icons.label, 'Icons');
    });

    test('should have 4 values', () {
      expect(SteamGridDbImageType.values, hasLength(4));
    });
  });

  group('SteamGridDbPanelNotifier', () {
    group('initial state', () {
      test('should return default state', () {
        final ProviderContainer container = createContainer();
        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));

        expect(state.isOpen, false);
        expect(state.searchResults, isEmpty);
        expect(state.selectedGame, isNull);
      });
    });

    group('togglePanel', () {
      test('should open panel when closed', () {
        final ProviderContainer container = createContainer();
        container
            .read(steamGridDbPanelProvider(testCollectionId).notifier)
            .togglePanel();

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.isOpen, true);
      });

      test('should close panel when open', () {
        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        notifier.togglePanel(); // open
        notifier.togglePanel(); // close

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.isOpen, false);
      });
    });

    group('openPanel', () {
      test('should set isOpen to true', () {
        final ProviderContainer container = createContainer();
        container
            .read(steamGridDbPanelProvider(testCollectionId).notifier)
            .openPanel();

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.isOpen, true);
      });
    });

    group('closePanel', () {
      test('should set isOpen to false', () {
        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        notifier.openPanel();
        notifier.closePanel();

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.isOpen, false);
      });
    });

    group('searchGames', () {
      test('should search and return results', () async {
        when(() => mockApi.searchGames('Chrono')).thenAnswer(
          (_) async => const <SteamGridDbGame>[testGame],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.searchGames('Chrono');

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.searchResults, hasLength(1));
        expect(state.searchResults.first.name, 'Chrono Trigger');
        expect(state.isSearching, false);
        expect(state.searchError, isNull);
        expect(state.searchTerm, 'Chrono');
      });

      test('should trim search term', () async {
        when(() => mockApi.searchGames('Chrono')).thenAnswer(
          (_) async => const <SteamGridDbGame>[testGame],
        );

        final ProviderContainer container = createContainer();
        await container
            .read(steamGridDbPanelProvider(testCollectionId).notifier)
            .searchGames('  Chrono  ');

        verify(() => mockApi.searchGames('Chrono')).called(1);
      });

      test('should ignore empty search term', () async {
        final ProviderContainer container = createContainer();
        await container
            .read(steamGridDbPanelProvider(testCollectionId).notifier)
            .searchGames('   ');

        verifyNever(() => mockApi.searchGames(any()));
      });

      test('should clear selected game on new search', () async {
        when(() => mockApi.searchGames(any())).thenAnswer(
          (_) async => const <SteamGridDbGame>[testGame],
        );
        when(() => mockApi.getGrids(any())).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage1],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        // Сначала выбираем игру
        await notifier.searchGames('Chrono');
        await notifier.selectGame(testGame);

        // Новый поиск должен сбросить выбор
        await notifier.searchGames('Metroid');

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.selectedGame, isNull);
        expect(state.images, isEmpty);
      });

      test('should set searchError on API exception', () async {
        when(() => mockApi.searchGames('test')).thenThrow(
          const SteamGridDbApiException('Rate limit exceeded'),
        );

        final ProviderContainer container = createContainer();
        await container
            .read(steamGridDbPanelProvider(testCollectionId).notifier)
            .searchGames('test');

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.searchError, 'Rate limit exceeded');
        expect(state.isSearching, false);
      });

      test('should set error when API key not set', () async {
        final ProviderContainer container =
            createContainer(settings: settingsWithoutKey);
        await container
            .read(steamGridDbPanelProvider(testCollectionId).notifier)
            .searchGames('test');

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.searchError, 'SteamGridDB API key not set');
        verifyNever(() => mockApi.searchGames(any()));
      });
    });

    group('selectGame', () {
      test('should set selected game and load grids', () async {
        when(() => mockApi.getGrids(123)).thenAnswer(
          (_) async =>
              const <SteamGridDbImage>[testImage1, testImage2],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.selectGame(testGame);

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.selectedGame, testGame);
        expect(state.selectedImageType, SteamGridDbImageType.grids);
        expect(state.images, hasLength(2));
        expect(state.isLoadingImages, false);
      });

      test('should cache loaded images', () async {
        when(() => mockApi.getGrids(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage1],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.selectGame(testGame);

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.imageCache.containsKey('123:grids'), true);
        expect(state.imageCache['123:grids'], hasLength(1));
      });

      test('should set imageError on API exception', () async {
        when(() => mockApi.getGrids(123)).thenThrow(
          const SteamGridDbApiException('Game not found'),
        );

        final ProviderContainer container = createContainer();
        await container
            .read(steamGridDbPanelProvider(testCollectionId).notifier)
            .selectGame(testGame);

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.imageError, 'Game not found');
        expect(state.isLoadingImages, false);
      });
    });

    group('clearGameSelection', () {
      test('should clear selected game and images', () async {
        when(() => mockApi.getGrids(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage1],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.selectGame(testGame);
        notifier.clearGameSelection();

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.selectedGame, isNull);
        expect(state.images, isEmpty);
        expect(state.imageError, isNull);
      });
    });

    group('selectImageType', () {
      test('should change image type and load images', () async {
        when(() => mockApi.getGrids(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage1],
        );
        when(() => mockApi.getHeroes(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage2],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.selectGame(testGame);
        await notifier.selectImageType(SteamGridDbImageType.heroes);

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.selectedImageType, SteamGridDbImageType.heroes);
        expect(state.images, hasLength(1));
        expect(state.images.first.id, 2);
      });

      test('should use cache on second call with same type', () async {
        when(() => mockApi.getGrids(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage1],
        );
        when(() => mockApi.getHeroes(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage2],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.selectGame(testGame); // Loads grids
        await notifier.selectImageType(SteamGridDbImageType.heroes); // Loads heroes
        await notifier.selectImageType(SteamGridDbImageType.grids); // Should use cache

        // getGrids вызван только 1 раз (при selectGame), а не 2
        verify(() => mockApi.getGrids(123)).called(1);
      });

      test('should load logos', () async {
        when(() => mockApi.getGrids(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[],
        );
        when(() => mockApi.getLogos(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage1],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.selectGame(testGame);
        await notifier.selectImageType(SteamGridDbImageType.logos);

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.images, hasLength(1));
        verify(() => mockApi.getLogos(123)).called(1);
      });

      test('should load icons', () async {
        when(() => mockApi.getGrids(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[],
        );
        when(() => mockApi.getIcons(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage2],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.selectGame(testGame);
        await notifier.selectImageType(SteamGridDbImageType.icons);

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.images, hasLength(1));
        verify(() => mockApi.getIcons(123)).called(1);
      });
    });

    group('_loadImages edge cases', () {
      test('should do nothing when no game selected', () async {
        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        // selectImageType без selectGame — _loadImages должен вернуть early
        // Нет выбранной игры, вызываем selectImageType напрямую
        await notifier.selectImageType(SteamGridDbImageType.heroes);

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.images, isEmpty);
        expect(state.isLoadingImages, false);
        verifyNever(() => mockApi.getHeroes(any()));
      });
    });

    group('image cache', () {
      test('should cache results for different game/type combinations',
          () async {
        when(() => mockApi.getGrids(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage1],
        );
        when(() => mockApi.getHeroes(123)).thenAnswer(
          (_) async => const <SteamGridDbImage>[testImage2],
        );

        final ProviderContainer container = createContainer();
        final SteamGridDbPanelNotifier notifier =
            container.read(steamGridDbPanelProvider(testCollectionId).notifier);

        await notifier.selectGame(testGame);
        await notifier.selectImageType(SteamGridDbImageType.heroes);

        final SteamGridDbPanelState state =
            container.read(steamGridDbPanelProvider(testCollectionId));
        expect(state.imageCache, hasLength(2));
        expect(state.imageCache.containsKey('123:grids'), true);
        expect(state.imageCache.containsKey('123:heroes'), true);
      });
    });
  });
}

/// Фейковый SettingsNotifier для тестов.
class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this._initialState);

  final SettingsState _initialState;

  @override
  SettingsState build() {
    return _initialState;
  }
}
