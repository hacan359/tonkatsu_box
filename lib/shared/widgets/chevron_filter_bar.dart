import 'package:core/models/item_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;

import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../constants/item_status_ui.dart';

/// Filter-bar segment: a V-notch on the left (except the first) and a
/// V-point on the right (except the last). [compact] shows a tooltip'd icon
/// instead of text; [subtitle] renders two lines (subtitle above the label)
/// and is ignored when `compact: true`.
class ChevronSegment extends StatelessWidget {
  const ChevronSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    this.compact = false,
    this.subtitle,
    this.tintWhenInactive = false,
    super.key,
  });

  final String label;

  /// Icon for the compact mode.
  final IconData icon;

  final bool selected;

  /// Fill color when selected.
  final Color accentColor;

  /// First segment (straight left edge).
  final bool isFirst;

  /// Last segment (straight right edge).
  final bool isLast;

  final VoidCallback onTap;

  /// Show the icon instead of the text.
  final bool compact;

  /// Optional two-line mode: subtitle above, label below.
  final String? subtitle;

  /// When inactive, tint the background/content with a muted [accentColor]
  /// instead of neutral grey.
  final bool tintWhenInactive;

  /// Width of the chevron bevel.
  static const double chevronWidth = 6;

  /// Background alpha of an inactive tinted segment (~15%).
  static const int inactiveTintBgAlpha = 38;

  /// Content (text/icon) alpha of an inactive tinted segment.
  static const int inactiveTintContentAlpha = 220;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color contentColor;
    if (selected) {
      bg = accentColor;
      contentColor = AppColors.background;
    } else if (tintWhenInactive) {
      bg = accentColor.withAlpha(inactiveTintBgAlpha);
      contentColor = accentColor.withAlpha(inactiveTintContentAlpha);
    } else {
      bg = AppColors.surface;
      contentColor = AppColors.textSecondary;
    }

    return ClipPath(
      clipper: ChevronClipper(
        chevronWidth: chevronWidth,
        hasLeftNotch: !isFirst,
        hasRightPoint: !isLast,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        color: bg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.only(
                left: isFirst ? 4 : chevronWidth + 1,
                right: isLast ? 4 : chevronWidth + 1,
              ),
              child: Center(
                child: buildChevronContent(
                  context: context,
                  label: label,
                  icon: icon,
                  subtitle: subtitle,
                  contentColor: contentColor,
                  selected: selected,
                  compact: compact,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segment content shared by [ChevronSegment] and [DropdownChevronSegment]:
/// icon with a tooltip when compact, two-line text when [subtitle] is set,
/// a single-line label otherwise. On narrow screens ([isCompactScreen])
/// fonts shrink to ~83%, matching MediaPosterCard / RatingBadge.
Widget buildChevronContent({
  required BuildContext context,
  required String label,
  required IconData icon,
  required String? subtitle,
  required Color contentColor,
  required bool selected,
  required bool compact,
}) {
  if (compact) {
    return Tooltip(
      message: label,
      child: Icon(icon, size: 18, color: contentColor),
    );
  }

  final bool dense = isCompactScreen(context);
  // 12 → 10, 9 → 8 — same ratio as MediaPosterCard.tagName / RatingBadge.
  final double labelSize = dense ? 10 : 12;
  final double subtitleSize = dense ? 8 : 9;

  if (subtitle == null) {
    return Text(
      label,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: AppTypography.bodySmall.copyWith(
        color: contentColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        fontSize: labelSize,
      ),
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        subtitle,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: subtitleSize,
          color: contentColor.withAlpha(selected ? 180 : 140),
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: AppTypography.bodySmall.copyWith(
          color: contentColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: labelSize,
          height: 1.1,
        ),
      ),
    ],
  );
}

/// Clips a rectangle into the chevron (arrow segment) shape.
class ChevronClipper extends CustomClipper<Path> {
  const ChevronClipper({
    required this.chevronWidth,
    required this.hasLeftNotch,
    required this.hasRightPoint,
  });

  /// Width of the V bevel.
  final double chevronWidth;

  /// V notch on the left edge.
  final bool hasLeftNotch;

  /// V point on the right edge.
  final bool hasRightPoint;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double mid = size.height / 2;

    if (hasLeftNotch) {
      path.moveTo(0, 0);
      path.lineTo(chevronWidth, mid);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
    }

    if (hasRightPoint) {
      path.lineTo(size.width - chevronWidth, size.height);
      path.lineTo(size.width, mid);
      path.lineTo(size.width - chevronWidth, 0);
    } else {
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ChevronClipper old) {
    return chevronWidth != old.chevronWidth ||
        hasLeftNotch != old.hasLeftNotch ||
        hasRightPoint != old.hasRightPoint;
  }
}

/// Status-picker chevron segment: looks like [ChevronSegment] but opens a
/// [PopupMenuButton] with the status list. Optional [subtitle] renders two
/// lines and is ignored in `compact` mode.
class StatusDropdownSegment extends StatelessWidget {
  const StatusDropdownSegment({
    required this.status,
    required this.compact,
    required this.onChanged,
    this.subtitle,
    this.isLast = true,
    super.key,
  });

  /// Currently selected status (null = all).
  final ItemStatus? status;

  /// Show the icon instead of the text.
  final bool compact;

  final ValueChanged<ItemStatus?> onChanged;

  /// Optional two-line mode: caption above, selected status below.
  final String? subtitle;

  /// `false` draws a right-pointing chevron edge so another segment can follow.
  final bool isLast;

  static const double _chevronWidth = 6;

  static const List<ItemStatus> _order = <ItemStatus>[
    ItemStatus.inProgress,
    ItemStatus.replaying,
    ItemStatus.planned,
    ItemStatus.notStarted,
    ItemStatus.completed,
    ItemStatus.dropped,
  ];

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final bool active = status != null;
    final Color accentColor = active ? status!.color : AppColors.surface;
    final Color contentColor =
        active ? AppColors.background : AppColors.textSecondary;
    final String label = active ? status!.genericLabel(l) : l.all;
    final IconData icon = active ? status!.materialIcon : Icons.filter_list;

    return PopupMenuButton<String>(
      onSelected: (String v) {
        onChanged(v == 'all' ? null : ItemStatus.fromString(v));
      },
      offset: const Offset(0, 40),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
        _menuItem('all', Icons.filter_list_off, l.all,
            status == null, null),
        const PopupMenuDivider(height: 8),
        for (final ItemStatus s in _order)
          _menuItem(s.value, s.materialIcon, s.genericLabel(l),
              status == s, s.color),
      ],
      child: ClipPath(
        clipper: ChevronClipper(
          chevronWidth: _chevronWidth,
          hasLeftNotch: true,
          hasRightPoint: !isLast,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          color: accentColor,
          child: Padding(
            padding: EdgeInsets.only(
              left: _chevronWidth + 1,
              right: isLast ? 4 : _chevronWidth + 1,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: buildChevronContent(
                        context: context,
                        label: label,
                        icon: icon,
                        subtitle: subtitle,
                        contentColor: contentColor,
                        selected: active,
                        compact: compact,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: contentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    bool selected,
    Color? statusColor,
  ) {
    final Color itemColor = selected
        ? (statusColor ?? AppColors.brand)
        : AppColors.textPrimary;
    final Color iconColor = selected
        ? (statusColor ?? AppColors.brand)
        : AppColors.textTertiary;

    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: itemColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chevron segment that opens a dropdown menu built by [menuBuilder];
/// long menus get scroll-arrow hints (see [showArrowedMenu]). Supports the
/// optional two-line [subtitle] and a drop-down indicator next to the label.
class DropdownChevronSegment<T extends Object> extends StatelessWidget {
  const DropdownChevronSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.menuBuilder,
    required this.onSelected,
    this.subtitle,
    this.compact = false,
    super.key,
  });

  final String label;

  /// Icon for the compact mode.
  final IconData icon;

  final bool selected;

  /// Fill color when selected.
  final Color accentColor;

  /// First segment (straight left edge).
  final bool isFirst;

  /// Last segment (straight right edge).
  final bool isLast;

  final List<PopupMenuEntry<T>> Function(BuildContext) menuBuilder;

  final ValueChanged<T?> onSelected;

  /// Optional two-line mode: subtitle above, label below.
  final String? subtitle;

  /// Show only the icon.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? accentColor : AppColors.surface;
    final Color contentColor =
        selected ? AppColors.background : AppColors.textSecondary;

    return ClipPath(
      clipper: ChevronClipper(
        chevronWidth: ChevronSegment.chevronWidth,
        hasLeftNotch: !isFirst,
        hasRightPoint: !isLast,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        color: bg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openMenu(context),
            child: Padding(
              padding: EdgeInsets.only(
                left: isFirst ? 4 : ChevronSegment.chevronWidth + 1,
                right: isLast ? 4 : ChevronSegment.chevronWidth + 1,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: buildChevronContent(
                        context: context,
                        label: label,
                        icon: icon,
                        subtitle: subtitle,
                        contentColor: contentColor,
                        selected: selected,
                        compact: compact,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 14, color: contentColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final T? value = await showArrowedMenu<T>(
      context: context,
      entries: menuBuilder(context),
    );
    // null = dismissed without choosing, same as PopupMenuButton's cancel.
    if (value != null) onSelected(value);
  }
}

/// Shows [entries] in a popup anchored below [context]'s widget, like
/// [PopupMenuButton], but with carousel-style up/down arrow hints that are
/// visible from the moment the menu opens when part of the list is cut off
/// (the stock popup scrolls silently until the pointer hovers it).
Future<T?> showArrowedMenu<T extends Object>({
  required BuildContext context,
  required List<PopupMenuEntry<T>> entries,
}) {
  final NavigatorState navigator = Navigator.of(context);
  final RenderBox button = context.findRenderObject()! as RenderBox;
  final RenderBox overlay =
      navigator.overlay!.context.findRenderObject()! as RenderBox;
  final Rect buttonRect = Rect.fromPoints(
    button.localToGlobal(Offset.zero, ancestor: overlay),
    button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    ),
  );
  return navigator.push(_ArrowedMenuRoute<T>(
    buttonRect: buttonRect,
    entries: entries,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  ));
}

class _ArrowedMenuRoute<T extends Object> extends PopupRoute<T> {
  _ArrowedMenuRoute({
    required this.buttonRect,
    required this.entries,
    required this.capturedThemes,
    required this.barrierLabel,
  });

  final Rect buttonRect;
  final List<PopupMenuEntry<T>> entries;
  final CapturedThemes capturedThemes;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return CustomSingleChildLayout(
      delegate: _ArrowedMenuLayout(buttonRect: buttonRect),
      child: capturedThemes.wrap(_ArrowedMenu<T>(entries: entries)),
    );
  }
}

/// Positions the menu under the button and keeps it inside the screen with
/// an 8px margin; height is capped at 75% of the available space so long
/// menus scroll instead of overflowing.
class _ArrowedMenuLayout extends SingleChildLayoutDelegate {
  const _ArrowedMenuLayout({required this.buttonRect});

  final Rect buttonRect;

  static const double _margin = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: 180,
      maxWidth: constraints.maxWidth - _margin * 2,
      maxHeight: constraints.maxHeight * 0.75,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double maxX = size.width - childSize.width - _margin;
    final double maxY = size.height - childSize.height - _margin;
    final double x = buttonRect.left
        .clamp(_margin, maxX < _margin ? _margin : maxX)
        .toDouble();
    final double y = buttonRect.bottom
        .clamp(_margin, maxY < _margin ? _margin : maxY)
        .toDouble();
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_ArrowedMenuLayout oldDelegate) =>
      buttonRect != oldDelegate.buttonRect;
}

class _ArrowedMenu<T extends Object> extends StatefulWidget {
  const _ArrowedMenu({required this.entries});

  final List<PopupMenuEntry<T>> entries;

  @override
  State<_ArrowedMenu<T>> createState() => _ArrowedMenuState<T>();
}

class _ArrowedMenuState<T extends Object> extends State<_ArrowedMenu<T>> {
  final ScrollController _controller = ScrollController();

  bool _scrollable = false;
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    // maxScrollExtent is only known after the first layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!mounted || !_controller.hasClients) return;
    final ScrollPosition pos = _controller.position;
    final bool scrollable = pos.maxScrollExtent > 0;
    final bool up = pos.pixels > pos.minScrollExtent + 1;
    final bool down = pos.pixels < pos.maxScrollExtent - 1;
    if (scrollable != _scrollable ||
        up != _canScrollUp ||
        down != _canScrollDown) {
      setState(() {
        _scrollable = scrollable;
        _canScrollUp = up;
        _canScrollDown = down;
      });
    }
  }

  void _scrollBy(double direction) {
    final ScrollPosition pos = _controller.position;
    final double target =
        (pos.pixels + direction * pos.viewportDimension * 0.8)
            .clamp(pos.minScrollExtent, pos.maxScrollExtent)
            .toDouble();
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Widget _arrow({required bool up, required bool enabled}) {
    return InkWell(
      onTap: enabled ? () => _scrollBy(up ? -1 : 1) : null,
      child: SizedBox(
        height: 22,
        child: Center(
          child: Icon(
            up ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 18,
            color: enabled
                ? AppColors.textSecondary
                : AppColors.textTertiary.withAlpha(60),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PopupMenuItem announces the menuItem semantics role, which requires a
    // menu-role ancestor (the stock popup route provides one).
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      role: SemanticsRole.menu,
      child: IntrinsicWidth(
        child: Material(
          color: AppColors.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_scrollable) _arrow(up: true, enabled: _canScrollUp),
              Flexible(
                child: SingleChildScrollView(
                  controller: _controller,
                  padding: _scrollable
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: ListBody(children: widget.entries),
                ),
              ),
              if (_scrollable) _arrow(up: false, enabled: _canScrollDown),
            ],
          ),
        ),
      ),
    );
  }
}
