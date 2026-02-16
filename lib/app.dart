import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/splash/screens/splash_screen.dart';
import 'shared/gamepad/gamepad_provider.dart';
import 'shared/theme/app_theme.dart';

/// Главный виджет приложения.
///
/// Принудительно тёмная тема через [AppTheme.darkTheme].
/// Стартовый экран — [SplashScreen] с анимированным логотипом.
///
/// [Listener] на верхнем уровне отслеживает движение мыши
/// для переключения [InputMode] (gamepad ↔ mouse).
class TonkatsuBoxApp extends ConsumerWidget {
  const TonkatsuBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        home: const SplashScreen(),
      ),
    );
  }
}
