import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/startup_error.dart';
import 'core/services/backup_service.dart';
import 'features/settings/providers/kodi_settings_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/splash/screens/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'shared/gamepad/gamepad_provider.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/app_theme_id.dart';

/// Root app widget. A top-level [Listener] watches mouse movement to switch
/// [InputMode] (gamepad ↔ mouse).
class TonkatsuBoxApp extends ConsumerStatefulWidget {
  const TonkatsuBoxApp({super.key});

  @override
  ConsumerState<TonkatsuBoxApp> createState() => _TonkatsuBoxAppState();
}

class _TonkatsuBoxAppState extends ConsumerState<TonkatsuBoxApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      // Veto OS-level close requests while a restore is mid-flight so SQLite
      // can't be cut off mid-write; forced kills still bypass this.
      onExitRequested: () async {
        if (ref.read(restoreInProgressProvider)) {
          return ui.AppExitResponse.cancel;
        }
        return ui.AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // select() so per-tick settings writes (e.g. the card-scale slider)
    // don't rebuild the ThemeData.
    final String appLanguage = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.appLanguage),
    );
    final AppThemeId themeId = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.appTheme),
    );
    // AppColors getters read a static palette, so it must be swapped before
    // the subtree builds; the ValueKey below remounts everything on switch.
    AppColors.palette = themeId.palette;
    final ThemeData theme = AppTheme.build(themeId.palette);

    // Kodi sync provider is lazy — a read is required to start it.
    ref.read(kodiSettingsProvider);

    return Listener(
      onPointerHover: (_) {
        ref.read(inputModeProvider.notifier).setMouseMode();
      },
      child: MaterialApp(
        key: ValueKey<AppThemeId>(themeId),
        title: 'Tonkatsu Box',
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: Locale(appLanguage),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        // The tiled background is applied via PageTransitionsTheme
        // (each route gets its own opaque DecoratedBox).
        home: const SplashScreen(),
        // A fatal startup error (failed migration, pre-first-frame throw)
        // paints over the whole UI instead of leaving a frozen splash logo.
        builder: (BuildContext context, Widget? child) {
          return ValueListenableBuilder<StartupErrorInfo?>(
            valueListenable: startupError,
            builder: (BuildContext context, StartupErrorInfo? info, _) {
              if (info == null) {
                return _TextScaleScope(child: child ?? const SizedBox.shrink());
              }
              return StartupErrorView(info: info);
            },
          );
        },
      ),
    );
  }
}

/// Multiplies the system text scale by the user's setting so accessibility
/// zoom still applies; a separate widget keeps slider ticks off ThemeData.
class _TextScaleScope extends ConsumerWidget {
  const _TextScaleScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double textScale = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.textScale),
    );
    if (textScale == SettingsKeys.textScaleDefault) return child;
    final MediaQueryData media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: _MultipliedTextScaler(media.textScaler, textScale),
      ),
      child: child,
    );
  }
}

/// Keeps the system scaler's curve (Android 14 scales large text less than
/// small) and multiplies its result, instead of sampling it at one size.
class _MultipliedTextScaler extends TextScaler {
  const _MultipliedTextScaler(this._system, this._factor);

  final TextScaler _system;
  final double _factor;

  @override
  double scale(double fontSize) => _system.scale(fontSize) * _factor;

  // Abstract in TextScaler, so it has to be implemented despite the deprecation.
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => _system.textScaleFactor * _factor;

  @override
  bool operator ==(Object other) =>
      other is _MultipliedTextScaler &&
      other._system == _system &&
      other._factor == _factor;

  @override
  int get hashCode => Object.hash(_system, _factor);
}
