import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/steamgriddb_game.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';

/// Боковая панель для поиска и добавления SteamGridDB-изображений на канвас.
class SteamGridDbPanel extends ConsumerStatefulWidget {
  /// Создаёт [SteamGridDbPanel].
  const SteamGridDbPanel({
    required this.collectionId,
    required this.collectionName,
    required this.onAddImage,
    super.key,
  });

  /// ID коллекции (null для uncategorized).
  final int? collectionId;

  /// Название коллекции (для автозаполнения поиска).
  final String collectionName;

  /// Колбэк при добавлении изображения на канвас.
  final void Function(SteamGridDbImage image) onAddImage;

  @override
  ConsumerState<SteamGridDbPanel> createState() => _SteamGridDbPanelState();
}

class _SteamGridDbPanelState extends ConsumerState<SteamGridDbPanel> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasPreFilled = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _preFillSearchIfNeeded(SteamGridDbPanelState panelState) {
    if (_hasPreFilled) return;
    if (panelState.searchResults.isEmpty &&
        panelState.searchTerm.isEmpty &&
        widget.collectionName.isNotEmpty) {
      _searchController.text = widget.collectionName;
    }
    _hasPreFilled = true;
  }

  String _localizedImageTypeLabel(
    BuildContext context,
    SteamGridDbImageType type,
  ) {
    final S l10n = S.of(context);
    switch (type) {
      case SteamGridDbImageType.grids:
        return l10n.steamGridDbGrids;
      case SteamGridDbImageType.heroes:
        return l10n.steamGridDbHeroes;
      case SteamGridDbImageType.logos:
        return l10n.steamGridDbLogos;
      case SteamGridDbImageType.icons:
        return l10n.steamGridDbIcons;
    }
  }

  void _performSearch() {
    final String term = _searchController.text.trim();
    if (term.isEmpty) return;
    ref
        .read(steamGridDbPanelProvider(widget.collectionId).notifier)
        .searchGames(term);
  }

  @override
  Widget build(BuildContext context) {
    final SteamGridDbPanelState panelState =
        ref.watch(steamGridDbPanelProvider(widget.collectionId));
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    _preFillSearchIfNeeded(panelState);

    return Container(
      width: 320,
      color: colorScheme.surface,
      child: Column(
        children: <Widget>[
          // Заголовок
          _buildHeader(colorScheme, theme),
          const Divider(height: 1),

          // Поиск
          _buildSearchBar(colorScheme),

          // Предупреждение об отсутствии ключа
          if (!settings.hasSteamGridDbKey)
            _buildNoApiKeyWarning(colorScheme, theme),

          // Заголовок выбранной игры
          if (panelState.selectedGame != null)
            _buildGameHeader(panelState.selectedGame!, colorScheme, theme),

          // Селектор типа изображений
          if (panelState.selectedGame != null)
            _buildImageTypeSelector(panelState, colorScheme),

          // Основной контент
          Expanded(
            child: _buildContent(panelState, settings, colorScheme, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.image_search, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).steamGridDbPanelTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: S.of(context).steamGridDbClosePanel,
            onPressed: () => ref
                .read(steamGridDbPanelProvider(widget.collectionId).notifier)
                .closePanel(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: S.of(context).steamGridDbSearchHint,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, size: 20),
            tooltip: S.of(context).search,
            onPressed: _performSearch,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildNoApiKeyWarning(ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.of(context).steamGridDbNoApiKey,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameHeader(
    SteamGridDbGame game,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: S.of(context).steamGridDbBackToSearch,
            onPressed: () {
              ref
                  .read(
                      steamGridDbPanelProvider(widget.collectionId).notifier)
                  .clearGameSelection();
            },
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              game.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (game.verified)
            Icon(Icons.verified, size: 16, color: colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildImageTypeSelector(
    SteamGridDbPanelState panelState,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SegmentedButton<SteamGridDbImageType>(
        segments: SteamGridDbImageType.values
            .map(
              (SteamGridDbImageType type) => ButtonSegment<SteamGridDbImageType>(
                value: type,
                label: Text(
                  _localizedImageTypeLabel(context, type),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
            .toList(),
        selected: <SteamGridDbImageType>{panelState.selectedImageType},
        onSelectionChanged: (Set<SteamGridDbImageType> selection) {
          ref
              .read(steamGridDbPanelProvider(widget.collectionId).notifier)
              .selectImageType(selection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    SteamGridDbPanelState panelState,
    SettingsState settings,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    // Загрузка поиска
    if (panelState.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // Загрузка изображений
    if (panelState.isLoadingImages) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ошибка поиска
    if (panelState.searchError != null) {
      return _buildError(panelState.searchError!, colorScheme, theme);
    }

    // Ошибка загрузки изображений
    if (panelState.imageError != null) {
      return _buildError(panelState.imageError!, colorScheme, theme);
    }

    // Если выбрана игра — показать сетку изображений
    if (panelState.selectedGame != null) {
      return _buildImageGrid(panelState, colorScheme, theme);
    }

    // Результаты поиска
    if (panelState.searchResults.isNotEmpty) {
      return _buildSearchResults(panelState, colorScheme, theme);
    }

    // Пустое состояние
    return _buildEmptyState(colorScheme, theme);
  }

  Widget _buildError(
    String message,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    SteamGridDbPanelState panelState,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: panelState.searchResults.length,
      itemBuilder: (BuildContext context, int index) {
        final SteamGridDbGame game = panelState.searchResults[index];
        return ListTile(
          dense: true,
          title: Text(
            game.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: game.verified
              ? Icon(Icons.verified, size: 16, color: colorScheme.primary)
              : null,
          onTap: () {
            ref
                .read(steamGridDbPanelProvider(widget.collectionId).notifier)
                .selectGame(game);
          },
        );
      },
    );
  }

  Widget _buildImageGrid(
    SteamGridDbPanelState panelState,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (panelState.images.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).steamGridDbNoResults,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: panelState.images.length,
      itemBuilder: (BuildContext context, int index) {
        final SteamGridDbImage image = panelState.images[index];
        return _ImageThumbnailCard(
          image: image,
          colorScheme: colorScheme,
          theme: theme,
          onTap: () => widget.onAddImage(image),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.image_search,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).steamGridDbSearchFirst,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка-превью изображения SteamGridDB.
class _ImageThumbnailCard extends StatelessWidget {
  const _ImageThumbnailCard({
    required this.image,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  final SteamGridDbImage image;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${image.dimensions} • ${image.style}'
          '${image.author != null ? ' • by ${image.author}' : ''}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: image.thumb,
                  fit: BoxFit.cover,
                  placeholder: (BuildContext context, String url) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget:
                      (BuildContext context, String url, Object error) =>
                          Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: colorScheme.surfaceContainerLow,
                child: Text(
                  image.dimensions,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
