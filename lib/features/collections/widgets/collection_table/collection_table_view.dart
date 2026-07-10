import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTheme, ShadThemeData;
import 'package:trina_grid/trina_grid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/media_type_theme.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/tag.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../settings/providers/profile_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import 'cells/favorite_cell.dart';
import 'cells/name_cell.dart';
import 'cells/rating_cell.dart';
import 'cells/status_cell.dart';
import 'cells/tag_cell.dart';
import 'cells/thumbnail_cell.dart';
import 'table_filter.dart';
import 'table_layout_store.dart';
import 'table_style.dart';

/// Grid-backed table view of a collection (trina_grid): drag-to-reorder and
/// resize columns, per-column sort and filters, inline editing through the
/// same cell widgets as before. Column layout persists per collection when
/// [collectionId] is set.
///
/// When [onReorder] is supplied the view flips into manual-order mode:
/// sorting is disabled and rows get a drag handle.
class CollectionTableView extends ConsumerStatefulWidget {
  const CollectionTableView({
    required this.items,
    required this.onItemTap,
    this.collectionId,
    this.heroHeader,
    this.onItemSecondaryTap,
    this.tags = const <Tag>[],
    this.itemTags = const <int, Set<int>>{},
    this.onRatingChanged,
    this.onStatusChanged,
    this.onTagsEdit,
    this.onFavoriteToggled,
    this.onReorder,
    this.selectedIds,
    this.onToggleSelect,
    this.onToggleSelectAll,
    this.onFilterStatusChanged,
    super.key,
  });

  final List<CollectionItem> items;
  final ValueChanged<CollectionItem> onItemTap;

  /// Persistence key for the column layout; null disables persistence.
  final int? collectionId;
  final Widget? heroHeader;
  final void Function(CollectionItem item, Offset globalPosition)?
  onItemSecondaryTap;
  final List<Tag> tags;

  /// Item id → global tag ids (from `itemTagsProvider`).
  final Map<int, Set<int>> itemTags;
  final void Function(int itemId, double? rating)? onRatingChanged;
  final void Function(int itemId, ItemStatus status, MediaType mediaType)?
  onStatusChanged;
  final void Function(int itemId)? onTagsEdit;
  final void Function(int itemId)? onFavoriteToggled;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final Set<int>? selectedIds;
  final void Function(int itemId)? onToggleSelect;
  final void Function(bool selectAll)? onToggleSelectAll;

  /// Kept for API compatibility with the outer filter chrome. The grid's
  /// own per-column filters replaced the old cyclic status filter, so this
  /// only fires once with `null` to reset the outer state.
  final ValueChanged<ItemStatus?>? onFilterStatusChanged;

  @override
  ConsumerState<CollectionTableView> createState() =>
      _CollectionTableViewState();
}

class _CollectionTableViewState extends ConsumerState<CollectionTableView> {
  static const String _fDrag = 'drag';
  static const String _fThumb = 'thumb';
  static const String _fName = 'name';
  static const String _fPlatform = 'platform';
  static const String _fType = 'type';
  static const String _fStatus = 'status';
  static const String _fFavorite = 'favorite';
  static const String _fRating = 'rating';
  static const String _fExternalRating = 'externalRating';
  static const String _fYear = 'year';
  static const String _fTags = 'tags';

  TrinaGridStateManager? _stateManager;
  TableColumnLayout? _layout;
  bool _layoutLoaded = false;
  Timer? _saveDebounce;
  String? _lastSavedJson;
  final List<TableFilterRule> _filterRules = <TableFilterRule>[];

  /// Set right after a grid-initiated row drag: the grid already moved the
  /// row internally, so the items-list change it triggers must not reload
  /// rows — reloading mid-gesture on touch tears down the drag widget before
  /// its pointer-up fires and leaves the grid stuck in "dragging" state.
  bool _skipNextReload = false;

  @override
  void initState() {
    super.initState();
    _loadLayout();
    if (widget.onFilterStatusChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onFilterStatusChanged?.call(null),
      );
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _stateManager?.removeListener(_onGridChanged);
    super.dispose();
  }

  Future<void> _loadLayout() async {
    final int? id = widget.collectionId;
    final TableColumnLayout? layout = id != null
        ? await TableLayoutStore.load(ref.read(currentProfileProvider).id, id)
        : null;
    if (!mounted) return;
    setState(() {
      _layout = layout;
      _lastSavedJson = layout?.encode();
      _layoutLoaded = true;
    });
  }

  @override
  void didUpdateWidget(CollectionTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_stateManager == null) return;
    final bool dataChanged =
        !identical(oldWidget.items, widget.items) ||
        !identical(oldWidget.itemTags, widget.itemTags) ||
        !identical(oldWidget.tags, widget.tags);
    if (dataChanged) {
      if (_skipNextReload) {
        // Grid already reflects this move; reloading now would kill the
        // in-flight touch drag. Consume the flag and leave rows as they are.
        _skipNextReload = false;
      } else {
        _reloadRows();
      }
    } else if (!identical(oldWidget.selectedIds, widget.selectedIds)) {
      _syncCheckedRows();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Grid columns are built once per grid lifetime; wait for the persisted
    // layout so saved order/widths apply from the first frame.
    if (!_layoutLoaded) return const SizedBox.shrink();

    final S l = S.of(context);
    // Manual row order and filtering are mutually exclusive: while filters
    // are active row drag is suspended (moved-row indices would point into
    // the filtered view) and header sorting takes over; clearing the filters
    // brings the drag handles back.
    final bool isReorderable = widget.onReorder != null && _filterRules.isEmpty;
    final bool selectable =
        widget.selectedIds != null && widget.onToggleSelect != null;
    final bool isRu = Localizations.localeOf(context).languageCode == 'ru';

    // TrinaGrid consumes columns/rows only at creation, so structural
    // changes (reorder mode, selection, locale) must recreate the grid.
    // ShadTheme: trina_grid's internal popups (filter dropdowns) are built
    // on shadcn_ui and require it in context — the app itself doesn't use
    // ShadApp.
    final Widget grid = ShadTheme(
      data: ShadThemeData(brightness: Brightness.dark),
      // Local checkbox theme (scoped to the grid, not app-wide): rounds the
      // otherwise-square Material checkbox trina renders and gives it a soft
      // unselected border. Fill/check colours still come from the grid style.
      child: Theme(
        data: Theme.of(context).copyWith(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            side: const BorderSide(color: AppColors.textTertiary, width: 1.5),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        child: TrinaGrid(
          key: ValueKey<String>(
            'collection_table_${isReorderable}_'
            '${selectable}_$isRu',
          ),
          columns: _buildColumns(
            l,
            isReorderable: isReorderable,
            selectable: selectable,
          ),
          rows: _buildRows(),
          configuration: collectionTableConfiguration(isRu: isRu),
          onLoaded: (TrinaGridOnLoadedEvent event) {
            _stateManager = event.stateManager;
            event.stateManager.addListener(_onGridChanged);
            if (_filterRules.isNotEmpty) _applyFilters();
          },
          onRowDoubleTap: (TrinaGridOnRowDoubleTapEvent event) =>
              widget.onItemTap(event.row.data as CollectionItem),
          onRowSecondaryTap: widget.onItemSecondaryTap != null
              ? (TrinaGridOnRowSecondaryTapEvent event) =>
                    widget.onItemSecondaryTap!(
                      event.row.data as CollectionItem,
                      event.offset,
                    )
              : null,
          onRowChecked: selectable ? _onRowChecked : null,
          onRowsMoved: isReorderable ? _onRowsMoved : null,
        ),
      ),
    );

    return Column(
      children: <Widget>[
        if (widget.heroHeader != null) ...<Widget>[
          widget.heroHeader!,
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            _buildColumnsButton(l),
            const SizedBox(width: AppSpacing.xs),
            _buildFilterButton(l),
          ],
        ),
        Expanded(child: grid),
      ],
    );
  }

  // ==================== Column visibility ====================

  /// Single ordered source of user-facing column labels, so the columns menu
  /// and the filter dialog can't drift apart. Thumbnail and drag columns are
  /// chrome and never appear here.
  Map<String, String> _columnLabels(S l) => <String, String>{
    _fName: l.collectionTableName,
    _fPlatform: l.collectionTablePlatform,
    _fType: l.collectionTableType,
    _fStatus: l.collectionTableStatus,
    _fFavorite: l.favorite,
    _fRating: l.collectionTableRating,
    _fExternalRating: l.collectionTableExternalRating,
    _fYear: l.collectionTableYear,
    _fTags: l.tagLabel,
  };

  /// Columns the user may hide (everything except the thumbnail).
  Map<String, String> _toggleableColumns(S l) => _columnLabels(l);

  Widget _buildColumnsButton(S l) {
    final Map<String, String> toggleable = _toggleableColumns(l);
    return PopupMenuButton<String>(
      tooltip: l.collectionTableColumns,
      color: AppColors.surface,
      // Keep the menu open across toggles by rebuilding it each time.
      onSelected: (String field) => _toggleColumnHidden(field),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final MapEntry<String, String> e in toggleable.entries)
          CheckedPopupMenuItem<String>(
            value: e.key,
            checked: !_isColumnHidden(e.key),
            child: Text(e.value, style: AppTypography.body),
          ),
      ],
      child: _buildToolbarChip(
        icon: Icons.view_column_outlined,
        label: l.collectionTableColumns,
        active: false,
      ),
    );
  }

  /// All columns including hidden ones. `stateManager.columns` filters hidden
  /// columns out, so a hidden column would be unreachable for re-showing —
  /// [FilteredList.originalList] keeps the full set.
  List<TrinaColumn> get _allColumns =>
      _stateManager?.refColumns.originalList ?? const <TrinaColumn>[];

  TrinaColumn? _columnByField(String field) {
    for (final TrinaColumn c in _allColumns) {
      if (c.field == field) return c;
    }
    return null;
  }

  bool _isColumnHidden(String field) {
    final TrinaColumn? column = _columnByField(field);
    if (column != null) return column.hide;
    return _layout?.hidden.contains(field) ?? false;
  }

  void _toggleColumnHidden(String field) {
    final TrinaGridStateManager? sm = _stateManager;
    final TrinaColumn? column = _columnByField(field);
    if (sm == null || column == null) return;
    // Never let the user hide every column: keep at least one visible.
    final int visible = _allColumns.where((TrinaColumn c) => !c.hide).length;
    if (!column.hide && visible <= 1) return;
    sm.hideColumn(column, !column.hide);
  }

  // ==================== Filters ====================

  Widget _buildFilterButton(S l) {
    final bool active = _filterRules.isNotEmpty;
    return InkWell(
      onTap: _openFilterDialog,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: _buildToolbarChip(
        icon: Icons.tune,
        label: active
            ? '${l.collectionFilterFilters} · ${_filterRules.length}'
            : l.collectionFilterFilters,
        active: active,
      ),
    );
  }

  /// Shared toolbar chip look for the columns / filter controls.
  Widget _buildToolbarChip({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    final Color color = active ? AppColors.brand : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }

  /// Filterable columns: every labelled column except favorite (a boolean,
  /// not meaningfully text/equals-filterable).
  Map<String, String> _filterableColumns(S l) => <String, String>{
    for (final MapEntry<String, String> e in _columnLabels(l).entries)
      if (e.key != _fFavorite) e.key: e.value,
  };

  Future<void> _openFilterDialog() async {
    final List<TableFilterRule>? result =
        await showDialog<List<TableFilterRule>>(
          context: context,
          builder: (BuildContext ctx) => TableFilterDialog(
            rules: _filterRules,
            columns: _filterableColumns(S.of(ctx)),
            // Columns whose value is picked from a fixed list (equals) rather
            // than typed. Status uses our real status labels.
            enumOptions: <String, List<String>>{
              _fStatus: <String>[
                for (final ItemStatus s in ItemStatus.values)
                  s.genericLabel(S.of(ctx)),
              ],
            },
          ),
        );
    if (result == null || !mounted) return;
    setState(() {
      _filterRules
        ..clear()
        ..addAll(result);
    });
    _applyFilters();
  }

  void _applyFilters() {
    final TrinaGridStateManager? sm = _stateManager;
    if (sm == null) return;
    final List<TrinaRow<dynamic>> filterRows = _filterRules
        .where((TableFilterRule r) => r.value.trim().isNotEmpty)
        .map(
          (TableFilterRule r) => FilterHelper.createFilterRow(
            columnField: r.field,
            filterType: r.condition.trinaType,
            filterValue: r.value.trim(),
          ),
        )
        .toList();
    sm.setFilterWithFilterRows(filterRows);
  }

  // ==================== Columns ====================

  List<TrinaColumn> _buildColumns(
    S l, {
    required bool isReorderable,
    required bool selectable,
  }) {
    final bool sortable = !isReorderable;
    final List<TrinaColumn> columns = <TrinaColumn>[
      // Dedicated drag-handle column, only in manual sort. Frozen to the left
      // so it stays put and can't be dragged itself; wide enough for a
      // comfortable touch target instead of cramming the handle next to the
      // thumbnail and checkbox.
      if (isReorderable)
        TrinaColumn(
          title: '',
          field: _fDrag,
          type: TrinaColumnType.text(),
          width: 48,
          minWidth: 48,
          frozen: TrinaColumnFrozen.start,
          readOnly: true,
          enableEditingMode: false,
          enableSorting: false,
          enableColumnDrag: false,
          enableContextMenu: false,
          enableDropToResize: false,
          enableRowDrag: true,
        ),
      TrinaColumn(
        title: '',
        field: _fThumb,
        type: TrinaColumnType.text(),
        width: selectable ? 108 : 76,
        minWidth: 60,
        readOnly: true,
        enableEditingMode: false,
        enableSorting: false,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableDropToResize: false,
        enableRowChecked: selectable,
        renderer: (TrinaColumnRendererContext ctx) => Align(
          alignment: Alignment.centerLeft,
          child: ThumbnailCell(
            item: ctx.row.data as CollectionItem,
            width: 48,
            height: 64,
            radius: 6,
          ),
        ),
      ),
      TrinaColumn(
        title: l.collectionTableName.toUpperCase(),
        field: _fName,
        type: TrinaColumnType.text(),
        width: 280,
        minWidth: 140,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        renderer: (TrinaColumnRendererContext ctx) {
          final CollectionItem item = ctx.row.data as CollectionItem;
          return NameCell(
            name: ctx.cell.value as String,
            genres: item.genresString,
            onTap: () => widget.onItemTap(item),
          );
        },
      ),
      TrinaColumn(
        title: l.collectionTablePlatform.toUpperCase(),
        field: _fPlatform,
        type: TrinaColumnType.text(),
        width: 120,
        minWidth: 70,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        textAlign: TrinaColumnTextAlign.center,
        titleTextAlign: TrinaColumnTextAlign.center,
        renderer: (TrinaColumnRendererContext ctx) => Center(
          child: Text(
            ctx.cell.value as String,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      TrinaColumn(
        title: l.collectionTableType.toUpperCase(),
        field: _fType,
        type: TrinaColumnType.text(),
        width: 76,
        minWidth: 56,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        titleTextAlign: TrinaColumnTextAlign.center,
        renderer: (TrinaColumnRendererContext ctx) {
          final CollectionItem item = ctx.row.data as CollectionItem;
          final Color accent = MediaTypeTheme.colorFor(item.mediaType);
          return Center(
            child: Tooltip(
              message: ctx.cell.value as String,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  MediaTypeTheme.iconFor(item.mediaType),
                  size: 14,
                  color: accent,
                ),
              ),
            ),
          );
        },
      ),
      TrinaColumn(
        title: l.collectionTableStatus.toUpperCase(),
        field: _fStatus,
        type: TrinaColumnType.text(),
        width: 150,
        minWidth: 110,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        titleTextAlign: TrinaColumnTextAlign.center,
        renderer: (TrinaColumnRendererContext ctx) {
          final CollectionItem item = ctx.row.data as CollectionItem;
          return Center(
            child: StatusCell(
              status: item.status,
              mediaType: item.mediaType,
              onStatusChanged: widget.onStatusChanged != null
                  ? (ItemStatus s) =>
                        widget.onStatusChanged!(item.id, s, item.mediaType)
                  : null,
            ),
          );
        },
      ),
      TrinaColumn(
        title: l.favorite.toUpperCase(),
        field: _fFavorite,
        type: TrinaColumnType.number(),
        width: 64,
        minWidth: 48,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        titleTextAlign: TrinaColumnTextAlign.center,
        renderer: (TrinaColumnRendererContext ctx) {
          final CollectionItem item = ctx.row.data as CollectionItem;
          return Center(
            child: FavoriteCell(
              isFavorite: item.isFavorite,
              onToggle: widget.onFavoriteToggled != null
                  ? () => widget.onFavoriteToggled!(item.id)
                  : null,
            ),
          );
        },
      ),
      TrinaColumn(
        title: l.collectionTableRating.toUpperCase(),
        field: _fRating,
        type: TrinaColumnType.number(),
        width: 84,
        minWidth: 60,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        titleTextAlign: TrinaColumnTextAlign.center,
        renderer: (TrinaColumnRendererContext ctx) {
          final CollectionItem item = ctx.row.data as CollectionItem;
          return Center(
            child: RatingCell(
              rating: item.userRating,
              onRatingChanged: widget.onRatingChanged != null
                  ? (double? r) => widget.onRatingChanged!(item.id, r)
                  : null,
            ),
          );
        },
      ),
      TrinaColumn(
        title: l.collectionTableExternalRating.toUpperCase(),
        field: _fExternalRating,
        type: TrinaColumnType.number(),
        width: 84,
        minWidth: 60,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        titleTextAlign: TrinaColumnTextAlign.center,
        renderer: (TrinaColumnRendererContext ctx) => Center(
          child: RatingCell(rating: (ctx.row.data as CollectionItem).apiRating),
        ),
      ),
      TrinaColumn(
        title: l.collectionTableYear.toUpperCase(),
        field: _fYear,
        type: TrinaColumnType.number(),
        width: 72,
        minWidth: 56,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        titleTextAlign: TrinaColumnTextAlign.center,
        renderer: (TrinaColumnRendererContext ctx) {
          final int? year = (ctx.row.data as CollectionItem).releaseYear;
          return Center(
            child: Text(
              year?.toString() ?? '',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
      TrinaColumn(
        title: l.tagLabel.toUpperCase(),
        field: _fTags,
        type: TrinaColumnType.text(),
        width: 200,
        minWidth: 100,
        readOnly: true,
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: sortable,
        renderer: (TrinaColumnRendererContext ctx) {
          final CollectionItem item = ctx.row.data as CollectionItem;
          return TagCell(
            tags: widget.tags.orderedFor(widget.itemTags[item.id]),
            onEditTags: widget.onTagsEdit != null
                ? () => widget.onTagsEdit!(item.id)
                : null,
          );
        },
      ),
    ];
    _applyLayout(columns);
    return columns;
  }

  /// Applies the persisted per-collection order, widths and hidden columns.
  void _applyLayout(List<TrinaColumn> columns) {
    final TableColumnLayout? layout = _layout;
    if (layout == null) return;
    for (final TrinaColumn column in columns) {
      final double? width = layout.widths[column.field];
      if (width != null && width >= column.minWidth) {
        column.width = width;
      }
      // Never restore the thumbnail column as hidden — it's not toggleable.
      if (column.field != _fThumb) {
        column.hide = layout.hidden.contains(column.field);
      }
    }
    if (layout.order.isEmpty) return;
    // Fields missing from the saved order keep their relative position at
    // the end (List.sort is not stable, so encode the fallback explicitly).
    final Map<String, int> savedIndex = <String, int>{
      for (int i = 0; i < layout.order.length; i++) layout.order[i]: i,
    };
    final Map<String, int> sortKey = <String, int>{
      for (int i = 0; i < columns.length; i++)
        columns[i].field:
            savedIndex[columns[i].field] ?? layout.order.length + i,
    };
    columns.sort(
      (TrinaColumn a, TrinaColumn b) =>
          sortKey[a.field]!.compareTo(sortKey[b.field]!),
    );
  }

  // ==================== Rows ====================

  List<TrinaRow<dynamic>> _buildRows() {
    final String anilistLang = ref
        .read(settingsNotifierProvider)
        .animeMangaTitleLanguage;
    final S l = S.of(context);
    final Set<int> selected = widget.selectedIds ?? const <int>{};
    return widget.items.map((CollectionItem item) {
      return TrinaRow<dynamic>(
        data: item,
        checked: selected.contains(item.id),
        cells: <String, TrinaCell>{
          _fDrag: TrinaCell(value: ''),
          _fThumb: TrinaCell(value: ''),
          _fName: TrinaCell(value: item.displayName(anilistLang)),
          _fPlatform: TrinaCell(value: _platformLabel(item)),
          _fType: TrinaCell(value: item.mediaType.localizedLabel(l)),
          _fStatus: TrinaCell(value: item.status.genericLabel(l)),
          _fFavorite: TrinaCell(value: item.isFavorite ? 1 : 0),
          _fRating: TrinaCell(value: item.userRating ?? 0),
          _fExternalRating: TrinaCell(value: item.apiRating ?? 0),
          _fYear: TrinaCell(value: item.releaseYear ?? 0),
          // All tag names joined so a "contains" filter matches any tag, not
          // just the primary one; sort still keys off the leading (primary)
          // tag since names stay in display order.
          _fTags: TrinaCell(
            value: widget.tags
                .orderedFor(widget.itemTags[item.id])
                .map((Tag t) => t.name)
                .join(', '),
          ),
        },
      );
    }).toList();
  }

  void _reloadRows() {
    final TrinaGridStateManager sm = _stateManager!;
    sm.removeAllRows(notify: false);
    sm.appendRows(_buildRows());
    // appendRows does not re-run the active filter, so freshly added rows
    // would all show through — re-apply it against the new row set.
    if (_filterRules.isNotEmpty) _applyFilters();
  }

  void _syncCheckedRows() {
    final TrinaGridStateManager sm = _stateManager!;
    final Set<int> selected = widget.selectedIds ?? const <int>{};
    for (final TrinaRow<dynamic> row in sm.refRows) {
      final bool shouldCheck = selected.contains(
        (row.data as CollectionItem).id,
      );
      if ((row.checked ?? false) != shouldCheck) {
        sm.setRowChecked(row, shouldCheck, notify: false);
      }
    }
    sm.notifyListeners();
  }

  // ==================== Events ====================

  void _onRowChecked(TrinaGridOnRowCheckedEvent event) {
    if (event.isAll) {
      widget.onToggleSelectAll?.call(event.isChecked ?? false);
    } else if (event.row != null) {
      widget.onToggleSelect?.call((event.row!.data as CollectionItem).id);
    }
  }

  void _onRowsMoved(TrinaGridOnRowsMovedEvent event) {
    if (event.rows.isEmpty) return;
    final CollectionItem moved = event.rows.first.data as CollectionItem;
    final int oldIndex = widget.items.indexWhere(
      (CollectionItem i) => i.id == moved.id,
    );
    if (oldIndex < 0 || oldIndex == event.idx) return;
    // The grid already moved the row; skip the reload the resulting items
    // change would otherwise trigger.
    _skipNextReload = true;
    widget.onReorder!(oldIndex, event.idx);
  }

  /// Debounced persistence of column order/widths/visibility on any grid
  /// change (drag, resize, hide).
  void _onGridChanged() {
    if (!mounted || widget.collectionId == null) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _persistLayout);
  }

  void _persistLayout() {
    final TrinaGridStateManager? sm = _stateManager;
    final int? id = widget.collectionId;
    if (sm == null || id == null || !mounted) return;
    // originalList keeps hidden columns, so their order and hidden flag
    // survive; sm.columns would drop them from the layout entirely. The
    // ephemeral drag column (manual sort only) is excluded so it never
    // pollutes the saved layout.
    final List<TrinaColumn> columns = sm.refColumns.originalList
        .where((TrinaColumn c) => c.field != _fDrag)
        .toList();
    final TableColumnLayout layout = TableColumnLayout(
      order: columns.map((TrinaColumn c) => c.field).toList(),
      widths: <String, double>{
        for (final TrinaColumn c in columns) c.field: c.width,
      },
      hidden: <String>{
        for (final TrinaColumn c in columns)
          if (c.hide) c.field,
      },
    );
    final String encoded = layout.encode();
    if (encoded == _lastSavedJson) return;
    _lastSavedJson = encoded;
    _layout = layout;
    unawaited(
      TableLayoutStore.save(ref.read(currentProfileProvider).id, id, layout),
    );
  }
}

String _platformLabel(CollectionItem item) {
  if (item.mediaType != MediaType.game) return '';
  return item.platform?.abbreviation ?? item.platform?.name ?? '';
}
