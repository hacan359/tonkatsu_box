// Отступы и размеры приложения.

/// Константы отступов и размеров.
///
/// Единая система отступов для согласованного UI.
/// Базовый шаг — 4px, основные значения кратны ему.
abstract final class AppSpacing {
  // ==================== Отступы ====================

  /// 4px — минимальный отступ.
  static const double xs = 4;

  /// 8px — малый отступ.
  static const double sm = 8;

  /// 16px — стандартный отступ.
  static const double md = 16;

  /// 24px — большой отступ.
  static const double lg = 24;

  /// 32px — очень большой отступ.
  static const double xl = 32;

  // ==================== Радиусы скругления ====================

  /// 4px — минимальное скругление (badge, chip).
  static const double radiusXs = 4;

  /// 8px — малое скругление (кнопки, поля ввода).
  static const double radiusSm = 8;

  /// 12px — стандартное скругление (карточки).
  static const double radiusMd = 12;

  /// 16px — большое скругление (диалоги, панели).
  static const double radiusLg = 16;
}
