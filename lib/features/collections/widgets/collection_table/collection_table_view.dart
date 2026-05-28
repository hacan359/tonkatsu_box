import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/collection_tag.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../settings/providers/settings_provider.dart';
import 'table_column.dart';
import 'table_header.dart';
import 'table_row.dart' as table_row;

export 'table_column.dart' show TableColumn;

/// Manifest-style table view of a collection. When [onReorder] is supplied
/// the view flips into a reorderable sliver: column sort/filter is disabled
/// and a drag handle appears on every row.
class CollectionTableView extends ConsumerStatefulWidget {
  const CollectionTableView({
    required this.items,
    required this.onItemTap,
    this.heroHeader,
    this.onItemSecondaryTap,
    this.tags = const <CollectionTag>[],
    this.onRatingChanged,
    this.onStatusChanged,
    this.onTagChanged,
    this.onReorder,
    this.selectedIds,
    this.onToggleSelect,
    this.onToggleSelectAll,
    this.onFilterStatusChanged,
    super.key,
  });

  final List<CollectionItem> items;
  final ValueChanged<CollectionItem> onItemTap;
  final Widget? heroHeader;
  final void Function(CollectionItem item, Offset globalPosition)?
      onItemSecondaryTap;
  final List<CollectionTag> tags;
  final void Function(int itemId, double? rating)? onRatingChanged;
  final void Function(int itemId, ItemStatus status, MediaType mediaType)?
      onStatusChanged;
  final void Function(int itemId, int? tagId)? onTagChanged;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final Set<int>? selectedIds;
  final void Function(int itemId)? onToggleSelect;
  final void Function(bool selectAll)? onToggleSelectAll;

  /// Notifies the parent when the in-table status column filter cycles, so
  /// outside chrome (e.g. chevron counts) can mirror the active filter.
  final ValueChanged<ItemStatus?>? onFilterStatusChanged;

  @override
  ConsumerState<CollectionTableView> createState() => _CollectionTableViewState();
}

class _CollectionTableViewState extends ConsumerState<CollectionTableView> {
  static const double _minTableWidth = 864;

  TableColumn _sortColumn = TableColumn.name;
  bool _sortAscending = true;

  ItemStatus? _filterStatus;
  MediaType? _filterType;
  double? _filterRating;
  int? _filterTagId;
  String? _filterPlatform;

  late Map<int, CollectionTag> _cachedTagMap;

  @override
  void initState() {
    super.initState();
    if (widget.onFilterStatusChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onFilterStatusChanged?.call(null),
      );
    }
  }

  @override
  void didUpdateWidget(CollectionTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      final bool hadStatusFilter = _filterStatus != null;
      _filterStatus = null;
      _filterType = null;
      _filterRating = null;
      _filterTagId = null;
      _filterPlatform = null;
      if (hadStatusFilter) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onFilterStatusChanged?.call(null),
        );
      }
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
        final bool needsHorizontalScroll = constraints.maxWidth < _minTableWidth;
        final double tableWidth =
            needsHorizontalScroll ? _minTableWidth : constraints.maxWidth;

        final Widget tableHeader = TableHeader(
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
        );

        final CustomScrollView scrollView = CustomScrollView(
          slivers: <Widget>[
            if (widget.heroHeader != null)
              SliverToBoxAdapter(child: widget.heroHeader),
            SliverToBoxAdapter(child: tableHeader),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              sliver: isReorderable
                  ? _buildReorderableSliver(sorted)
                  : _buildSortableSliver(sorted),
            ),
          ],
        );

        if (!needsHorizontalScroll) return scrollView;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: tableWidth, child: scrollView),
        );
      },
    );
  }

  Widget _buildSortableSliver(List<CollectionItem> sorted) {
    return SliverList.builder(
      itemCount: sorted.length,
      itemBuilder: (BuildContext context, int index) =>
          _row(sorted[index], dragIndex: null),
    );
  }

  Widget _buildReorderableSliver(List<CollectionItem> sorted) {
    return SliverReorderableList(
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
      itemBuilder: (BuildContext context, int index) =>
          _row(sorted[index], dragIndex: index),
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
          widget.onFilterStatusChanged?.call(_filterStatus);
        case TableColumn.type:
          _filterType = _cycleFilter<MediaType>(
            _filterType,
            widget.items.map((CollectionItem i) => i.mediaType),
            (MediaType a, MediaType b) => a.index.compareTo(b.index),
          );
        case TableColumn.rating:
          _filterRating = _cycleFilter<double>(
            _filterRating,
            widget.items.map((CollectionItem i) => i.userRating ?? 0),
            (double a, double b) => a.compareTo(b),
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
    final String anilistLang = ref
        .read(settingsNotifierProvider)
        .animeMangaTitleLanguage;
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
          return a.displayName(anilistLang).compareTo(b.displayName(anilistLang)) * dir;
        case TableColumn.type:
          return a.mediaType.index.compareTo(b.mediaType.index) * dir;
        case TableColumn.platform:
          return _platformLabel(a).compareTo(_platformLabel(b)) * dir;
        case TableColumn.status:
          return a.status.index.compareTo(b.status.index) * dir;
        case TableColumn.tag:
          return _tagName(a).compareTo(_tagName(b)) * dir;
        case TableColumn.rating:
          final double ra = a.userRating ?? 0;
          final double rb = b.userRating ?? 0;
          return ra.compareTo(rb) * dir;
        case TableColumn.externalRating:
          final double ea = a.apiRating ?? 0;
          final double eb = b.apiRating ?? 0;
          return ea.compareTo(eb) * dir;
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
    return null;
  }
}

String _platformLabel(CollectionItem item) {
  if (item.mediaType != MediaType.game) return '';
  return item.platform?.abbreviation ?? item.platform?.name ?? '';
}
