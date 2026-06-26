import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/settings_provider.dart';

const int configFormatVersion = 1;

const String _configVersionKey = 'tonkatsu_box_config_version';

// Legacy version key, accepted on import for backwards compatibility.
const String _legacyConfigVersionKey = 'xerabora_config_version';

final Provider<ConfigService> configServiceProvider =
    Provider<ConfigService>((Ref ref) {
  return ConfigService(prefs: ref.watch(sharedPreferencesProvider));
});

class ConfigResult {
  const ConfigResult({
    required this.success,
    this.filePath,
    this.error,
  });

  const ConfigResult.success(String path)
      : success = true,
        filePath = path,
        error = null;

  const ConfigResult.failure(String message)
      : success = false,
        filePath = null,
        error = message;

  const ConfigResult.cancelled()
      : success = false,
        filePath = null,
        error = null;

  final bool success;

  final String? filePath;

  final String? error;

  /// Cancelled = not successful but with no error message.
  bool get isCancelled => !success && error == null;
}

/// Exports and imports app configuration stored in SharedPreferences
/// (API keys, source credentials and related display settings).
class ConfigService {
  ConfigService({required SharedPreferences prefs}) : _prefs = prefs;

  // ignore: unused_field
  static final Logger _log = Logger('ConfigService');

  final SharedPreferences _prefs;

  static const List<String> _settingsKeys = <String>[
    SettingsKeys.clientId,
    SettingsKeys.clientSecret,
    SettingsKeys.accessToken,
    SettingsKeys.tokenExpires,
    SettingsKeys.lastSync,
    SettingsKeys.steamGridDbApiKey,
    SettingsKeys.tmdbApiKey,
    SettingsKeys.comicVineApiKey,
    SettingsKeys.googleBooksApiKey,
    SettingsKeys.screenScraperSsid,
    SettingsKeys.screenScraperSspassword,
    SettingsKeys.raApiKey,
    SettingsKeys.raUsername,
    SettingsKeys.steamApiKey,
    SettingsKeys.steamId,
    SettingsKeys.steamRememberCredentials,
    SettingsKeys.aniListUsername,
    SettingsKeys.defaultAuthor,
    SettingsKeys.tmdbLanguage,
    SettingsKeys.appLanguage,
    SettingsKeys.dateFormat,
    SettingsKeys.animeMangaTitleLanguage,
    // Display & feature toggles.
    SettingsKeys.showRecommendations,
    SettingsKeys.showBlurayOverlay,
    SettingsKeys.showPlatformOverlay,
    SettingsKeys.discordRpcEnabled,
    SettingsKeys.discordRaSyncEnabled,
    SettingsKeys.richCollectionsEnabled,
    SettingsKeys.hideEmptyMediaTypeChevrons,
  ];

  /// Keys whose values are ints, not strings.
  static const List<String> _intKeys = <String>[
    SettingsKeys.tokenExpires,
    SettingsKeys.lastSync,
  ];

  /// Keys whose values are bools. steamRememberCredentials must round-trip —
  /// the import screen only restores the saved Steam key/id when it is set.
  static const List<String> _boolKeys = <String>[
    SettingsKeys.steamRememberCredentials,
    SettingsKeys.showRecommendations,
    SettingsKeys.showBlurayOverlay,
    SettingsKeys.showPlatformOverlay,
    SettingsKeys.discordRpcEnabled,
    SettingsKeys.discordRaSyncEnabled,
    SettingsKeys.richCollectionsEnabled,
    SettingsKeys.hideEmptyMediaTypeChevrons,
  ];

  Map<String, Object> collectSettings() {
    final Map<String, Object> config = <String, Object>{
      _configVersionKey: configFormatVersion,
    };

    for (final String key in _settingsKeys) {
      if (_intKeys.contains(key)) {
        final int? value = _prefs.getInt(key);
        if (value != null) {
          config[key] = value;
        }
      } else if (_boolKeys.contains(key)) {
        final bool? value = _prefs.getBool(key);
        if (value != null) {
          config[key] = value;
        }
      } else {
        final String? value = _prefs.getString(key);
        if (value != null) {
          config[key] = value;
        }
      }
    }

    return config;
  }

  /// Returns the number of applied settings.
  Future<int> applySettings(Map<String, Object?> config) async {
    int applied = 0;

    for (final String key in _settingsKeys) {
      final Object? value = config[key];
      if (value == null) continue;

      if (_intKeys.contains(key)) {
        if (value is int) {
          await _prefs.setInt(key, value);
          applied++;
        } else if (value is num) {
          await _prefs.setInt(key, value.toInt());
          applied++;
        }
      } else if (_boolKeys.contains(key)) {
        if (value is bool) {
          await _prefs.setBool(key, value);
          applied++;
        }
      } else {
        if (value is String) {
          await _prefs.setString(key, value);
          applied++;
        }
      }
    }

    return applied;
  }

  Future<ConfigResult> exportToFile() async {
    try {
      final Map<String, Object> config = collectSettings();
      final String json = const JsonEncoder.withIndent('  ').convert(config);
      final Uint8List jsonBytes = Uint8List.fromList(utf8.encode(json));

      // On Android/iOS FileType.custom doesn't support custom extensions.
      final bool useAny = Platform.isAndroid || Platform.isIOS;
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Configuration',
        fileName: 'tonkatsu-box-config.json',
        type: useAny ? FileType.any : FileType.custom,
        allowedExtensions: useAny ? null : <String>['json'],
        bytes: jsonBytes,
      );

      if (outputPath == null) {
        return const ConfigResult.cancelled();
      }

      // On Android/iOS file_picker writes the bytes via SAF;
      // on desktop the file must be written manually.
      if (!Platform.isAndroid && !Platform.isIOS) {
        final String finalPath =
            outputPath.endsWith('.json') ? outputPath : '$outputPath.json';

        final File file = File(finalPath);
        await file.writeAsString(json);

        return ConfigResult.success(finalPath);
      }

      return ConfigResult.success(outputPath);
    } on FileSystemException catch (e) {
      return ConfigResult.failure('Failed to save file: ${e.message}');
    } on Exception catch (e) {
      return ConfigResult.failure('Export failed: $e');
    }
  }

  Future<ConfigResult> importFromFile() async {
    try {
      // On Android FileType.custom doesn't support custom extensions.
      final bool useAny = Platform.isAndroid;
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Configuration',
        type: useAny ? FileType.any : FileType.custom,
        allowedExtensions: useAny ? null : <String>['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return const ConfigResult.cancelled();
      }

      final String? filePath = result.files.first.path;
      if (filePath == null) {
        return const ConfigResult.failure('Could not access file');
      }

      final File file = File(filePath);
      final String content = await file.readAsString();

      final Object? decoded = jsonDecode(content);
      if (decoded is! Map<String, Object?>) {
        return const ConfigResult.failure('Invalid config file format');
      }

      final Object? version =
          decoded[_configVersionKey] ?? decoded[_legacyConfigVersionKey];
      if (version == null) {
        return const ConfigResult.failure(
          'Not a valid Tonkatsu Box config file (missing version)',
        );
      }

      final int applied = await applySettings(decoded);
      if (applied == 0) {
        return const ConfigResult.failure('No settings found in config file');
      }

      return ConfigResult.success(filePath);
    } on FormatException {
      return const ConfigResult.failure('Invalid JSON format');
    } on FileSystemException catch (e) {
      return ConfigResult.failure('Failed to read file: ${e.message}');
    } on Exception catch (e) {
      return ConfigResult.failure('Import failed: $e');
    }
  }
}
