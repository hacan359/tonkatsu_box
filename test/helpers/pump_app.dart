// Extension для WidgetTester, упрощающий создание виджетов с
// ProviderScope + MaterialApp + локализация.
//
// Использование:
//   await tester.pumpApp(const MyScreen(), overrides: [...]);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

/// Расширение [WidgetTester] для быстрого pump виджетов в тестовом окружении.
extension PumpApp on WidgetTester {
  /// Создаёт ProviderScope + MaterialApp с локализацией и делает pumpAndSettle.
  ///
  /// [widget] — тестируемый виджет (будет помещён в `home:`).
  /// [overrides] — дополнительные Riverpod overrides.
  /// [prefs] — SharedPreferences; если null, создаются пустые.
  /// [breadcrumbLabel] — если указан, оборачивает виджет в BreadcrumbScope.
  /// [wrapInScaffold] — если true, оборачивает виджет в Scaffold.body.
  /// [mediaQuerySize] — если указан, оборачивает виджет в MediaQuery.
  /// [settle] — если true (по умолчанию), вызывает pumpAndSettle.
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const <Override>[],
    SharedPreferences? prefs,
    String? breadcrumbLabel,
    bool wrapInScaffold = false,
    Size? mediaQuerySize,
    bool settle = true,
  }) async {
    if (prefs == null) {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    }

    Widget child = widget;

    if (wrapInScaffold) {
      child = Scaffold(body: child);
    }

    if (breadcrumbLabel != null) {
      child = BreadcrumbScope(label: breadcrumbLabel, child: child);
    }

    if (mediaQuerySize != null) {
      child = MediaQuery(
        data: MediaQueryData(size: mediaQuerySize),
        child: child,
      );
    }

    await pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...overrides,
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: child,
        ),
      ),
    );

    if (settle) {
      await pumpAndSettle();
    }
  }
}
