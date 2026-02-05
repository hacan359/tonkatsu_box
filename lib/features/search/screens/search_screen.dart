import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/widgets/cached_image.dart' as app_cached;
import '../../collections/providers/collections_provider.dart';
import '../providers/game_search_provider.dart';
import '../widgets/game_card.dart';
import '../widgets/platform_filter_sheet.dart';

/// Экран поиска игр.
///
/// Позволяет искать игры в базе IGDB с фильтрацией по платформе.
class SearchScreen extends ConsumerStatefulWidget {
  /// Создаёт [SearchScreen].
  const SearchScreen({
    this.onGameSelected,
    this.collectionId,
    super.key,
  });

  /// Callback при выборе игры (устаревший режим).
  final void Function(Game game)? onGameSelected;

  /// ID коллекции для добавления игр (новый режим).
  ///
  /// Если задан, при выборе игры она добавляется в коллекцию
  /// и пользователь остаётся на экране поиска.
  final int? collectionId;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Platform> _platforms = <Platform>[];
  Map<int, Platform> _platformMap = <int, Platform>{};
  bool _platformsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
    // Обновляем UI при изменении текста (для иконки clear)
    _searchController.addListener(_onControllerChanged);
    // Автофокус на поле поиска
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _onControllerChanged() {
    // Вызываем setState для обновления suffixIcon
    if (mounted) {
      setState(() {});
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
    _searchController.removeListener(_onControllerChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(gameSearchProvider.notifier).search(query);
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(gameSearchProvider.notifier).clear();
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
    // Сохраняем ScaffoldMessenger до async операций
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
    // Сохраняем ссылки до async операций
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String gameName = game.name;

    // Получаем список коллекций
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.read(collectionsProvider);

    final List<Collection>? collections = collectionsAsync.valueOrNull;
    if (collections == null || collections.isEmpty) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No collections available. Create one first.'),
          ),
        );
      }
      return;
    }

    // Фильтруем только редактируемые коллекции
    final List<Collection> editableCollections =
        collections.where((Collection c) => c.isEditable).toList();

    if (editableCollections.isEmpty) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No editable collections. Create your own first.'),
          ),
        );
      }
      return;
    }

    // Показываем диалог выбора коллекции
    final Collection? selectedCollection = await showDialog<Collection>(
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

    if (selectedCollection == null || !mounted) return;

    // Выбираем платформу
    final int? platformId = await _showPlatformSelectionDialog(game);
    if (platformId == null || !mounted) return;

    // Добавляем игру
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

  Future<int?> _showPlatformSelectionDialog(Game game) async {
    final List<int>? platformIds = game.platformIds;

    if (platformIds == null || platformIds.isEmpty) {
      // Возвращаем -1 как placeholder для игр без информации о платформах
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

  @override
  Widget build(BuildContext context) {
    final GameSearchState searchState = ref.watch(gameSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Games'),
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
                    hintText: 'Search for games...',
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
                    ref.read(gameSearchProvider.notifier).searchImmediate(query);
                  },
                ),

                const SizedBox(height: 12),

                // Фильтр по платформе
                _buildPlatformFilter(searchState),
              ],
            ),
          ),

          // Результаты
          Expanded(
            child: _buildResults(searchState),
          ),
        ],
      ),
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

  Widget _buildResults(GameSearchState searchState) {
    // Ошибка
    if (searchState.error != null) {
      return _buildErrorState(searchState.error!);
    }

    // Загрузка
    if (searchState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Пустое состояние
    if (searchState.isEmpty) {
      return _buildEmptyState();
    }

    // Нет результатов
    if (!searchState.hasResults && searchState.query.isNotEmpty) {
      return _buildNoResults(searchState.query);
    }

    // Результаты
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

  Widget _buildEmptyState() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for games',
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
            'No games found for "$query"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              onPressed: () {
                ref
                    .read(gameSearchProvider.notifier)
                    .searchImmediate(_searchController.text);
              },
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
              // Handle
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

              // Название
              Text(
                game.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Метаданные
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

              // Жанры
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

              // Описание
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

              // Кнопка добавления
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
