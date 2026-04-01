// Табличный (Manifest) вид элементов коллекции.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_tag.dart';
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

  /// Тег.
  tag,

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
/// Поддерживает inline-редактирование рейтинга, статуса и тега.
class CollectionTableView extends StatefulWidget {
  /// Создаёт [CollectionTableView].
  const CollectionTableView({
    required this.items,
    required this.onItemTap,
    this.onItemSecondaryTap,
    this.tags = const <CollectionTag>[],
    this.onRatingChanged,
    this.onStatusChanged,
    this.onTagChanged,
    super.key,
  });

  /// Элементы для отображения.
  final List<CollectionItem> items;

  /// Callback нажатия на элемент.
  final ValueChanged<CollectionItem> onItemTap;

  /// Callback правого клика на элемент (координаты + элемент).
  final void Function(CollectionItem item, Offset globalPosition)?
      onItemSecondaryTap;

  /// Теги коллекции.
  final List<CollectionTag> tags;

  /// Callback изменения рейтинга (itemId, newRating).
  final void Function(int itemId, int? rating)? onRatingChanged;

  /// Callback изменения статуса (itemId, newStatus, mediaType).
  final void Function(int itemId, ItemStatus status, MediaType mediaType)?
      onStatusChanged;

  /// Callback изменения тега (itemId, newTagId).
  final void Function(int itemId, int? tagId)? onTagChanged;

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
  int? _filterTagId;
  String? _filterPlatform;

  @override
  void didUpdateWidget(CollectionTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Сброс фильтров при изменении данных — избегаем stale state.
    if (!identical(oldWidget.items, widget.items)) {
      _filterStatus = null;
      _filterType = null;
      _filterRating = null;
      _filterTagId = null;
      _filterPlatform = null;
    }
  }

  /// Ширина миниатюры.
  static const double _thumbWidth = 32.0;

  /// Высота миниатюры.
  static const double _thumbHeight = 46.0;

  /// Радиус скругления миниатюры.
  static const double _thumbRadius = 4.0;

  /// Lookup тегов по id, кэшируется на время build.
  late Map<int, CollectionTag> _cachedTagMap;

  Map<int, CollectionTag> _buildTagMap() {
    return <int, CollectionTag>{
      for (final CollectionTag t in widget.tags) t.id: t,
    };
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    _cachedTagMap = _buildTagMap();
    final List<CollectionItem> sorted = _sortedItems();
    final Map<int, CollectionTag> tagMap = _cachedTagMap;

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
                filterTagId: _filterTagId,
                filterPlatform: _filterPlatform,
                tagMap: tagMap,
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
                      tag: item.tagId != null ? tagMap[item.tagId] : null,
                      onTap: () => widget.onItemTap(item),
                      onSecondaryTap: widget.onItemSecondaryTap != null
                          ? (Offset pos) =>
                              widget.onItemSecondaryTap!(item, pos)
                          : null,
                      onRatingChanged: widget.onRatingChanged,
                      onStatusChanged: widget.onStatusChanged,
                      onTagChanged: widget.onTagChanged,
                      tags: widget.tags,
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
            (ItemStatus a, ItemStatus b) => a.index.compareTo(b.index),
          );
        case TableColumn.type:
          _filterType = _cycleFilter<MediaType>(
            _filterType,
            widget.items.map((CollectionItem i) => i.mediaType),
            (MediaType a, MediaType b) => a.index.compareTo(b.index),
          );
        case TableColumn.rating:
          _filterRating = _cycleFilter<int>(
            _filterRating,
            widget.items.map((CollectionItem i) => i.userRating ?? 0),
            (int a, int b) => a.compareTo(b),
          );
        case TableColumn.tag:
          _filterTagId = _cycleFilter<int>(
            _filterTagId,
            widget.items.map((CollectionItem i) => i.tagId ?? 0),
            (int a, int b) => a.compareTo(b),
          );
        case TableColumn.platform:
          _filterPlatform = _cycleFilter<String>(
            _filterPlatform,
            widget.items.map(_platformLabel),
            (String a, String b) => a.compareTo(b),
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
  T? _cycleFilter<T>(
    T? current,
    Iterable<T> values,
    int Function(T, T) compare,
  ) {
    final List<T> available = values.toSet().toList()..sort(compare);
    if (available.length <= 1) return current;
    if (current == null) return available.first;
    final int idx = available.indexOf(current);
    return idx < available.length - 1 ? available[idx + 1] : null;
  }

  List<CollectionItem> _sortedItems() {
    final bool hasFilter = _filterStatus != null ||
        _filterType != null ||
        _filterRating != null ||
        _filterTagId != null ||
        _filterPlatform != null;

    final List<CollectionItem> list = hasFilter
        ? widget.items
            .where((CollectionItem i) =>
                (_filterStatus == null || i.status == _filterStatus) &&
                (_filterType == null || i.mediaType == _filterType) &&
                (_filterRating == null ||
                    (i.userRating ?? 0) == _filterRating) &&
                (_filterTagId == null || (i.tagId ?? 0) == _filterTagId) &&
                (_filterPlatform == null ||
                    _platformLabel(i) == _filterPlatform))
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
        case TableColumn.tag:
          final String ta = _tagName(a);
          final String tb = _tagName(b);
          return ta.compareTo(tb) * dir;
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

  String _tagName(CollectionItem item) {
    if (item.tagId == null) return '';
    return _cachedTagMap[item.tagId]?.name ?? '';
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
    required this.tagMap,
    this.filterStatus,
    this.filterType,
    this.filterRating,
    this.filterTagId,
    this.filterPlatform,
  });

  final TableColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<TableColumn> onSort;
  final S l;
  final ItemStatus? filterStatus;
  final MediaType? filterType;
  final int? filterRating;
  final int? filterTagId;
  final String? filterPlatform;
  final Map<int, CollectionTag> tagMap;

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
          _col(
            filterPlatform != null
                ? (filterPlatform!.isEmpty
                    ? '\u2014'
                    : filterPlatform!)
                : l.collectionTablePlatform,
            TableColumn.platform,
            flex: 1,
            isFiltered: filterPlatform != null,
          ),
          // Status
          _col(
            filterStatus != null
                ? filterStatus!.genericLabel(l)
                : l.collectionTableStatus,
            TableColumn.status,
            width: 88,
            isFiltered: filterStatus != null,
          ),
          // Tag
          _col(
            filterTagId != null
                ? (filterTagId == 0
                    ? '\u2014'
                    : tagMap[filterTagId]?.name ?? l.tagLabel)
                : l.tagLabel,
            TableColumn.tag,
            width: 80,
            isFiltered: filterTagId != null,
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
      key: ValueKey<TableColumn>(column),
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
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(left: 2),
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
    this.onRatingChanged,
    this.onStatusChanged,
    this.onTagChanged,
    this.tag,
    this.tags = const <CollectionTag>[],
    required this.thumbWidth,
    required this.thumbHeight,
    required this.thumbRadius,
    super.key,
  });

  final CollectionItem item;
  final VoidCallback onTap;
  final void Function(Offset globalPosition)? onSecondaryTap;
  final void Function(int itemId, int? rating)? onRatingChanged;
  final void Function(int itemId, ItemStatus status, MediaType mediaType)?
      onStatusChanged;
  final void Function(int itemId, int? tagId)? onTagChanged;
  final CollectionTag? tag;
  final List<CollectionTag> tags;
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

              // Status chip (editable)
              SizedBox(
                width: 88,
                child: _StatusChip(
                  status: item.status,
                  mediaType: item.mediaType,
                  onStatusChanged: widget.onStatusChanged != null
                      ? (ItemStatus s) => widget.onStatusChanged!(
                            item.id,
                            s,
                            item.mediaType,
                          )
                      : null,
                ),
              ),

              // Tag chip (editable)
              SizedBox(
                width: 80,
                child: _TagCell(
                  tag: widget.tag,
                  tags: widget.tags,
                  onTagChanged: widget.onTagChanged != null
                      ? (int? tagId) =>
                          widget.onTagChanged!(item.id, tagId)
                      : null,
                ),
              ),

              // Rating (editable)
              SizedBox(
                width: 52,
                child: _RatingCell(
                  rating: item.userRating,
                  onRatingChanged: widget.onRatingChanged != null
                      ? (int? r) =>
                          widget.onRatingChanged!(item.id, r)
                      : null,
                ),
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
// Rating cell — звезда + число, с popup для редактирования
// ---------------------------------------------------------------------------

class _RatingCell extends StatelessWidget {
  const _RatingCell({
    required this.rating,
    this.onRatingChanged,
  });

  final int? rating;
  final ValueChanged<int?>? onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final Widget content = rating == null
        ? Align(
            alignment: Alignment.centerRight,
            child: Text(
              '\u2014',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const Icon(
                  Icons.star_rounded, size: 14, color: AppColors.ratingStar),
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

    if (onRatingChanged == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showRatingPopup(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: content,
      ),
    );
  }

  void _showRatingPopup(BuildContext context) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    showMenu<int?>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      constraints: const BoxConstraints(maxWidth: 240),
      items: <PopupMenuEntry<int?>>[
        _RatingPopupItem(currentRating: rating),
      ],
    ).then((int? value) {
      // value == -1 means "clear", null means "dismissed"
      if (value == null) return;
      if (value == -1) {
        onRatingChanged!(null);
      } else {
        onRatingChanged!(value);
      }
    });
  }
}

/// Кастомный popup item с горизонтальным рядом звёзд.
class _RatingPopupItem extends PopupMenuEntry<int?> {
  const _RatingPopupItem({required this.currentRating});

  final int? currentRating;

  @override
  double get height => 40;

  @override
  bool represents(int? value) => false;

  @override
  State<_RatingPopupItem> createState() => _RatingPopupItemState();
}

class _RatingPopupItemState extends State<_RatingPopupItem> {
  int? _hoveredRating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Кнопка очистки
          _buildClearButton(),
          const SizedBox(width: 4),
          // 10 звёзд
          for (int i = 1; i <= 10; i++) _buildStar(i),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return InkWell(
      onTap: () => Navigator.of(context).pop(-1),
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.all(2),
        child: Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildStar(int value) {
    final bool isActive = widget.currentRating != null &&
        value <= widget.currentRating!;
    final bool isHovered = _hoveredRating != null && value <= _hoveredRating!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRating = value),
      onExit: (_) => setState(() => _hoveredRating = null),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            isHovered || isActive
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: 18,
            color: isHovered
                ? AppColors.ratingStar
                : isActive
                    ? AppColors.ratingStar.withAlpha(180)
                    : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip — с popup для редактирования
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.mediaType,
    this.onStatusChanged,
  });

  final ItemStatus status;
  final MediaType mediaType;
  final ValueChanged<ItemStatus>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final Color color = status.color;

    final Widget chip = Align(
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

    if (onStatusChanged == null) return chip;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showStatusPopup(context, l),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: chip,
      ),
    );
  }

  void _showStatusPopup(BuildContext context, S l) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    showMenu<ItemStatus>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      items: ItemStatus.values.map((ItemStatus s) {
        return PopupMenuItem<ItemStatus>(
          value: s,
          height: 36,
          child: Row(
            children: <Widget>[
              Icon(s.materialIcon, size: 16, color: s.color),
              const SizedBox(width: 8),
              Text(
                s.localizedLabel(l, mediaType),
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  color: s.color,
                ),
              ),
              const Spacer(),
              if (s == status)
                const Icon(Icons.check_rounded, size: 16,
                    color: AppColors.brand),
            ],
          ),
        );
      }).toList(),
    ).then((ItemStatus? value) {
      if (value != null && value != status) {
        onStatusChanged!(value);
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Tag cell — цветной чип, popup для назначения тега
// ---------------------------------------------------------------------------

class _TagCell extends StatelessWidget {
  const _TagCell({
    this.tag,
    this.tags = const <CollectionTag>[],
    this.onTagChanged,
  });

  final CollectionTag? tag;
  final List<CollectionTag> tags;
  final ValueChanged<int?>? onTagChanged;

  @override
  Widget build(BuildContext context) {
    final Widget content = tag != null
        ? Align(
            alignment: Alignment.centerLeft,
            child: _buildTagChip(tag!),
          )
        : Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '\u2014',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          );

    if (onTagChanged == null || tags.isEmpty) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showTagPopup(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: content,
      ),
    );
  }

  Widget _buildTagChip(CollectionTag t) {
    final Color chipColor =
        t.color != null ? Color(t.color!) : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: chipColor.withAlpha(60)),
      ),
      child: Text(
        t.name,
        style: AppTypography.caption.copyWith(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showTagPopup(BuildContext context) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    final S l = S.of(context);

    final List<PopupMenuEntry<int?>> items = <PopupMenuEntry<int?>>[
      // «Без тега»
      PopupMenuItem<int?>(
        value: -1,
        height: 36,
        child: Row(
          children: <Widget>[
            const Icon(Icons.label_off_outlined, size: 16,
                color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              l.tagNone,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (tag == null)
              const Icon(Icons.check_rounded, size: 16,
                  color: AppColors.brand),
          ],
        ),
      ),
      const PopupMenuDivider(height: 1),
      ...tags.map((CollectionTag t) {
        final Color chipColor =
            t.color != null ? Color(t.color!) : AppColors.textSecondary;
        return PopupMenuItem<int?>(
          value: t.id,
          height: 36,
          child: Row(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.name,
                  style: AppTypography.body.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tag?.id == t.id)
                const Icon(Icons.check_rounded, size: 16,
                    color: AppColors.brand),
            ],
          ),
        );
      }),
    ];

    showMenu<int?>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      items: items,
    ).then((int? value) {
      if (value == null) return; // dismissed
      if (value == -1) {
        // «Без тега»
        if (tag != null) onTagChanged!(null);
      } else if (value != tag?.id) {
        onTagChanged!(value);
      }
    });
  }
}
