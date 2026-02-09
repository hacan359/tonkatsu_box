import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/settings_provider.dart';

// Версия формата конфигурации.
const int configFormatVersion = 1;

// Ключ версии в JSON.
const String _configVersionKey = 'xerabora_config_version';

/// Провайдер для сервиса конфигурации.
final Provider<ConfigService> configServiceProvider =
    Provider<ConfigService>((Ref ref) {
  return ConfigService(prefs: ref.watch(sharedPreferencesProvider));
});

/// Результат операции с конфигурацией.
class ConfigResult {
  /// Создаёт экземпляр [ConfigResult].
  const ConfigResult({
    required this.success,
    this.filePath,
    this.error,
  });

  /// Успешный результат.
  const ConfigResult.success(String path)
      : success = true,
        filePath = path,
        error = null;

  /// Неуспешный результат.
  const ConfigResult.failure(String message)
      : success = false,
        filePath = null,
        error = message;

  /// Отменённая операция.
  const ConfigResult.cancelled()
      : success = false,
        filePath = null,
        error = null;

  /// Успешность операции.
  final bool success;

  /// Путь к файлу.
  final String? filePath;

  /// Сообщение об ошибке.
  final String? error;

  /// Возвращает true, если операция была отменена.
  bool get isCancelled => !success && error == null;
}

/// Сервис для экспорта и импорта конфигурации приложения.
///
/// Работает с 7 ключами SharedPreferences (API ключи IGDB, SteamGridDB, TMDB).
class ConfigService {
  /// Создаёт экземпляр [ConfigService].
  ConfigService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  /// Все ключи настроек для экспорта/импорта.
  static const List<String> _settingsKeys = <String>[
    SettingsKeys.clientId,
    SettingsKeys.clientSecret,
    SettingsKeys.accessToken,
    SettingsKeys.tokenExpires,
    SettingsKeys.lastSync,
    SettingsKeys.steamGridDbApiKey,
    SettingsKeys.tmdbApiKey,
  ];

  /// Ключи с int-значениями.
  static const List<String> _intKeys = <String>[
    SettingsKeys.tokenExpires,
    SettingsKeys.lastSync,
  ];

  /// Собирает все настройки в Map.
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
      } else {
        final String? value = _prefs.getString(key);
        if (value != null) {
          config[key] = value;
        }
      }
    }

    return config;
  }

  /// Применяет настройки из Map в SharedPreferences.
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
      } else {
        if (value is String) {
          await _prefs.setString(key, value);
          applied++;
        }
      }
    }

    return applied;
  }

  /// Экспортирует конфигурацию в файл.
  ///
  /// Открывает диалог сохранения и записывает JSON с настройками.
  Future<ConfigResult> exportToFile() async {
    try {
      final Map<String, Object> config = collectSettings();
      final String json = const JsonEncoder.withIndent('  ').convert(config);

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Configuration',
        fileName: 'xerabora-config.json',
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );

      if (outputPath == null) {
        return const ConfigResult.cancelled();
      }

      final String finalPath =
          outputPath.endsWith('.json') ? outputPath : '$outputPath.json';

      final File file = File(finalPath);
      await file.writeAsString(json);

      return ConfigResult.success(finalPath);
    } on FileSystemException catch (e) {
      return ConfigResult.failure('Failed to save file: ${e.message}');
    } on Exception catch (e) {
      return ConfigResult.failure('Export failed: $e');
    }
  }

  /// Импортирует конфигурацию из файла.
  ///
  /// Открывает диалог выбора файла и применяет настройки из JSON.
  Future<ConfigResult> importFromFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Configuration',
        type: FileType.custom,
        allowedExtensions: <String>['json'],
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

      final Object? version = decoded[_configVersionKey];
      if (version == null) {
        return const ConfigResult.failure(
          'Not a valid xerabora config file (missing version)',
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
