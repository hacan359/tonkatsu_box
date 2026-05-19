import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/collection_tag.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/theme/app_spacing.dart';
import 'table_column.dart';
import 'table_header.dart';
import 'table_row.dart' as table_row;

export 'table_column.dart' show TableColumn;

/// Manifest-style table view of a collection. When [onReorder] is supplied
/// the view flips into a [ReorderableListView]: column sort/filter is
/// disabled and a drag handle appears on every row.
class CollectionTableView extends StatefulWidget {
  const CollectionTableView({
    required this.items,
    required this.onItemTap,
    this.onItemSecondaryTap,
    this.tags = const <CollectionTag>[],
    this.onRatingChanged,
    this.onStatusChanged,
    this.onTagChanged,
    this.onReorder,
    this.selectedIds,
    this.onToggleSelect,
    this.onToggleSelectAll,
    super.key,
  });

  final List<CollectionItem> items;
  final ValueChanged<CollectionItem> onItemTap;
  final void Function(CollectionItem item, Offset globalPosition)?
      onItemSecondaryTap;
  final List<CollectionTag> tags;
  final void Function(int itemId, int? rating)? onRatingChanged;
  final void Function(int itemId, ItemStatus status, MediaType mediaType)?
      onStatusChanged;
  final void Function(int itemId, int? tagId)? onTagChanged;

  /// When non-null the view becomes a [ReorderableListView] and column-based
  /// sort/filter is disabled. Indices are reported with the trailing-shift
  /// already removed (i.e. semantic source→destination).
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Set of currently selected ids. Together with [onToggleSelect] this drives
  /// per-row checkboxes and the master tri-state checkbox in the header.
  final Set<int>? selectedIds;
  final void Function(int itemId)? onToggleSelect;
  final void Function(bool selectAll)? onToggleSelectAll;

  @override
  State<CollectionTableView> createState() => _CollectionTableViewState();
}

class _CollectionTableViewState extends State<CollectionTableView> {
  TableColumn _sortColumn = TableColumn.name;
  bool _sortAscending = true;

  ItemStatus? _filterStatus;
  MediaType? _filterType;
  int? _filterRating;
  int? _filterTagId;
  String? _filterPlatform;

  late Map<int, CollectionTag> _cachedTagMap;

  @override
  void didUpdateWidget(CollectionTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset filters when the parent ships a fresh items list — otherwise a
    // value pointing at a now-missing tag/status would silently hide rows.
    if (!identical(oldWidget.items, widget.items)) {
      _filterStatus = null;
      _filterType = null;
      _filterRating = null;
      _filterTagId = null;
      _filterPlatform = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    _cachedTagMap = <int, CollectionTag>{
      for (final CollectionTag t in widget.tags) t.id: t,
    };
    final bool isReorderable = widget.onReorder != null;
    final List<CollectionItem> sorted =
        isReorderable ? widget.items : _sortedItems();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tableWidth =
            constraints.maxWidth < 820 ? 820 : constraints.maxWidth;
        // Horizontal scroll for narrow windows; the body itself sizes to its
        // content (shrinkWrap) so a parent vertical scrollable can carry it
        // alongside an external header (e.g. collection hero).
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TableHeader(
                  sortColumn: _sortColumn,
                  sortAscending: _sortAscending,
                  onSort: _toggleSort,
                  filterStatus: _filterStatus,
                  filterType: _filterType,
                  filterRating: _filterRating,
                  filterTagId: _filterTagId,
                  filterPlatform: _filterPlatform,
                  tagMap: _cachedTagMap,
                  l: l,
                  isReorderable: isReorderable,
                  selectionState: _selectionStateForVisible(sorted),
                  onToggleSelectAll: widget.onToggleSelectAll,
                ),
                isReorderable
                    ? _buildReorderableBody(sorted)
                    : _buildSortableBody(sorted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortableBody(List<CollectionItem> sorted) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: sorted.length,
      itemBuilder: (BuildContext context, int index) {
        return _row(sorted[index], dragIndex: null);
      },
    );
  }

  Widget _buildReorderableBody(List<CollectionItem> sorted) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      buildDefaultDragHandles: false,
      itemCount: sorted.length,
      proxyDecorator:
          (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? c) {
            final double elevation = lerpDouble(0, 6, animation.value) ?? 0;
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black26,
              child: c,
            );
          },
          child: child,
        );
      },
      onReorderItem: (int oldIndex, int newIndex) {
        widget.onReorder!(oldIndex, newIndex);
      },
      itemBuilder: (BuildContext context, int index) {
        return _row(sorted[index], dragIndex: index);
      },
    );
  }

  Widget _row(CollectionItem item, {required int? dragIndex}) {
    return Padding(
      key: ValueKey<int>(item.id),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: table_row.TableRow(
        item: item,
      tag: item.tagId != null ? _cachedTagMap[item.tagId] : null,
      tags: widget.tags,
      onTap: () => widget.onItemTap(item),
      onSecondaryTap: widget.onItemSecondaryTap != null
          ? (Offset pos) => widget.onItemSecondaryTap!(item, pos)
          : null,
      onRatingChanged: widget.onRatingChanged,
      onStatusChanged: widget.onStatusChanged,
      onTagChanged: widget.onTagChanged,
      dragIndex: dragIndex,
      isSelected: widget.selectedIds?.contains(item.id) ?? false,
      onToggleSelect: widget.onToggleSelect != null
          ? () => widget.onToggleSelect!(item.id)
          : null,
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

  /// Cycles a filter through the available unique values in the column:
  /// null → first → next → ... → null (reset).
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
          return _tagName(a).compareTo(_tagName(b)) * dir;
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

  /// Tri-state value for the header master checkbox; null hides it.
  bool? _selectionStateForVisible(List<CollectionItem> visible) {
    final Set<int>? selected = widget.selectedIds;
    if (selected == null || widget.onToggleSelect == null) return null;
    if (visible.isEmpty) return false;
    int hit = 0;
    for (final CollectionItem i in visible) {
      if (selected.contains(i.id)) hit++;
    }
    if (hit == 0) return false;
    if (hit == visible.length) return true;
    return null; // partial → tri-state indeterminate
  }
}

String _platformLabel(CollectionItem item) {
  if (item.mediaType != MediaType.game) return '';
  return item.platform?.abbreviation ?? item.platform?.name ?? '';
}
