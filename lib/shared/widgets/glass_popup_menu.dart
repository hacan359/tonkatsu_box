import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_panel.dart';

/// A popup menu drawn on a [GlassPanel]: the route's own Material stays
/// clear and one disabled entry carries the frosted body with [rows].
class GlassPopupMenuButton<T> extends StatelessWidget {
  const GlassPopupMenuButton({
    required this.rows,
    this.child,
    this.icon,
    this.iconSize,
    this.onSelected,
    this.tooltip,
    this.offset = const Offset(0, 44),
    this.constraints,
    super.key,
  }) : assert(child == null || icon == null, 'child or icon, not both');

  /// Built per open so checkmarks reflect the current state.
  final List<Widget> Function(BuildContext menuContext) rows;

  /// The trigger; with neither this nor [icon] the Material default icon.
  final Widget? child;
  final Widget? icon;
  final double? iconSize;
  final ValueChanged<T>? onSelected;
  final String? tooltip;
  final Offset offset;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      offset: offset,
      constraints: constraints,
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      padding: EdgeInsets.zero,
      icon: icon,
      iconSize: iconSize,
      onSelected: onSelected,
      itemBuilder: (BuildContext ctx) => <PopupMenuEntry<T>>[
        PopupMenuItem<T>(
          enabled: false,
          height: 0,
          padding: EdgeInsets.zero,
          child: GlassPanel(
            radius: AppSpacing.radiusMd,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            // The disabled entry dims descendant icons; restore them.
            child: IconTheme.merge(
              data: const IconThemeData(opacity: 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows(ctx),
              ),
            ),
          ),
        ),
      ],
      child: child,
    );
  }
}

/// One row of a [GlassPopupMenuButton]; tapping pops the menu with [value]
/// (or just closes it when [value] is null and [onTap] does the work).
class GlassMenuRow<T> extends StatelessWidget {
  const GlassMenuRow({
    required this.label,
    this.value,
    this.icon,
    this.iconColor,
    this.onTap,
    this.closeOnTap = true,
    this.checked = false,
    this.labelColor,
    super.key,
  });

  final String label;
  final T? value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool closeOnTap;

  /// The current choice: a check mark takes the icon's place.
  final bool checked;

  /// Tints the label, for a destructive entry.
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final IconData? leading = checked ? Icons.check : icon;
    final Color leadingColor = checked
        ? AppColors.brand
        : (iconColor ?? AppColors.textTertiary);
    return InkWell(
      onTap: () {
        if (closeOnTap) Navigator.of(context).pop(value);
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (leading != null)
              Icon(leading, size: 16, color: leadingColor)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: checked
                      ? AppColors.brand
                      : (labelColor ?? AppColors.textPrimary),
                  fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hairline between row groups inside a glass menu.
class GlassMenuDivider extends StatelessWidget {
  const GlassMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 8,
      thickness: 0.5,
      color: AppColors.textPrimary.withAlpha(30),
    );
  }
}
