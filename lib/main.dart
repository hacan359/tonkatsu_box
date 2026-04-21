import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'core/services/api_key_initializer.dart';
import 'core/services/collection_hero_service.dart';
import 'core/services/profile_service.dart';
import 'features/settings/providers/profile_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'shared/models/profile.dart';

/// Глобальные данные инициализации, перечитываемые при перезапуске.
late SharedPreferences _prefs;
late ApiKeys _apiKeys;
late ProfilesData _profilesData;
late String _heroDir;

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

      // SharedPreferences.setPrefix должен вызываться строго до первого
      // getInstance() и ровно один раз за процесс, иначе StateError при
      // рестарте через AppRestartScope.
      if (!kReleaseMode) {
        SharedPreferences.setPrefix('flutter_dev.');
      }

      await _loadAppState();

      runApp(const AppRestartScope(child: TonkatsuBoxApp()));
    },
    (Object error, StackTrace stack) {
      Logger('main').severe('Unhandled exception', error, stack);
    },
  );
}

/// Загружает SharedPreferences, API keys и профильные данные.
Future<void> _loadAppState() async {
  _prefs = await SharedPreferences.getInstance();
  _apiKeys = ApiKeys.fromPrefs(_prefs);

  final ProfileService profileService = ProfileService();
  await profileService.migrateIfNeeded();
  _profilesData = await profileService.loadProfiles();

  _heroDir = await CollectionHeroService.resolveRoot();
}

/// Обёртка для перезапуска приложения на мобильных платформах.
///
/// Меняет [Key] у [ProviderScope], что пересоздаёт все провайдеры с нуля.
/// На десктопе перезапуск происходит через `Process.start + exit(0)`.
class AppRestartScope extends StatefulWidget {
  /// Создаёт [AppRestartScope].
  const AppRestartScope({required this.child, super.key});

  /// Дочерний виджет (обычно [TonkatsuBoxApp]).
  final Widget child;

  /// Перезапускает приложение: перечитывает профили и пересоздаёт ProviderScope.
  static Future<void> restart(BuildContext context) async {
    final _AppRestartScopeState? state =
        context.findAncestorStateOfType<_AppRestartScopeState>();
    await state?._restart();
  }

  @override
  State<AppRestartScope> createState() => _AppRestartScopeState();
}

class _AppRestartScopeState extends State<AppRestartScope> {
  Key _key = UniqueKey();

  Future<void> _restart() async {
    await _loadAppState();
    if (mounted) {
      setState(() => _key = UniqueKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _key,
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(_prefs),
        apiKeysProvider.overrideWithValue(_apiKeys),
        collectionsHeroDirProvider.overrideWithValue(_heroDir),
        profilesDataProvider.overrideWith(
          (Ref ref) => _profilesData,
        ),
      ],
      child: widget.child,
    );
  }
}
