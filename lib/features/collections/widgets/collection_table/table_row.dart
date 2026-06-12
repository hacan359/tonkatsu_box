import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/constants/media_type_theme.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/collection_tag.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../extensions/item_display_name.dart';
import 'cells/rating_cell.dart';
import 'cells/status_cell.dart';
import 'cells/tag_cell.dart';
import 'cells/thumbnail_cell.dart';
import 'table_column.dart';

/// One row of the collection table. The row is a transparent card with a
/// subtle [AppColors.surfaceLight] tint; hover and selected just shift the
/// alpha. No backdrop image — keeps rendering predictable across media types.
class TableRow extends StatefulWidget {
  const TableRow({
    required this.item,
    required this.onTap,
    this.onSecondaryTap,
    this.onRatingChanged,
    this.onStatusChanged,
    this.onTagChanged,
    this.tag,
    this.tags = const <CollectionTag>[],
    this.dragIndex,
    this.isSelected = false,
    this.onToggleSelect,
    super.key,
  });

  final CollectionItem item;
  final VoidCallback onTap;
  final void Function(Offset globalPosition)? onSecondaryTap;
  final void Function(int itemId, double? rating)? onRatingChanged;
  final void Function(int itemId, ItemStatus status, MediaType mediaType)?
      onStatusChanged;
  final void Function(int itemId, int? tagId)? onTagChanged;
  final CollectionTag? tag;
  final List<CollectionTag> tags;

  /// Non-null in reorder mode — drives the drag handle hit area.
  final int? dragIndex;

  final bool isSelected;
  final VoidCallback? onToggleSelect;

  @override
  State<TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final CollectionItem item = widget.item;

    // Subtle per-row card so rows visually separate from one another against
    // the page background. Hover/selected just shift the alpha, keeping the
    // rhythm consistent.
    final Color bgColor = widget.isSelected
        ? AppColors.brand.withAlpha(50)
        : (_hovered
            ? AppColors.surfaceLight.withAlpha(70)
            : AppColors.surfaceLight.withAlpha(28));

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onSecondaryTapUp: widget.onSecondaryTap != null
              ? (TapUpDetails details) =>
                  widget.onSecondaryTap!(details.globalPosition)
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: InkWell(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                color: bgColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: _RowContent(
                  item: item,
                  tag: widget.tag,
                  tags: widget.tags,
                  dragIndex: widget.dragIndex,
                  isSelected: widget.isSelected,
                  onToggleSelect: widget.onToggleSelect,
                  onRatingChanged: widget.onRatingChanged,
                  onStatusChanged: widget.onStatusChanged,
                  onTagChanged: widget.onTagChanged,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowContent extends ConsumerWidget {
  const _RowContent({
    required this.item,
    required this.tag,
    required this.tags,
    required this.dragIndex,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onRatingChanged,
    required this.onStatusChanged,
    required this.onTagChanged,
  });

  final CollectionItem item;
  final CollectionTag? tag;
  final List<CollectionTag> tags;
  final int? dragIndex;
  final bool isSelected;
  final VoidCallback? onToggleSelect;
  final void Function(int itemId, double? rating)? onRatingChanged;
  final void Function(int itemId, ItemStatus status, MediaType mediaType)?
      onStatusChanged;
  final void Function(int itemId, int? tagId)? onTagChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String displayName = ref.displayNameOf(item);
    return Row(
      children: <Widget>[
        if (onToggleSelect != null)
          SizedBox(
            width: kCheckboxColumnWidth,
            child: Center(
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect!(),
              ),
            ),
          ),
        if (dragIndex != null)
          SizedBox(
            width: kDragHandleWidth,
            child: ReorderableDragStartListener(
              index: dragIndex!,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: AppColors.textTertiary.withAlpha(180),
                ),
              ),
            ),
          ),
        ThumbnailCell(
          item: item,
          width: kThumbWidth,
          height: kThumbHeight,
          radius: kThumbRadius,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                displayName,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.genresString != null && item.genresString!.isNotEmpty)
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
        SizedBox(
          width: 140,
          child: Text(
            _platformLabel(item),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 56,
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    MediaTypeTheme.colorFor(item.mediaType).withAlpha(40),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                MediaTypeTheme.iconFor(item.mediaType),
                size: 14,
                color: MediaTypeTheme.colorFor(item.mediaType),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 140,
          child: StatusCell(
            status: item.status,
            mediaType: item.mediaType,
            onStatusChanged: onStatusChanged != null
                ? (ItemStatus s) =>
                    onStatusChanged!(item.id, s, item.mediaType)
                : null,
          ),
        ),
        SizedBox(
          width: 60,
          child: RatingCell(
            rating: item.userRating,
            onRatingChanged: onRatingChanged != null
                ? (double? r) => onRatingChanged!(item.id, r)
                : null,
          ),
        ),
        SizedBox(
          width: 60,
          child: RatingCell(rating: item.apiRating),
        ),
        SizedBox(
          width: 56,
          child: Center(
            child: Text(
              item.releaseYear?.toString() ?? '',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: TagCell(
            tag: tag,
            tags: tags,
            onTagChanged: onTagChanged != null
                ? (int? tagId) => onTagChanged!(item.id, tagId)
                : null,
          ),
        ),
      ],
    );
  }
}

String _platformLabel(CollectionItem item) {
  if (item.mediaType != MediaType.game) return '';
  return item.platform?.abbreviation ?? item.platform?.name ?? '';
}

