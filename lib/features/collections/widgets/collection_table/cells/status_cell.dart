import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_typography.dart';
import '../../../../../shared/constants/item_status_ui.dart';

class StatusCell extends StatelessWidget {
  const StatusCell({
    required this.status,
    required this.mediaType,
    this.onStatusChanged,
    super.key,
  });

  final ItemStatus status;
  final MediaType mediaType;
  final ValueChanged<ItemStatus>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final Color color = status.color;

    final Widget chip = Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withAlpha(110)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
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
          ],
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
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.brand,
                ),
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
