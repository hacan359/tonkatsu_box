import 'package:flutter/material.dart';

import '../theme/app_surface.dart';
import '../widgets/glass_panel.dart';
import 'app_bottom_bar.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'app_wallpaper.dart';
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
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}

/// Height the frame's own panels and gaps take from the shell, so the
/// shell's minimum height can leave the content panel its full share.
double frameChromeHeight({required bool compact}) {
  final double gap = AppSurface.frameGap;
  final double wide = kAppTopBarHeight + 3 * gap;
  return compact ? wide + kAppBottomBarHeight + gap : wide;
}

/// Glass panels over the wallpaper: search row, menu rail (bottom band on
/// phones) and content. Real boxes, so a page never knows about the chrome.
class AppFrame extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final EdgeInsets sys = media.padding;
    final double gap = AppSurface.frameGap;

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
            appBarTheme: Theme.of(
              context,
            ).appBarTheme.copyWith(backgroundColor: Colors.transparent),
            // The app theme backs every route with the opaque tile; inside
            // the panel the glass is the backing.
            pageTransitionsTheme: PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                for (final TargetPlatform target in TargetPlatform.values)
                  target: const _GlassPageTransitionsBuilder(),
              },
            ),
          ),
          child: child,
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
            child: Center(child: menuZone),
          ),
        if (!compact) SizedBox(width: gap),
        Expanded(key: const ValueKey<String>('frame-content'), child: content),
        if (compact) SizedBox(height: gap),
        if (compact)
          GlassPanel(
            key: const ValueKey<String>('frame-bottom'),
            height: kAppBottomBarHeight,
            blurSigma: 0,
            child: menuZone,
          ),
      ],
    );

    return Stack(
      children: <Widget>[
        const Positioned.fill(child: AppWallpaper()),
        Positioned.fill(
          child: Padding(
            padding: sys + EdgeInsets.all(gap),
            child: Column(
              children: <Widget>[
                GlassPanel(
                  height: kAppTopBarHeight,
                  blurSigma: 0,
                  // Own inset, not the gap: classic has no gap and the gear
                  // would touch the window edge.
                  padding: const EdgeInsets.symmetric(
                    horizontal: kFrameZoneInset,
                  ),
                  child: topZone,
                ),
                SizedBox(height: gap),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
