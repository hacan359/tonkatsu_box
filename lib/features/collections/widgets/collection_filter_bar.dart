// Панель фильтров и сортировки для CollectionScreen.
//
// Chevron-бар типов медиа + dropdown статуса, платформы при Games,
// сортировка. Desktop-first, мобильный вариант будет позже.

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
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../providers/collections_provider.dart';

/// Панель фильтров и сортировки для CollectionScreen.
///
/// Chevron-бар типов медиа + status dropdown, ChoiceChip платформ
/// (видны при Games), строка сортировки.
class CollectionFilterBar extends ConsumerStatefulWidget {
  /// Создаёт [CollectionFilterBar].
  const CollectionFilterBar({
    required this.collectionId,
    required this.statsAsync,
    required this.itemsAsync,
    required this.filterTypes,
    required this.filterPlatformIds,
    required this.filterTagIds,
    required this.filterStatus,
    required this.tags,
    this.searchQuery = '',
    required this.onTypeToggled,
    required this.onPlatformToggled,
    required this.onTagToggled,
    required this.onStatusChanged,
    required this.onGroupToggled,
    this.groupByTags = false,
    super.key,
  });

  /// ID коллекции (null для uncategorized).
  final int? collectionId;

  /// Статистика коллекции.
  final AsyncValue<CollectionStats> statsAsync;

  /// Элементы коллекции (для извлечения платформ).
  final AsyncValue<List<CollectionItem>> itemsAsync;

  /// Выбранные типы медиа.
  final Set<MediaType> filterTypes;

  /// Выбранные ID платформ.
  final Set<int> filterPlatformIds;

  /// Выбранные ID тегов.
  final Set<int> filterTagIds;

  /// Фильтр по статусу.
  final ItemStatus? filterStatus;

  /// Теги коллекции.
  final List<CollectionTag> tags;

  /// Текущий поисковый запрос (из глобального top bar).
  final String searchQuery;

  /// Callback тоггла типа медиа.
  final ValueChanged<MediaType?> onTypeToggled;

  /// Callback тоггла платформы.
  final ValueChanged<int?> onPlatformToggled;

  /// Callback тоггла тега.
  final ValueChanged<int?> onTagToggled;

  /// Callback изменения статуса.
  final ValueChanged<ItemStatus?> onStatusChanged;

  /// Callback тоггла группировки по тегам.
  final VoidCallback onGroupToggled;

  /// Группировка по тегам.
  final bool groupByTags;

  @override
  ConsumerState<CollectionFilterBar> createState() =>
      _CollectionFilterBarState();
}

class _CollectionFilterBarState extends ConsumerState<CollectionFilterBar> {
  /// Ширина, ниже которой сегменты показывают иконки вместо текста.
  static const double _compactBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final CollectionStats? stats = widget.statsAsync.valueOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildTypeChevronBar(l, stats),
        _buildPlatformChipsRow(),
      ],
    );
  }

  // ===================== Chevron бар типов медиа =====================

  Widget _buildTypeChevronBar(S l, CollectionStats? stats) {
    final List<_TypeEntry> entries = _typeEntries(l, stats);
    final bool compact =
        MediaQuery.sizeOf(context).width < _compactBreakpoint;

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < entries.length; i++)
              Expanded(
                child: ChevronSegment(
                  label: entries[i].count != null && entries[i].count! > 0
                      ? '${entries[i].label} (${entries[i].count})'
                      : entries[i].label,
                  icon: MediaTypeTheme.iconFor(entries[i].type),
                  selected: widget.filterTypes.contains(entries[i].type),
                  accentColor: MediaTypeTheme.colorFor(entries[i].type),
                  isFirst: i == 0,
                  isLast: false,
                  onTap: () => widget.onTypeToggled(entries[i].type),
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
            SizedBox(width: 40, child: _buildSortSegment(context)),
          ],
        ),
      ),
    );
  }

  // ===================== Платформы (ChoiceChip) =====================

  Widget _buildPlatformChipsRow() {
    if (!widget.filterTypes.contains(MediaType.game)) {
      return const SizedBox.shrink();
    }
    final List<Platform> platforms = _extractPlatforms();
    if (platforms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final Platform p in platforms) ...<Widget>[
              _buildPlatformChip(p),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChip(Platform platform) {
    final bool selected = widget.filterPlatformIds.contains(platform.id);
    const Color accentColor = AppColors.brand;

    return ChoiceChip(
      label: Text(
        platform.displayName,
        style: AppTypography.caption.copyWith(
          color: selected ? AppColors.background : AppColors.textTertiary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: accentColor,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? Colors.transparent : accentColor.withAlpha(50),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      onSelected: (bool value) {
        widget.onPlatformToggled(platform.id);
      },
    );
  }

  // ===================== Сортировка (chevron-сегмент) =====================

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

  // ===================== Helpers =====================

  List<Platform> _extractPlatforms() {
    final List<CollectionItem>? items = widget.itemsAsync.valueOrNull;
    if (items == null) return <Platform>[];

    final Map<int, Platform> map = <int, Platform>{};
    for (final CollectionItem item in items) {
      if (item.mediaType == MediaType.game &&
          item.platformId != null &&
          item.platformId != -1 &&
          item.platform != null) {
        map[item.platformId!] = item.platform!;
      }
    }
    return map.values.toList()
      ..sort((Platform a, Platform b) => a.name.compareTo(b.name));
  }

  List<_TypeEntry> _typeEntries(S l, CollectionStats? stats) {
    return <_TypeEntry>[
      _TypeEntry(MediaType.game, l.collectionFilterGames, stats?.gameCount),
      _TypeEntry(MediaType.movie, l.collectionFilterMovies, stats?.movieCount),
      _TypeEntry(MediaType.tvShow, l.collectionFilterTvShows, stats?.tvShowCount),
      _TypeEntry(MediaType.animation, l.collectionFilterAnimation, stats?.animationCount),
      _TypeEntry(MediaType.visualNovel, l.collectionFilterVisualNovels, stats?.visualNovelCount),
      _TypeEntry(MediaType.manga, l.collectionFilterManga, stats?.mangaCount),
      _TypeEntry(MediaType.anime, l.mediaTypeAnime, stats?.animeCount),
      _TypeEntry(MediaType.custom, l.collectionFilterCustom, stats?.customCount),
    ];
  }
}

class _TypeEntry {
  const _TypeEntry(this.type, this.label, this.count);
  final MediaType type;
  final String label;
  final int? count;
}
