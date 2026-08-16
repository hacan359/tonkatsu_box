import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_durations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/constants/item_status_ui.dart';

const String _kStatusMenuPrefix = 'status:';

/// Decodes a `showMenu` value produced by [statusChipPopupMenuEntries];
/// returns `null` for ordinary (non-status) menu entries.
ItemStatus? tryDecodeStatusMenuValue(String value) {
  if (!value.startsWith(_kStatusMenuPrefix)) return null;
  return ItemStatus.fromString(value.substring(_kStatusMenuPrefix.length));
}

/// Tapping a segment pops the menu with an encoded value; the caller
/// decodes it through [tryDecodeStatusMenuValue].
List<PopupMenuEntry<String>> statusChipPopupMenuEntries({
  required BuildContext context,
  required CollectionItem item,
}) {
  final S l = S.of(context);
  return <PopupMenuEntry<String>>[
    const PopupMenuDivider(),
    PopupMenuItem<String>(
      enabled: false,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        l.status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.textTertiary,
        ),
      ),
    ),
    PopupMenuItem<String>(
      enabled: false,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: StatusChipRow(
        status: item.status,
        mediaType: item.displayMediaType,
        onChanged: (ItemStatus newStatus) => Navigator.of(context)
            .pop('$_kStatusMenuPrefix${newStatus.value}'),
      ),
    ),
  ];
}

/// Segmented status switcher rendered as a single rounded "pill".
class StatusChipRow extends StatelessWidget {
  const StatusChipRow({
    required this.status,
    required this.mediaType,
    required this.onChanged,
    super.key,
  });

  final ItemStatus status;

  /// Media type, which drives the per-status labels.
  final MediaType mediaType;

  final void Function(ItemStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    const List<ItemStatus> statuses = ItemStatus.values;
    final int selectedIndex = statuses.indexOf(status);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: SizedBox(
        height: _StatusSegment.height,
        child: Stack(
          children: <Widget>[
            // Implicitly animated highlight; Alignment-based (not
            // LayoutBuilder) so popup menus can measure via IntrinsicWidth.
            Positioned.fill(
              child: AnimatedAlign(
                duration: AppDurations.slow,
                curve: Curves.easeOutCubic,
                alignment: Alignment(
                  statuses.length > 1
                      ? -1 + 2 * selectedIndex / (statuses.length - 1)
                      : 0,
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / statuses.length,
                  heightFactor: 1,
                  child: AnimatedContainer(
                    duration: AppDurations.slow,
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: status.color.withAlpha(48),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                for (final ItemStatus s in statuses)
                  Expanded(
                    child: _StatusSegment(
                      status: s,
                      mediaType: mediaType,
                      isSelected: s == status,
                      onTap: () => onChanged(s),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSegment extends StatelessWidget {
  const _StatusSegment({
    required this.status,
    required this.mediaType,
    required this.isSelected,
    required this.onTap,
  });

  static const double height = 34;

  final ItemStatus status;
  final MediaType mediaType;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: status.localizedLabel(S.of(context), mediaType),
      waitDuration: AppDurations.tooltipDelay,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: height,
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                end: isSelected ? status.color : AppColors.textTertiary,
              ),
              duration: AppDurations.slow,
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, Color? color, Widget? _) =>
                  Icon(status.materialIcon, size: 18, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
