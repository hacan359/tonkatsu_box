import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';
import 'glass_panel.dart';

/// A dialog body on a [GlassPanel]: the route's own Material stays clear
/// and the panel blurs the page under the barrier.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    required this.children,
    this.title,
    this.maxWidth = 420,
    super.key,
  });

  final String? title;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final TextStyle? titleStyle = Theme.of(context).dialogTheme.titleTextStyle;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassPanel(
          radius: AppSpacing.radiusLg,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(title!, style: titleStyle),
                ),
              // A long option list (languages) must scroll, not overflow.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable row of a [GlassDialog], sized like [SimpleDialogOption].
class GlassDialogOption extends StatelessWidget {
  const GlassDialogOption({
    required this.child,
    required this.onPressed,
    super.key,
  });

  final Widget child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }
}

/// Drop-in for [AlertDialog] on a [GlassPanel]: same title / content /
/// actions slots and paddings, so a call site changes only the class name.
class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    this.title,
    this.content,
    this.actions,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    this.actionsAlignment = MainAxisAlignment.end,
    this.scrollable = false,
    this.insetPadding = const EdgeInsets.all(AppSpacing.lg),
    this.maxWidth = 560,
    super.key,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment actionsAlignment;

  /// Scrolls the content when it is taller than the dialog may be.
  final bool scrollable;
  final EdgeInsets insetPadding;
  final double maxWidth;

  static const EdgeInsets _titleDefault = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.lg,
    0,
  );
  static const EdgeInsets _contentDefault = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.md,
    AppSpacing.lg,
    AppSpacing.lg,
  );
  static const EdgeInsets _actionsDefault = EdgeInsets.fromLTRB(
    AppSpacing.md,
    0,
    AppSpacing.md,
    AppSpacing.md,
  );

  @override
  Widget build(BuildContext context) {
    final DialogThemeData dialogTheme = Theme.of(context).dialogTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassPanel(
          radius: AppSpacing.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (title != null)
                Padding(
                  padding: titlePadding ?? _titleDefault,
                  child: DefaultTextStyle.merge(
                    style: dialogTheme.titleTextStyle,
                    child: title!,
                  ),
                ),
              if (content != null)
                Flexible(
                  child: Padding(
                    padding: contentPadding ?? _contentDefault,
                    child: DefaultTextStyle.merge(
                      style: dialogTheme.contentTextStyle,
                      child: scrollable
                          ? SingleChildScrollView(child: content)
                          : content!,
                    ),
                  ),
                ),
              if (actions != null && actions!.isNotEmpty)
                Padding(
                  padding: actionsPadding ?? _actionsDefault,
                  child: OverflowBar(
                    alignment: actionsAlignment,
                    spacing: AppSpacing.sm,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bottom sheet body on a [GlassPanel], rounded on top; the route's own
/// Material stays clear.
class GlassSheet extends StatelessWidget {
  const GlassSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: child,
    );
  }
}

/// Wraps the builder in a [GlassSheet]; a self-sized sheet (draggable) draws
/// its own [GlassPanel] and sets [selfBacked].
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool useRootNavigator = false,
  bool selfBacked = false,
  BoxConstraints? constraints,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    constraints: constraints,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (BuildContext ctx) =>
        selfBacked ? builder(ctx) : GlassSheet(child: builder(ctx)),
  );
}

/// Drop-in for a bare [Dialog] with a custom body: the route's Material
/// stays clear and the child lands on a [GlassPanel].
class GlassDialogFrame extends StatelessWidget {
  const GlassDialogFrame({
    required this.child,
    this.insetPadding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget child;
  final EdgeInsets insetPadding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: insetPadding,
      child: GlassPanel(radius: AppSpacing.radiusLg, child: child),
    );
  }
}
