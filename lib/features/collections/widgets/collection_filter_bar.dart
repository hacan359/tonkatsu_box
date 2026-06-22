import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/utils/media_format.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../../../shared/widgets/filter_subfilter_bar.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/collections_provider.dart';
import 'collection_filter_sheet.dart';

class CollectionFilterBar extends ConsumerStatefulWidget {
  const CollectionFilterBar({
    required this.collectionId,
    required this.statsAsync,
    required this.itemsAsync,
    required this.filterTypes,
    required this.filterPlatformIds,
    required this.filterMangaFormats,
    required this.filterAnimeFormats,
    required this.filterTagIds,
    required this.filterStatus,
    this.effectiveStatusForCounts,
    required this.tags,
    this.searchQuery = '',
    required this.onTypeToggled,
    required this.onPlatformToggled,
    required this.onMangaFormatToggled,
    required this.onAnimeFormatToggled,
    required this.onTagToggled,
    required this.onStatusChanged,
    required this.onGroupToggled,
    this.groupByTags = false,
    super.key,
  });

  /// `null` means the uncategorized collection.
  final int? collectionId;

  final AsyncValue<CollectionStats> statsAsync;

  final AsyncValue<List<CollectionItem>> itemsAsync;

  final Set<MediaType> filterTypes;

  final Set<int> filterPlatformIds;

  /// Active manga `format` subfilter codes.
  final Set<String> filterMangaFormats;

  /// Active anime `format` subfilter codes.
  final Set<String> filterAnimeFormats;

  final Set<int> filterTagIds;

  final ItemStatus? filterStatus;

  /// Status that drives chevron counts when it diverges from [filterStatus]
  /// (e.g. the table column header cycled a local filter). Falls back to
  /// [filterStatus] when null.
  final ItemStatus? effectiveStatusForCounts;

  final List<CollectionTag> tags;

  /// Current search query (coming from the global top bar).
  final String searchQuery;

  final ValueChanged<MediaType?> onTypeToggled;

  final ValueChanged<int?> onPlatformToggled;

  final ValueChanged<String?> onMangaFormatToggled;

  final ValueChanged<String?> onAnimeFormatToggled;

  final ValueChanged<int?> onTagToggled;

  final ValueChanged<ItemStatus?> onStatusChanged;

  final VoidCallback onGroupToggled;

  final bool groupByTags;

  @override
  ConsumerState<CollectionFilterBar> createState() =>
      _CollectionFilterBarState();
}

class _CollectionFilterBarState extends ConsumerState<CollectionFilterBar> {
  /// Below this width segments show icons instead of text labels.
  static const double _compactBreakpoint = 700;

  /// Cached platform list, recomputed only when the identity of the
  /// items list (AsyncValue.value) changes.
  List<Platform>? _cachedPlatforms;
  List<CollectionItem>? _cachedPlatformsSource;

  /// Cached manga/anime format lists, invalidated on items-list identity.
  List<CollectionItem>? _cachedFormatsSource;
  List<String>? _cachedMangaFormats;
  List<String>? _cachedAnimeFormats;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final CollectionStats? stats = widget.statsAsync.valueOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildTypeChevronBar(l, stats),
        SubfilterBar(groups: _subfilterGroups()),
      ],
    );
  }

  /// One subfilter group per active type — game platforms, manga formats,
  /// anime formats — each tinted with its media-type accent.
  List<List<SubfilterChipData>> _subfilterGroups() {
    return <List<SubfilterChipData>>[
      if (widget.filterTypes.contains(MediaType.game))
        <SubfilterChipData>[
          for (final Platform p in _extractPlatforms())
            SubfilterChipData(
              label: p.displayName,
              accent: MediaTypeTheme.colorFor(MediaType.game),
              selected: widget.filterPlatformIds.contains(p.id),
              onTap: () => widget.onPlatformToggled(p.id),
            ),
        ],
      _formatGroup(
        MediaType.manga,
        widget.filterMangaFormats,
        widget.onMangaFormatToggled,
      ),
      _formatGroup(
        MediaType.anime,
        widget.filterAnimeFormats,
        widget.onAnimeFormatToggled,
      ),
    ];
  }

  List<SubfilterChipData> _formatGroup(
    MediaType type,
    Set<String> selected,
    ValueChanged<String?> onToggled,
  ) {
    if (!widget.filterTypes.contains(type)) return const <SubfilterChipData>[];
    return <SubfilterChipData>[
      for (final String code in _formatsFor(type))
        SubfilterChipData(
          label: MediaFormat.label(type, code),
          accent: MediaTypeTheme.colorFor(type),
          selected: selected.contains(code),
          onTap: () => onToggled(code),
        ),
    ];
  }

  Widget _buildTypeChevronBar(S l, CollectionStats? stats) {
    final List<_TypeEntry> entries = _typeEntries(l, stats);
    final bool hideEmpty = ref.watch(
      settingsNotifierProvider.select(
        (SettingsState s) => s.hideEmptyMediaTypeChevrons,
      ),
    );
    final List<_TypeEntry> visibleEntries =
        (hideEmpty && stats != null)
            ? entries
                .where((_TypeEntry e) =>
                    (_totalCountFor(e.type, stats) ?? 0) > 0 ||
                    widget.filterTypes.contains(e.type))
                .toList()
            : entries;
    final bool compact =
        MediaQuery.sizeOf(context).width < _compactBreakpoint;
    // On narrow screens the TagSidebar is hidden, so show a button that
    // opens a sheet with tags and sorting. Wide screens keep the compact
    // sort segment (tags are reachable via the TagSidebar on the right).
    final bool useTagSheetButton = isCompactScreen(context);

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < visibleEntries.length; i++)
              Expanded(
                child: ChevronSegment(
                  label: visibleEntries[i].count != null &&
                          visibleEntries[i].count! > 0
                      ? '${visibleEntries[i].label} (${visibleEntries[i].count})'
                      : visibleEntries[i].label,
                  icon: MediaTypeTheme.iconFor(visibleEntries[i].type),
                  selected:
                      widget.filterTypes.contains(visibleEntries[i].type),
                  accentColor:
                      MediaTypeTheme.colorFor(visibleEntries[i].type),
                  isFirst: i == 0,
                  isLast: false,
                  onTap: () => widget.onTypeToggled(visibleEntries[i].type),
                  compact: compact,
                  tintWhenInactive: true,
                ),
              ),
            Expanded(
              child: StatusDropdownSegment(
                status: widget.filterStatus,
                compact: compact,
                subtitle: l.detailStatus,
                onChanged: widget.onStatusChanged,
              ),
            ),
            if (useTagSheetButton)
              SizedBox(width: 44, child: _buildTagSheetButton(context))
            else
              SizedBox(width: 40, child: _buildSortSegment(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSheetButton(BuildContext context) {
    final bool active = widget.filterTagIds.isNotEmpty;
    final int count = widget.filterTagIds.length;
    return ChevronSegment(
      label: count > 0 ? '$count' : '',
      icon: Icons.tune,
      selected: active,
      accentColor: AppColors.brand,
      isFirst: false,
      isLast: true,
      onTap: () => showCollectionFilterSheet(
        context,
        collectionId: widget.collectionId,
        tags: widget.tags,
        selectedTagIds: widget.filterTagIds,
        groupByTags: widget.groupByTags,
        onTagToggled: widget.onTagToggled,
        onGroupToggled: widget.onGroupToggled,
      ),
      tintWhenInactive: true,
      compact: true,
    );
  }

  List<String> _formatsFor(MediaType type) {
    final List<CollectionItem>? items = widget.itemsAsync.valueOrNull;
    if (items == null) return const <String>[];

    if (!identical(_cachedFormatsSource, items)) {
      _cachedFormatsSource = items;
      _cachedMangaFormats = MediaFormat.present(items, MediaType.manga);
      _cachedAnimeFormats = MediaFormat.present(items, MediaType.anime);
    }
    return (type == MediaType.manga
            ? _cachedMangaFormats
            : _cachedAnimeFormats) ??
        const <String>[];
  }

  Widget _buildSortSegment(BuildContext context) {
    final CollectionSortMode currentSort =
        ref.watch(collectionSortProvider(widget.collectionId));
    final bool isDescending =
        ref.watch(collectionSortDescProvider(widget.collectionId));

    return PopupMenuButton<String>(
      tooltip: S.of(context).collectionFilterSort,
      onSelected: (String value) {
        if (value == 'toggle_direction') {
          ref
              .read(collectionSortDescProvider(widget.collectionId).notifier)
              .toggle();
        } else {
          ref
              .read(collectionSortProvider(widget.collectionId).notifier)
              .setSortMode(CollectionSortMode.fromString(value));
        }
      },
      offset: const Offset(0, 40),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      itemBuilder: (BuildContext ctx) {
        final S sl = S.of(ctx);
        return <PopupMenuEntry<String>>[
          ...CollectionSortMode.values.map(
            (CollectionSortMode mode) => PopupMenuItem<String>(
              value: mode.value,
              height: 36,
              child: Row(
                children: <Widget>[
                  if (mode == currentSort)
                    const Icon(Icons.check, size: 16, color: AppColors.brand)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(mode.localizedDisplayLabel(sl)),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(height: 8),
          PopupMenuItem<String>(
            value: 'toggle_direction',
            height: 36,
            child: Row(
              children: <Widget>[
                Icon(
                  isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(isDescending
                    ? S.of(ctx).collectionFilterDescending
                    : S.of(ctx).collectionFilterAscending),
              ],
            ),
          ),
        ];
      },
      child: ClipPath(
        clipper: const ChevronClipper(
          chevronWidth: ChevronSegment.chevronWidth,
          hasLeftNotch: true,
          hasRightPoint: false,
        ),
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.only(
            left: ChevronSegment.chevronWidth + 1,
            right: 4,
          ),
          child: Center(
            child: Icon(
              isDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  List<Platform> _extractPlatforms() {
    final List<CollectionItem>? items = widget.itemsAsync.valueOrNull;
    if (items == null) return <Platform>[];

    // The cache is valid while the list identity is unchanged: the provider
    // emits a new List on any collection change, so an identity comparison
    // is a correct invalidation check.
    if (identical(_cachedPlatformsSource, items) && _cachedPlatforms != null) {
      return _cachedPlatforms!;
    }

    final Map<int, Platform> map = <int, Platform>{};
    for (final CollectionItem item in items) {
      if (item.mediaType == MediaType.game &&
          item.platformId != null &&
          item.platformId != -1 &&
          item.platform != null) {
        map[item.platformId!] = item.platform!;
      }
    }
    final List<Platform> result = map.values.toList()
      ..sort((Platform a, Platform b) => a.name.compareTo(b.name));

    _cachedPlatformsSource = items;
    _cachedPlatforms = result;
    return result;
  }

  List<_TypeEntry> _typeEntries(S l, CollectionStats? stats) {
    final Map<MediaType, int?> counts = _typeCounts(stats);
    return <_TypeEntry>[
      _TypeEntry(MediaType.game, l.collectionFilterGames, counts[MediaType.game]),
      _TypeEntry(MediaType.movie, l.collectionFilterMovies, counts[MediaType.movie]),
      _TypeEntry(MediaType.tvShow, l.collectionFilterTvShows, counts[MediaType.tvShow]),
      _TypeEntry(MediaType.animation, l.collectionFilterAnimation, counts[MediaType.animation]),
      _TypeEntry(MediaType.visualNovel, l.collectionFilterVisualNovels, counts[MediaType.visualNovel]),
      _TypeEntry(MediaType.manga, l.collectionFilterManga, counts[MediaType.manga]),
      _TypeEntry(MediaType.anime, l.mediaTypeAnime, counts[MediaType.anime]),
      _TypeEntry(MediaType.book, l.collectionFilterBooks, counts[MediaType.book]),
      _TypeEntry(MediaType.custom, l.collectionFilterCustom, counts[MediaType.custom]),
    ];
  }

  Map<MediaType, int?> _typeCounts(CollectionStats? stats) {
    final ItemStatus? statusFilter =
        widget.effectiveStatusForCounts ?? widget.filterStatus;
    if (statusFilter == null) {
      return <MediaType, int?>{
        MediaType.game: stats?.gameCount,
        MediaType.movie: stats?.movieCount,
        MediaType.tvShow: stats?.tvShowCount,
        MediaType.animation: stats?.animationCount,
        MediaType.visualNovel: stats?.visualNovelCount,
        MediaType.manga: stats?.mangaCount,
        MediaType.anime: stats?.animeCount,
        MediaType.book: stats?.bookCount,
        MediaType.custom: stats?.customCount,
      };
    }
    final List<CollectionItem>? items = widget.itemsAsync.valueOrNull;
    if (items == null) {
      return const <MediaType, int?>{};
    }
    final Map<MediaType, int> tally = <MediaType, int>{
      for (final MediaType t in MediaType.values) t: 0,
    };
    for (final CollectionItem item in items) {
      if (item.status == statusFilter) {
        tally[item.mediaType] = tally[item.mediaType]! + 1;
      }
    }
    return tally;
  }
}

class _TypeEntry {
  const _TypeEntry(this.type, this.label, this.count);
  final MediaType type;
  final String label;
  final int? count;
}

int? _totalCountFor(MediaType type, CollectionStats? stats) {
  if (stats == null) return null;
  return switch (type) {
    MediaType.game => stats.gameCount,
    MediaType.movie => stats.movieCount,
    MediaType.tvShow => stats.tvShowCount,
    MediaType.animation => stats.animationCount,
    MediaType.visualNovel => stats.visualNovelCount,
    MediaType.manga => stats.mangaCount,
    MediaType.anime => stats.animeCount,
    MediaType.book => stats.bookCount,
    MediaType.custom => stats.customCount,
  };
}
