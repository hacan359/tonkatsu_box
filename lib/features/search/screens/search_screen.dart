import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/widgets/cached_image.dart' as app_cached;
import '../../collections/providers/collections_provider.dart';
import '../providers/game_search_provider.dart';
import '../providers/media_search_provider.dart';
import '../widgets/game_card.dart';
import '../widgets/movie_card.dart';
import '../widgets/platform_filter_sheet.dart';
import '../widgets/tv_show_card.dart';

/// Экран поиска игр, фильмов и сериалов.
///
/// Позволяет искать контент через IGDB (игры) и TMDB (фильмы, сериалы)
/// с возможностью добавления в коллекцию.
class SearchScreen extends ConsumerStatefulWidget {
  /// Создаёт [SearchScreen].
  const SearchScreen({
    this.onGameSelected,
    this.collectionId,
    this.initialTabIndex,
    super.key,
  });

  /// Callback при выборе игры (устаревший режим).
  final void Function(Game game)? onGameSelected;

  /// ID коллекции для добавления элементов.
  ///
  /// Если задан, при выборе элемента он добавляется в коллекцию
  /// и пользователь остаётся на экране поиска.
  final int? collectionId;

  /// Начальный индекс таба (0=Games, 1=Movies, 2=TV Shows).
  final int? initialTabIndex;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late TabController _tabController;

  List<Platform> _platforms = <Platform>[];
  Map<int, Platform> _platformMap = <int, Platform>{};
  bool _platformsLoading = true;

  /// Индекс активного таба.
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex ?? 0;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _activeTabIndex,
    );
    _tabController.addListener(_onTabChanged);
    _loadPlatforms();
    _searchController.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final int newIndex = _tabController.index;
      if (_activeTabIndex == newIndex) return;
      setState(() {
        _activeTabIndex = newIndex;
      });

      // Синхронизируем таб в mediaSearchProvider
      if (newIndex == 1) {
        ref
            .read(mediaSearchProvider.notifier)
            .switchTab(MediaSearchTab.movies);
      } else if (newIndex == 2) {
        ref
            .read(mediaSearchProvider.notifier)
            .switchTab(MediaSearchTab.tvShows);
      }

      // Если есть запрос и переходим на Games — повторяем поиск игр
      if (newIndex == 0 && _searchController.text.length >= 2) {
        final GameSearchState gameState = ref.read(gameSearchProvider);
        if (gameState.query != _searchController.text) {
          ref
              .read(gameSearchProvider.notifier)
              .searchImmediate(_searchController.text);
        }
      }
    }
  }

  Future<void> _loadPlatforms() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<Platform> platforms = await db.getAllPlatforms();
    if (mounted) {
      setState(() {
        _platforms = platforms;
        _platformMap = <int, Platform>{
          for (final Platform p in platforms) p.id: p,
        };
        _platformsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onControllerChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_activeTabIndex == 0) {
      ref.read(gameSearchProvider.notifier).search(query);
    } else {
      ref.read(mediaSearchProvider.notifier).search(query);
    }
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(gameSearchProvider.notifier).clear();
    ref.read(mediaSearchProvider.notifier).clear();
    _searchFocus.requestFocus();
  }

  void _showPlatformFilterSheet() {
    final GameSearchState state = ref.read(gameSearchProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => PlatformFilterSheet(
        platforms: _platforms,
        selectedIds: state.selectedPlatformIds,
        onApply: (List<int> selectedIds) {
          ref.read(gameSearchProvider.notifier).setPlatformFilters(selectedIds);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _removePlatformFilter(int platformId) {
    ref.read(gameSearchProvider.notifier).removePlatformFilter(platformId);
  }

  // ==================== Game actions ====================

  void _onGameTap(Game game) {
    if (widget.onGameSelected != null) {
      widget.onGameSelected!(game);
    } else if (widget.collectionId != null) {
      _addGameToCollection(game);
    } else {
      _showGameDetails(game);
    }
  }

  Future<void> _addGameToCollection(Game game) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String gameName = game.name;

    final int? platformId = await _showPlatformSelectionDialog(game);
    if (platformId == null || !mounted) return;

    final bool success = await ref
        .read(collectionGamesNotifierProvider(widget.collectionId!).notifier)
        .addGame(
          igdbId: game.id,
          platformId: platformId,
        );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(content: Text('$gameName added to collection')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Game already in collection')),
        );
      }
    }
  }

  Future<void> _addGameToAnyCollection(Game game) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String gameName = game.name;

    final Collection? selectedCollection =
        await _showCollectionSelectionDialog();
    if (selectedCollection == null || !mounted) return;

    final int? platformId = await _showPlatformSelectionDialog(game);
    if (platformId == null || !mounted) return;

    final bool success = await ref
        .read(collectionGamesNotifierProvider(selectedCollection.id).notifier)
        .addGame(
          igdbId: game.id,
          platformId: platformId,
        );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$gameName added to ${selectedCollection.name}'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$gameName already in ${selectedCollection.name}'),
          ),
        );
      }
    }
  }

  // ==================== Movie actions ====================

  void _onMovieTap(Movie movie) {
    if (widget.collectionId != null) {
      _addMovieToCollection(movie);
    } else {
      _showMovieDetails(movie);
    }
  }

  Future<void> _addMovieToCollection(Movie movie) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String title = movie.title;

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId!).notifier)
        .addItem(
          mediaType: MediaType.movie,
          externalId: movie.tmdbId,
        );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(content: Text('$title added to collection')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Movie already in collection')),
        );
      }
    }
  }

  Future<void> _addMovieToAnyCollection(Movie movie) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String title = movie.title;

    final Collection? selectedCollection =
        await _showCollectionSelectionDialog();
    if (selectedCollection == null || !mounted) return;

    final bool success = await ref
        .read(collectionItemsNotifierProvider(selectedCollection.id).notifier)
        .addItem(
          mediaType: MediaType.movie,
          externalId: movie.tmdbId,
        );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$title added to ${selectedCollection.name}'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$title already in ${selectedCollection.name}'),
          ),
        );
      }
    }
  }

  // ==================== TV Show actions ====================

  void _onTvShowTap(TvShow tvShow) {
    if (widget.collectionId != null) {
      _addTvShowToCollection(tvShow);
    } else {
      _showTvShowDetails(tvShow);
    }
  }

  Future<void> _addTvShowToCollection(TvShow tvShow) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String title = tvShow.title;

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId!).notifier)
        .addItem(
          mediaType: MediaType.tvShow,
          externalId: tvShow.tmdbId,
        );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(content: Text('$title added to collection')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('TV show already in collection')),
        );
      }
    }
  }

  Future<void> _addTvShowToAnyCollection(TvShow tvShow) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String title = tvShow.title;

    final Collection? selectedCollection =
        await _showCollectionSelectionDialog();
    if (selectedCollection == null || !mounted) return;

    final bool success = await ref
        .read(collectionItemsNotifierProvider(selectedCollection.id).notifier)
        .addItem(
          mediaType: MediaType.tvShow,
          externalId: tvShow.tmdbId,
        );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$title added to ${selectedCollection.name}'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$title already in ${selectedCollection.name}'),
          ),
        );
      }
    }
  }

  // ==================== Shared dialogs ====================

  Future<Collection?> _showCollectionSelectionDialog() async {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.read(collectionsProvider);

    final List<Collection>? collections = collectionsAsync.valueOrNull;
    if (collections == null || collections.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No collections available. Create one first.'),
          ),
        );
      }
      return null;
    }

    final List<Collection> editableCollections =
        collections.where((Collection c) => c.isEditable).toList();

    if (editableCollections.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No editable collections. Create your own first.'),
          ),
        );
      }
      return null;
    }

    return showDialog<Collection>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Add to Collection'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: editableCollections.length,
            itemBuilder: (BuildContext context, int index) {
              final Collection collection = editableCollections[index];
              return ListTile(
                leading: Icon(
                  collection.type == CollectionType.own
                      ? Icons.folder
                      : Icons.fork_right,
                ),
                title: Text(collection.name),
                subtitle: Text(collection.author),
                onTap: () => Navigator.of(context).pop(collection),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<int?> _showPlatformSelectionDialog(Game game) async {
    final List<int>? platformIds = game.platformIds;

    if (platformIds == null || platformIds.isEmpty) {
      return -1;
    }

    if (platformIds.length == 1) {
      return platformIds.first;
    }

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Select Platform'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: platformIds.map((int id) {
              final Platform? platform = _platformMap[id];
              final String platformName =
                  platform?.displayName ?? 'Platform $id';
              return ListTile(
                leading: _buildPlatformLogo(platform),
                title: Text(platformName),
                onTap: () => Navigator.of(context).pop(id),
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformLogo(Platform? platform) {
    if (platform?.logoUrl != null && platform?.logoImageId != null) {
      return app_cached.CachedImage(
        imageType: ImageType.platformLogo,
        imageId: platform!.logoImageId!,
        remoteUrl: platform.logoUrl!,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        placeholder: const Icon(Icons.videogame_asset, size: 24),
        errorWidget: const Icon(Icons.videogame_asset, size: 24),
      );
    }
    return const Icon(Icons.videogame_asset, size: 24);
  }

  // ==================== Detail sheets ====================

  void _showGameDetails(Game game) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _GameDetailsSheet(
        game: game,
        onAddToCollection: () => _addGameToAnyCollection(game),
      ),
    );
  }

  void _showMovieDetails(Movie movie) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _MediaDetailsSheet(
        title: movie.title,
        overview: movie.overview,
        year: movie.releaseYear,
        rating: movie.formattedRating,
        genres: movie.genres,
        icon: Icons.movie,
        extraInfo: movie.runtime != null ? '${movie.runtime} min' : null,
        onAddToCollection: () => _addMovieToAnyCollection(movie),
      ),
    );
  }

  void _showTvShowDetails(TvShow tvShow) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _MediaDetailsSheet(
        title: tvShow.title,
        overview: tvShow.overview,
        year: tvShow.firstAirYear,
        rating: tvShow.formattedRating,
        genres: tvShow.genres,
        icon: Icons.tv,
        extraInfo: tvShow.status,
        onAddToCollection: () => _addTvShowToAnyCollection(tvShow),
      ),
    );
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.videogame_asset), text: 'Games'),
            Tab(icon: Icon(Icons.movie), text: 'Movies'),
            Tab(icon: Icon(Icons.tv), text: 'TV Shows'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: _searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _onClearSearch,
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (String query) {
                    if (_activeTabIndex == 0) {
                      ref
                          .read(gameSearchProvider.notifier)
                          .searchImmediate(query);
                    } else {
                      ref
                          .read(mediaSearchProvider.notifier)
                          .searchImmediate(query);
                    }
                  },
                ),
              ],
            ),
          ),

          // Контент табов
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildGamesTab(),
                _buildMoviesTab(),
                _buildTvShowsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _searchHint {
    switch (_activeTabIndex) {
      case 0:
        return 'Search for games...';
      case 1:
        return 'Search for movies...';
      case 2:
        return 'Search for TV shows...';
      default:
        return 'Search...';
    }
  }

  // ==================== Games tab ====================

  Widget _buildGamesTab() {
    final GameSearchState searchState = ref.watch(gameSearchProvider);

    return Column(
      children: <Widget>[
        // Фильтр по платформе (только для игр)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildPlatformFilter(searchState),
        ),

        Expanded(
          child: _buildGameResults(searchState),
        ),
      ],
    );
  }

  Widget _buildPlatformFilter(GameSearchState searchState) {
    if (_platformsLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_platforms.isEmpty) {
      return const SizedBox.shrink();
    }

    final int selectedCount = searchState.selectedPlatformIds.length;
    final String buttonLabel = selectedCount == 0
        ? 'All Platforms'
        : '$selectedCount platform${selectedCount > 1 ? 's' : ''} selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showPlatformFilterSheet,
            icon: const Icon(Icons.filter_list),
            label: Text(buttonLabel),
          ),
        ),
        if (searchState.selectedPlatformIds.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          _buildSelectedPlatformChips(searchState.selectedPlatformIds),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSelectedPlatformChips(List<int> selectedIds) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: selectedIds.map((int id) {
        final Platform? platform = _platformMap[id];
        return Chip(
          label: Text(platform?.displayName ?? 'Unknown'),
          onDeleted: () => _removePlatformFilter(id),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  List<String> _getPlatformNames(List<int>? platformIds) {
    if (platformIds == null || platformIds.isEmpty) {
      return <String>[];
    }
    return platformIds
        .map((int id) => _platformMap[id]?.displayName)
        .whereType<String>()
        .toList();
  }

  Widget _buildGameResults(GameSearchState searchState) {
    if (searchState.error != null) {
      return _buildErrorState(searchState.error!, onRetry: () {
        ref
            .read(gameSearchProvider.notifier)
            .searchImmediate(_searchController.text);
      });
    }

    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.isEmpty) {
      return _buildEmptyState('Search for games', Icons.videogame_asset);
    }

    if (!searchState.hasResults && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchState.results.length,
      itemBuilder: (BuildContext context, int index) {
        final Game game = searchState.results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GameCard(
            game: game,
            onTap: () => _onGameTap(game),
            platformNames: _getPlatformNames(game.platformIds),
            trailing: widget.collectionId == null
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add to collection',
                    onPressed: () => _addGameToAnyCollection(game),
                  )
                : null,
          ),
        );
      },
    );
  }

  // ==================== Movies tab ====================

  Widget _buildMoviesTab() {
    final MediaSearchState searchState = ref.watch(mediaSearchProvider);

    if (searchState.error != null && searchState.activeTab == MediaSearchTab.movies) {
      return _buildErrorState(searchState.error!, onRetry: () {
        ref
            .read(mediaSearchProvider.notifier)
            .searchImmediate(_searchController.text);
      });
    }

    if (searchState.isLoading && searchState.activeTab == MediaSearchTab.movies) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.query.isEmpty && searchState.movieResults.isEmpty) {
      return _buildEmptyState('Search for movies', Icons.movie);
    }

    if (searchState.movieResults.isEmpty && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchState.movieResults.length,
      itemBuilder: (BuildContext context, int index) {
        final Movie movie = searchState.movieResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MovieCard(
            movie: movie,
            onTap: () => _onMovieTap(movie),
            trailing: widget.collectionId == null
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add to collection',
                    onPressed: () => _addMovieToAnyCollection(movie),
                  )
                : null,
          ),
        );
      },
    );
  }

  // ==================== TV Shows tab ====================

  Widget _buildTvShowsTab() {
    final MediaSearchState searchState = ref.watch(mediaSearchProvider);

    if (searchState.error != null && searchState.activeTab == MediaSearchTab.tvShows) {
      return _buildErrorState(searchState.error!, onRetry: () {
        ref
            .read(mediaSearchProvider.notifier)
            .searchImmediate(_searchController.text);
      });
    }

    if (searchState.isLoading && searchState.activeTab == MediaSearchTab.tvShows) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.query.isEmpty && searchState.tvShowResults.isEmpty) {
      return _buildEmptyState('Search for TV shows', Icons.tv);
    }

    if (searchState.tvShowResults.isEmpty && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchState.tvShowResults.length,
      itemBuilder: (BuildContext context, int index) {
        final TvShow tvShow = searchState.tvShowResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TvShowCard(
            tvShow: tvShow,
            onTap: () => _onTvShowTap(tvShow),
            trailing: widget.collectionId == null
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add to collection',
                    onPressed: () => _addTvShowToAnyCollection(tvShow),
                  )
                : null,
          ),
        );
      },
    );
  }

  // ==================== Shared UI states ====================

  Widget _buildEmptyState(String message, IconData icon) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type at least 2 characters to start searching',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing found for "$query"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, {required VoidCallback onRetry}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Search failed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet с деталями игры.
class _GameDetailsSheet extends StatelessWidget {
  const _GameDetailsSheet({
    required this.game,
    required this.onAddToCollection,
  });

  final Game game;
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                game.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: <Widget>[
                  if (game.releaseYear != null)
                    _buildChip(
                      Icons.calendar_today,
                      game.releaseYear.toString(),
                      colorScheme,
                    ),
                  if (game.formattedRating != null)
                    _buildChip(
                      Icons.star,
                      '${game.formattedRating} (${game.ratingCount ?? 0})',
                      colorScheme,
                    ),
                ],
              ),

              if (game.genres != null && game.genres!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: game.genres!
                      .map((String genre) => Chip(label: Text(genre)))
                      .toList(),
                ),
              ],

              if (game.summary != null) ...<Widget>[
                const SizedBox(height: 24),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.summary!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAddToCollection();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Collection'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

/// Bottom sheet с деталями фильма или сериала.
class _MediaDetailsSheet extends StatelessWidget {
  const _MediaDetailsSheet({
    required this.title,
    required this.icon,
    required this.onAddToCollection,
    this.overview,
    this.year,
    this.rating,
    this.genres,
    this.extraInfo,
  });

  final String title;
  final String? overview;
  final int? year;
  final String? rating;
  final List<String>? genres;
  final IconData icon;
  final String? extraInfo;
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: <Widget>[
                  if (year != null)
                    _buildChip(
                      Icons.calendar_today,
                      year.toString(),
                      colorScheme,
                    ),
                  if (rating != null)
                    _buildChip(Icons.star, rating!, colorScheme),
                  if (extraInfo != null)
                    _buildChip(icon, extraInfo!, colorScheme),
                ],
              ),

              if (genres != null && genres!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres!
                      .map((String genre) => Chip(label: Text(genre)))
                      .toList(),
                ),
              ],

              if (overview != null) ...<Widget>[
                const SizedBox(height: 24),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  overview!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAddToCollection();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Collection'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
