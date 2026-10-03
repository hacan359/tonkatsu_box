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
          primaryContainer: p.brandContainer,
          onPrimaryContainer: p.onBrandContainer,
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
        // Spelled out so both palettes agree; the M3 defaults are near
        // invisible on the dark surface, and focus must read on a gamepad.
        hoverColor: p.textPrimary.withAlpha(_hoverAlpha),
        focusColor: p.brand.withAlpha(_focusAlpha),
        // Every platform, not just the two we ship: scaffolds are transparent,
        // so a target without a builder here shows white through every route.
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
          // Without these M3 falls back to 24px titles and action insets, and
          // dialogs read bloated next to the app's type scale.
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
        // M3 fills FABs with primaryContainer; the canvas buttons stay brand.
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
        ),
        switchTheme: _switchTheme(p),
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

  // Overlay opacities: hover 8%, focus 16%.
  static const int _hoverAlpha = 20;
  static const int _focusAlpha = 41;

  // M3 disabled-state opacities (38% content, 12% container).
  static const int _disabledContentAlpha = 97;
  static const int _disabledContainerAlpha = 31;

  /// The thumb keeps one color through hover and focus: M3 swaps it to
  /// primaryContainer there, which merged it into the track.
  static SwitchThemeData _switchTheme(AppPalette p) => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          final bool on = s.contains(WidgetState.selected);
          if (s.contains(WidgetState.disabled)) {
            return (on ? p.onBrand : p.textPrimary)
                .withAlpha(_disabledContentAlpha);
          }
          if (on) return p.onBrand;
          return s.contains(WidgetState.hovered) ||
                  s.contains(WidgetState.focused) ||
                  s.contains(WidgetState.pressed)
              ? p.textSecondary
              : p.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          final bool on = s.contains(WidgetState.selected);
          if (s.contains(WidgetState.disabled)) {
            return (on ? p.textPrimary : p.surfaceLight)
                .withAlpha(_disabledContainerAlpha);
          }
          return on ? p.brand : p.surfaceLight;
        }),
        trackOutlineColor:
            WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) return Colors.transparent;
          return s.contains(WidgetState.disabled)
              ? p.surfaceBorder.withAlpha(_disabledContainerAlpha)
              : p.surfaceBorder;
        }),
      );
}

/// Scaffolds are transparent to expose the tiled background, so each route
/// gets its own [DecoratedBox] or the two pages bleed through mid-transition.
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
        // Descendant ListTiles need an ink ancestor — Flutter 3.44 asserts
        // when a coloured DecoratedBox sits between them and the Material.
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      ),
    );
  }
}
