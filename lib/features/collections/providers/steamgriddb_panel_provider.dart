import 'package:core/models/steamgriddb_game.dart';
import 'package:core/models/steamgriddb_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/steamgriddb_api.dart';
import '../../settings/providers/settings_provider.dart';

/// SteamGridDB image kind shown by the side panel.
enum SteamGridDbImageType {
  grids('Grids'),
  heroes('Heroes'),
  logos('Logos'),
  icons('Icons');

  const SteamGridDbImageType(this.label);

  /// Display label.
  final String label;
}

/// State for the SteamGridDB side panel.
class SteamGridDbPanelState {
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

  final bool isOpen;
  final String searchTerm;
  final List<SteamGridDbGame> searchResults;

  /// Currently selected game; `null` means the panel is showing search
  /// results, not a specific game's image grid.
  final SteamGridDbGame? selectedGame;

  final SteamGridDbImageType selectedImageType;
  final List<SteamGridDbImage> images;
  final bool isSearching;
  final bool isLoadingImages;
  final String? searchError;
  final String? imageError;

  /// Per-`(gameId, imageType)` cache survives close/open so reopening the
  /// panel for a recently-viewed game does not re-hit the API.
  final Map<String, List<SteamGridDbImage>> imageCache;

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

final NotifierProviderFamily<SteamGridDbPanelNotifier, SteamGridDbPanelState,
        int?> steamGridDbPanelProvider =
    NotifierProvider.family<SteamGridDbPanelNotifier, SteamGridDbPanelState,
        int?>(
  SteamGridDbPanelNotifier.new,
);

class SteamGridDbPanelNotifier
    extends FamilyNotifier<SteamGridDbPanelState, int?> {
  late SteamGridDbApi _api;

  @override
  SteamGridDbPanelState build(int? arg) {
    _api = ref.watch(steamGridDbApiProvider);
    return const SteamGridDbPanelState();
  }

  void togglePanel() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void openPanel() {
    state = state.copyWith(isOpen: true);
  }

  /// Resets the search input, results, and selection while keeping
  /// [imageCache]. Without this reset the previous query leaked across
  /// canvases that share the provider key (`collectionId`).
  void closePanel() {
    state = SteamGridDbPanelState(imageCache: state.imageCache);
  }

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

  /// Selects a game and fetches its grids by default.
  Future<void> selectGame(SteamGridDbGame game) async {
    state = state.copyWith(
      selectedGame: game,
      selectedImageType: SteamGridDbImageType.grids,
      images: const <SteamGridDbImage>[],
      clearImageError: true,
    );
    await _loadImages();
  }

  /// Returns from a selected game back to the search-results view.
  void clearGameSelection() {
    state = state.copyWith(
      clearSelectedGame: true,
      images: const <SteamGridDbImage>[],
      clearImageError: true,
    );
  }

  Future<void> selectImageType(SteamGridDbImageType type) async {
    state = state.copyWith(
      selectedImageType: type,
      images: const <SteamGridDbImage>[],
      clearImageError: true,
    );
    await _loadImages();
  }

  String _cacheKey(int gameId, SteamGridDbImageType type) {
    return '$gameId:${type.name}';
  }

  Future<void> _loadImages() async {
    final SteamGridDbGame? game = state.selectedGame;
    if (game == null) return;

    final String key = _cacheKey(game.id, state.selectedImageType);

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
