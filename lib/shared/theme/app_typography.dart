// Типографика приложения.

import 'package:flutter/material.dart';

import '../constants/platform_features.dart';
import 'app_colors.dart';

/// Типографика приложения.
///
/// Определяет стили текста для всех уровней иерархии.
/// Все стили используют шрифт Inter и [AppColors.textPrimary] по умолчанию.
abstract final class AppTypography {
  /// Семейство шрифтов по умолчанию.
  static const String fontFamily = 'Inter';

  /// Базовая шкала плотная, под desktop; на мобильных экранах она мелкая,
  /// поэтому все стили получают +1px.
  static final double _bump = kIsMobile ? 1 : 0;

  /// Крупный заголовок (название приложения, заголовок экрана).
  static final TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26 + _bump,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Заголовок секции.
  static final TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18 + _bump,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  /// Подзаголовок (название карточки, элемент списка).
  static final TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14 + _bump,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Основной текст.
  static final TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13 + _bump,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Мелкий текст (даты, мета-информация).
  static final TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12 + _bump,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Подпись (badge, chip, label).
  static final TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11 + _bump,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.2,
  );

  /// Название на постерной карточке.
  static final TextStyle posterTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13 + _bump,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Подпись на постерной карточке (год, жанр).
  static final TextStyle posterSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11 + _bump,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// Название на карточке (grid).
  static final TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13 + _bump,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Подпись на карточке (grid).
  static final TextStyle cardSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11 + _bump,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );
}
