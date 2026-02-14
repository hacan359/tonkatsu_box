import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared/navigation/navigation_shell.dart';
import 'shared/theme/app_theme.dart';

/// Главный виджет приложения.
///
/// Принудительно тёмная тема через [AppTheme.darkTheme].
class XeraboraApp extends ConsumerWidget {
  const XeraboraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'xeRAbora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const _AppRouter(),
    );
  }
}

/// Роутер приложения.
///
/// Всегда показывает [NavigationShell]. Поиск недоступен без API ключей.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return const NavigationShell();
  }
}
