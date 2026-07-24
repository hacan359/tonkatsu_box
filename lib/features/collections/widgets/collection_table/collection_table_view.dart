import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTheme, ShadThemeData;
import 'package:trina_grid/trina_grid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/tag.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../settings/providers/profile_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import 'table_columns.dart';
import 'table_fields.dart';
import 'table_filter.dart';
import 'table_layout_store.dart';
import 'table_rows.dart';
import 'table_style.dart';
import 'table_toolbar.dart';
import '../../../../shared/constants/item_status_ui.dart';

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
    this.itemTags = const <int, List<int>>{},
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
  final Map<int, List<int>> itemTags;
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
  TrinaGridStateManager? _stateManager;
  TableColumnLayout? _layout;
  bool _layoutLoaded = false;
  Timer? _saveDebounce;
  String? _lastSavedJson;
  final List<TableFilterRule> _filterRules = <TableFilterRule>[];

  /// Set right after a grid-initiated row drag: the grid already moved the
  /// row, so the items-list change it triggers must not reload rows.
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
        // Reloading now would kill the in-flight touch drag; consume the
        // flag and leave rows as they are.
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
    // are active row drag is suspended and header sorting takes over.
    final bool isReorderable = widget.onReorder != null && _filterRules.isEmpty;
    final bool selectable =
        widget.selectedIds != null && widget.onToggleSelect != null;
    final bool isRu = Localizations.localeOf(context).languageCode == 'ru';

    // TrinaGrid consumes columns/rows only at creation, so structural
    // changes (reorder mode, selection, locale) must recreate the grid.
    // ShadTheme: trina_grid's filter popups are built on shadcn_ui and
    // require it in context — the app itself doesn't use ShadApp.
    final Widget grid = ShadTheme(
      data: ShadThemeData(brightness: Brightness.dark),
      // Grid-scoped checkbox theme: rounds the otherwise-square Material
      // checkbox trina renders and gives it a soft unselected border.
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
          columns: buildCollectionTableColumns(
            l: l,
            isReorderable: isReorderable,
            selectable: selectable,
            layout: _layout,
            view: () => widget,
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
        TableToolbar(
          columnLabels: tableColumnLabels(l),
          isColumnHidden: _isColumnHidden,
          onToggleColumn: _toggleColumnHidden,
          activeFilterCount: _filterRules.length,
          onOpenFilters: _openFilterDialog,
        ),
        Expanded(child: grid),
      ],
    );
  }


  /// All columns including hidden ones. `stateManager.columns` filters hidden
  /// columns out, so [FilteredList.originalList] keeps the full set.
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


  /// Filterable columns: every labelled column except favorite (a boolean,
  /// not meaningfully text/equals-filterable).
  Map<String, String> _filterableColumns(S l) => <String, String>{
    for (final MapEntry<String, String> e in tableColumnLabels(l).entries)
      if (e.key != TableFields.favorite) e.key: e.value,
  };

  Future<void> _openFilterDialog() async {
    final List<TableFilterRule>? result =
        await showDialog<List<TableFilterRule>>(
          context: context,
          builder: (BuildContext ctx) => TableFilterDialog(
            rules: _filterRules,
            columns: _filterableColumns(S.of(ctx)),
            // Columns whose value is picked from a fixed list (equals)
            // rather than typed. Status uses our real status labels.
            enumOptions: <String, List<String>>{
              TableFields.status: <String>[
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


  List<TrinaRow<dynamic>> _buildRows() => buildCollectionTableRows(
    items: widget.items,
    selectedIds: widget.selectedIds ?? const <int>{},
    anilistTitleLanguage: ref
        .read(settingsNotifierProvider)
        .animeMangaTitleLanguage,
    l: S.of(context),
    tags: widget.tags,
    itemTags: widget.itemTags,
  );

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
    // originalList keeps hidden columns so their order and hidden flag
    // survive; the ephemeral drag column never enters the saved layout.
    final List<TrinaColumn> columns = sm.refColumns.originalList
        .where((TrinaColumn c) => c.field != TableFields.drag)
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
