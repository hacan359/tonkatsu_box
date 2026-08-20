import 'dart:async';

import 'package:core/models/audio_item.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../handlers/media_handlers.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import '../providers/discover_provider.dart';
import '../sources/search_sources.dart';
import '../widgets/browse_grid.dart';
import '../widgets/audio_discover_feed.dart';
import '../widgets/browse_sections.dart';
import '../widgets/browse_sections_compact.dart';
import '../widgets/collection_chips_row.dart';
import '../widgets/discover_customize_sheet.dart';
import '../widgets/discover_feed.dart';
import '../widgets/filter_bar.dart';
import '../widgets/source_chips_row.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/constants/platform_ui.dart';

/// Search and browse screen — two modes: Browse (filter bar + Discover/Grid)
/// and Search (query field + results).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static ShortcutGroup shortcutGroup(S l) => ShortcutGroup(
        title: l.search,
        entries: <ShortcutEntry>[
          ShortcutEntry(keys: 'Ctrl+F', description: l.shortcutFocusSearchField),
          ShortcutEntry(keys: 'Escape', description: l.shortcutClearOrBack),
          ShortcutEntry(keys: 'Enter', description: l.shortcutRunSearch),
        ],
      );

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Timer? _searchDebounce;
  Map<int, Platform> _platformMap = <int, Platform>{};
  late MediaHandlers _handlers;

  @override
  void initState() {
    super.initState();
    _handlers = _buildHandlers();
    _loadPlatforms();
  }

  /// The platform map and the add-target collections are read live in closures,
  /// so handlers never rebuild — a tap resolves the current selection.
  MediaHandlers _buildHandlers() => MediaHandlers(
        ref: ref,
        platformMap: () => _platformMap,
        targetCollections: () => ref.read(searchTargetCollectionsProvider),
      );

  Future<void> _loadPlatforms() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<Platform> platforms = await db.gameDao.getAllPlatforms();
    if (mounted) {
      setState(() {
        _platformMap = <int, Platform>{
          for (final Platform p in platforms) p.id: p,
        };
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _syncSearchText() {
    final String text = ref.read(searchTabQueryProvider).trim();
    if (text.length >= 2) {
      ref.read(browseProvider.notifier).setSearchQuery(text);
    }
  }

  void _onQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      ref.read(browseProvider.notifier).clearSearch();
      return;
    }
    if (query.length < 2) return;
    _searchDebounce = Timer(_activeDebounce(), () {
      if (mounted) {
        ref.read(browseProvider.notifier).search(query);
      }
    });
  }

  /// Strictest debounce among the enabled sources of the active type — a
  /// rate-limited provider must not be hit on every few keystrokes.
  Duration _activeDebounce() {
    final BrowseState state = ref.read(browseProvider);
    Duration debounce = SearchSource.defaultSearchDebounce;
    for (final SearchSource source in searchSourcesFor(state.mediaType)) {
      if (state.disabledSourceIds.contains(source.id)) continue;
      if (source.searchDebounce > debounce) debounce = source.searchDebounce;
    }
    return debounce;
  }

  Future<void> _openItemInCollection(
    int externalId,
    MediaType mediaType,
    DataSource? source,
  ) async {
    final List<CollectedItemInfo> infos = await _getCollectedInfos(
      externalId,
      mediaType,
      source,
    );
    if (infos.isEmpty || !mounted) return;

    if (infos.length == 1) {
      _navigateToItemDetail(infos.first);
      return;
    }

    if (!mounted) return;
    final CollectedItemInfo? chosen = await showDialog<CollectedItemInfo>(
      context: context,
      builder: (BuildContext context) {
        final S l = S.of(context);
        return SimpleDialog(
          title: Text(l.openInCollection),
          children: infos.map((CollectedItemInfo info) {
            final String name =
                info.collectionName ?? l.collectionsUncategorized;
            final Platform? platform = info.platformId != null
                ? _platformMap[info.platformId]
                : null;
            return SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(info),
              child: Row(
                children: <Widget>[
                  if (platform != null) ...<Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: platform.familyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(name),
                        if (platform != null)
                          Text(
                            platform.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
    if (chosen != null && mounted) {
      _navigateToItemDetail(chosen);
    }
  }

  Future<List<CollectedItemInfo>> _getCollectedInfos(
    int externalId,
    MediaType mediaType,
    DataSource? source,
  ) async {
    final Map<int, List<CollectedItemInfo>> collected;
    switch (mediaType) {
      case MediaType.game:
        collected = await ref.read(collectedGameIdsProvider.future);
      case MediaType.movie:
        collected = await ref.read(collectedMovieIdsProvider.future);
      case MediaType.tvShow:
        collected = await ref.read(collectedTvShowIdsProvider.future);
      case MediaType.animation:
        collected = await ref.read(collectedAnimationIdsProvider.future);
      case MediaType.visualNovel:
        collected = await ref.read(collectedVisualNovelIdsProvider.future);
      case MediaType.manga:
        collected = await ref.read(collectedMangaIdsProvider.future);
      case MediaType.anime:
        collected = await ref.read(collectedAnimeIdsProvider.future);
      case MediaType.book:
        collected = await ref.read(collectedBookIdsProvider.future);
      case MediaType.audio:
        collected = await ref.read(collectedAudioIdsProvider.future);
      case MediaType.custom:
        return <CollectedItemInfo>[];
    }
    // Narrowed by source so the placements match how the card's badge is
    // keyed: by (source, id), not by id alone.
    return (collected[externalId] ?? <CollectedItemInfo>[])
        .forSource(mediaType, source);
  }

  void _navigateToItemDetail(CollectedItemInfo info) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ItemDetailScreen(
          collectionId: info.collectionId,
          itemId: info.recordId,
          isEditable: true,
        ),
      ),
    );
  }

  void _onItemTap(Object item, MediaType mediaType) {
    final BrowseState state = ref.read(browseProvider);
    // A source-specific handler override only makes sense while one provider
    // answers; with several, the item's own model carries its source.
    _handlers.onTap(
      context,
      item,
      mediaType,
      sourceId: state.isSingleSource ? state.activeSources.first.id : null,
    );
  }

  void _showDiscoverCustomizeSheet() {
    final Size screenSize = MediaQuery.sizeOf(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      constraints: BoxConstraints(
        maxWidth: screenSize.width,
        maxHeight: screenSize.height * 0.85,
      ),
      builder: (BuildContext _) => DiscoverCustomizeSheet(
        mediaType: ref.read(browseProvider).mediaType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BrowseState browseState = ref.watch(browseProvider);

    ref.listen<String>(searchTabQueryProvider, (String? prev, String next) {
      _onQueryChanged(next);
    });

    final Widget body = Column(
      children: <Widget>[
        FilterBar(
          onBeforeFilterChange: _syncSearchText,
          onDiscoverCustomize: _showDiscoverCustomizeSheet,
        ),
        if (!isCompactScreen(context)) const SourceChipsRow(),
        const CollectionChipsRow(),
        const SizedBox(height: AppSpacing.xs),
        Expanded(child: _buildContent(browseState)),
      ],
    );

    return body;
  }

  Widget _buildContent(BrowseState browseState) {
    if (!browseState.hasActiveQuery) {
      if (browseState.mediaType == MediaType.audio) {
        return AudioDiscoverFeed(
          onItemTap: (AudioItem album) =>
              _handlers.onTap(context, album, MediaType.audio),
        );
      }
      if (discoverMediaTypes.contains(browseState.mediaType)) {
        final MediaType outputMediaType = browseState.mediaType;
        return DiscoverFeed(
          mediaType: outputMediaType,
          onAddMovie: (Movie movie) => _handlers.addToAnyCollection(
            context,
            movie,
            outputMediaType,
          ),
          onAddTvShow: (TvShow tvShow) => _handlers.addToAnyCollection(
            context,
            tvShow,
            outputMediaType,
          ),
        );
      }
      return _buildEmptyFilterState();
    }

    // One provider answering means one honest order, so the flat grid stays.
    // Several answer per source instead — see the ADR in the layout widgets.
    if (browseState.activeSources.length <= 1) {
      return BrowseGrid(
        onItemTap: _onItemTap,
        onOpenInCollection: _openItemInCollection,
        platformMap: _platformMap,
      );
    }

    if (isCompactScreen(context)) {
      return BrowseSectionsCompact(
        onItemTap: _onItemTap,
        onOpenInCollection: _openItemInCollection,
        platformMap: _platformMap,
      );
    }

    return BrowseSections(
      onItemTap: _onItemTap,
      onOpenInCollection: _openItemInCollection,
      platformMap: _platformMap,
    );
  }

  Widget _buildEmptyFilterState() {
    final S l = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.filter_alt_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.browseEmptyFilters,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
