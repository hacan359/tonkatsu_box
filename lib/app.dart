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
import 'shared/theme/app_theme.dart';

/// Главный виджет приложения.
///
/// Принудительно тёмная тема через [AppTheme.darkTheme].
/// Стартовый экран — [SplashScreen] с анимированным логотипом.
///
/// [Listener] на верхнем уровне отслеживает движение мыши
/// для переключения [InputMode] (gamepad ↔ mouse).
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
      // can't be cut off mid-write. User-initiated kills (kill -9, taskmgr)
      // still go through — there's no defence against those.
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
    final String appLanguage =
        ref.watch(settingsNotifierProvider).appLanguage;

    // Инициализация Kodi sync (провайдер ленивый — нужен read для запуска).
    ref.read(kodiSettingsProvider);

    return Listener(
      onPointerHover: (_) {
        ref.read(inputModeProvider.notifier).setMouseMode();
      },
      child: MaterialApp(
        title: 'Tonkatsu Box',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        locale: Locale(appLanguage),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        // Тайловый фон применяется через PageTransitionsTheme
        // (каждый route получает свой непрозрачный DecoratedBox).
        home: const SplashScreen(),
        // A captured fatal startup error (failed migration, throw before the
        // first frame) paints over the whole UI so it's visible on-device
        // instead of a frozen splash logo.
        builder: (BuildContext context, Widget? child) {
          return ValueListenableBuilder<StartupErrorInfo?>(
            valueListenable: startupError,
            builder: (BuildContext context, StartupErrorInfo? info, _) {
              if (info == null) return child ?? const SizedBox.shrink();
              return StartupErrorView(info: info);
            },
          );
        },
      ),
    );
  }
}
