// Типографика приложения.

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Типографика приложения.
///
/// Определяет стили текста для всех уровней иерархии.
/// Все стили используют [AppColors.textPrimary] по умолчанию.
abstract final class AppTypography {
  /// Крупный заголовок (название приложения, заголовок экрана).
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Заголовок секции.
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Подзаголовок (название карточки, элемент списка).
  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Основной текст.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Мелкий текст (даты, мета-информация).
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Подпись (badge, chip, label).
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.2,
  );
}
