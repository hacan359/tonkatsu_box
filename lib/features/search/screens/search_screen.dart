import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/search_sort.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/widgets/cached_image.dart' as app_cached;
import '../../../shared/widgets/poster_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../collections/providers/collections_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/game_search_provider.dart';
import '../providers/genre_provider.dart';
import '../providers/media_search_provider.dart';
import '../widgets/media_filter_sheet.dart';
import '../widgets/platform_filter_sheet.dart';
import '../widgets/sort_selector.dart';

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

  /// Начальный индекс таба (0=Games, 1=Movies, 2=TV Shows, 3=Animation).
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
      length: 4,
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
      } else if (newIndex == 3) {
        ref
            .read(mediaSearchProvider.notifier)
            .switchTab(MediaSearchTab.animation);
      }

      // Если есть запрос и переходим на Games — повторяем поиск игр
      if (newIndex == 0 && _searchController.text.length >= 2) {
        final GameSearchState gameState = ref.read(gameSearchProvider);
        if (gameState.query != _searchController.text) {
          ref
              .read(gameSearchProvider.notifier)
              .search(_searchController.text);
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

  void _onSearchSubmit() {
    final String query = _searchController.text;
    if (query.length < 2) return;

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

  void _showMediaFilterSheet() {
    final MediaSearchState searchState = ref.read(mediaSearchProvider);
    final bool isMovies = searchState.activeTab == MediaSearchTab.movies;

    final AsyncValue<List<TmdbGenre>> genresAsync = isMovies
        ? ref.read(movieGenresProvider)
        : ref.read(tvGenresProvider);

    final List<TmdbGenre> genres = genresAsync.valueOrNull ?? <TmdbGenre>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => MediaFilterSheet(
        genres: genres,
        selectedYear: searchState.selectedYear,
        selectedGenreIds: searchState.selectedGenreIds,
        onApply: ({int? year, required List<int> genreIds}) {
          ref
              .read(mediaSearchProvider.notifier)
              .applyFilters(year: year, genreIds: genreIds);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildMediaFilterBar(MediaSearchState searchState) {
    final int filterCount = (searchState.selectedYear != null ? 1 : 0) +
        searchState.selectedGenreIds.length;
    final String buttonLabel = filterCount == 0
        ? 'Filters'
        : '$filterCount filter${filterCount > 1 ? 's' : ''} active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showMediaFilterSheet,
            icon: const Icon(Icons.filter_list),
            label: Text(buttonLabel),
          ),
        ),
        if (searchState.hasFilters) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildMediaFilterChips(searchState),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildMediaFilterChips(MediaSearchState searchState) {
    final bool isMovies = searchState.activeTab == MediaSearchTab.movies;
    final AsyncValue<List<TmdbGenre>> genresAsync = isMovies
        ? ref.watch(movieGenresProvider)
        : ref.watch(tvGenresProvider);
    final List<TmdbGenre> allGenres =
        genresAsync.valueOrNull ?? <TmdbGenre>[];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        if (searchState.selectedYear != null)
          Chip(
            label: Text('Year: ${searchState.selectedYear}'),
            onDeleted: () {
              ref.read(mediaSearchProvider.notifier).setYearFilter(null);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ...searchState.selectedGenreIds.map((int id) {
          final String name = allGenres
              .where((TmdbGenre g) => g.id == id)
              .map((TmdbGenre g) => g.name)
              .firstOrNull ?? 'Genre $id';
          return Chip(
            label: Text(name),
            onDeleted: () {
              final List<int> updated = List<int>.from(
                searchState.selectedGenreIds,
              )..remove(id);
              ref.read(mediaSearchProvider.notifier).setGenreFilter(updated);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        }),
      ],
    );
  }

  // ==================== Image caching ====================

  /// Кэширует обложку элемента в фоне сразу после добавления в коллекцию.
  void _cacheImage(ImageType type, String imageId, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final ImageCacheService cacheService = ref.read(imageCacheServiceProvider);
    // Fire-and-forget: не блокируем UI, ошибки игнорируем
    cacheService.downloadImage(
      type: type,
      imageId: imageId,
      remoteUrl: imageUrl,
    );
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
        .read(collectionItemsNotifierProvider(widget.collectionId!).notifier)
        .addItem(
          mediaType: MediaType.game,
          externalId: game.id,
          platformId: platformId,
        );

    if (mounted) {
      if (success) {
        _cacheImage(ImageType.gameCover, game.id.toString(), game.coverUrl);
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
        .read(collectionItemsNotifierProvider(selectedCollection.id).notifier)
        .addItem(
          mediaType: MediaType.game,
          externalId: game.id,
          platformId: platformId,
        );

    if (mounted) {
      if (success) {
        _cacheImage(ImageType.gameCover, game.id.toString(), game.coverUrl);
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
        _cacheImage(
          ImageType.moviePoster,
          movie.tmdbId.toString(),
          movie.posterUrl,
        );
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
        _cacheImage(
          ImageType.moviePoster,
          movie.tmdbId.toString(),
          movie.posterUrl,
        );
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
        _cacheImage(
          ImageType.tvShowPoster,
          tvShow.tmdbId.toString(),
          tvShow.posterUrl,
        );
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
        _cacheImage(
          ImageType.tvShowPoster,
          tvShow.tmdbId.toString(),
          tvShow.posterUrl,
        );
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
        posterUrl: movie.posterUrl,
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
        posterUrl: tvShow.posterUrl,
        onAddToCollection: () => _addTvShowToAnyCollection(tvShow),
      ),
    );
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final bool isApiReady = ref.watch(hasValidApiKeyProvider);

    if (!isApiReady) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          title: const Text('Search'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textTertiary.withAlpha(100),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Search unavailable',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Configure IGDB API keys in Settings to enable search.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.videogame_asset), text: 'Games'),
            Tab(icon: Icon(Icons.movie), text: 'Movies'),
            Tab(icon: Icon(Icons.tv), text: 'TV Shows'),
            Tab(icon: Icon(Icons.animation), text: 'Animation'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
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
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearchSubmit(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _searchController.text.length >= 2
                      ? _onSearchSubmit
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  ),
                  child: const Text('Search'),
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
                _buildAnimationTab(),
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
      case 3:
        return 'Search for animation...';
      default:
        return 'Search...';
    }
  }

  // ==================== Grid helpers ====================

  int get _gridCrossAxisCount {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth >= navigationBreakpoint) {
      return AppSpacing.gridColumnsDesktop;
    } else if (screenWidth >= 500) {
      return AppSpacing.gridColumnsTablet;
    }
    return AppSpacing.gridColumnsMobile;
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.55,
      ),
      itemCount: _gridCrossAxisCount * 2,
      itemBuilder: (BuildContext context, int index) {
        return const ShimmerPosterCard();
      },
    );
  }

  // ==================== Games tab ====================

  Widget _buildGamesTab() {
    final GameSearchState searchState = ref.watch(gameSearchProvider);

    return Column(
      children: <Widget>[
        // Фильтр по платформе (только для игр)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildPlatformFilter(searchState),
        ),

        // Сортировка (только когда есть результаты)
        if (searchState.hasResults)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SortSelector(
              currentSort: searchState.currentSort,
              onChanged: (SearchSort sort) {
                ref.read(gameSearchProvider.notifier).setSort(sort);
              },
            ),
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
          const SizedBox(height: AppSpacing.sm),
          _buildSelectedPlatformChips(searchState.selectedPlatformIds),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildSelectedPlatformChips(List<int> selectedIds) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
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

  Widget _buildGameResults(GameSearchState searchState) {
    if (searchState.error != null) {
      return _buildErrorState(searchState.error!, onRetry: () {
        ref
            .read(gameSearchProvider.notifier)
            .search(_searchController.text);
      });
    }

    if (searchState.isLoading) {
      return _buildShimmerGrid();
    }

    if (searchState.isEmpty) {
      return _buildEmptyState('Search for games', Icons.videogame_asset);
    }

    if (!searchState.hasResults && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    final Map<int, List<CollectedItemInfo>> collectedGameInfos =
        ref.watch(collectedGameIdsProvider).valueOrNull ??
            <int, List<CollectedItemInfo>>{};

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.55,
      ),
      itemCount: searchState.results.length,
      itemBuilder: (BuildContext context, int index) {
        final Game game = searchState.results[index];
        final List<CollectedItemInfo>? infos = collectedGameInfos[game.id];
        return PosterCard(
          key: ValueKey<int>(game.id),
          title: game.name,
          imageUrl: game.coverUrl ?? '',
          cacheImageType: ImageType.gameCover,
          cacheImageId: game.id.toString(),
          rating: game.rating != null ? game.rating! / 10 : null,
          year: game.releaseYear,
          subtitle: game.genres?.take(2).join(', '),
          isInCollection: infos != null && infos.isNotEmpty,
          onTap: () => _onGameTap(game),
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
            .search(_searchController.text);
      });
    }

    if (searchState.isLoading && searchState.activeTab == MediaSearchTab.movies) {
      return _buildShimmerGrid();
    }

    if (searchState.query.isEmpty && searchState.movieResults.isEmpty) {
      return _buildEmptyState('Search for movies', Icons.movie);
    }

    if (searchState.movieResults.isEmpty && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    final Map<int, List<CollectedItemInfo>> collectedMovieInfos =
        ref.watch(collectedMovieIdsProvider).valueOrNull ??
            <int, List<CollectedItemInfo>>{};

    return Column(
      children: <Widget>[
        // Фильтры медиа
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildMediaFilterBar(searchState),
        ),

        // Сортировка (только когда есть результаты)
        if (searchState.movieResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SortSelector(
              currentSort: searchState.currentSort,
              onChanged: (SearchSort sort) {
                ref.read(mediaSearchProvider.notifier).setSort(sort);
              },
            ),
          ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCrossAxisCount,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.55,
            ),
            itemCount: searchState.movieResults.length,
            itemBuilder: (BuildContext context, int index) {
              final Movie movie = searchState.movieResults[index];
              final List<CollectedItemInfo>? infos =
                  collectedMovieInfos[movie.tmdbId];
              return PosterCard(
                key: ValueKey<int>(movie.tmdbId),
                title: movie.title,
                imageUrl: movie.posterUrl ?? '',
                cacheImageType: ImageType.moviePoster,
                cacheImageId: movie.tmdbId.toString(),
                rating: movie.rating,
                year: movie.releaseYear,
                subtitle: movie.genres?.take(2).join(', '),
                isInCollection: infos != null && infos.isNotEmpty,
                onTap: () => _onMovieTap(movie),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== TV Shows tab ====================

  Widget _buildTvShowsTab() {
    final MediaSearchState searchState = ref.watch(mediaSearchProvider);

    if (searchState.error != null && searchState.activeTab == MediaSearchTab.tvShows) {
      return _buildErrorState(searchState.error!, onRetry: () {
        ref
            .read(mediaSearchProvider.notifier)
            .search(_searchController.text);
      });
    }

    if (searchState.isLoading && searchState.activeTab == MediaSearchTab.tvShows) {
      return _buildShimmerGrid();
    }

    if (searchState.query.isEmpty && searchState.tvShowResults.isEmpty) {
      return _buildEmptyState('Search for TV shows', Icons.tv);
    }

    if (searchState.tvShowResults.isEmpty && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    final Map<int, List<CollectedItemInfo>> collectedTvShowInfos =
        ref.watch(collectedTvShowIdsProvider).valueOrNull ??
            <int, List<CollectedItemInfo>>{};

    return Column(
      children: <Widget>[
        // Фильтры медиа
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildMediaFilterBar(searchState),
        ),

        // Сортировка (только когда есть результаты)
        if (searchState.tvShowResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SortSelector(
              currentSort: searchState.currentSort,
              onChanged: (SearchSort sort) {
                ref.read(mediaSearchProvider.notifier).setSort(sort);
              },
            ),
          ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCrossAxisCount,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.55,
            ),
            itemCount: searchState.tvShowResults.length,
            itemBuilder: (BuildContext context, int index) {
              final TvShow tvShow = searchState.tvShowResults[index];
              final List<CollectedItemInfo>? infos =
                  collectedTvShowInfos[tvShow.tmdbId];
              return PosterCard(
                key: ValueKey<int>(tvShow.tmdbId),
                title: tvShow.title,
                imageUrl: tvShow.posterUrl ?? '',
                cacheImageType: ImageType.tvShowPoster,
                cacheImageId: tvShow.tmdbId.toString(),
                rating: tvShow.rating,
                year: tvShow.firstAirYear,
                subtitle: tvShow.genres?.take(2).join(', '),
                isInCollection: infos != null && infos.isNotEmpty,
                onTap: () => _onTvShowTap(tvShow),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== Animation tab ====================

  Future<void> _addAnimationMovieToAnyCollection(Movie movie) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String title = movie.title;

    final Collection? selectedCollection =
        await _showCollectionSelectionDialog();
    if (selectedCollection == null || !mounted) return;

    final bool success = await ref
        .read(collectionItemsNotifierProvider(selectedCollection.id).notifier)
        .addItem(
          mediaType: MediaType.animation,
          externalId: movie.tmdbId,
          platformId: AnimationSource.movie,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.moviePoster,
          movie.tmdbId.toString(),
          movie.posterUrl,
        );
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

  Future<void> _addAnimationTvShowToAnyCollection(TvShow tvShow) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String title = tvShow.title;

    final Collection? selectedCollection =
        await _showCollectionSelectionDialog();
    if (selectedCollection == null || !mounted) return;

    final bool success = await ref
        .read(collectionItemsNotifierProvider(selectedCollection.id).notifier)
        .addItem(
          mediaType: MediaType.animation,
          externalId: tvShow.tmdbId,
          platformId: AnimationSource.tvShow,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.tvShowPoster,
          tvShow.tmdbId.toString(),
          tvShow.posterUrl,
        );
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

  Future<void> _addAnimationMovieToCollection(Movie movie) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String title = movie.title;

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId!).notifier)
        .addItem(
          mediaType: MediaType.animation,
          externalId: movie.tmdbId,
          platformId: AnimationSource.movie,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.moviePoster,
          movie.tmdbId.toString(),
          movie.posterUrl,
        );
        messenger.showSnackBar(
          SnackBar(content: Text('$title added to collection')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Already in collection')),
        );
      }
    }
  }

  Future<void> _addAnimationTvShowToCollection(TvShow tvShow) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String title = tvShow.title;

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId!).notifier)
        .addItem(
          mediaType: MediaType.animation,
          externalId: tvShow.tmdbId,
          platformId: AnimationSource.tvShow,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.tvShowPoster,
          tvShow.tmdbId.toString(),
          tvShow.posterUrl,
        );
        messenger.showSnackBar(
          SnackBar(content: Text('$title added to collection')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Already in collection')),
        );
      }
    }
  }

  void _onAnimationMovieTap(Movie movie) {
    if (widget.collectionId != null) {
      _addAnimationMovieToCollection(movie);
    } else {
      _showAnimationMovieDetails(movie);
    }
  }

  void _onAnimationTvShowTap(TvShow tvShow) {
    if (widget.collectionId != null) {
      _addAnimationTvShowToCollection(tvShow);
    } else {
      _showAnimationTvShowDetails(tvShow);
    }
  }

  void _showAnimationMovieDetails(Movie movie) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _MediaDetailsSheet(
        title: movie.title,
        overview: movie.overview,
        year: movie.releaseYear,
        rating: movie.formattedRating,
        genres: movie.genres,
        icon: Icons.animation,
        extraInfo: movie.runtime != null ? '${movie.runtime} min' : null,
        posterUrl: movie.posterUrl,
        onAddToCollection: () => _addAnimationMovieToAnyCollection(movie),
      ),
    );
  }

  void _showAnimationTvShowDetails(TvShow tvShow) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _MediaDetailsSheet(
        title: tvShow.title,
        overview: tvShow.overview,
        year: tvShow.firstAirYear,
        rating: tvShow.formattedRating,
        genres: tvShow.genres,
        icon: Icons.animation,
        extraInfo: tvShow.status,
        posterUrl: tvShow.posterUrl,
        onAddToCollection: () => _addAnimationTvShowToAnyCollection(tvShow),
      ),
    );
  }

  Widget _buildAnimationTab() {
    final MediaSearchState searchState = ref.watch(mediaSearchProvider);

    if (searchState.error != null &&
        searchState.activeTab == MediaSearchTab.animation) {
      return _buildErrorState(searchState.error!, onRetry: () {
        ref
            .read(mediaSearchProvider.notifier)
            .search(_searchController.text);
      });
    }

    if (searchState.isLoading &&
        searchState.activeTab == MediaSearchTab.animation) {
      return _buildShimmerGrid();
    }

    final bool hasAnimationResults =
        searchState.animationMovieResults.isNotEmpty ||
            searchState.animationTvShowResults.isNotEmpty;

    if (searchState.query.isEmpty && !hasAnimationResults) {
      return _buildEmptyState('Search for animation', Icons.animation);
    }

    if (!hasAnimationResults && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    final Map<int, List<CollectedItemInfo>> collectedAnimationInfos =
        ref.watch(collectedAnimationIdsProvider).valueOrNull ??
            <int, List<CollectedItemInfo>>{};

    // Объединяем анимационные фильмы и сериалы в один список
    final List<_AnimationItem> items = <_AnimationItem>[
      ...searchState.animationMovieResults
          .map((Movie m) => _AnimationItem(movie: m)),
      ...searchState.animationTvShowResults
          .map((TvShow t) => _AnimationItem(tvShow: t)),
    ];

    return Column(
      children: <Widget>[
        // Фильтры медиа
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildMediaFilterBar(searchState),
        ),

        // Сортировка
        if (hasAnimationResults)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SortSelector(
              currentSort: searchState.currentSort,
              onChanged: (SearchSort sort) {
                ref.read(mediaSearchProvider.notifier).setSort(sort);
              },
            ),
          ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCrossAxisCount,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.55,
            ),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final _AnimationItem item = items[index];
              if (item.isMovie) {
                final Movie movie = item.movie!;
                final List<CollectedItemInfo>? infos =
                    collectedAnimationInfos[movie.tmdbId];
                return PosterCard(
                  key: ValueKey<String>('anim_m_${movie.tmdbId}'),
                  title: movie.title,
                  imageUrl: movie.posterUrl ?? '',
                  cacheImageType: ImageType.moviePoster,
                  cacheImageId: movie.tmdbId.toString(),
                  rating: movie.rating,
                  year: movie.releaseYear,
                  subtitle: 'Movie${_genreSuffix(movie.genres)}',
                  isInCollection: infos != null && infos.isNotEmpty,
                  onTap: () => _onAnimationMovieTap(movie),
                );
              } else {
                final TvShow tvShow = item.tvShow!;
                final List<CollectedItemInfo>? infos =
                    collectedAnimationInfos[tvShow.tmdbId];
                return PosterCard(
                  key: ValueKey<String>('anim_t_${tvShow.tmdbId}'),
                  title: tvShow.title,
                  imageUrl: tvShow.posterUrl ?? '',
                  cacheImageType: ImageType.tvShowPoster,
                  cacheImageId: tvShow.tmdbId.toString(),
                  rating: tvShow.rating,
                  year: tvShow.firstAirYear,
                  subtitle: 'Series${_genreSuffix(tvShow.genres)}',
                  isInCollection: infos != null && infos.isNotEmpty,
                  onTap: () => _onAnimationTvShowTap(tvShow),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  String _genreSuffix(List<String>? genres) {
    if (genres == null || genres.isEmpty) return '';
    final List<String> filtered = genres
        .where((String g) => g != 'Animation' && g != '16')
        .take(1)
        .toList();
    if (filtered.isEmpty) return '';
    return ' \u2022 ${filtered.first}';
  }

  // ==================== Shared UI states ====================

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary.withAlpha(128),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.h3.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Type at least 2 characters to start searching',
              style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary.withAlpha(179),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No results found',
            style: AppTypography.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nothing found for "$query"',
            style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary.withAlpha(179),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, {required VoidCallback onRetry}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Search failed',
              style: AppTypography.h3.copyWith(
                    color: AppColors.error,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withAlpha(102),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Обложка и основная информация
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (game.coverUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: CachedNetworkImage(
                        imageUrl: game.coverUrl!,
                        width: 100,
                        height: 133,
                        fit: BoxFit.cover,
                        placeholder:
                            (BuildContext context, String url) => Container(
                          width: 100,
                          height: 133,
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (BuildContext context, String url,
                                Object error) =>
                            Container(
                          width: 100,
                          height: 133,
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.videogame_asset,
                              color: AppColors.textSecondary, size: 32),
                        ),
                      ),
                    ),
                  if (game.coverUrl != null)
                    const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          game.name,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            if (game.releaseYear != null)
                              _buildChip(
                                Icons.calendar_today,
                                game.releaseYear.toString(),
                              ),
                            if (game.formattedRating != null)
                              _buildChip(
                                Icons.star,
                                '${game.formattedRating} (${game.ratingCount ?? 0})',
                              ),
                          ],
                        ),
                        if (game.genres != null &&
                            game.genres!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: game.genres!
                                .map((String genre) =>
                                    Chip(label: Text(genre)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (game.summary != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Description',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  game.summary!,
                  style: AppTypography.body,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

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

  Widget _buildChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.gameAccent),
        const SizedBox(width: AppSpacing.xs),
        Text(label),
      ],
    );
  }
}

/// Обёртка для элемента анимации (может быть фильмом или сериалом).
class _AnimationItem {
  const _AnimationItem({this.movie, this.tvShow});

  final Movie? movie;
  final TvShow? tvShow;

  bool get isMovie => movie != null;
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
    this.posterUrl,
  });

  final String title;
  final String? overview;
  final int? year;
  final String? rating;
  final List<String>? genres;
  final IconData icon;
  final String? extraInfo;
  final String? posterUrl;
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withAlpha(102),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Постер и основная информация
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (posterUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: CachedNetworkImage(
                        imageUrl: posterUrl!,
                        width: 100,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder:
                            (BuildContext context, String url) => Container(
                          width: 100,
                          height: 150,
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (BuildContext context, String url,
                                Object error) =>
                            Container(
                          width: 100,
                          height: 150,
                          color: AppColors.surfaceLight,
                          child: Icon(icon,
                              color: AppColors.textSecondary, size: 32),
                        ),
                      ),
                    ),
                  if (posterUrl != null)
                    const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            if (year != null)
                              _buildChip(
                                Icons.calendar_today,
                                year.toString(),
                              ),
                            if (rating != null)
                              _buildChip(Icons.star, rating!),
                            if (extraInfo != null)
                              _buildChip(icon, extraInfo!),
                          ],
                        ),
                        if (genres != null &&
                            genres!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: genres!
                                .map((String genre) =>
                                    Chip(label: Text(genre)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (overview != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Description',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  overview!,
                  style: AppTypography.body,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

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

  Widget _buildChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.gameAccent),
        const SizedBox(width: AppSpacing.xs),
        Text(label),
      ],
    );
  }
}
