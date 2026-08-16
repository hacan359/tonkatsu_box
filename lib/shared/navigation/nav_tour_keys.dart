import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nav_tab.dart';

/// One [GlobalKey] per [NavTab], attached to the real nav buttons — the tour
/// reads `currentContext` for each button's on-screen rect.
class NavTourKeys {
  final Map<NavTab, GlobalKey> _keys = <NavTab, GlobalKey>{};

  /// The button key for [tab], created on first use.
  GlobalKey keyFor(NavTab tab) => _keys.putIfAbsent(tab, GlobalKey.new);

  /// The centre button is a shell-level destination, not a [NavTab], so it
  /// needs its own key instead of a slot in [_keys].
  final GlobalKey personalization = GlobalKey();
}

/// Single shared [NavTourKeys] instance for the app.
final Provider<NavTourKeys> navTourKeysProvider =
    Provider<NavTourKeys>((Ref ref) => NavTourKeys());
