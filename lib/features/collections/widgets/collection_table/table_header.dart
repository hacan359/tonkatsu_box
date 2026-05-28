import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/collection_tag.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import 'table_column.dart';

/// Sticky header for the collection table view.
///
/// Tapping a column header cycles between sort direction or filter values
/// depending on the column kind. In reorder mode all clicks are disabled
/// because the row order is driven by the parent.
class TableHeader extends StatelessWidget {
  const TableHeader({
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
    this.isReorderable = false,
    this.selectionState,
    this.onToggleSelectAll,
    super.key,
  });

  final TableColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<TableColumn> onSort;
  final S l;
  final ItemStatus? filterStatus;
  final MediaType? filterType;
  final double? filterRating;
  final int? filterTagId;
  final String? filterPlatform;
  final Map<int, CollectionTag> tagMap;
  final bool isReorderable;

  /// `null` hides the select-all checkbox column; otherwise the value drives
  /// the tri-state checkbox: true = all visible selected, false = none,
  /// null = partial.
  final bool? selectionState;

  final void Function(bool selectAll)? onToggleSelectAll;

  @override
  Widget build(BuildContext context) {
    // The header floats over the page background. No fill, no border —
    // it reads as a label strip above the rows rather than a table chrome.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          if (onToggleSelectAll != null)
            SizedBox(
              width: kCheckboxColumnWidth,
              child: Center(
                child: Checkbox(
                  value: selectionState,
                  tristate: true,
                  onChanged: (bool? value) {
                    // Treat partial/false as "select all", true as "deselect".
                    onToggleSelectAll!(selectionState != true);
                  },
                ),
              ),
            ),
          if (isReorderable) const SizedBox(width: kDragHandleWidth),
          const SizedBox(width: kThumbWidth + AppSpacing.sm),
          _col(
            l.collectionTableName,
            TableColumn.name,
            flex: 5,
          ),
          _col(
            filterPlatform != null
                ? (filterPlatform!.isEmpty ? '—' : filterPlatform!)
                : l.collectionTablePlatform,
            TableColumn.platform,
            width: 140,
            alignCenter: true,
            isFiltered: filterPlatform != null,
          ),
          _col(
            filterType != null
                ? filterType!.localizedLabel(l)
                : l.collectionTableType,
            TableColumn.type,
            width: 56,
            alignCenter: true,
            isFiltered: filterType != null,
          ),
          _col(
            filterStatus != null
                ? filterStatus!.genericLabel(l)
                : l.collectionTableStatus,
            TableColumn.status,
            width: 140,
            alignCenter: true,
            isFiltered: filterStatus != null,
          ),
          _col(
            filterRating != null
                ? (filterRating == 0
                    ? '—'
                    : '★ ${filterRating!.toStringAsFixed(1)}')
                : l.collectionTableRating,
            TableColumn.rating,
            width: 60,
            alignCenter: true,
            isFiltered: filterRating != null,
          ),
          _col(
            l.collectionTableExternalRating,
            TableColumn.externalRating,
            width: 60,
            alignCenter: true,
          ),
          _col(
            l.collectionTableYear,
            TableColumn.year,
            width: 56,
            alignCenter: true,
          ),
          _col(
            filterTagId != null
                ? (filterTagId == 0
                    ? '—'
                    : tagMap[filterTagId]?.name ?? l.tagLabel)
                : l.tagLabel,
            TableColumn.tag,
            flex: 2,
            isFiltered: filterTagId != null,
          ),
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
    bool alignCenter = false,
    bool isFiltered = false,
  }) {
    final bool isActive = !isReorderable && column == sortColumn;
    final bool showFilterIcon = !isReorderable && isFiltered;
    final bool highlighted = isActive || showFilterIcon;
    final Widget cell = InkWell(
      key: ValueKey<TableColumn>(column),
      onTap: isReorderable ? null : () => onSort(column),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text.rich(
          TextSpan(
            text: label.toUpperCase(),
            children: <InlineSpan>[
              if (isActive && !showFilterIcon)
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
              if (showFilterIcon)
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
            color:
                highlighted ? AppColors.brand : AppColors.textTertiary,
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.8,
            fontSize: 10.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd
              ? TextAlign.end
              : (alignCenter ? TextAlign.center : TextAlign.start),
        ),
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex, child: cell);
  }
}
