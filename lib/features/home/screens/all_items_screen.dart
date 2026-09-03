import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/constants/collection_item_ui.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/item_card_progress.dart';
import '../../../shared/utils/media_format.dart';
import '../../../shared/utils/poster_grid_delegate.dart';
import '../../../shared/utils/url_launch.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../../../shared/widgets/filter_subfilter_bar.dart';
import '../../../shared/widgets/logo_loader.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/uncategorized_deprecation_banner.dart';
import '../../collections/helpers/collection_actions.dart';
import '../../collections/helpers/tracker_card_progress.dart';
import '../../collections/providers/all_items_selection_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/extensions/item_display_name.dart';
import '../../collections/screens/collection_screen.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../../collections/widgets/bulk_action_bar.dart';
import '../../collections/widgets/selectable_poster_card.dart';
import '../../collections/widgets/context_menu_item.dart';
import '../../collections/widgets/status_chip_row.dart';
import '../providers/all_items_provider.dart';
import '../../collections/providers/item_tags_provider.dart';
import '../../../shared/constants/platform_ui.dart';

/// Grid of all items across all collections (Home tab). The platforms
/// filter row appears only while Games is selected.
class AllItemsScreen extends ConsumerStatefulWidget {
  const AllItemsScreen({super.key});

  @override
  ConsumerState<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends ConsumerState<AllItemsScreen> {
  final Set<MediaType> _selectedTypes = <MediaType>{};
  final Set<int> _selectedPlatformIds = <int>{};
  final Set<String> _selectedMangaFormats = <String>{};
  final Set<String> _selectedAnimeFormats = <String>{};

  /// Below this width the segments show icons instead of text.
  static const double _compactBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(visibleAllItemsProvider);
    // Hiding a collection mid-selection would leave ids of now invisible
    // items in the set.
    ref.listen<Set<int>>(
      hiddenCollectionIdsProvider,
      (Set<int>? previous, Set<int> next) =>
          ref.read(allItemsSelectionProvider.notifier).clear(),
    );
    final Map<int, String> collectionNames =
        ref.watch(collectionNamesProvider);
    final Map<int, Tag> tagsMap = ref.watch(allTagsMapProvider);
    final Map<int, List<int>> itemTags =
        ref.watch(itemTagsProvider).valueOrNull ?? <int, List<int>>{};
    final Set<ItemStatus> filterStatuses =
        ref.watch(homeStatusFilterProvider);
    final bool favoriteOnly = ref.watch(homeFavoriteFilterProvider);
    final String searchQuery = ref.watch(homeSearchQueryProvider);

    final List<CollectionItem> allItems =
        itemsAsync.valueOrNull ?? const <CollectionItem>[];
    final List<CollectionItem> visibleItems =
        _applyFilter(
            allItems, filterStatuses, favoriteOnly, tagsMap, searchQuery);

    return Column(
      children: <Widget>[
        _buildMediaTypeBar(
            itemsAsync, filterStatuses, favoriteOnly, tagsMap, searchQuery),
        SubfilterBar(groups: _subfilterGroups(itemsAsync)),
        _AllItemsBulkBar(allItems: allItems, visibleItems: visibleItems),
        Expanded(
          child: itemsAsync.when(
            data: (List<CollectionItem> items) {
              if (visibleItems.isEmpty) {
                return _buildEmptyState(items.isEmpty);
              }
              return _buildGridView(
                  visibleItems, collectionNames, tagsMap, itemTags);
            },
            loading: () => const Center(child: LogoLoader()),
            error: (Object error, StackTrace stack) =>
                _buildErrorState(error),
          ),
        ),
      ],
    );
  }

  List<CollectionItem> _applyFilter(
    List<CollectionItem> items,
    Set<ItemStatus> filterStatuses,
    bool favoriteOnly,
    Map<int, Tag> tagsMap,
    String searchQuery,
  ) {
    final String query = searchQuery.toLowerCase();
    final String lang =
        ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
    return items
        .where((CollectionItem item) =>
            (_selectedTypes.isEmpty ||
                item.matchesTypeFilter(_selectedTypes)) &&
            _matchesNonTypeFilters(
                item, filterStatuses, favoriteOnly, tagsMap, query, lang))
        .toList();
  }

  bool _matchesNonTypeFilters(
    CollectionItem item,
    Set<ItemStatus> filterStatuses,
    bool favoriteOnly,
    Map<int, Tag> tagsMap,
    String lowerQuery,
    String animeMangaTitleLanguage,
  ) {
    if (favoriteOnly && !item.isFavorite) return false;
    if (filterStatuses.isNotEmpty && !filterStatuses.contains(item.status)) {
      return false;
    }
    if (!MediaFormat.matchesSubfilters(
      item,
      platformIds: _selectedPlatformIds,
      mangaFormats: _selectedMangaFormats,
      animeFormats: _selectedAnimeFormats,
    )) {
      return false;
    }
    if (lowerQuery.isNotEmpty) {
      final bool match = item
              .displayName(animeMangaTitleLanguage)
              .toLowerCase()
              .contains(lowerQuery) ||
          _matchesTagName(item, tagsMap, lowerQuery) ||
          (item.userComment?.toLowerCase().contains(lowerQuery) ?? false) ||
          (item.authorComment?.toLowerCase().contains(lowerQuery) ?? false) ||
          _matchesCreator(item, lowerQuery);
      if (!match) return false;
    }
    return true;
  }

  /// Albums also match by artist, books by author — "pink floyd" should find
  /// the album even though the query is not in its title.
  static bool _matchesCreator(CollectionItem item, String lowerQuery) {
    final List<String> creators = switch (item.mediaType) {
      MediaType.audio => item.audioItem?.artists ?? const <String>[],
      MediaType.book => item.book?.authors ?? const <String>[],
      _ => const <String>[],
    };
    return creators
        .any((String name) => name.toLowerCase().contains(lowerQuery));
  }

  /// Chevron bar: media types (multi-select) plus the status dropdown as
  /// the last segment.
  Widget _buildMediaTypeBar(
    AsyncValue<List<CollectionItem>> itemsAsync,
    Set<ItemStatus> filterStatuses,
    bool favoriteOnly,
    Map<int, Tag> tagsMap,
    String searchQuery,
  ) {
    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    final Map<MediaType, int> counts = _countByMediaType(
        items, filterStatuses, favoriteOnly, tagsMap, searchQuery);
    final Map<MediaType, int> totals = _rawTotalsByMediaType(items);
    final S l = S.of(context);

    final List<_MediaTypeEntry> entries = <_MediaTypeEntry>[
      _MediaTypeEntry(
        type: MediaType.game,
        label: l.collectionFilterGames,
        count: counts[MediaType.game] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.movie,
        label: l.collectionFilterMovies,
        count: counts[MediaType.movie] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.tvShow,
        label: l.collectionFilterTvShows,
        count: counts[MediaType.tvShow] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.animation,
        label: l.mediaTypeAnimation,
        count: counts[MediaType.animation] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.visualNovel,
        label: l.collectionFilterVisualNovels,
        count: counts[MediaType.visualNovel] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.manga,
        label: l.mediaTypeManga,
        count: counts[MediaType.manga] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.anime,
        label: l.mediaTypeAnime,
        count: counts[MediaType.anime] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.book,
        label: l.collectionFilterBooks,
        count: counts[MediaType.book] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.audio,
        label: l.mediaTypeAudio,
        count: counts[MediaType.audio] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.custom,
        label: l.mediaTypeCustom,
        count: counts[MediaType.custom] ?? 0,
      ),
    ];

    final bool compact =
        MediaQuery.sizeOf(context).width < _compactBreakpoint;
    final bool hideEmpty = ref.watch(
      settingsNotifierProvider.select(
        (SettingsState s) => s.hideEmptyMediaTypeChevrons,
      ),
    );
    final List<_MediaTypeEntry> visibleEntries =
        (hideEmpty && items != null)
            ? entries
                .where((_MediaTypeEntry e) =>
                    (totals[e.type] ?? 0) > 0 ||
                    _selectedTypes.contains(e.type))
                .toList()
            : entries;

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < visibleEntries.length; i++)
              Expanded(
                child: ChevronSegment(
                  label: visibleEntries[i].displayLabel,
                  icon: MediaTypeTheme.iconFor(visibleEntries[i].type),
                  selected: _selectedTypes.contains(visibleEntries[i].type),
                  accentColor:
                      MediaTypeTheme.colorFor(visibleEntries[i].type),
                  isFirst: i == 0,
                  isLast: false,
                  onTap: () => _toggleMediaType(visibleEntries[i].type),
                  compact: compact,
                  tintWhenInactive: true,
                ),
              ),
            Expanded(
              child: StatusDropdownSegment(
                statuses: filterStatuses,
                compact: compact,
                subtitle: l.status,
                isLast: false,
                onChanged: (Set<ItemStatus> s) =>
                    ref.read(homeStatusFilterProvider.notifier).setFilter(s),
              ),
            ),
            Expanded(
              child: ChevronSegment(
                label: l.favorite,
                icon: Icons.favorite,
                selected: favoriteOnly,
                accentColor: AppColors.favorite,
                isFirst: false,
                isLast: true,
                onTap: () =>
                    ref.read(homeFavoriteFilterProvider.notifier).toggle(),
                compact: compact,
                tintWhenInactive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A group appears only once its media-type chevron is selected; the
  /// "always show subcategories" setting shows every group upfront.
  List<List<SubfilterChipData>> _subfilterGroups(
    AsyncValue<List<CollectionItem>> itemsAsync,
  ) {
    final List<CollectionItem> items =
        itemsAsync.valueOrNull ?? const <CollectionItem>[];
    final bool alwaysShow = ref.watch(
      settingsNotifierProvider.select(
        (SettingsState s) => s.alwaysShowSubcategories,
      ),
    );
    return <List<SubfilterChipData>>[
      if (alwaysShow || _selectedTypes.contains(MediaType.game))
        <SubfilterChipData>[
          for (final Platform p
              in ref.watch(allItemsPlatformsProvider).valueOrNull ??
                  const <Platform>[])
            SubfilterChipData(
              label: p.displayName,
              accent: MediaTypeTheme.colorFor(MediaType.game),
              selected: _selectedPlatformIds.contains(p.id),
              onTap: () => setState(() {
                if (_selectedPlatformIds.contains(p.id)) {
                  _selectedPlatformIds.remove(p.id);
                } else {
                  _selectedPlatformIds.add(p.id);
                }
              }),
            ),
        ],
      _formatGroup(MediaType.manga, _selectedMangaFormats, items,
          alwaysShow: alwaysShow),
      _formatGroup(MediaType.anime, _selectedAnimeFormats, items,
          alwaysShow: alwaysShow),
    ];
  }

  List<SubfilterChipData> _formatGroup(
    MediaType type,
    Set<String> selected,
    List<CollectionItem> items, {
    required bool alwaysShow,
  }) {
    if (!alwaysShow && !_selectedTypes.contains(type)) {
      return const <SubfilterChipData>[];
    }
    return <SubfilterChipData>[
      for (final String code in MediaFormat.present(items, type))
        SubfilterChipData(
          label: MediaFormat.label(type, code),
          accent: MediaTypeTheme.colorFor(type),
          selected: selected.contains(code),
          onTap: () => setState(() {
            if (selected.contains(code)) {
              selected.remove(code);
            } else {
              selected.add(code);
            }
          }),
        ),
    ];
  }

  void _toggleMediaType(MediaType type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
      if (!_selectedTypes.contains(MediaType.game)) {
        _selectedPlatformIds.clear();
      }
      if (!_selectedTypes.contains(MediaType.manga)) {
        _selectedMangaFormats.clear();
      }
      if (!_selectedTypes.contains(MediaType.anime)) {
        _selectedAnimeFormats.clear();
      }
    });
  }

  /// Ignores every filter: search hits change the chevron label but must not
  /// hide non-matching media types when "Hide empty" is on.
  static Map<MediaType, int> _rawTotalsByMediaType(
    List<CollectionItem>? items,
  ) {
    if (items == null) return const <MediaType, int>{};
    final Map<MediaType, int> totals = <MediaType, int>{};
    for (final CollectionItem item in items) {
      for (final MediaType bucket in item.filterTypeBuckets) {
        totals[bucket] = (totals[bucket] ?? 0) + 1;
      }
    }
    return totals;
  }

  /// True when any of the item's tags matches the search query.
  bool _matchesTagName(
    CollectionItem item,
    Map<int, Tag> tagsMap,
    String lowerQuery,
  ) {
    final List<int>? ids = ref.read(itemTagsProvider).valueOrNull?[item.id];
    if (ids == null) return false;
    return ids.any((int id) =>
        tagsMap[id]?.name.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Applies every active filter except the media-type one, so each chevron
  /// shows how many items would be visible if the user picked it.
  Map<MediaType, int> _countByMediaType(
    List<CollectionItem>? items,
    Set<ItemStatus> filterStatuses,
    bool favoriteOnly,
    Map<int, Tag> tagsMap,
    String searchQuery,
  ) {
    if (items == null) return <MediaType, int>{};
    final String lower = searchQuery.toLowerCase();
    final String lang =
        ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
    final Map<MediaType, int> counts = <MediaType, int>{};
    for (final CollectionItem item in items) {
      if (!_matchesNonTypeFilters(
          item, filterStatuses, favoriteOnly, tagsMap, lower, lang)) {
        continue;
      }
      for (final MediaType bucket in item.filterTypeBuckets) {
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _buildGridView(
    List<CollectionItem> items,
    Map<int, String> collectionNames,
    Map<int, Tag> tagsMap,
    Map<int, List<int>> itemTags,
  ) {
    // getAll() returns display order, and the map preserves insertion order.
    final List<Tag> orderedTags = tagsMap.values.toList();
    final bool isLandscape = isLandscapeMobile(context);
    final double cardScale = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.cardScale),
    );
    final ({SliverGridDelegate delegate, double padding}) geometry =
        posterGridGeometry(context, cardScale: cardScale);
    final SliverGridDelegate gridDelegate = geometry.delegate;
    final double gridPadding = geometry.padding;

    final List<_CollectionGroup> groups =
        _groupByCollection(items, collectionNames, S.of(context).collectionsUncategorized);
    final bool selectionActive = ref.watch(
      allItemsSelectionProvider.select((Set<int> s) => s.isNotEmpty),
    );

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(allItemsNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: <Widget>[
          for (int i = 0; i < groups.length; i++) ...<Widget>[
            SliverToBoxAdapter(
              child: _buildCollectionDivider(
                groups[i],
                isFirst: i == 0,
                selectionActive: selectionActive,
              ),
            ),
            if (groups[i].isUncategorized)
              const SliverToBoxAdapter(
                child: UncategorizedDeprecationBanner(),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gridPadding,
                AppSpacing.sm,
                gridPadding,
                0,
              ),
              sliver: SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final CollectionItem item = groups[i].items[index];
                    final List<int>? tagIds = itemTags[item.id];
                    return _AllItemsCard(
                      key: ValueKey<int>(item.id),
                      item: item,
                      variant: isLandscape ||
                              isCompactScreen(context)
                          ? CardVariant.compact
                          : CardVariant.grid,
                      tag: orderedTags.primaryFor(tagIds),
                      tagCount: tagIds?.length ?? 0,
                      onShowDetails: () =>
                          _showItemDetails(item, collectionNames),
                      onShowContextMenu: (Offset pos) =>
                          _showItemContextMenu(pos, item),
                    );
                  },
                  childCount: groups[i].items.length,
                ),
              ),
            ),
            if (i < groups.length - 1)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.sm),
              ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),
        ],
      ),
    );
  }

  static List<_CollectionGroup> _groupByCollection(
    List<CollectionItem> items,
    Map<int, String> collectionNames,
    String uncategorizedLabel,
  ) {
    final Map<int?, _CollectionGroup> map = <int?, _CollectionGroup>{};
    final List<int?> order = <int?>[];
    for (final CollectionItem item in items) {
      final int? colId = item.collectionId;
      final _CollectionGroup? existing = map[colId];
      if (existing == null) {
        final String name = colId != null
            ? (collectionNames[colId] ?? 'Unknown')
            : uncategorizedLabel;
        final _CollectionGroup group = _CollectionGroup(
          collectionId: colId,
          name: name,
          items: <CollectionItem>[item],
          isUncategorized: colId == null,
        );
        map[colId] = group;
        order.add(colId);
      } else {
        existing.items.add(item);
      }
    }
    return <_CollectionGroup>[
      for (final int? id in order)
        if (map[id] case final _CollectionGroup g) g,
    ];
  }

  Widget _buildCollectionDivider(
    _CollectionGroup group, {
    required bool isFirst,
    required bool selectionActive,
  }) {
    final Color accent =
        group.isUncategorized ? AppColors.textTertiary : AppColors.brand;

    // A phone has room for the name or the tallies, not both: the chips crowd
    // the title into an ellipsis and stop being readable anyway.
    final List<Widget> tallies =
        kIsMobile ? const <Widget>[] : _headerTallies(group.items);

    // Wrap, not Row: a long name plus a tally per media type overflows a
    // narrow window — the name ellipsizes and the chips flow to the next line.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        isFirst ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppSpacing.xs,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: _CollectionGroupTitle(
                  name: group.name,
                  accent: accent,
                  // Leaving the screen mid-selection would drop the picks.
                  onTap: selectionActive
                      ? null
                      : () => _openCollection(group.collectionId),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${group.items.length}',
                style: AppTypography.body.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          ...tallies,
        ],
      ),
    );
  }

  List<Widget> _headerTallies(List<CollectionItem> items) {
    final Map<MediaType, int> typeCounts = <MediaType, int>{};
    int favorites = 0;
    for (final CollectionItem item in items) {
      final MediaType t = item.displayMediaType;
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
      if (item.isFavorite) favorites++;
    }
    // Enum order, so the tallies keep the order the type chevrons have.
    final Map<MediaType, int> ordered = <MediaType, int>{
      for (final MediaType t in MediaType.values)
        if (typeCounts.containsKey(t)) t: typeCounts[t]!,
    };
    return _headerInfo(ordered, favorites);
  }

  /// Each tally is one self-contained chip so it never splits when the
  /// header wraps.
  List<Widget> _headerInfo(Map<MediaType, int> typeCounts, int favorites) {
    const double iconSize = 20;

    Widget tally(IconData icon, Color color, String text, double size) {
      return Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: size, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return <Widget>[
      for (final MapEntry<MediaType, int> e in typeCounts.entries)
        tally(
          MediaTypeTheme.iconFor(e.key),
          MediaTypeTheme.colorFor(e.key).withAlpha(220),
          '${e.value}',
          iconSize,
        ),
      if (favorites > 0)
        tally(
          Icons.favorite,
          AppColors.favorite,
          '$favorites',
          iconSize - 2,
        ),
    ];
  }

  Widget _buildEmptyState(bool noItemsAtAll) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            noItemsAtAll ? Icons.inbox_outlined : Icons.filter_list_off,
            size: 64,
            color: AppColors.textTertiary.withAlpha(120),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            noItemsAtAll
                ? S.of(context).allItemsNoItems
                : S.of(context).allItemsNoMatch,
            style: AppTypography.h2.copyWith(color: AppColors.textTertiary),
          ),
          if (noItemsAtAll) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.of(context).allItemsAddViaCollections,
              textAlign: TextAlign.center,
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            S.of(context).allItemsFailedToLoad,
            style: AppTypography.h2.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () =>
                ref.read(allItemsNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(S.of(context).retry),
          ),
        ],
      ),
    );
  }

  bool _isItemEditable(CollectionItem item) {
    if (item.isUncategorized) return true;
    final List<Collection>? collections =
        ref.read(collectionsProvider).valueOrNull;
    final Collection? collection =
        collections?.cast<Collection?>().firstWhere(
      (Collection? c) => c?.id == item.collectionId,
      orElse: () => null,
    );
    return collection?.isEditable ?? false;
  }

  Future<void> _showItemContextMenu(Offset position, CollectionItem item) async {
    if (!_isItemEditable(item)) return;
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        contextMenuItem<String>(
          value: 'favorite',
          icon: item.isFavorite ? Icons.favorite : Icons.favorite_border,
          label: item.isFavorite ? l.removeFromFavorites : l.addToFavorites,
        ),
        const PopupMenuDivider(),
        contextMenuItem<String>(
          value: 'move',
          icon: Icons.drive_file_move_outlined,
          label: l.collectionMoveToCollection,
        ),
        contextMenuItem<String>(
          value: 'clone',
          icon: Icons.copy_outlined,
          label: l.collectionCopyToCollection,
        ),
        contextMenuItem<String>(
          value: 'copyLink',
          icon: Icons.link,
          label: l.cardLinkCopy,
        ),
        const PopupMenuDivider(),
        contextMenuItem<String>(
          value: 'remove',
          icon: Icons.remove_circle_outline,
          label: l.remove,
          color: AppColors.error,
        ),
        ...statusChipPopupMenuEntries(context: context, item: item),
      ],
    );

    if (value == null || !mounted) return;
    final ItemStatus? newStatus = tryDecodeStatusMenuValue(value);
    if (newStatus != null) {
      if (newStatus != item.status) {
        await ref
            .read(collectionItemsNotifierProvider(item.collectionId).notifier)
            .updateStatus(item.id, newStatus, item.mediaType);
      }
      return;
    }
    switch (value) {
      case 'favorite':
        await ref.read(allItemsNotifierProvider.notifier).toggleFavorite(item.id);
      case 'move':
        await CollectionActions.moveItem(
          context: context,
          ref: ref,
          collectionId: item.collectionId,
          item: item,
        );
      case 'clone':
        await CollectionActions.cloneItem(
          context: context,
          ref: ref,
          collectionId: item.collectionId,
          item: item,
        );
      case 'copyLink':
        if (mounted) CollectionActions.copyItemLink(context, item);
      case 'remove':
        await CollectionActions.removeItem(
          context: context,
          ref: ref,
          collectionId: item.collectionId,
          item: item,
        );
    }
  }

  void _openCollection(int? collectionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CollectionScreen(collectionId: collectionId),
      ),
    );
  }

  void _showItemDetails(
    CollectionItem item,
    Map<int, String> collectionNames,
  ) {
    final bool isEditable = _isItemEditable(item);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ItemDetailScreen(
          collectionId: item.collectionId,
          itemId: item.id,
          isEditable: isEditable,
        ),
      ),
    );
  }

  static int? _yearFor(CollectionItem item) {
    switch (item.mediaType) {
      case MediaType.game:
        return item.game?.releaseYear;
      case MediaType.movie:
        return item.movie?.releaseYear;
      case MediaType.tvShow:
        return item.tvShow?.firstAirYear;
      case MediaType.animation:
        if (item.platformId == AnimationSource.tvShow) {
          return item.tvShow?.firstAirYear;
        }
        return item.movie?.releaseYear;
      case MediaType.visualNovel:
        return item.visualNovel?.releaseYear;
      case MediaType.manga:
        return item.manga?.releaseYear;
      case MediaType.anime:
        return item.anime?.releaseYear;
      case MediaType.book:
        return item.book?.releaseYear;
      case MediaType.audio:
        return item.audioItem?.releaseYear;
      case MediaType.custom:
        return item.customMedia?.year;
    }
  }

  static ImageType _imageTypeFor(MediaType mediaType, int? platformId) {
    switch (mediaType) {
      case MediaType.game:
        return ImageType.gameCover;
      case MediaType.movie:
        return ImageType.moviePoster;
      case MediaType.tvShow:
        return ImageType.tvShowPoster;
      case MediaType.animation:
        if (platformId == AnimationSource.tvShow) {
          return ImageType.tvShowPoster;
        }
        return ImageType.moviePoster;
      case MediaType.visualNovel:
        return ImageType.vnCover;
      case MediaType.manga:
        return ImageType.mangaCover;
      case MediaType.anime:
        return ImageType.animeCover;
      case MediaType.book:
        return ImageType.bookCover;
      case MediaType.audio:
        return ImageType.audioCover;
      case MediaType.custom:
        return ImageType.customCover;
    }
  }
}

class _MediaTypeEntry {
  const _MediaTypeEntry({
    required this.type,
    required this.label,
    required this.count,
  });

  final MediaType type;
  final String label;
  final int count;

  String get displayLabel => count > 0 ? '$label ($count)' : label;
}

/// Underlined group name; tappable when it leads to a collection screen.
class _CollectionGroupTitle extends StatelessWidget {
  const _CollectionGroupTitle({
    required this.name,
    required this.accent,
    required this.onTap,
  });

  final String name;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget label = Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: accent, width: 3)),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    if (onTap == null) return label;
    return Tooltip(
      message: S.of(context).openCollection,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: label,
      ),
    );
  }
}

class _CollectionGroup {
  _CollectionGroup({
    required this.collectionId,
    required this.name,
    required this.items,
    this.isUncategorized = false,
  });

  /// Null for the uncategorized group, which CollectionScreen also takes.
  final int? collectionId;
  final String name;
  final List<CollectionItem> items;
  final bool isUncategorized;
}

/// Watches the selection itself so a toggle never rebuilds the screen
/// (and its O(n) grouping) — only the bar.
class _AllItemsBulkBar extends ConsumerWidget {
  const _AllItemsBulkBar({
    required this.allItems,
    required this.visibleItems,
  });

  final List<CollectionItem> allItems;
  final List<CollectionItem> visibleItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<int> selection = ref.watch(allItemsSelectionProvider);
    if (selection.isEmpty) return const SizedBox.shrink();
    final List<CollectionItem> selectedItems = <CollectionItem>[
      for (final CollectionItem i in allItems)
        if (selection.contains(i.id)) i,
    ];
    return BulkActionBar(
      items: selectedItems,
      visibleCount: visibleItems.length,
      onSelectAllVisible: () => ref
          .read(allItemsSelectionProvider.notifier)
          .selectAll(visibleItems.map((CollectionItem i) => i.id)),
      onClearSelection: () =>
          ref.read(allItemsSelectionProvider.notifier).clear(),
    );
  }
}

/// Scopes selection/settings/tracker watches to one card: bool-valued
/// `select`s rebuild only the card whose value actually changed.
class _AllItemsCard extends ConsumerWidget {
  const _AllItemsCard({
    required this.item,
    required this.variant,
    required this.tag,
    required this.tagCount,
    required this.onShowDetails,
    required this.onShowContextMenu,
    super.key,
  });

  final CollectionItem item;
  final CardVariant variant;
  final Tag? tag;
  final int tagCount;
  final VoidCallback onShowDetails;
  final void Function(Offset position) onShowContextMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = ref.watch(
      allItemsSelectionProvider.select((Set<int> s) => s.contains(item.id)),
    );
    final bool selectionActive = ref.watch(
      allItemsSelectionProvider.select((Set<int> s) => s.isNotEmpty),
    );
    final String? overlayAsset = ref.watch(
      settingsNotifierProvider.select(
        (SettingsState s) => s.resolveOverlay(
          platformOverlay: item.platform?.overlayAsset,
          mediaTypeOverlay: item.mediaType.overlayAsset,
        ),
      ),
    );
    final ItemCardProgress? progress =
        itemCardProgress(item) ?? trackerCardProgress(ref, item);
    void toggle() =>
        ref.read(allItemsSelectionProvider.notifier).toggle(item.id);
    return RepaintBoundary(
      child: SelectablePosterCard(
        isSelected: isSelected,
        selectionActive: selectionActive,
        onToggleSelect: toggle,
        child: MediaPosterCard(
          variant: variant,
          title: item.cardTitle(ref.displayNameOf(item)),
          imageUrl: item.thumbnailUrl ?? '',
          cacheImageType: _AllItemsScreenState._imageTypeFor(
            item.mediaType,
            item.platformId,
          ),
          cacheImageId: item.coverImageId,
          userRating: item.userRating,
          apiRating: item.apiRating,
          splitRatings: true,
          year: _AllItemsScreenState._yearFor(item),
          platformLabel: item.platform?.displayName,
          platformColor: item.platform?.familyColor,
          platformOverlayAsset: overlayAsset,
          mediaType: item.displayMediaType,
          typeLabelOverride: item.formatLabel,
          status: item.status,
          progress: progress,
          isFavorite: item.isFavorite,
          showFavorite: true,
          enableHoverScale: !isSelected,
          onToggleFavorite: selectionActive
              ? null
              : () => ref
                  .read(allItemsNotifierProvider.notifier)
                  .toggleFavorite(item.id),
          tagName: tag?.name,
          tagColor: tag?.color,
          tagTextColor: tag?.textColor,
          tagMoreCount: tagCount > 1 ? tagCount - 1 : 0,
          source: item.dataSource,
          onSourceTap: openUrlCallback(item.externalUrl),
          onTap: selectionActive ? toggle : onShowDetails,
          onSecondaryTap: onShowContextMenu,
          onLongPress: toggle,
        ),
      ),
    );
  }
}
