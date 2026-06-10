import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../handlers/media_handlers.dart';
import '../providers/browse_provider.dart';
import '../widgets/browse_grid.dart';
import '../widgets/discover_customize_sheet.dart';
import '../widgets/discover_feed.dart';
import '../widgets/filter_bar.dart';

/// Search and browse screen — two modes: Browse (filter bar + Discover/Grid)
/// and Search (query field + results).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    this.onGameSelected,
    this.collectionId,
    this.initialTabIndex,
    this.initialSourceId,
    this.initialQuery,
    this.isPushed = false,
    super.key,
  });

  final void Function(Game game)? onGameSelected;
  final int? collectionId;
  final int? initialTabIndex;
  final String? initialSourceId;
  final String? initialQuery;

  /// When pushed on the root navigator the global [AppTopBar] is hidden,
  /// so the screen draws its own AppBar bound to [searchTabQueryProvider].
  final bool isPushed;

  static const ShortcutGroup shortcutGroup = ShortcutGroup(
    title: 'Поиск',
    entries: <ShortcutEntry>[
      ShortcutEntry(keys: 'Ctrl+F', description: 'Фокус в поле поиска'),
      ShortcutEntry(keys: 'Escape', description: 'Очистить / назад'),
      ShortcutEntry(keys: 'Enter', description: 'Выполнить поиск'),
    ],
  );

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Timer? _searchDebounce;
  TextEditingController? _pushedSearchController;
  Map<int, Platform> _platformMap = <int, Platform>{};
  late final MediaHandlers _handlers;

  @override
  void initState() {
    super.initState();
    _handlers = MediaHandlers(
      ref: ref,
      platformMap: () => _platformMap,
      targetCollectionId: widget.collectionId,
      onGameSelected: widget.onGameSelected,
    );
    _loadPlatforms();

    if (widget.isPushed) {
      final String initial =
          widget.initialQuery ?? ref.read(searchTabQueryProvider);
      _pushedSearchController = TextEditingController(text: initial);
    }

    final String? sourceToSet = widget.initialSourceId ??
        (widget.initialTabIndex == 1 ? 'games' : null);

    if (sourceToSet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(browseProvider.notifier).setSource(sourceToSet);
        if (widget.initialQuery != null &&
            widget.initialQuery!.isNotEmpty) {
          ref.read(searchTabQueryProvider.notifier).state =
              widget.initialQuery!;
          ref.read(browseProvider.notifier).search(widget.initialQuery!);
        }
      });
    } else if (widget.initialQuery != null &&
        widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchTabQueryProvider.notifier).state =
            widget.initialQuery!;
        ref.read(browseProvider.notifier).search(widget.initialQuery!);
      });
    }
  }

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
    _pushedSearchController?.dispose();
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
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(browseProvider.notifier).search(query);
      }
    });
  }

  Future<void> _openItemInCollection(
    int externalId,
    MediaType mediaType,
  ) async {
    final List<CollectedItemInfo> infos = await _getCollectedInfos(
      externalId,
      mediaType,
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
      case MediaType.custom:
        return <CollectedItemInfo>[];
    }
    return collected[externalId] ?? <CollectedItemInfo>[];
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
    final String sourceId = ref.read(browseProvider).sourceId;
    _handlers.onTap(context, item, mediaType, sourceId: sourceId);
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
        sourceId: ref.read(browseProvider).sourceId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BrowseState browseState = ref.watch(browseProvider);

    ref.listen<String>(searchTabQueryProvider, (String? prev, String next) {
      _onQueryChanged(next);
      final TextEditingController? c = _pushedSearchController;
      if (c != null && c.text != next) {
        c.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    final Widget body = Column(
      children: <Widget>[
        FilterBar(
          onBeforeFilterChange: _syncSearchText,
          onDiscoverCustomize: _showDiscoverCustomizeSheet,
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(child: _buildContent(browseState)),
      ],
    );

    if (!widget.isPushed) return body;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _pushedSearchController,
          // Desktop only: on mobile this would pop the soft keyboard before the
          // user taps the field.
          autofocus: !kIsMobile,
          decoration: InputDecoration(
            hintText: S.of(context).appBarSearchHint,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (String value) {
            ref.read(searchTabQueryProvider.notifier).state = value;
          },
        ),
      ),
      body: body,
    );
  }

  Widget _buildContent(BrowseState browseState) {
    if (!browseState.hasActiveQuery) {
      final String sourceId = browseState.sourceId;
      if (sourceId == 'movies' || sourceId == 'tv' || sourceId == 'anime') {
        final MediaType outputMediaType = browseState.source.outputMediaType;
        return DiscoverFeed(
          sourceId: sourceId,
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

    return BrowseGrid(
      onItemTap: _onItemTap,
      onOpenInCollection: _openItemInCollection,
      clientFilter: '',
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
            const Icon(
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
