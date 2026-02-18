import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/steamgriddb_api.dart';
import '../../../shared/models/steamgriddb_game.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../settings/providers/settings_provider.dart';

/// Тип изображений SteamGridDB для фильтрации в панели.
enum SteamGridDbImageType {
  /// Обложки (box art).
  grids('Grids'),

  /// Баннеры.
  heroes('Heroes'),

  /// Логотипы.
  logos('Logos'),

  /// Иконки.
  icons('Icons');

  const SteamGridDbImageType(this.label);

  /// Отображаемое название.
  final String label;
}

/// Состояние боковой панели SteamGridDB.
class SteamGridDbPanelState {
  /// Создаёт экземпляр [SteamGridDbPanelState].
  const SteamGridDbPanelState({
    this.isOpen = false,
    this.searchTerm = '',
    this.searchResults = const <SteamGridDbGame>[],
    this.selectedGame,
    this.selectedImageType = SteamGridDbImageType.grids,
    this.images = const <SteamGridDbImage>[],
    this.isSearching = false,
    this.isLoadingImages = false,
    this.searchError,
    this.imageError,
    this.imageCache = const <String, List<SteamGridDbImage>>{},
  });

  /// Открыта ли панель.
  final bool isOpen;

  /// Текущий поисковый запрос.
  final String searchTerm;

  /// Результаты поиска игр.
  final List<SteamGridDbGame> searchResults;

  /// Выбранная игра (null = показываем результаты поиска).
  final SteamGridDbGame? selectedGame;

  /// Выбранный тип изображений.
  final SteamGridDbImageType selectedImageType;

  /// Текущие изображения для отображения.
  final List<SteamGridDbImage> images;

  /// Идёт поиск игр.
  final bool isSearching;

  /// Идёт загрузка изображений.
  final bool isLoadingImages;

  /// Ошибка при поиске.
  final String? searchError;

  /// Ошибка при загрузке изображений.
  final String? imageError;

  /// Кэш изображений по ключу "$gameId:$imageType".
  final Map<String, List<SteamGridDbImage>> imageCache;

  /// Создаёт копию с изменёнными полями.
  SteamGridDbPanelState copyWith({
    bool? isOpen,
    String? searchTerm,
    List<SteamGridDbGame>? searchResults,
    SteamGridDbGame? selectedGame,
    bool clearSelectedGame = false,
    SteamGridDbImageType? selectedImageType,
    List<SteamGridDbImage>? images,
    bool? isSearching,
    bool? isLoadingImages,
    String? searchError,
    bool clearSearchError = false,
    String? imageError,
    bool clearImageError = false,
    Map<String, List<SteamGridDbImage>>? imageCache,
  }) {
    return SteamGridDbPanelState(
      isOpen: isOpen ?? this.isOpen,
      searchTerm: searchTerm ?? this.searchTerm,
      searchResults: searchResults ?? this.searchResults,
      selectedGame: clearSelectedGame
          ? null
          : (selectedGame ?? this.selectedGame),
      selectedImageType: selectedImageType ?? this.selectedImageType,
      images: images ?? this.images,
      isSearching: isSearching ?? this.isSearching,
      isLoadingImages: isLoadingImages ?? this.isLoadingImages,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      imageError: clearImageError ? null : (imageError ?? this.imageError),
      imageCache: imageCache ?? this.imageCache,
    );
  }
}

/// Провайдер для управления боковой панелью SteamGridDB.
final NotifierProviderFamily<SteamGridDbPanelNotifier, SteamGridDbPanelState,
        int?> steamGridDbPanelProvider =
    NotifierProvider.family<SteamGridDbPanelNotifier, SteamGridDbPanelState,
        int?>(
  SteamGridDbPanelNotifier.new,
);

/// Notifier для управления состоянием боковой панели SteamGridDB.
class SteamGridDbPanelNotifier
    extends FamilyNotifier<SteamGridDbPanelState, int?> {
  late SteamGridDbApi _api;

  @override
  SteamGridDbPanelState build(int? arg) {
    _api = ref.watch(steamGridDbApiProvider);
    return const SteamGridDbPanelState();
  }

  /// Переключает видимость панели.
  void togglePanel() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  /// Открывает панель.
  void openPanel() {
    state = state.copyWith(isOpen: true);
  }

  /// Закрывает панель.
  void closePanel() {
    state = state.copyWith(isOpen: false);
  }

  /// Ищет игры по названию.
  Future<void> searchGames(String term) async {
    final String trimmedTerm = term.trim();
    if (trimmedTerm.isEmpty) return;

    final SettingsState settings = ref.read(settingsNotifierProvider);
    if (!settings.hasSteamGridDbKey) {
      state = state.copyWith(
        searchError: 'SteamGridDB API key not set',
        clearSearchError: false,
      );
      return;
    }

    state = state.copyWith(
      isSearching: true,
      clearSearchError: true,
      searchTerm: trimmedTerm,
      clearSelectedGame: true,
      images: const <SteamGridDbImage>[],
    );

    try {
      final List<SteamGridDbGame> results = await _api.searchGames(trimmedTerm);
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } on SteamGridDbApiException catch (e) {
      state = state.copyWith(
        searchError: e.message,
        isSearching: false,
      );
    }
  }

  /// Выбирает игру и загружает изображения по умолчанию (grids).
  Future<void> selectGame(SteamGridDbGame game) async {
    state = state.copyWith(
      selectedGame: game,
      selectedImageType: SteamGridDbImageType.grids,
      images: const <SteamGridDbImage>[],
      clearImageError: true,
    );
    await _loadImages();
  }

  /// Очищает выбор игры, возвращаясь к результатам поиска.
  void clearGameSelection() {
    state = state.copyWith(
      clearSelectedGame: true,
      images: const <SteamGridDbImage>[],
      clearImageError: true,
    );
  }

  /// Выбирает тип изображений и загружает их.
  Future<void> selectImageType(SteamGridDbImageType type) async {
    state = state.copyWith(
      selectedImageType: type,
      images: const <SteamGridDbImage>[],
      clearImageError: true,
    );
    await _loadImages();
  }

  /// Возвращает ключ кэша для пары (gameId, imageType).
  String _cacheKey(int gameId, SteamGridDbImageType type) {
    return '$gameId:${type.name}';
  }

  /// Загружает изображения для выбранной игры и типа.
  Future<void> _loadImages() async {
    final SteamGridDbGame? game = state.selectedGame;
    if (game == null) return;

    final String key = _cacheKey(game.id, state.selectedImageType);

    // Проверяем кэш
    final List<SteamGridDbImage>? cached = state.imageCache[key];
    if (cached != null) {
      state = state.copyWith(images: cached);
      return;
    }

    state = state.copyWith(isLoadingImages: true, clearImageError: true);

    try {
      final List<SteamGridDbImage> results;
      switch (state.selectedImageType) {
        case SteamGridDbImageType.grids:
          results = await _api.getGrids(game.id);
        case SteamGridDbImageType.heroes:
          results = await _api.getHeroes(game.id);
        case SteamGridDbImageType.logos:
          results = await _api.getLogos(game.id);
        case SteamGridDbImageType.icons:
          results = await _api.getIcons(game.id);
      }

      // Сохраняем в кэш
      final Map<String, List<SteamGridDbImage>> updatedCache =
          Map<String, List<SteamGridDbImage>>.of(state.imageCache);
      updatedCache[key] = results;

      state = state.copyWith(
        images: results,
        isLoadingImages: false,
        imageCache: updatedCache,
      );
    } on SteamGridDbApiException catch (e) {
      state = state.copyWith(
        imageError: e.message,
        isLoadingImages: false,
      );
    }
  }
}
