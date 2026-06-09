// Whether the interactive menu coachmark tour is running.
//
// Flipped on when the welcome wizard finishes (or is replayed from Settings),
// watched by [AppShell], which then shows the tour overlay over the real
// navigation. The state lives in the root ProviderScope, so it survives the
// route replacement from the wizard to the shell.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the menu tour overlay: `true` while the tour is on screen.
class MenuTourController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Starts the tour.
  void start() => state = true;

  /// Ends the tour.
  void stop() => state = false;
}

/// Provider for [MenuTourController].
final NotifierProvider<MenuTourController, bool> menuTourControllerProvider =
    NotifierProvider<MenuTourController, bool>(MenuTourController.new);
