import 'package:flutter/material.dart';

/// What a sub-screen lends to the frame's top zone: a back button, a title,
/// its own actions. Replaces a second row of chrome under the zone.
class FrameChrome {
  const FrameChrome({
    this.title,
    this.onBack,
    this.actions = const <Widget>[],
    this.center,
  });

  final String? title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// A screen's own filter strip for the middle of the zone (desktop).
  final Widget? center;
}

class FrameChromeController extends ChangeNotifier {
  final Map<Object, FrameChrome> _visible = <Object, FrameChrome>{};
  FrameChrome? _current;

  FrameChrome? get current => _current;

  /// One screen may lend several pieces from different widgets (its title
  /// bar, its filter strip); per field the latest binding wins.
  void set(Object owner, FrameChrome chrome) {
    _visible[owner] = chrome;
    _recompute();
  }

  void clear(Object owner) {
    if (_visible.remove(owner) == null) return;
    _recompute();
  }

  void _recompute() {
    if (_visible.isEmpty) {
      _current = null;
    } else {
      String? title;
      VoidCallback? onBack;
      List<Widget> actions = const <Widget>[];
      Widget? center;
      for (final FrameChrome c in _visible.values) {
        title = c.title ?? title;
        onBack = c.onBack ?? onBack;
        if (c.actions.isNotEmpty) actions = c.actions;
        center = c.center ?? center;
      }
      _current = FrameChrome(
        title: title,
        onBack: onBack,
        actions: actions,
        center: center,
      );
    }
    notifyListeners();
  }
}

class FrameChromeScope extends InheritedNotifier<FrameChromeController> {
  const FrameChromeScope({
    required FrameChromeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static FrameChromeController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FrameChromeScope>()
      ?.notifier;
}

/// Lends [chrome] to the frame while this subtree is the visible route of
/// the visible tab; renders [child] untouched.
class FrameChromeBinding extends StatefulWidget {
  const FrameChromeBinding({
    required this.chrome,
    required this.child,
    super.key,
  });

  final FrameChrome chrome;
  final Widget child;

  @override
  State<FrameChromeBinding> createState() => _FrameChromeBindingState();
}

class _FrameChromeBindingState extends State<FrameChromeBinding> {
  FrameChromeController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = FrameChromeScope.maybeOf(context);
    _publish();
  }

  @override
  void didUpdateWidget(FrameChromeBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    _publish();
  }

  /// Hidden tabs keep their routes mounted (IndexedStack), as does the route
  /// under a pushed one — only the visible top route may speak.
  void _publish() {
    final FrameChromeController? controller = _controller;
    if (controller == null) return;
    final bool visible =
        TickerMode.valuesOf(context).enabled &&
            (ModalRoute.of(context)?.isCurrent ?? true);
    // The scope sits above this subtree, so it must not be marked dirty
    // from inside a build; the zone catches up on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (visible) {
        controller.set(this, widget.chrome);
      } else {
        controller.clear(this);
      }
    });
  }

  @override
  void dispose() {
    final FrameChromeController? controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) => controller?.clear(this));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
