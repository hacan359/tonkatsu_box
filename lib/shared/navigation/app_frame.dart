import 'package:flutter/rendering.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassBackdropGroup;
import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';
import '../theme/app_surface.dart';
import '../widgets/glass_panel.dart';
import 'app_bottom_bar.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'app_wallpaper.dart';
import 'frame_chrome.dart';
import 'frame_inset.dart';
import 'frame_metrics.dart';

/// Routes inside the panel paint no backing of their own; ListTiles still
/// need an ink ancestor, hence the transparent Material.
class _GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const _GlassPageTransitionsBuilder();

  // The old page shrinks and dims, then the new one grows out of a slight
  // contraction. No snapshot: it flashes on a transparent page.
  static const double _shrunk = 0.92;

  static final Animatable<double> _enterScale =
      Tween<double>(begin: _shrunk, end: 1).chain(
        CurveTween(curve: const Interval(0.35, 1, curve: Curves.easeOutCubic)),
      );

  static final Animatable<double> _enterFade = Tween<double>(
    begin: 0,
    end: 1,
  ).chain(CurveTween(curve: const Interval(0.35, 1, curve: Curves.easeOut)));

  static final Animatable<double> _exitScale =
      Tween<double>(begin: 1, end: _shrunk).chain(
        CurveTween(curve: const Interval(0, 0.65, curve: Curves.easeInCubic)),
      );

  static final Animatable<double> _exitFade = Tween<double>(
    begin: 1,
    end: 0,
  ).chain(CurveTween(curve: const Interval(0, 0.65, curve: Curves.easeIn)));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: secondaryAnimation.drive(_exitFade),
      child: ScaleTransition(
        scale: secondaryAnimation.drive(_exitScale),
        child: FadeTransition(
          opacity: animation.drive(_enterFade),
          child: ScaleTransition(
            scale: animation.drive(_enterScale),
            child: Material(
              type: MaterialType.transparency,
              child: FrameRouteInset(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stronger than a modal's: icons must read over any poster under a bar.
const double _floatingBlurSigma = 14;

/// Scroll travel in one direction before the lent strip folds or returns;
/// a finger's jitter must not flap it.
const double _stripToggleTravel = 24;

const Duration _stripFold = Duration(milliseconds: 220);

/// Height the frame's own panels and gaps take from the shell, so the
/// shell's minimum height can leave the content panel its full share.
double frameChromeHeight({required bool compact}) {
  final double gap = AppSurface.frameGap;
  // Floating bars overlap the content panel and take no height themselves.
  if (compact && AppSurface.floatingBars) return 2 * gap;
  final double wide = kAppTopBarHeight + 3 * gap;
  return compact ? wide + kAppBottomBarHeight + gap : wide;
}

/// Glass panels over the wallpaper: search row, menu rail (bottom band on
/// phones) and content. Where the skin floats its bars, a phone gets one
/// content panel with the search block and the menu laid over it.
class AppFrame extends StatefulWidget {
  const AppFrame({
    required this.compact,
    required this.topZone,
    required this.menuZone,
    required this.child,
    super.key,
  });

  final bool compact;
  final Widget topZone;
  final Widget menuZone;
  final Widget child;

  @override
  State<AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends State<AppFrame> {
  // Measured unfolded, since the strip's rows come and go with the filters;
  // pages keep that room while it is folded, so nothing jumps.
  double _stripHeight = 0;
  bool _stripShown = true;
  double _travel = 0;
  Object? _stripOwner;

  void _onStripSize(Size size) {
    if (!mounted || size.height == _stripHeight) return;
    setState(() => _stripHeight = size.height);
  }

  // The list whose travel folded the strip; only it may bring the strip
  // back by running out of scroll.
  BuildContext? _foldSource;

  /// Whether [source] is a page's own list: on the visible tab and not
  /// inside another list that scrolls (an inner list, a text field).
  bool _isPageScroll(BuildContext source) {
    if (!TickerMode.valuesOf(source).enabled) return false;
    // The shell scrolls the whole frame in a short window; that one is not
    // a parent list.
    final ScrollableState? shell = context
        .findAncestorStateOfType<ScrollableState>();
    // The nearest scrollable is the one notifying; its ancestors are parents.
    ScrollableState? parent = source
        .findAncestorStateOfType<ScrollableState>()
        ?.context
        .findAncestorStateOfType<ScrollableState>();
    while (parent != null && !identical(parent, shell)) {
      final ScrollPosition p = parent.position;
      // A wrapper with nothing to scroll is not a list the page moves in.
      if (p.axis == Axis.vertical &&
          p.hasContentDimensions &&
          p.maxScrollExtent > p.minScrollExtent) {
        return false;
      }
      parent = parent.context.findAncestorStateOfType<ScrollableState>();
    }
    return true;
  }

  bool _onScroll(Notification note) {
    if (note is ScrollMetricsNotification) {
      // A list that shrank (a search narrowed it) scrolls no more, so no
      // update would ever bring a folded strip back.
      final ScrollMetrics m = note.metrics;
      if (!_stripShown &&
          identical(note.context, _foldSource) &&
          (m.maxScrollExtent <= m.minScrollExtent ||
              m.pixels <= m.minScrollExtent)) {
        _travel = 0;
        setState(() => _stripShown = true);
      }
      return false;
    }
    if (note is! ScrollUpdateNotification) return false;
    final ScrollMetrics m = note.metrics;
    final BuildContext? source = note.context;
    if (m.axis != Axis.vertical) return false;
    if (source == null || !source.mounted || !_isPageScroll(source)) {
      return false;
    }
    final double delta = note.scrollDelta ?? 0;
    bool shown = _stripShown;
    if (m.pixels <= m.minScrollExtent) {
      shown = true;
      _travel = 0;
    } else if (m.pixels < m.maxScrollExtent && delta != 0) {
      // Overscroll bounces back against the gesture; only real travel counts.
      _travel = (_travel.sign == delta.sign ? _travel : 0) + delta;
      if (_travel > _stripToggleTravel) shown = false;
      if (_travel < -_stripToggleTravel) shown = true;
    }
    if (shown != _stripShown) {
      _foldSource = shown ? null : source;
      setState(() => _stripShown = shown);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = widget.compact;
    final MediaQueryData media = MediaQuery.of(context);
    final EdgeInsets sys = media.padding;
    final double gap = AppSurface.frameGap;
    final bool floating = compact && AppSurface.floatingBars;
    final FrameChromeController? chrome = floating
        ? FrameChromeScope.watch(context)
        : null;
    final Widget? lentStrip = chrome?.current?.below;
    // Another page lends its strip unfolded, whatever the last one did.
    if (chrome?.belowOwner != _stripOwner) {
      _stripOwner = chrome?.belowOwner;
      _stripShown = true;
      _travel = 0;
      _foldSource = null;
    }
    final double topBlockHeight =
        kAppTopBarHeight + (lentStrip == null ? 0 : _stripHeight);

    // The panel's bounds are the only inset a page sees; panels do not blur
    // themselves because the wallpaper under them is blurred once.
    final Widget pages = MediaQuery(
      data: media.copyWith(
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent,
          appBarTheme: Theme.of(context).appBarTheme
              .copyWith(backgroundColor: Colors.transparent),
          // The app theme backs every route with the opaque tile; inside
          // the panel the glass is the backing.
          pageTransitionsTheme: PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              for (final TargetPlatform target in TargetPlatform.values)
                target: const _GlassPageTransitionsBuilder(),
            },
          ),
        ),
        child: FrameBarInsets(
          insets: floating
              ? EdgeInsets.only(
                  top: topBlockHeight + 2 * gap,
                  bottom: kAppBottomBarHeight + 2 * gap,
                )
              : EdgeInsets.zero,
          child: lentStrip == null
              ? widget.child
              : NotificationListener<Notification>(
                  onNotification: _onScroll,
                  child: widget.child,
                ),
        ),
      ),
    );
    // Liquid glass is for the chrome only: pages lie on the picture with no
    // panel of their own. Classic pages sit straight on the tile.
    final Widget content = AppSurface.liquidGlass
        ? pages
        : GlassPanel(
            blurSigma: 0,
            fill: AppSurface.contentOnWallpaper ? Colors.transparent : null,
            child: pages,
          );

    // Keyed children in one flipping Flex: reparenting the tab Navigators
    // mid-layout on a compact/wide change makes OverlayPortal assert.
    final Widget body = Flex(
      direction: compact ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!compact)
          GlassPanel(
            key: const ValueKey<String>('frame-rail'),
            width: kAppSidebarWidth,
            blurSigma: 0,
            child: Center(child: widget.menuZone),
          ),
        if (!compact) SizedBox(width: gap),
        Expanded(key: const ValueKey<String>('frame-content'), child: content),
        if (compact && !floating) SizedBox(height: gap),
        if (compact && !floating)
          GlassPanel(
            key: const ValueKey<String>('frame-bottom'),
            height: kAppBottomBarHeight,
            blurSigma: 0,
            child: widget.menuZone,
          ),
      ],
    );

    // Own inset, not the gap: classic has no gap and the gear would touch
    // the window edge.
    const EdgeInsets zoneInset = EdgeInsets.symmetric(
      horizontal: kFrameZoneInset,
    );

    return Stack(
      children: <Widget>[
        const Positioned.fill(child: AppWallpaper()),
        Positioned.fill(
          child: Padding(
            // Floating bars keep their own side gap, so the pages under them
            // run the full width of a phone.
            padding:
                sys +
                (floating
                    ? EdgeInsets.symmetric(vertical: gap)
                    : EdgeInsets.all(gap)),
            child: Column(
              children: <Widget>[
                if (!floating)
                  GlassPanel(
                    key: const ValueKey<String>('frame-top'),
                    height: kAppTopBarHeight,
                    blurSigma: 0,
                    padding: zoneInset,
                    child: widget.topZone,
                  ),
                if (!floating) SizedBox(height: gap),
                Expanded(
                  // Keyed, and the Flex first inside: neither layout may
                  // reparent the tab Navigators.
                  key: const ValueKey<String>('frame-body'),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      body,
                      // The floating bars blur for themselves: posters scroll
                      // under them, out of reach of the wallpaper's one blur.
                      // Grouped, they share one read of the screen; apart, each bar
                      // costs a phone its own full-screen copies every frame.
                      if (floating)
                        GlassBackdropGroup(
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              Positioned(
                                left: gap,
                                right: gap,
                                top: gap,
                                child: GlassPanel(
                                  key: const ValueKey<String>('frame-top'),
                                  fill: AppSurface.floatingFill(),
                                  blurSigma: _floatingBlurSigma,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      SizedBox(
                                        height: kAppTopBarHeight,
                                        child: Padding(
                                          padding: zoneInset,
                                          child: widget.topZone,
                                        ),
                                      ),
                                      if (lentStrip != null)
                                        _FoldingStrip(
                                          shown: _stripShown,
                                          onSize: _onStripSize,
                                          child: lentStrip,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: gap,
                                right: gap,
                                bottom: gap,
                                child: GlassPanel(
                                  key: const ValueKey<String>('frame-bottom'),
                                  height: kAppBottomBarHeight,
                                  fill: AppSurface.floatingFill(),
                                  blurSigma: _floatingBlurSigma,
                                  child: widget.menuZone,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The lent strip under the search row, folded away while the page scrolls
/// down and back once it scrolls up.
class _FoldingStrip extends StatelessWidget {
  const _FoldingStrip({
    required this.shown,
    required this.onSize,
    required this.child,
  });

  final bool shown;
  final ValueChanged<Size> onSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      excluding: !shown,
      child: ClipRect(
        child: AnimatedAlign(
          duration: _stripFold,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          heightFactor: shown ? 1 : 0,
          child: AnimatedOpacity(
            duration: _stripFold,
            opacity: shown ? 1 : 0,
            child: _MeasureSize(
              onChange: onSize,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kFrameZoneInset,
                  0,
                  kFrameZoneInset,
                  AppSpacing.sm,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reports its child's laid-out size a frame later; the listener rebuilds
/// an ancestor, which layout itself must not do.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final Size current = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(current));
  }
}
