import 'package:flutter/widgets.dart';

import 'stats_layout.dart';
import 'stats_layout_desktop.dart';

/// Content width below which the page switches to its phone layout. Measured
/// on the section area: the nav shell makes the window width overstate it.
const double kStatsMobileBreakpoint = 600;

/// Publishes the enclosing page's [StatsLayout] to the sections below it.
class StatsLayoutScope extends InheritedWidget {
  /// Creates the scope.
  const StatsLayoutScope({
    required this.layout,
    required super.child,
    super.key,
  });

  /// The layout numbers for this page.
  final StatsLayout layout;

  /// Falls back to the wide numbers with no scope above, so the offscreen
  /// share card and a stand-alone section render instead of asserting.
  static StatsLayout of(BuildContext context) {
    final StatsLayoutScope? scope =
        context.dependOnInheritedWidgetOfExactType<StatsLayoutScope>();
    return scope?.layout ?? kStatsLayoutDesktop;
  }

  @override
  bool updateShouldNotify(StatsLayoutScope oldWidget) =>
      layout != oldWidget.layout;
}
