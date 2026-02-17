import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/platform_features.dart';
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
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/widgets/breadcrumb_app_bar.dart';
import '../../../shared/widgets/cached_image.dart' as app_cached;
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../collections/providers/collections_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/media_search_item.dart';
import '../models/tv_sub_filter.dart';
import '../providers/game_search_provider.dart';
import '../providers/media_search_provider.dart';
import '../widgets/game_details_sheet.dart';
import '../widgets/media_details_sheet.dart';
import '../widgets/platform_filter_sheet.dart';

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
  final int? collectionId;

  /// Начальный индекс таба (0=TV, 1=Games).
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

  /// Высота элементов FilterRow (единый стандарт с collection_screen).
  static const double _filterRowHeight = 32;

  /// Индекс активного таба.
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex ?? 0;
    _tabController = TabController(
      length: 2,
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
      // Не запускаем поиск — каждый таб хранит свои результаты
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
      // TV tab
      ref.read(mediaSearchProvider.notifier).search(query);
    } else {
      // Games tab
      ref.read(gameSearchProvider.notifier).search(query);
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
          ref
              .read(gameSearchProvider.notifier)
              .setPlatformFilters(selectedIds);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ==================== Image caching ====================

  void _cacheImage(ImageType type, String imageId, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final ImageCacheService cacheService = ref.read(imageCacheServiceProvider);
    cacheService.downloadImage(
      type: type,
      imageId: imageId,
      remoteUrl: imageUrl,
    );
  }

  void _preloadSeasons(int tmdbId) {
    _preloadSeasonsAsync(tmdbId);
  }

  Future<void> _preloadSeasonsAsync(int tmdbId) async {
    if (!mounted) return;
    try {
      final DatabaseService db = ref.read(databaseServiceProvider);
      final List<TvSeason> cached = await db.getTvSeasonsByShowId(tmdbId);
      if (cached.isNotEmpty) return;
      final TmdbApi tmdb = ref.read(tmdbApiProvider);
      final List<TvSeason> seasons = await tmdb.getTvSeasons(tmdbId);
      if (seasons.isNotEmpty) {
        await db.upsertTvSeasons(seasons);
      }
    } catch (_) {
      // Не критично — сезоны загрузятся при просмотре деталей
    }
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

  // ==================== Media actions ====================

  /// Определяет тип анимации: если MediaSearchItem.isAnimation, добавляем
  /// как animation с правильным platformId.
  void _onMediaItemTapForAnimation(MediaSearchItem item) {
    if (item.type == MediaSearchItemType.movie) {
      final Movie movie = item.movie!;
      if (widget.collectionId != null) {
        if (item.isAnimation) {
          _addAnimationMovieToCollection(movie);
        } else {
          _addMovieToCollection(movie);
        }
      } else {
        _showMediaItemDetails(item);
      }
    } else {
      final TvShow tvShow = item.tvShow!;
      if (widget.collectionId != null) {
        if (item.isAnimation) {
          _addAnimationTvShowToCollection(tvShow);
        } else {
          _addTvShowToCollection(tvShow);
        }
      } else {
        _showMediaItemDetails(item);
      }
    }
  }

  void _showMediaItemDetails(MediaSearchItem item) {
    if (item.type == MediaSearchItemType.movie) {
      final Movie movie = item.movie!;
      final bool isAnim = item.isAnimation;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) => MediaDetailsSheet(
          title: movie.title,
          overview: movie.overview,
          year: movie.releaseYear,
          rating: movie.formattedRating,
          genres: movie.genres,
          icon: isAnim ? Icons.animation : Icons.movie,
          extraInfo: movie.runtime != null ? '${movie.runtime} min' : null,
          posterUrl: movie.posterUrl,
          onAddToCollection: () => isAnim
              ? _addAnimationMovieToAnyCollection(movie)
              : _addMovieToAnyCollection(movie),
        ),
      );
    } else {
      final TvShow tvShow = item.tvShow!;
      final bool isAnim = item.isAnimation;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) => MediaDetailsSheet(
          title: tvShow.title,
          overview: tvShow.overview,
          year: tvShow.firstAirYear,
          rating: tvShow.formattedRating,
          genres: tvShow.genres,
          icon: isAnim ? Icons.animation : Icons.tv,
          extraInfo: tvShow.status,
          posterUrl: tvShow.posterUrl,
          onAddToCollection: () => isAnim
              ? _addAnimationTvShowToAnyCollection(tvShow)
              : _addTvShowToAnyCollection(tvShow),
        ),
      );
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
        _preloadSeasons(tvShow.tmdbId);
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
        _preloadSeasons(tvShow.tmdbId);
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

  // ==================== Animation actions ====================

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
        _preloadSeasons(tvShow.tmdbId);
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
        _preloadSeasons(tvShow.tmdbId);
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
        scrollable: true,
        title: const Text('Select Platform'),
        content: Column(
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
      builder: (BuildContext context) => GameDetailsSheet(
        game: game,
        onAddToCollection: () => _addGameToAnyCollection(game),
      ),
    );
  }


  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final bool isApiReady = ref.watch(hasValidApiKeyProvider);
    final bool isLandscape = isLandscapeMobile(context);

    if (!isApiReady) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BreadcrumbAppBar(
          crumbs: <BreadcrumbItem>[
            BreadcrumbItem(label: 'Search'),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.search_off,
                  size: isLandscape ? 40 : 64,
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
      resizeToAvoidBottomInset: !isLandscape,
      appBar: BreadcrumbAppBar(
        crumbs: const <BreadcrumbItem>[
          BreadcrumbItem(label: 'Search'),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: isLandscape
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm)
              : null,
          tabs: isLandscape
              ? const <Widget>[
                  Tab(icon: Icon(Icons.tv, size: 18)),
                  Tab(icon: Icon(Icons.videogame_asset, size: 18)),
                ]
              : const <Widget>[
                  Tab(icon: Icon(Icons.tv), text: 'TV'),
                  Tab(icon: Icon(Icons.videogame_asset), text: 'Games'),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildTvTab(),
          _buildGamesTab(),
        ],
      ),
    );
  }

  // ==================== FilterRow builders ====================

  /// Строит FilterRow для TV таба: [Search] [Type] [Sort].
  Widget _buildTvFilterRow() {
    final MediaSearchState mediaState = ref.watch(mediaSearchProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: SizedBox(
        height: _filterRowHeight,
        child: Row(
          children: <Widget>[
            // Поле поиска
            Expanded(child: _buildCompactSearchField()),

            const SizedBox(width: AppSpacing.xs),

            // TvSubFilter dropdown
            _buildTvSubFilterButton(mediaState),

            const SizedBox(width: AppSpacing.xs),

            // Sort dropdown
            _buildSortDropdown(
              currentSort: mediaState.currentSort,
              onChanged: (SearchSort sort) {
                ref.read(mediaSearchProvider.notifier).setSort(sort);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Строит FilterRow для Games таба: [Search] [Platform] [Sort].
  Widget _buildGamesFilterRow() {
    final GameSearchState gameState = ref.watch(gameSearchProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: SizedBox(
        height: _filterRowHeight,
        child: Row(
          children: <Widget>[
            // Поле поиска
            Expanded(child: _buildCompactSearchField()),

            const SizedBox(width: AppSpacing.xs),

            // Platform filter button
            _buildCompactPlatformButton(gameState),

            const SizedBox(width: AppSpacing.xs),

            // Sort dropdown
            _buildSortDropdown(
              currentSort: gameState.currentSort,
              onChanged: (SearchSort sort) {
                ref.read(gameSearchProvider.notifier).setSort(sort);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Компактное поле поиска (стиль collection_screen).
  Widget _buildCompactSearchField() {
    final bool hasText = _searchController.text.isNotEmpty;
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: _activeTabIndex == 0 ? 'Search TV...' : 'Search games...',
        hintStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiary,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: AppColors.textTertiary,
        ),
        suffixIcon: hasText
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: _onClearSearch,
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: 'Search',
                    onPressed: _onSearchSubmit,
                  ),
                ],
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _onSearchSubmit(),
    );
  }

  /// Кнопка TvSubFilter (dropdown).
  Widget _buildTvSubFilterButton(MediaSearchState mediaState) {
    return PopupMenuButton<TvSubFilter>(
      onSelected: (TvSubFilter filter) {
        ref.read(mediaSearchProvider.notifier).setSubFilter(filter);
      },
      initialValue: mediaState.subFilter,
      tooltip: 'Type filter',
      constraints: const BoxConstraints(minWidth: 120),
      child: Container(
        height: _filterRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              mediaState.subFilter.label,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => TvSubFilter.values
          .map(
            (TvSubFilter filter) => PopupMenuItem<TvSubFilter>(
              value: filter,
              child: Text(filter.label),
            ),
          )
          .toList(),
    );
  }

  /// Компактная кнопка Platform filter.
  Widget _buildCompactPlatformButton(GameSearchState gameState) {
    final int count = gameState.selectedPlatformIds.length;
    final String label = count == 0 ? 'All' : '$count plat.';

    return GestureDetector(
      onTap: _platformsLoading ? null : _showPlatformFilterSheet,
      child: Container(
        height: _filterRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.filter_list, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }

  /// Единый Sort dropdown (одинаковый для обоих табов).
  Widget _buildSortDropdown({
    required SearchSort currentSort,
    required ValueChanged<SearchSort> onChanged,
  }) {
    return PopupMenuButton<SearchSortField>(
      onSelected: (SearchSortField field) {
        if (field == currentSort.field) {
          // Если тот же field — toggle order
          onChanged(currentSort.toggleOrder());
        } else {
          onChanged(SearchSort(
            field: field,
            order: SearchSortOrder.descending,
          ));
        }
      },
      tooltip: 'Sort',
      constraints: const BoxConstraints(minWidth: 130),
      child: Container(
        height: _filterRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              currentSort.order == SearchSortOrder.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
            ),
            const SizedBox(width: 2),
            Text(
              currentSort.field.shortLabel,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => SearchSortField.values
          .map(
            (SearchSortField field) => PopupMenuItem<SearchSortField>(
              value: field,
              child: Row(
                children: <Widget>[
                  if (field == currentSort.field)
                    Icon(
                      currentSort.order == SearchSortOrder.ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                    )
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(field.displayLabel),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ==================== Grid helpers ====================

  static const double _desktopMaxCardWidth = 150;

  bool get _isDesktop {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return screenWidth >= navigationBreakpoint && !kIsMobile;
  }

  int get _gridCrossAxisCount {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLandscape = isLandscapeMobile(context);
    if (isLandscape) {
      return AppSpacing.gridColumnsDesktop;
    } else if (screenWidth >= 500) {
      return AppSpacing.gridColumnsTablet;
    }
    return AppSpacing.gridColumnsMobile;
  }

  SliverGridDelegate get _gridDelegate {
    if (_isDesktop) {
      return SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _desktopMaxCardWidth,
        crossAxisSpacing: _gridCrossAxisSpacing,
        mainAxisSpacing: _gridMainAxisSpacing,
        childAspectRatio: 0.55,
      );
    }
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _gridCrossAxisCount,
      crossAxisSpacing: _gridCrossAxisSpacing,
      mainAxisSpacing: _gridMainAxisSpacing,
      childAspectRatio: 0.55,
    );
  }

  double get _gridPadding =>
      isLandscapeMobile(context) ? AppSpacing.sm : AppSpacing.md;

  double get _gridCrossAxisSpacing =>
      isLandscapeMobile(context) ? AppSpacing.sm : AppSpacing.md;

  double get _gridMainAxisSpacing =>
      isLandscapeMobile(context) ? AppSpacing.sm : AppSpacing.lg;

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(_gridPadding),
      gridDelegate: _gridDelegate,
      itemCount: _gridCrossAxisCount * 2,
      itemBuilder: (BuildContext context, int index) {
        return const ShimmerPosterCard();
      },
    );
  }

  // ==================== TV tab ====================

  Widget _buildTvTab() {
    final MediaSearchState searchState = ref.watch(mediaSearchProvider);

    return Column(
      children: <Widget>[
        _buildTvFilterRow(),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: _buildMediaResults(searchState),
        ),
      ],
    );
  }

  Widget _buildMediaResults(MediaSearchState searchState) {
    if (searchState.error != null) {
      return _buildErrorState(searchState.error!, onRetry: () {
        ref
            .read(mediaSearchProvider.notifier)
            .search(_searchController.text);
      });
    }

    if (searchState.isLoading) {
      return _buildShimmerGrid();
    }

    if (searchState.isEmpty) {
      return _buildEmptyState('Search for TV & Movies', Icons.tv);
    }

    if (!searchState.hasResults && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    final Map<int, List<CollectedItemInfo>> collectedMovieInfos =
        ref.watch(collectedMovieIdsProvider).valueOrNull ??
            <int, List<CollectedItemInfo>>{};
    final Map<int, List<CollectedItemInfo>> collectedTvShowInfos =
        ref.watch(collectedTvShowIdsProvider).valueOrNull ??
            <int, List<CollectedItemInfo>>{};
    final Map<int, List<CollectedItemInfo>> collectedAnimationInfos =
        ref.watch(collectedAnimationIdsProvider).valueOrNull ??
            <int, List<CollectedItemInfo>>{};

    final int itemCount = searchState.items.length;
    final bool showLoader = searchState.isLoadingMore;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          final ScrollMetrics metrics = notification.metrics;
          if (metrics.pixels > metrics.maxScrollExtent * 0.8) {
            ref.read(mediaSearchProvider.notifier).loadMore();
          }
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.all(_gridPadding),
        gridDelegate: _gridDelegate,
        itemCount: itemCount + (showLoader ? _gridCrossAxisCount : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= itemCount) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final MediaSearchItem item = searchState.items[index];

          // Определяем, есть ли в коллекции
          bool isInCollection = false;
          if (item.isAnimation) {
            final List<CollectedItemInfo>? infos =
                collectedAnimationInfos[item.tmdbId];
            isInCollection = infos != null && infos.isNotEmpty;
          } else if (item.type == MediaSearchItemType.movie) {
            final List<CollectedItemInfo>? infos =
                collectedMovieInfos[item.tmdbId];
            isInCollection = infos != null && infos.isNotEmpty;
          } else {
            final List<CollectedItemInfo>? infos =
                collectedTvShowInfos[item.tmdbId];
            isInCollection = infos != null && infos.isNotEmpty;
          }

          final ImageType imageType =
              item.type == MediaSearchItemType.movie
                  ? ImageType.moviePoster
                  : ImageType.tvShowPoster;

          return MediaPosterCard(
            key: ValueKey<String>(
                '${item.type.name}_${item.tmdbId}'),
            variant: isLandscapeMobile(context)
                ? CardVariant.compact
                : CardVariant.grid,
            title: item.title,
            imageUrl: item.posterUrl ?? '',
            cacheImageType: imageType,
            cacheImageId: item.tmdbId.toString(),
            apiRating: item.rating,
            year: item.year,
            subtitle: _mediaSubtitle(item),
            isInCollection: isInCollection,
            onTap: () => _onMediaItemTapForAnimation(item),
          );
        },
      ),
    );
  }

  String? _mediaSubtitle(MediaSearchItem item) {
    final List<String>? genres = item.genres;
    if (item.isAnimation) {
      final String typeLabel = item.type == MediaSearchItemType.movie
          ? 'Movie'
          : 'Series';
      return '$typeLabel${_genreSuffix(genres)}';
    }
    return genres?.take(2).join(', ');
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

  // ==================== Games tab ====================

  Widget _buildGamesTab() {
    final GameSearchState searchState = ref.watch(gameSearchProvider);

    return Column(
      children: <Widget>[
        _buildGamesFilterRow(),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: _buildGameResults(searchState),
        ),
      ],
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

    final int itemCount = searchState.results.length;
    final bool showLoader = searchState.isLoadingMore;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          final ScrollMetrics metrics = notification.metrics;
          if (metrics.pixels > metrics.maxScrollExtent * 0.8) {
            ref.read(gameSearchProvider.notifier).loadMore();
          }
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.all(_gridPadding),
        gridDelegate: _gridDelegate,
        itemCount: itemCount + (showLoader ? _gridCrossAxisCount : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= itemCount) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final Game game = searchState.results[index];
          final List<CollectedItemInfo>? infos = collectedGameInfos[game.id];
          return MediaPosterCard(
            key: ValueKey<int>(game.id),
            variant: isLandscapeMobile(context)
                ? CardVariant.compact
                : CardVariant.grid,
            title: game.name,
            imageUrl: game.coverUrl ?? '',
            cacheImageType: ImageType.gameCover,
            cacheImageId: game.id.toString(),
            apiRating: game.rating != null ? game.rating! / 10 : null,
            year: game.releaseYear,
            subtitle: game.genres?.take(2).join(', '),
            isInCollection: infos != null && infos.isNotEmpty,
            onTap: () => _onGameTap(game),
          );
        },
      ),
    );
  }

  // ==================== Shared UI states ====================

  Widget _buildEmptyState(String message, IconData icon) {
    final bool isLandscape = isLandscapeMobile(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: isLandscape ? 32 : 64,
              color: AppColors.textSecondary.withAlpha(128),
            ),
            SizedBox(height: isLandscape ? AppSpacing.sm : AppSpacing.md),
            Text(
              message,
              style: (isLandscape ? AppTypography.body : AppTypography.h3)
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!isLandscape) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Type at least 2 characters and press Enter',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(String query) {
    final bool isLandscape = isLandscapeMobile(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: isLandscape ? 32 : 64,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          SizedBox(height: isLandscape ? AppSpacing.sm : AppSpacing.md),
          Text(
            'No results found',
            style: (isLandscape ? AppTypography.body : AppTypography.h3)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nothing found for "$query"',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, {required VoidCallback onRetry}) {
    final bool isLandscape = isLandscapeMobile(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isLandscape ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: isLandscape ? 32 : 64,
              color: AppColors.error,
            ),
            SizedBox(height: isLandscape ? AppSpacing.sm : AppSpacing.md),
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
