import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'core/services/api_key_initializer.dart';
import 'features/settings/providers/settings_provider.dart';

/// Точка входа в приложение.
Future<void> main() async {
  AppLogger.init();

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLogger.setupErrorHandlers();

      // Инициализация SQLite FFI для Windows/Linux/macOS
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // Инициализация SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Загрузить API ключи ДО runApp, чтобы избежать race condition
      final ApiKeys apiKeys = ApiKeys.fromPrefs(prefs);

      runApp(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiKeysProvider.overrideWithValue(apiKeys),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      Logger('main').severe('Unhandled exception', error, stack);
    },
  );
}
