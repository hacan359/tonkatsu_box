// Централизованная тема приложения.

import 'package:flutter/material.dart';

import 'app_assets.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Централизованная тёмная тема приложения.
///
/// Все компоненты Material стилизованы через [AppColors].
/// Принудительно тёмная тема — светлая не поддерживается.
abstract final class AppTheme {
  /// Тёмная тема приложения.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: AppTypography.fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.brand,
      onPrimary: AppColors.background,
      secondary: AppColors.movieAccent,
      onSecondary: AppColors.background,
      tertiary: AppColors.tvShowAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceLight,
      outline: AppColors.surfaceBorder,
      outlineVariant: AppColors.surfaceBorder,
      error: AppColors.error,
      onError: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.windows: _OpaquePageTransitionsBuilder(),
        TargetPlatform.android: _OpaquePageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: const BorderSide(color: AppColors.brand),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textTertiary),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: Colors.black54,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.brand.withAlpha(51),
      side: const BorderSide(color: AppColors.surfaceBorder),
      labelStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppColors.surfaceBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceBorder,
      thickness: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      selectedIconTheme: IconThemeData(color: AppColors.textPrimary),
      unselectedIconTheme: IconThemeData(color: AppColors.textTertiary),
      indicatorColor: AppColors.surfaceLight,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brand,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textTertiary,
      indicatorColor: AppColors.brand,
    ),
  );
}

/// Обёртка для [ZoomPageTransitionsBuilder], делающая каждую страницу непрозрачной.
///
/// Каждый route оборачивается в [DecoratedBox] с тайловым фоном —
/// это предотвращает просвечивание контента двух страниц друг через друга
/// при переходе (scaffold'ы прозрачные для отображения фона из builder).
class _OpaquePageTransitionsBuilder extends PageTransitionsBuilder {
  const _OpaquePageTransitionsBuilder();

  static const ZoomPageTransitionsBuilder _delegate =
      ZoomPageTransitionsBuilder();

  static const BoxDecoration _tiledDecoration = BoxDecoration(
    color: AppColors.background,
    image: DecorationImage(
      image: AssetImage(AppAssets.backgroundTile),
      repeat: ImageRepeat.repeat,
      opacity: 0.03,
      scale: 0.667,
    ),
  );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _delegate.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      DecoratedBox(
        decoration: _tiledDecoration,
        child: child,
      ),
    );
  }
}
