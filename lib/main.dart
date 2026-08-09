import 'dart:async';

import 'package:core/models/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/startup_error.dart';
import 'core/services/api_key_initializer.dart';
import 'core/services/collection_hero_service.dart';
import 'core/services/platform_init_io.dart'
    if (dart.library.js_interop) 'core/services/platform_init_web.dart';
import 'core/selfhost/credential_upload.dart';
import 'core/selfhost/server_managed_keys.dart';
import 'core/services/profile_service.dart';
import 'features/settings/providers/profile_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'shared/constants/platform_features.dart';

late SharedPreferences _prefs;
late ApiKeys _apiKeys;
late ProfilesData _profilesData;
late String _heroDir;

Future<void> main() async {
  AppLogger.init();

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLogger.setupErrorHandlers();
      initPlatform();

      // setPrefix must run before the first getInstance() and exactly once
      // per process — otherwise a restart via AppRestartScope hits StateError.
      if (!kReleaseMode) {
        SharedPreferences.setPrefix('flutter_dev.');
      }

      try {
        await _loadAppState();
      } catch (error, stack) {
        // Pre-runApp crash: no real app to overlay, so show a standalone
        // error screen instead of a frozen native splash.
        Logger('main').severe('Startup _loadAppState failed', error, stack);
        final StartupErrorInfo info =
            recordStartupError('_loadAppState', error, stack);
        runApp(StartupErrorApp(info: info));
        return;
      }

      runApp(const AppRestartScope(child: TonkatsuBoxApp()));
    },
    (Object error, StackTrace stack) {
      Logger('main').severe('Unhandled exception', error, stack);
      recordStartupError('zone', error, stack);
    },
  );
}

Future<void> _loadAppState() async {
  _prefs = await SharedPreferences.getInstance();
  // Web keeps the same prefs-backed reads as desktop; the server is where the
  // values live, so they are copied in before anything reads them.
  if (kIsWebBuild) {
    final Map<String, String> fromServer = await fetchServerCredentials();
    for (final MapEntry<String, String> e in fromServer.entries) {
      final String? prefKey = kCredentialToConfigKey[e.key];
      if (prefKey != null) await _prefs.setString(prefKey, e.value);
    }
  }
  _apiKeys = ApiKeys.fromPrefs(_prefs);

  final ProfileService profileService = ProfileService();
  await profileService.migrateIfNeeded();
  _profilesData = await profileService.loadProfiles();

  _heroDir = await CollectionHeroService.resolveRoot();
}

/// In-process restart for mobile: swaps the [ProviderScope]'s [Key] to rebuild
/// every provider from scratch. Desktop restarts via `Process.start + exit(0)`.
class AppRestartScope extends StatefulWidget {
  const AppRestartScope({required this.child, super.key});

  final Widget child;

  /// Reloads profiles and recreates the ProviderScope.
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
