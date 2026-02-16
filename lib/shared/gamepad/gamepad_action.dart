// Модели действий геймпада и режима ввода.

/// Действия, которые геймпад может выполнить в UI.
enum GamepadAction {
  /// D-pad навигация.
  navigateUp,
  navigateDown,
  navigateLeft,
  navigateRight,

  /// A — подтвердить / открыть / выбрать.
  confirm,

  /// B — назад / закрыть / отмена.
  back,

  /// LB — предыдущий основной таб.
  previousTab,

  /// RB — следующий основной таб.
  nextTab,

  /// LT (digital) — предыдущий суб-таб / фильтр.
  previousSubTab,

  /// RT (digital) — следующий суб-таб / фильтр.
  nextSubTab,

  /// Left Stick — скролл.
  scrollUp,
  scrollDown,
  scrollLeft,
  scrollRight,

  /// Right Stick — панорама Canvas.
  panUp,
  panDown,
  panLeft,
  panRight,

  /// Triggers analog — зум Canvas.
  zoomIn,
  zoomOut,

  /// Start / Menu — контекстное меню.
  openMenu,
}

/// Текущий режим ввода.
enum InputMode {
  /// Мышь + клавиатура (по умолчанию).
  mouse,

  /// Геймпад.
  gamepad,
}
