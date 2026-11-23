import 'package:material_ui/material_ui.dart';

/// What a sub-screen lends to the frame's top zone: a back button, a title,
/// its own actions. Replaces a second row of chrome under the zone.
class FrameChrome {
  const FrameChrome({
    this.title,
    this.onBack,
    this.actions = const <Widget>[],
    this.center,
    this.below,
    this.showSearch = true,
    this.priority = 0,
  });

  final String? title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// A screen's own filter strip for the middle of the zone (desktop).
  final Widget? center;

  /// A screen's filter strip, drawn under the search row when the frame
  /// floats its top block over the content.
  final Widget? below;

  /// False on a screen with nothing to search; any visible lender can veto.
  final bool showSearch;

  /// Per field the highest priority wins; a page's own title row lends at
  /// 1 so a filter strip mounted later cannot take its place.
  final int priority;
}

class FrameChromeController extends ChangeNotifier {
  final Map<Object, FrameChrome> _visible = <Object, FrameChrome>{};
  FrameChrome? _current;
  Object? _belowOwner;
  bool _disposed = false;

  FrameChrome? get current => _current;

  /// The binding whose strip [current] shows; it changes with the page.
  Object? get belowOwner => _belowOwner;

  /// One screen may lend several pieces from different widgets (its title
  /// bar, its filter strip); per field the latest binding wins.
  void set(Object owner, FrameChrome chrome) {
    if (_disposed) return;
    _visible[owner] = chrome;
    _recompute();
  }

  // A binding clears itself a frame after its own dispose, which can land
  // after the shell (and this controller) is gone.
  void clear(Object owner) {
    if (_disposed || _visible.remove(owner) == null) return;
    _recompute();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _recompute() {
    if (_visible.isEmpty) {
      _current = null;
      _belowOwner = null;
    } else {
      String? title;
      VoidCallback? onBack;
      List<Widget> actions = const <Widget>[];
      Widget? center;
      Widget? below;
      Object? belowOwner;
      // List.sort is not stable; ties must keep mount order.
      final List<MapEntry<Object, FrameChrome>> mounted = _visible.entries
          .toList();
      final List<MapEntry<Object, FrameChrome>> entries =
          <MapEntry<Object, FrameChrome>>[
            for (final int p
                in mounted
                    .map((MapEntry<Object, FrameChrome> e) => e.value.priority)
                    .toSet()
                    .toList()
                  ..sort())
              ...mounted.where(
                (MapEntry<Object, FrameChrome> e) => e.value.priority == p,
              ),
          ];
      final List<FrameChrome> ordered = <FrameChrome>[
        for (final MapEntry<Object, FrameChrome> e in entries) e.value,
      ];
      for (final MapEntry<Object, FrameChrome> e in entries) {
        final FrameChrome c = e.value;
        title = c.title ?? title;
        onBack = c.onBack ?? onBack;
        if (c.actions.isNotEmpty) actions = c.actions;
        center = c.center ?? center;
        if (c.below != null) {
          below = c.below;
          belowOwner = e.key;
        }
      }
      _belowOwner = belowOwner;
      _current = FrameChrome(
        title: title,
        onBack: onBack,
        actions: actions,
        center: center,
        below: below,
        showSearch: ordered.every((FrameChrome c) => c.showSearch),
        priority: ordered.last.priority,
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

  /// No dependency on purpose: depending would rebuild the lender on its own
  /// publish and loop forever.
  static FrameChromeController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FrameChromeScope>()?.notifier;

  /// The controller with a dependency: for the zone that renders the chrome.
  static FrameChromeController? watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FrameChromeScope>()?.notifier;
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller?.clear(this),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
