import 'package:material_ui/material_ui.dart';

import '../constants/platform_features.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surface.dart';
import 'frame_chrome.dart';

/// Whether the frame around [context] floats its bars over the content, so a
/// screen lends its filter strip to the top one instead of drawing it.
bool frameFloats(BuildContext context) =>
    AppSurface.floatingBars &&
    isCompactScreen(context) &&
    FrameChromeScope.maybeOf(context) != null;

/// Inset of a page's filter strip. A lent strip gets none: the frame's top
/// block insets every screen's strip the same way.
EdgeInsets frameStripInset(BuildContext context) => frameFloats(context)
    ? EdgeInsets.zero
    : const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      );

/// How much of the content panel the floating bars cover, top and bottom.
class FrameBarInsets extends InheritedWidget {
  const FrameBarInsets({required this.insets, required super.child, super.key});

  final EdgeInsets insets;

  static EdgeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FrameBarInsets>()?.insets ??
      EdgeInsets.zero;

  @override
  bool updateShouldNotify(FrameBarInsets oldWidget) =>
      insets != oldWidget.insets;
}

/// Keeps a route clear of the floating bars until something in it opts in
/// with [FrameBleed]; a page that never heard of them stays fully usable.
class FrameRouteInset extends StatefulWidget {
  const FrameRouteInset({required this.child, super.key});

  final Widget child;

  @override
  State<FrameRouteInset> createState() => _FrameRouteInsetState();
}

class _FrameRouteInsetState extends State<FrameRouteInset> {
  int _bleeders = 0;

  void _add() {
    if (mounted) setState(() => _bleeders++);
  }

  void _remove() {
    if (mounted) setState(() => _bleeders--);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets insets = FrameBarInsets.of(context);
    final bool bleeding = _bleeders > 0;
    return _BleedScope(
      state: this,
      insets: bleeding ? insets : EdgeInsets.zero,
      child: Padding(
        padding: bleeding ? EdgeInsets.zero : insets,
        child: widget.child,
      ),
    );
  }
}

class _BleedScope extends InheritedWidget {
  const _BleedScope({
    required this.state,
    required this.insets,
    required super.child,
  });

  final _FrameRouteInsetState state;
  final EdgeInsets insets;

  @override
  bool updateShouldNotify(_BleedScope oldWidget) => insets != oldWidget.insets;
}

/// Lets its route run under the floating bars and hands [builder] the room
/// to leave free at both ends of the scrollable it builds.
class FrameBleed extends StatefulWidget {
  const FrameBleed({required this.builder, super.key});

  final Widget Function(BuildContext context, EdgeInsets barInsets) builder;

  /// What the bars cover of the route around [context]: zero until the
  /// route bleeds. For an overlay (a FAB) that must stay clear of them.
  static EdgeInsets insetsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BleedScope>()?.insets ??
      EdgeInsets.zero;

  @override
  State<FrameBleed> createState() => _FrameBleedState();
}

class _FrameBleedState extends State<FrameBleed> {
  _FrameRouteInsetState? _route;

  @override
  void initState() {
    super.initState();
    // The route sits above this subtree and must not be dirtied mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _route = context.getInheritedWidgetOfExactType<_BleedScope>()?.state;
      _route?._add();
    });
  }

  @override
  void dispose() {
    final _FrameRouteInsetState? route = _route;
    WidgetsBinding.instance.addPostFrameCallback((_) => route?._remove());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, FrameBleed.insetsOf(context));
  }
}

/// A page's fixed strip above its body: a floating frame draws it in its own
/// top block, anywhere else it stays a row of the page.
class FrameStrip extends StatelessWidget {
  const FrameStrip({required this.strip, required this.child, super.key});

  /// Empty when the page has nothing to show there right now.
  final List<Widget> strip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!frameFloats(context)) {
      return Column(
        children: <Widget>[
          ...strip,
          Expanded(child: child),
        ],
      );
    }
    return FrameChromeBinding(
      chrome: FrameChrome(
        below: strip.isEmpty
            ? null
            : Column(mainAxisSize: MainAxisSize.min, children: strip),
      ),
      child: child,
    );
  }
}
