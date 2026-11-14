import 'package:material_ui/material_ui.dart';

import '../navigation/frame_chrome.dart';
import '../navigation/frame_metrics.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Inside the app frame the title, back button and actions are lent to its
/// top zone; outside it they are drawn as a plain row.
class FramePage extends StatelessWidget {
  const FramePage({
    required this.child,
    this.title,
    this.onBack,
    this.actions = const <Widget>[],
    this.header,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;

  /// Null on a tab's root screen, which has nothing to go back to.
  final String? title;

  /// Defaults to `Navigator.pop` whenever the page has a title or actions.
  final VoidCallback? onBack;

  final List<Widget> actions;

  /// Fixed panels (filters, chips) above the scrolling body.
  final Widget? header;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bool hasChrome =
        title != null || onBack != null || actions.isNotEmpty;
    final bool inFrame = FrameChromeScope.maybeOf(context) != null;
    final VoidCallback back = onBack ?? () => Navigator.of(context).pop();

    final Widget body = Padding(padding: padding, child: child);
    final Widget? row = hasChrome && !inFrame
        ? _TitleRow(title: title, onBack: back, actions: actions)
        : null;
    final Widget page = Material(
      type: MaterialType.transparency,
      child: row == null && header == null
          ? body
          : Column(
              children: <Widget>[
                ?row,
                ?header,
                Expanded(child: body),
              ],
            ),
    );
    if (!hasChrome || !inFrame) return page;
    return FrameChromeBinding(
      chrome: FrameChrome(
        title: title,
        onBack: back,
        actions: actions,
        priority: 1,
      ),
      child: page,
    );
  }
}

/// Stands in for an AppBar inside a tab Navigator, where a real app bar
/// would sit above the wrong route.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.onBack,
    required this.actions,
  });

  final String? title;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kFrameTitleRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            color: AppColors.textTertiary,
            visualDensity: VisualDensity.compact,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title ?? '',
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
