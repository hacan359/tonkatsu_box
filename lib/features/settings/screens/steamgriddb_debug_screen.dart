// Debug экран для тестирования SteamGridDB API.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/steamgriddb_api.dart';
import '../../../shared/models/steamgriddb_game.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/widgets/breadcrumb_app_bar.dart';

/// Экран отладки SteamGridDB API.
///
/// Позволяет тестировать все эндпоинты: поиск игр, grids, heroes, logos, icons.
class SteamGridDbDebugScreen extends ConsumerStatefulWidget {
  /// Создаёт [SteamGridDbDebugScreen].
  const SteamGridDbDebugScreen({super.key});

  @override
  ConsumerState<SteamGridDbDebugScreen> createState() =>
      _SteamGridDbDebugScreenState();
}

class _SteamGridDbDebugScreenState
    extends ConsumerState<SteamGridDbDebugScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _gameIdController = TextEditingController();

  List<SteamGridDbGame> _searchResults = <SteamGridDbGame>[];
  List<SteamGridDbImage> _images = <SteamGridDbImage>[];
  bool _isSearching = false;
  bool _isLoadingImages = false;
  String? _searchError;
  String? _imageError;
  int _lastImageTab = -1;

  @override
  void dispose() {
    _searchController.dispose();
    _gameIdController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final String term = _searchController.text.trim();
    if (term.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = <SteamGridDbGame>[];
    });

    try {
      final SteamGridDbApi api = ref.read(steamGridDbApiProvider);
      final List<SteamGridDbGame> results = await api.searchGames(term);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } on SteamGridDbApiException catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.message;
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _loadImages(int tabIndex) async {
    final String idText = _gameIdController.text.trim();
    if (idText.isEmpty) return;

    final int? gameId = int.tryParse(idText);
    if (gameId == null) {
      setState(() {
        _imageError = 'Invalid game ID';
      });
      return;
    }

    setState(() {
      _isLoadingImages = true;
      _imageError = null;
      _images = <SteamGridDbImage>[];
      _lastImageTab = tabIndex;
    });

    try {
      final SteamGridDbApi api = ref.read(steamGridDbApiProvider);
      final List<SteamGridDbImage> results;

      switch (tabIndex) {
        case 1:
          results = await api.getGrids(gameId);
        case 2:
          results = await api.getHeroes(gameId);
        case 3:
          results = await api.getLogos(gameId);
        case 4:
          results = await api.getIcons(gameId);
        default:
          results = <SteamGridDbImage>[];
      }

      if (mounted) {
        setState(() {
          _images = results;
          _isLoadingImages = false;
        });
      }
    } on SteamGridDbApiException catch (e) {
      if (mounted) {
        setState(() {
          _imageError = e.message;
          _isLoadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: BreadcrumbAppBar(
          crumbs: <BreadcrumbItem>[
            BreadcrumbItem(
              label: 'Settings',
              onTap: () => Navigator.of(context)
                  .popUntil((Route<dynamic> route) => route.isFirst),
            ),
            BreadcrumbItem(
              label: 'Debug',
              onTap: () => Navigator.of(context).pop(),
            ),
            const BreadcrumbItem(label: 'SteamGridDB'),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(text: 'Search'),
              Tab(text: 'Grids'),
              Tab(text: 'Heroes'),
              Tab(text: 'Logos'),
              Tab(text: 'Icons'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildSearchTab(),
            _buildImageTab(1),
            _buildImageTab(2),
            _buildImageTab(3),
            _buildImageTab(4),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search games',
              hintText: 'Enter game name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _performSearch,
                    ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        if (_searchError != null)
          _buildErrorCard(_searchError!),
        Expanded(
          child: _searchResults.isEmpty && !_isSearching
              ? const Center(
                  child: Text(
                    'Enter a game name to search',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (BuildContext context, int index) {
                    final SteamGridDbGame game = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(game.id.toString()),
                      ),
                      title: Text(game.name),
                      subtitle: Text(
                        <String>[
                          'ID: ${game.id}',
                          if (game.types != null && game.types!.isNotEmpty)
                            game.types!.join(', '),
                        ].join(' | '),
                      ),
                      trailing: game.verified
                          ? const Icon(Icons.verified,
                              color: Colors.blue, size: 20)
                          : null,
                      onTap: () {
                        _gameIdController.text = game.id.toString();
                        _showSnackBar(
                          'Game ID ${game.id} copied to image tabs',
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildImageTab(int tabIndex) {
    final String tabName = switch (tabIndex) {
      1 => 'Grids',
      2 => 'Heroes',
      3 => 'Logos',
      4 => 'Icons',
      _ => '',
    };

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _gameIdController,
                  decoration: const InputDecoration(
                    labelText: 'Game ID',
                    hintText: 'Enter SteamGridDB game ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loadImages(tabIndex),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                height: 48,
                child: FilledButton.icon(
                  onPressed:
                      _isLoadingImages ? null : () => _loadImages(tabIndex),
                  icon: _isLoadingImages
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text('Load $tabName'),
                ),
              ),
            ],
          ),
        ),
        if (_imageError != null && _lastImageTab == tabIndex)
          _buildErrorCard(_imageError!),
        Expanded(
          child: _images.isEmpty && _lastImageTab != tabIndex
              ? Center(
                  child: Text(
                    'Enter a game ID and press Load $tabName',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : _images.isEmpty && !_isLoadingImages
                  ? const Center(
                      child: Text(
                        'No images found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _lastImageTab == tabIndex
                      ? GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _images.length,
                          itemBuilder: (BuildContext context, int index) {
                            return _buildImageCard(_images[index]);
                          },
                        )
                      : Center(
                          child: Text(
                            'Enter a game ID and press Load $tabName',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildImageCard(SteamGridDbImage image) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Image.network(
              image.thumb,
              fit: BoxFit.cover,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                );
              },
              loadingBuilder: (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
              ) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  image.dimensions,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${image.style} | Score: ${image.score}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (image.author != null)
                  Text(
                    'by ${image.author}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: <Widget>[
              Icon(Icons.warning_amber, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
