// Сервис управления пользовательскими профилями.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../main.dart' show AppRestartScope;
import '../../shared/constants/platform_features.dart';
import '../../shared/models/profile.dart';
import '../database/database_service.dart';

/// Провайдер [ProfileService].
final Provider<ProfileService> profileServiceProvider =
    Provider<ProfileService>((Ref ref) {
  return ProfileService();
});

/// Сервис управления профилями пользователей.
///
/// Каждый профиль имеет изолированную БД и кэш изображений.
/// Данные профилей хранятся в `profiles.json` в корне приложения.
class ProfileService {
  static final Logger _log = Logger('ProfileService');

  static const String _profilesFileName = 'profiles.json';
  static const String _profilesFolderName = 'profiles';
  static const String _dbFileName = 'tonkatsu_box.db';
  static const String _imageCacheFolderName = 'image_cache';

  String? _basePath;

  /// Возвращает базовый путь приложения.
  Future<String> getBasePath() async {
    if (_basePath != null) return _basePath!;
    final Directory appDir = await getApplicationSupportDirectory();
    const String folderName =
        kReleaseMode ? 'tonkatsu_box' : 'tonkatsu_box_dev';
    _basePath = p.join(appDir.path, folderName);
    return _basePath!;
  }

  /// Загружает данные профилей из `profiles.json`.
  ///
  /// Если файл не существует, создаёт дефолтный профиль.
  Future<ProfilesData> loadProfiles() async {
    final String basePath = await getBasePath();
    final File file = File(p.join(basePath, _profilesFileName));

    if (await file.exists()) {
      final String content = await file.readAsString();
      return ProfilesData.fromJsonString(content);
    }

    // Первый запуск — создаём дефолтный профиль
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String authorName =
        prefs.getString('default_author') ?? 'Default';

    final ProfilesData data =
        ProfilesData.defaultData(authorName: authorName);
    await _saveProfiles(data);
    return data;
  }

  /// Сохраняет данные профилей.
  Future<void> _saveProfiles(ProfilesData data) async {
    final String basePath = await getBasePath();
    final Directory baseDir = Directory(basePath);
    if (!baseDir.existsSync()) {
      await baseDir.create(recursive: true);
    }
    final File file = File(p.join(basePath, _profilesFileName));
    await file.writeAsString(data.toJsonString());
  }

  /// Создаёт новый профиль.
  Future<Profile> createProfile(String name, String color) async {
    final ProfilesData data = await loadProfiles();

    final DateTime now = DateTime.now();
    final String id = now.millisecondsSinceEpoch.toRadixString(36);
    final Profile profile = Profile(
      id: id,
      name: name,
      color: color,
      createdAt: now,
    );

    // Создаём папку профиля
    final String profileDir = await getProfileDir(id);
    await Directory(profileDir).create(recursive: true);

    // Добавляем в список
    final ProfilesData updated = data.copyWith(
      profiles: <Profile>[...data.profiles, profile],
    );
    await _saveProfiles(updated);

    _log.info('Created profile: ${profile.name} (${profile.id})');
    return profile;
  }

  /// Удаляет профиль.
  ///
  /// Нельзя удалить последний профиль.
  /// Если удаляется активный — переключаемся на первый оставшийся.
  Future<void> deleteProfile(String profileId) async {
    final ProfilesData data = await loadProfiles();

    if (data.profiles.length <= 1) {
      throw StateError('Cannot delete the last profile');
    }

    // Удаляем папку профиля
    final String profileDir = await getProfileDir(profileId);
    final Directory dir = Directory(profileDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // Удаляем из списка
    final List<Profile> remaining = data.profiles
        .where((Profile p) => p.id != profileId)
        .toList();

    // Если удаляли активный — переключаемся на первый
    String currentId = data.currentProfileId;
    if (currentId == profileId) {
      currentId = remaining.first.id;
    }

    final ProfilesData updated = data.copyWith(
      currentProfileId: currentId,
      profiles: remaining,
    );
    await _saveProfiles(updated);

    _log.info('Deleted profile: $profileId');
  }

  /// Обновляет профиль (имя, цвет).
  Future<void> updateProfile(Profile profile) async {
    final ProfilesData data = await loadProfiles();
    final List<Profile> updated = data.profiles.map((Profile p) {
      if (p.id == profile.id) return profile;
      return p;
    }).toList();

    await _saveProfiles(data.copyWith(profiles: updated));
    _log.info('Updated profile: ${profile.name} (${profile.id})');
  }

  /// Переключает активный профиль.
  Future<void> switchProfile(String profileId) async {
    final ProfilesData data = await loadProfiles();
    await _saveProfiles(data.copyWith(currentProfileId: profileId));
    _log.info('Switched to profile: $profileId');
  }

  /// Возвращает путь к папке профиля.
  Future<String> getProfileDir(String profileId) async {
    final String basePath = await getBasePath();
    return p.join(basePath, _profilesFolderName, profileId);
  }

  /// Возвращает путь к БД профиля.
  Future<String> getDatabasePath(String profileId) async {
    final String dir = await getProfileDir(profileId);
    return p.join(dir, _dbFileName);
  }

  /// Возвращает путь к кэшу изображений профиля.
  Future<String> getImageCachePath(String profileId) async {
    final String dir = await getProfileDir(profileId);
    return p.join(dir, _imageCacheFolderName);
  }

  /// Мигрирует старые данные (до профильной системы) в профиль default.
  ///
  /// Условие: существует старая БД и нет папки profiles/.
  Future<bool> migrateIfNeeded() async {
    final String basePath = await getBasePath();
    final File oldDb = File(p.join(basePath, _dbFileName));
    final Directory profilesDir =
        Directory(p.join(basePath, _profilesFolderName));

    if (!oldDb.existsSync() || profilesDir.existsSync()) {
      return false;
    }

    _log.info('Migrating existing database to profile system...');

    // Создаём папку профиля default
    final String defaultDir =
        p.join(basePath, _profilesFolderName, 'default');
    await Directory(defaultDir).create(recursive: true);

    // Перемещаем БД
    await oldDb.rename(p.join(defaultDir, _dbFileName));

    // Перемещаем кэш изображений
    final Directory oldCache =
        Directory(p.join(basePath, _imageCacheFolderName));
    if (oldCache.existsSync()) {
      await oldCache.rename(p.join(defaultDir, _imageCacheFolderName));
    }

    // Получаем имя из SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String authorName =
        prefs.getString('default_author') ?? 'Default';

    // Создаём profiles.json
    final ProfilesData data =
        ProfilesData.defaultData(authorName: authorName);
    await _saveProfiles(data);

    _log.info('Migration complete: profile "$authorName" created');
    return true;
  }

  /// Получает статистику профиля (открывает БД readonly).
  Future<ProfileStats> getProfileStats(String profileId) async {
    final String dbPath = await getDatabasePath(profileId);
    final File dbFile = File(dbPath);

    if (!dbFile.existsSync()) return ProfileStats.empty;

    try {
      final Database db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final List<Map<String, Object?>> collectionsResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM collections');
      final int collectionsCount =
          collectionsResult.first['count'] as int? ?? 0;

      final List<Map<String, Object?>> itemsResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM collection_items');
      final int itemsCount = itemsResult.first['count'] as int? ?? 0;

      await db.close();

      return ProfileStats(
        collectionsCount: collectionsCount,
        itemsCount: itemsCount,
      );
    } on Exception catch (e) {
      _log.warning('Failed to get profile stats for $profileId', e);
      return ProfileStats.empty;
    }
  }

  /// Перезапускает приложение после переключения профиля.
  ///
  /// На десктопе: запускает новый процесс и завершает текущий.
  /// На Android: закрывает БД и пересоздаёт [ProviderScope] через
  /// [AppRestartScope], что обнуляет все провайдеры и показывает SplashScreen.
  static Future<void> restartApp(BuildContext context, WidgetRef ref) async {
    if (kIsMobile) {
      // Закрываем текущую БД перед пересозданием ProviderScope
      final DatabaseService db = ref.read(databaseServiceProvider);
      await db.close();

      // Меняем ключ ProviderScope → все провайдеры пересоздаются
      if (!context.mounted) return;
      await AppRestartScope.restart(context);
    } else {
      // Desktop: запускаем новый экземпляр и завершаем текущий
      final String exe = Platform.resolvedExecutable;
      await Process.start(exe, <String>[], mode: ProcessStartMode.detached);
      exit(0);
    }
  }
}
