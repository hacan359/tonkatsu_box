import 'package:core/models/collection_item.dart';
import 'package:core/models/marked_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../home/providers/all_items_provider.dart';
import '../providers/marked_units_provider.dart';
import '../utils/marked_unit_label.dart';

/// One title with its marked units listed underneath. Any tap opens the
/// title's card — scrolling to the unit itself is not attempted.
class MarkedGroupTile extends ConsumerWidget {
  const MarkedGroupTile({
    required this.group,
    required this.onOpen,
    super.key,
  });

  final MarkedUnitGroup group;
  final VoidCallback onOpen;

  static const double _coverWidth = 36;
  static const double _coverHeight = 54;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final CollectionItem item = group.item;
    final String? collectionName =
        ref.watch(collectionNamesProvider)[item.collectionId];
    final String subtitle = <String>[
      item.mediaType.localizedLabel(l),
      ?collectionName,
    ].join(' · ');

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  _Cover(item: item),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.itemName,
                          style: AppTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: MediaTypeTheme.colorFor(item.mediaType),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 0.5, thickness: 0.5, color: AppColors.surfaceBorder),
          for (final MarkedUnit unit in group.units)
            _UnitRow(unit: unit, label: markedUnitLabel(l, unit), onTap: onOpen),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final String? url = item.thumbnailUrl;
    final Widget placeholder = Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(
        MediaTypeTheme.placeholderIconFor(item.mediaType),
        size: 16,
        color: AppColors.textTertiary,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: SizedBox(
        width: MarkedGroupTile._coverWidth,
        height: MarkedGroupTile._coverHeight,
        child: url == null || url.isEmpty
            ? placeholder
            : CachedImage(
                imageType: item.imageType,
                imageId: item.coverImageId,
                remoteUrl: url,
                fit: BoxFit.cover,
                placeholder: placeholder,
                errorWidget: placeholder,
              ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.label,
    required this.onTap,
  });

  final MarkedUnit unit;
  final String label;
  final VoidCallback onTap;

  /// Fixed slot for the two mark icons so labels line up across rows.
  static const double _iconSlot = 40;
  static const double _iconSize = 14;
  static const double _noteGap = 2;

  @override
  Widget build(BuildContext context) {
    final String? note = unit.mark.note;
    final TextStyle labelStyle =
        AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500);
    // The slot is exactly one label line tall so the icons sit centred on
    // the label, whatever the text scale, while a note wraps below.
    final double lineHeight =
        MediaQuery.textScalerOf(context).scale(labelStyle.fontSize ?? 0) *
            (labelStyle.height ?? 1);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Both icons can show at once: a unit may be liked and noted.
            SizedBox(
              width: _iconSlot,
              height: lineHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (unit.mark.isFavorite)
                    Icon(
                      Icons.favorite,
                      size: _iconSize,
                      color: AppColors.favorite,
                    ),
                  if (unit.mark.isFavorite && note != null)
                    const SizedBox(width: AppSpacing.xs),
                  if (note != null)
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: _iconSize,
                      color: AppColors.textTertiary,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: _noteGap),
                      child: Text(
                        note,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
