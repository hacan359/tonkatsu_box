import 'package:flutter/rendering.dart';
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
  // Grows when a screen lends its filter strip; measured, since the strip's
  // rows come and go with the filters.
  double _topBlockHeight = kAppTopBarHeight;

  void _onTopBlockSize(Size size) {
    if (!mounted || size.height == _topBlockHeight) return;
    setState(() => _topBlockHeight = size.height);
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = widget.compact;
    final MediaQueryData media = MediaQuery.of(context);
    final EdgeInsets sys = media.padding;
    final double gap = AppSurface.frameGap;
    final bool floating = compact && AppSurface.floatingBars;
    final Widget? lentStrip = floating
        ? FrameChromeScope.watch(context)?.current?.below
        : null;

    // The panel's bounds are the only inset a page sees; panels do not blur
    // themselves because the wallpaper under them is blurred once.
    final Widget content = GlassPanel(
      blurSigma: 0,
      // Classic pages sit straight on the tile, as they did before the frame.
      fill: AppSurface.contentOnWallpaper ? Colors.transparent : null,
      child: MediaQuery(
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
                    top: _topBlockHeight + 2 * gap,
                    bottom: kAppBottomBarHeight + 2 * gap,
                  )
                : EdgeInsets.zero,
            child: widget.child,
          ),
        ),
      ),
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
            padding: sys + EdgeInsets.all(gap),
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
                      if (floating)
                        Positioned(
                          left: gap,
                          right: gap,
                          top: gap,
                          child: _MeasureSize(
                            onChange: _onTopBlockSize,
                            child: GlassPanel(
                              key: const ValueKey<String>('frame-top'),
                              fill: AppSurface.floatingFill(),
                              blurSigma: _floatingBlurSigma,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  SizedBox(
                                    height: kAppTopBarHeight,
                                    child: Padding(
                                      padding: zoneInset,
                                      child: widget.topZone,
                                    ),
                                  ),
                                  if (lentStrip != null)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        kFrameZoneInset,
                                        0,
                                        kFrameZoneInset,
                                        AppSpacing.sm,
                                      ),
                                      child: lentStrip,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (floating)
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
        ),
      ],
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
