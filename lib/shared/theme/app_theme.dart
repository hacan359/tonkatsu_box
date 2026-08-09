// Centralized application theme.

import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Centralized application theme, built from an [AppPalette].
abstract final class AppTheme {
  /// The original dark theme — kept as the default for tests and tooling.
  static final ThemeData darkTheme = build(AppPalette.dark);

  static ThemeData build(AppPalette p) => ThemeData(
        brightness: p.brightness,
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        colorScheme: ColorScheme(
          brightness: p.brightness,
          primary: p.brand,
          onPrimary: p.onBrand,
          secondary: p.movieAccent,
          onSecondary: p.onBrand,
          tertiary: p.tvShowAccent,
          onTertiary: p.onBrand,
          surface: p.surface,
          onSurface: p.textPrimary,
          surfaceContainerHighest: p.surfaceLight,
          outline: p.surfaceBorder,
          outlineVariant: p.surfaceBorder,
          error: p.error,
          onError: p.onOverlay,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        // Every platform, not the two we ship: the scaffold is transparent, so
        // a target without a builder here shows white through every route. A
        // browser reports whatever OS it runs on.
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            for (final TargetPlatform target in TargetPlatform.values)
              target: _OpaquePageTransitionsBuilder(p),
          },
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: p.background,
          foregroundColor: p.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: p.shadow.withAlpha(66),
          color: p.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: p.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(color: p.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(color: p.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(color: p.brand),
          ),
          labelStyle: TextStyle(color: p.textSecondary),
          hintStyle: TextStyle(color: p.textTertiary),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: p.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          // Without these M3 falls back to headlineSmall (24px) titles and
          // 24px action insets — dialogs read bloated next to the app's type
          // scale.
          titleTextStyle: AppTypography.h2,
          contentTextStyle: AppTypography.body.copyWith(
            color: p.textSecondary,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: p.surface,
          surfaceTintColor: Colors.transparent,
          modalBarrierColor: p.barrier,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: p.surfaceLight,
          selectedColor: p.brand.withAlpha(51),
          side: BorderSide(color: p.surfaceBorder),
          labelStyle: TextStyle(
            color: p.textPrimary,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            side: BorderSide(color: p.surfaceBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: p.brand,
          ),
        ),
        dividerTheme: DividerThemeData(
          color: p.surfaceBorder,
          thickness: 1,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          elevation: 4,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: p.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: p.surface,
          selectedIconTheme: IconThemeData(color: p.textPrimary),
          unselectedIconTheme: IconThemeData(color: p.textTertiary),
          indicatorColor: p.surfaceLight,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: p.brand,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: p.textPrimary,
          unselectedLabelColor: p.textTertiary,
          indicatorColor: p.brand,
        ),
        badgeTheme: BadgeThemeData(
          backgroundColor: p.badge,
          textColor: p.onBadge,
        ),
      );
}

/// Wrapper around [ZoomPageTransitionsBuilder] that makes every page opaque.
///
/// Each route is wrapped in a [DecoratedBox] with the tiled background —
/// this keeps the two pages' content from showing through each other during
/// a transition (scaffolds are transparent to expose the builder background).
class _OpaquePageTransitionsBuilder extends PageTransitionsBuilder {
  // Decoration is prebuilt: buildTransitions runs every transition frame.
  _OpaquePageTransitionsBuilder(AppPalette palette)
      : _tiledDecoration = BoxDecoration(
          color: palette.background,
          image: palette.tileImage,
        );

  final BoxDecoration _tiledDecoration;

  static const ZoomPageTransitionsBuilder _delegate =
      ZoomPageTransitionsBuilder();

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
        // Transparent Material provides an ink ancestor for descendant
        // ListTiles — Flutter 3.44 asserts when a coloured DecoratedBox
        // sits between them and the nearest Material.
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      ),
    );
  }
}
