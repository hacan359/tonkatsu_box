enum GamepadAction {
  navigateUp,
  navigateDown,
  navigateLeft,
  navigateRight,

  confirm,

  back,

  previousTab,

  nextTab,

  /// LT (digital).
  previousSubTab,

  /// RT (digital).
  nextSubTab,

  scrollUp,
  scrollDown,
  scrollLeft,
  scrollRight,

  panUp,
  panDown,
  panLeft,
  panRight,

  zoomIn,
  zoomOut,

  /// Y — the gamepad stand-in for a right click.
  contextMenu,

  openMenu,
}

enum InputMode {
  mouse,

  gamepad,
}
