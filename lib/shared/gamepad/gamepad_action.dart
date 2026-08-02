
enum GamepadAction {
  navigateUp,
  navigateDown,
  navigateLeft,
  navigateRight,

  confirm,

  back,

  previousTab,

  nextTab,

  /// LT (digital) — предыдущий суб-таб / фильтр.
  previousSubTab,

  /// RT (digital) — следующий суб-таб / фильтр.
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

  /// Y — контекстное меню элемента (аналог ПКМ).
  contextMenu,

  openMenu,
}

enum InputMode {
  /// Мышь + клавиатура (по умолчанию).
  mouse,

  gamepad,
}
