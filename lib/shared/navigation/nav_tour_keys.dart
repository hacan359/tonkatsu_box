// Stable GlobalKeys for the live navigation buttons, shared so the welcome
// menu tour can locate each one on screen and highlight it.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nav_tab.dart';

/// Holds one [GlobalKey] per [NavTab], attached to the real nav buttons (the
/// rail / bottom bar entries and the settings gear). The menu tour reads a
/// key's `currentContext` to find the button's on-screen rect.
///
/// Keys are created lazily and reused, so they stay stable across rebuilds.
class NavTourKeys {
  final Map<NavTab, GlobalKey> _keys = <NavTab, GlobalKey>{};

  /// The button key for [tab], created on first use.
  GlobalKey keyFor(NavTab tab) => _keys.putIfAbsent(tab, GlobalKey.new);
}

/// Single shared [NavTourKeys] instance for the app.
final Provider<NavTourKeys> navTourKeysProvider =
    Provider<NavTourKeys>((Ref ref) => NavTourKeys());
