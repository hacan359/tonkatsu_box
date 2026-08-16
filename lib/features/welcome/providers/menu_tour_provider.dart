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

final NotifierProvider<MenuTourController, bool> menuTourControllerProvider =
    NotifierProvider<MenuTourController, bool>(MenuTourController.new);
