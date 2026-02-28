// Цветовая палитра приложения.

import 'package:flutter/material.dart';

/// Цветовая палитра приложения (тёмная тема).
///
/// Все цвета определены как статические константы для согласованности
/// и удобства использования во всех виджетах.
abstract final class AppColors {
  // ==================== Фоны ====================

  /// Основной фон приложения.
  static const Color background = Color(0xFF0A0A0A);

  /// Фон поверхностей (карточки, панели).
  static const Color surface = Color(0xFF141414);

  /// Фон приподнятых поверхностей (hover, выделенные элементы).
  static const Color surfaceLight = Color(0xFF1E1E1E);

  /// Граница поверхностей.
  static const Color surfaceBorder = Color(0xFF2A2A2A);

  // ==================== Текст ====================

  /// Основной текст.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Вторичный текст (подзаголовки, подписи).
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Третичный текст (неактивные элементы, подсказки).
  static const Color textTertiary = Color(0xFF707070);

  // ==================== Brand / App Accent ====================

  /// Основной акцентный цвет приложения (оранжевый).
  static const Color brand = Color(0xFFEF7B44);

  /// Светлый вариант brand (hover, highlighted).
  static const Color brandLight = Color(0xFFF79D72);

  /// Бледный вариант brand (фоновые заливки).
  static const Color brandPale = Color(0xFFF7B596);

  // ==================== Акценты по типам медиа ====================

  /// Акцентный цвет для игр (индиго).
  static const Color gameAccent = Color(0xFF707DD2);

  /// Акцентный цвет для фильмов (оранжевый).
  static const Color movieAccent = Color(0xFFEF7B44);

  /// Акцентный цвет для сериалов (лаймовый).
  static const Color tvShowAccent = Color(0xFFB1E140);

  /// Акцентный цвет для анимации (пурпурный).
  static const Color animationAccent = Color(0xFFA86ED4);

  /// Акцентный цвет для визуальных новелл (синий).
  static const Color visualNovelAccent = Color(0xFF2A5FC1);

  // ==================== Семантические цвета ====================

  /// Цвет успеха (completed, done).
  static const Color success = Color(0xFF66BB6A);

  /// Цвет предупреждения (on hold, paused).
  static const Color warning = Color(0xFFFFA726);

  /// Цвет ошибки.
  static const Color error = Color(0xFFEF5350);

  // ==================== Статусы ====================

  /// Цвет статуса "In Progress" (playing/watching).
  static const Color statusInProgress = Color(0xFF42A5F5);

  /// Цвет статуса "Completed".
  static const Color statusCompleted = success;

  /// Цвет статуса "Dropped".
  static const Color statusDropped = error;

  /// Цвет статуса "Planned" (backlog, wishlist).
  static const Color statusPlanned = Color(0xFF8B5CF6);

  // ==================== Рейтинги ====================

  /// Цвет иконки звезды рейтинга (amber).
  static const Color ratingStar = Color(0xFFF59E0B);

  /// Рейтинг высокий (>= 8.0).
  static const Color ratingHigh = Color(0xFF22C55E);

  /// Рейтинг средний (>= 6.0).
  static const Color ratingMedium = Color(0xFFFBBF24);

  /// Рейтинг низкий (< 6.0).
  static const Color ratingLow = Color(0xFFEF4444);
}
