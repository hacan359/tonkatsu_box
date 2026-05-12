import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/services/api_key_initializer.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';

class _DefaultSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const <Override>[],
    SharedPreferences? prefs,
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
          apiKeysProvider.overrideWithValue(const ApiKeys()),
          settingsNotifierProvider.overrideWith(
            _DefaultSettingsNotifier.new,
          ),
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
