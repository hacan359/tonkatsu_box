// Табличный (Manifest) вид элементов коллекции.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';

/// Колонка таблицы для сортировки.
enum TableColumn {
  /// Название.
  name,

  /// Тип медиа.
  type,

  /// Платформа (только для игр).
  platform,

  /// Статус.
  status,

  /// Пользовательский рейтинг (1-10).
  rating,

  /// Год выпуска.
  year,

  /// Дата добавления.
  added,
}

/// Табличный вид элементов коллекции.
///
/// Компактные строки с sticky-заголовком, сортировка по клику,
/// цветовая маркировка статусов и hover-подсветка.
class CollectionTableView extends StatefulWidget {
  /// Создаёт [CollectionTableView].
  const CollectionTableView({
    required this.items,
    required this.onItemTap,
    this.onItemSecondaryTap,
    super.key,
  });

  /// Элементы для отображения.
  final List<CollectionItem> items;

  /// Callback нажатия на элемент.
  final ValueChanged<CollectionItem> onItemTap;

  /// Callback правого клика на элемент (координаты + элемент).
  final void Function(CollectionItem item, Offset globalPosition)?
      onItemSecondaryTap;

  @override
  State<CollectionTableView> createState() => _CollectionTableViewState();
}

class _CollectionTableViewState extends State<CollectionTableView> {
  TableColumn _sortColumn = TableColumn.name;
  bool _sortAscending = true;

  // Фильтрация: null = все, иначе — конкретное значение.
  ItemStatus? _filterStatus;
  MediaType? _filterType;
  int? _filterRating;

  @override
  void didUpdateWidget(CollectionTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Сброс фильтров при изменении данных — избегаем stale state.
    if (!identical(oldWidget.items, widget.items)) {
      _filterStatus = null;
      _filterType = null;
      _filterRating = null;
    }
  }

  /// Ширина миниатюры.
  static const double _thumbWidth = 32.0;

  /// Высота миниатюры.
  static const double _thumbHeight = 46.0;

  /// Радиус скругления миниатюры.
  static const double _thumbRadius = 4.0;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<CollectionItem> sorted = _sortedItems();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusMd),
          ),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: <Widget>[
              _TableHeader(
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                onSort: _toggleSort,
                filterStatus: _filterStatus,
                filterType: _filterType,
                filterRating: _filterRating,
                l: l,
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: sorted.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppColors.surfaceBorder,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final CollectionItem item = sorted[index];
                    return _TableRow(
                      key: ValueKey<int>(item.id),
                      item: item,
                      onTap: () => widget.onItemTap(item),
                      onSecondaryTap: widget.onItemSecondaryTap != null
                          ? (Offset pos) =>
                              widget.onItemSecondaryTap!(item, pos)
                          : null,
                      thumbWidth: _thumbWidth,
                      thumbHeight: _thumbHeight,
                      thumbRadius: _thumbRadius,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSort(TableColumn column) {
    setState(() {
      switch (column) {
        case TableColumn.status:
          _filterStatus = _cycleFilter<ItemStatus>(
            _filterStatus,
            widget.items.map((CollectionItem i) => i.status),
          );
        case TableColumn.type:
          _filterType = _cycleFilter<MediaType>(
            _filterType,
            widget.items.map((CollectionItem i) => i.mediaType),
          );
        case TableColumn.rating:
          _filterRating = _cycleFilter<int>(
            _filterRating,
            widget.items.map((CollectionItem i) => i.userRating ?? 0),
          );
        default:
          if (_sortColumn == column) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = column;
            _sortAscending = true;
          }
      }
    });
  }

  /// Циклически переключает фильтр по уникальным значениям.
  /// null → first → next → ... → null (сброс).
  T? _cycleFilter<T>(T? current, Iterable<T> values) {
    final List<T> available = values.toSet().toList();
    if (available.length <= 1) return current;
    if (current == null) return available.first;
    final int idx = available.indexOf(current);
    return idx < available.length - 1 ? available[idx + 1] : null;
  }

  List<CollectionItem> _sortedItems() {
    final bool hasFilter =
        _filterStatus != null || _filterType != null || _filterRating != null;

    final List<CollectionItem> list = hasFilter
        ? widget.items
            .where((CollectionItem i) =>
                (_filterStatus == null || i.status == _filterStatus) &&
                (_filterType == null || i.mediaType == _filterType) &&
                (_filterRating == null ||
                    (i.userRating ?? 0) == _filterRating))
            .toList()
        : List<CollectionItem>.of(widget.items);

    final int dir = _sortAscending ? 1 : -1;

    list.sort((CollectionItem a, CollectionItem b) {
      switch (_sortColumn) {
        case TableColumn.name:
          return a.itemName.compareTo(b.itemName) * dir;
        case TableColumn.type:
          return a.mediaType.index.compareTo(b.mediaType.index) * dir;
        case TableColumn.platform:
          return _platformLabel(a).compareTo(_platformLabel(b)) * dir;
        case TableColumn.status:
          return a.status.index.compareTo(b.status.index) * dir;
        case TableColumn.rating:
          final int ra = a.userRating ?? 0;
          final int rb = b.userRating ?? 0;
          return ra.compareTo(rb) * dir;
        case TableColumn.year:
          final int ya = a.releaseYear ?? 0;
          final int yb = b.releaseYear ?? 0;
          return ya.compareTo(yb) * dir;
        case TableColumn.added:
          return a.addedAt.compareTo(b.addedAt) * dir;
      }
    });

    return list;
  }
}

/// Формирует метку платформы для строки таблицы.
///
/// Для не-игр возвращает пустую строку.
String _platformLabel(CollectionItem item) {
  if (item.mediaType != MediaType.game) return '';
  return item.platform?.abbreviation ?? item.platform?.name ?? '';
}

// ---------------------------------------------------------------------------
// Sticky header
// ---------------------------------------------------------------------------

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.l,
    this.filterStatus,
    this.filterType,
    this.filterRating,
  });

  final TableColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<TableColumn> onSort;
  final S l;
  final ItemStatus? filterStatus;
  final MediaType? filterType;
  final int? filterRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          // Место под обложку
          const SizedBox(width: 32 + AppSpacing.sm),
          // Name
          _col(l.collectionTableName, TableColumn.name, flex: 3),
          // Type
          _col(
            filterType != null
                ? filterType!.localizedLabel(l)
                : l.collectionTableType,
            TableColumn.type,
            width: 44,
            isFiltered: filterType != null,
          ),
          // Platform
          _col(l.collectionTablePlatform, TableColumn.platform, flex: 1),
          // Status
          _col(
            filterStatus != null
                ? filterStatus!.genericLabel(l)
                : l.collectionTableStatus,
            TableColumn.status,
            width: 88,
            isFiltered: filterStatus != null,
          ),
          // Rating
          _col(
            filterRating != null
                ? (filterRating == 0
                    ? '\u2014'
                    : '\u2605 $filterRating')
                : l.collectionTableRating,
            TableColumn.rating,
            width: 52,
            alignEnd: true,
            isFiltered: filterRating != null,
          ),
          // Year
          _col(l.collectionTableYear, TableColumn.year,
              width: 52, alignEnd: true),
        ],
      ),
    );
  }

  Widget _col(
    String label,
    TableColumn column, {
    int flex = 0,
    double? width,
    bool alignEnd = false,
    bool isFiltered = false,
  }) {
    final bool isActive = column == sortColumn;
    final bool highlighted = isActive || isFiltered;
    final Widget cell = InkWell(
      onTap: () => onSort(column),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text.rich(
          TextSpan(
            text: label,
            children: <InlineSpan>[
              if (isActive && !isFiltered)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      sortAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 12,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              if (isFiltered)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.filter_list_rounded,
                      size: 12,
                      color: AppColors.brand,
                    ),
                  ),
                ),
            ],
          ),
          style: AppTypography.caption.copyWith(
            color: highlighted ? AppColors.brand : AppColors.textSecondary,
            fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        ),
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex, child: cell);
  }
}

// ---------------------------------------------------------------------------
// Row
// ---------------------------------------------------------------------------

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.item,
    required this.onTap,
    this.onSecondaryTap,
    required this.thumbWidth,
    required this.thumbHeight,
    required this.thumbRadius,
    super.key,
  });

  final CollectionItem item;
  final VoidCallback onTap;
  final void Function(Offset globalPosition)? onSecondaryTap;
  final double thumbWidth;
  final double thumbHeight;
  final double thumbRadius;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final CollectionItem item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onSecondaryTapUp: widget.onSecondaryTap != null
            ? (TapUpDetails details) =>
                widget.onSecondaryTap!(details.globalPosition)
            : null,
        child: InkWell(
          onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? AppColors.brand.withAlpha(12)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            children: <Widget>[
              // Thumbnail
              _Thumbnail(
                item: item,
                width: widget.thumbWidth,
                height: widget.thumbHeight,
                radius: widget.thumbRadius,
              ),
              const SizedBox(width: AppSpacing.sm),

              // Name + subtitle
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      item.itemName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.genresString != null &&
                        item.genresString!.isNotEmpty)
                      Text(
                        item.genresString!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Type icon
              SizedBox(
                width: 44,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: MediaTypeTheme.colorFor(item.mediaType)
                          .withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      MediaTypeTheme.iconFor(item.mediaType),
                      size: 14,
                      color: MediaTypeTheme.colorFor(item.mediaType),
                    ),
                  ),
                ),
              ),

              // Platform
              Expanded(
                flex: 1,
                child: Text(
                  _platformLabel(item),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Status chip
              SizedBox(
                width: 88,
                child: _StatusChip(
                  status: item.status,
                  mediaType: item.mediaType,
                ),
              ),

              // Rating
              SizedBox(
                width: 52,
                child: _RatingCell(rating: item.userRating),
              ),

              // Year
              SizedBox(
                width: 52,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    item.releaseYear?.toString() ?? '',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Thumbnail
// ---------------------------------------------------------------------------

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.item,
    required this.width,
    required this.height,
    required this.radius,
  });

  final CollectionItem item;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: item.thumbnailUrl != null
            ? CachedImage(
                imageType: item.imageType,
                imageId: item.externalId.toString(),
                remoteUrl: item.thumbnailUrl!,
                fit: BoxFit.cover,
                memCacheWidth: (width * 2).toInt(),
                memCacheHeight: (height * 2).toInt(),
                placeholder: _placeholder(),
                errorWidget: _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        item.placeholderIcon,
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rating cell — звезда + число
// ---------------------------------------------------------------------------

class _RatingCell extends StatelessWidget {
  const _RatingCell({required this.rating});

  final int? rating;

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          '\u2014',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        const Icon(Icons.star_rounded, size: 14, color: AppColors.ratingStar),
        const SizedBox(width: 2),
        Text(
          rating.toString(),
          style: AppTypography.body.copyWith(
            color: AppColors.ratingStar,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.mediaType,
  });

  final ItemStatus status;
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final Color color = _statusColor();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          status.localizedLabel(l, mediaType),
          style: AppTypography.caption.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _statusColor() {
    switch (status) {
      case ItemStatus.notStarted:
        return AppColors.textTertiary;
      case ItemStatus.planned:
        return AppColors.statusPlanned;
      case ItemStatus.inProgress:
        return AppColors.statusInProgress;
      case ItemStatus.completed:
        return AppColors.statusCompleted;
      case ItemStatus.dropped:
        return AppColors.statusDropped;
    }
  }
}
