import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Single progress fact tile: icon + label on top, value below. Shows an
/// edit hint icon and becomes tappable when [onTap] is set.
class ProgressTile extends StatelessWidget {
  const ProgressTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hasValue,
    this.tooltip,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool hasValue;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: AppColors.brand,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    Widget tile = Material(
      color: AppColors.surfaceLight.withAlpha(120),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: body,
            )
          : body,
    );
    if (tooltip != null) {
      tile = Tooltip(message: tooltip, child: tile);
    }
    return tile;
  }
}

/// Symmetric grid of [tiles]: one row on wide layouts, 2 per row under
/// 480px; [trailing] is centered to the right of the grid.
class ProgressTileGrid extends StatelessWidget {
  const ProgressTileGrid({
    required this.tiles,
    required this.trailing,
    super.key,
  });

  final List<Widget> tiles;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int perRow = constraints.maxWidth < 480 ? 2 : tiles.length;
        final List<Widget> rows = <Widget>[];
        for (int i = 0; i < tiles.length; i += perRow) {
          final int end =
              (i + perRow > tiles.length) ? tiles.length : i + perRow;
          final List<Widget> chunk = tiles.sublist(i, end);
          if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.sm));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int j = 0; j < perRow; j++) ...<Widget>[
                  if (j > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: j < chunk.length ? chunk[j] : const SizedBox(),
                  ),
                ],
              ],
            ),
          );
        }
        final Widget grid = Column(children: rows);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: grid),
            const SizedBox(width: AppSpacing.xs),
            trailing,
          ],
        );
      },
    );
  }
}
