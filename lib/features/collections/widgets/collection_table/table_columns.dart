import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/media_type_theme.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import 'cells/favorite_cell.dart';
import 'cells/name_cell.dart';
import 'cells/rating_cell.dart';
import 'cells/status_cell.dart';
import 'cells/tag_cell.dart';
import 'cells/thumbnail_cell.dart';
import 'collection_table_view.dart';
import 'row_drag_handle.dart';
import 'table_fields.dart';
import 'table_layout_store.dart';

/// Builds trina_grid columns for [CollectionTableView] and applies [layout];
/// renderers call [view] at render time so callbacks and tag data stay fresh.
List<TrinaColumn> buildCollectionTableColumns({
  required S l,
  required bool isReorderable,
  required bool selectable,
  required TableColumnLayout? layout,
  required CollectionTableView Function() view,
}) {
  final bool sortable = !isReorderable;
  final List<TrinaColumn> columns = <TrinaColumn>[
    // Drag-handle column, manual sort only. Frozen so it stays put and can't
    // be dragged itself; wide enough for a comfortable touch target.
    // enableRowDrag is off: trina's built-in handle can't start a drag on
    // touch (loses to the grid scroll), so [RowDragHandle] replaces it.
    if (isReorderable)
      TrinaColumn(
        title: '',
        field: TableFields.drag,
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
        renderer: (TrinaColumnRendererContext ctx) => RowDragHandle(
          row: ctx.row,
          stateManager: ctx.stateManager,
        ),
      ),
    TrinaColumn(
      title: '',
      field: TableFields.thumb,
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
      title: l.name.toUpperCase(),
      field: TableFields.name,
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
          onTap: () => view().onItemTap(item),
        );
      },
    ),
    TrinaColumn(
      title: l.platform.toUpperCase(),
      field: TableFields.platform,
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
      title: l.type.toUpperCase(),
      field: TableFields.type,
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
      title: l.status.toUpperCase(),
      field: TableFields.status,
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
            onStatusChanged: view().onStatusChanged != null
                ? (ItemStatus s) =>
                      view().onStatusChanged!(item.id, s, item.mediaType)
                : null,
          ),
        );
      },
    ),
    TrinaColumn(
      title: l.progress.toUpperCase(),
      field: TableFields.progress,
      type: TrinaColumnType.text(),
      width: 96,
      minWidth: 64,
      readOnly: true,
      enableEditingMode: false,
      enableContextMenu: false,
      enableSorting: sortable,
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
      title: l.favorite.toUpperCase(),
      field: TableFields.favorite,
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
            onToggle: view().onFavoriteToggled != null
                ? () => view().onFavoriteToggled!(item.id)
                : null,
          ),
        );
      },
    ),
    TrinaColumn(
      title: l.rating.toUpperCase(),
      field: TableFields.rating,
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
            onRatingChanged: view().onRatingChanged != null
                ? (double? r) => view().onRatingChanged!(item.id, r)
                : null,
          ),
        );
      },
    ),
    TrinaColumn(
      title: l.collectionTableExternalRating.toUpperCase(),
      field: TableFields.externalRating,
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
      title: l.year.toUpperCase(),
      field: TableFields.year,
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
      field: TableFields.tags,
      type: TrinaColumnType.text(),
      width: 200,
      minWidth: 100,
      readOnly: true,
      enableEditingMode: false,
      enableContextMenu: false,
      enableSorting: sortable,
      renderer: (TrinaColumnRendererContext ctx) {
        final CollectionItem item = ctx.row.data as CollectionItem;
        final CollectionTableView w = view();
        return TagCell(
          tags: w.tags.orderedFor(w.itemTags[item.id]),
          onEditTags: w.onTagsEdit != null
              ? () => w.onTagsEdit!(item.id)
              : null,
        );
      },
    ),
  ];
  _applyLayout(columns, layout);
  return columns;
}

/// Applies the persisted per-collection order, widths and hidden columns.
void _applyLayout(List<TrinaColumn> columns, TableColumnLayout? layout) {
  if (layout == null) return;
  for (final TrinaColumn column in columns) {
    final double? width = layout.widths[column.field];
    if (width != null && width >= column.minWidth) {
      column.width = width;
    }
    // Never restore the thumbnail column as hidden — it's not toggleable.
    if (column.field != TableFields.thumb) {
      column.hide = layout.hidden.contains(column.field);
    }
  }
  if (layout.order.isEmpty) return;
  // Fields missing from the saved order keep their relative position at the
  // end (List.sort is not stable, so encode the fallback explicitly).
  final Map<String, int> savedIndex = <String, int>{
    for (int i = 0; i < layout.order.length; i++) layout.order[i]: i,
  };
  final Map<String, int> sortKey = <String, int>{
    for (int i = 0; i < columns.length; i++)
      columns[i].field: savedIndex[columns[i].field] ?? layout.order.length + i,
  };
  columns.sort(
    (TrinaColumn a, TrinaColumn b) =>
        sortKey[a.field]!.compareTo(sortKey[b.field]!),
  );
}
