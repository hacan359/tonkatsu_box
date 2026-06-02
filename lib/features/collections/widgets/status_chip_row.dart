import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

const String _kStatusMenuPrefix = 'status:';

/// Decodes a `showMenu` value produced by [statusChipPopupMenuEntries].
///
/// Returns `null` for ordinary (non-status) menu entries.
ItemStatus? tryDecodeStatusMenuValue(String value) {
  if (!value.startsWith(_kStatusMenuPrefix)) return null;
  return ItemStatus.fromString(value.substring(_kStatusMenuPrefix.length));
}

/// Builds a "Status" header and a [StatusChipRow] for use inside `showMenu`.
///
/// Tapping a segment closes the menu via `Navigator.pop` with an encoded value;
/// the caller decodes it through [tryDecodeStatusMenuValue].
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
        l.detailStatus.toUpperCase(),
        style: const TextStyle(
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
///
/// Every status sits in an equal-width segment; the selected one is highlighted
/// with a soft tint of its status color while the rest stay muted. Tapping a
/// segment invokes [onChanged].
class StatusChipRow extends StatelessWidget {
  /// Creates a [StatusChipRow].
  const StatusChipRow({
    required this.status,
    required this.mediaType,
    required this.onChanged,
    super.key,
  });

  /// Currently selected status.
  final ItemStatus status;

  /// Media type, which drives the per-status labels.
  final MediaType mediaType;

  /// Called when a different status segment is tapped.
  final void Function(ItemStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    const List<ItemStatus> statuses = ItemStatus.values;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
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

  final ItemStatus status;
  final MediaType mediaType;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status.color;
    return Tooltip(
      message: status.localizedLabel(S.of(context), mediaType),
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? statusColor.withAlpha(48) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          alignment: Alignment.center,
          child: Icon(
            status.materialIcon,
            size: 18,
            color: isSelected ? statusColor : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
