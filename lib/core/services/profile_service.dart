import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../main.dart' show AppRestartScope;
import '../../shared/constants/platform_features.dart';
import '../../shared/models/profile.dart';
import '../database/database_service.dart';
import 'storage_root.dart';

final Provider<ProfileService> profileServiceProvider =
    Provider<ProfileService>((Ref ref) {
  return ProfileService();
});

/// Each profile has an isolated database and image cache. Profile metadata
/// lives in `profiles.json` at the app root.
class ProfileService {
  static final Logger _log = Logger('ProfileService');

  static const String _imageCacheFolderName = 'image_cache';

  String? _basePath;

  Future<String> getBasePath() async {
    if (_basePath != null) return _basePath!;
    _basePath = (await StorageRoot.resolve()).path;
    return _basePath!;
  }

  /// Creates a default profile when `profiles.json` does not exist yet.
  Future<ProfilesData> loadProfiles() async {
    final String basePath = await getBasePath();
    final File file = File(p.join(basePath, StorageRoot.profilesFileName));

    if (await file.exists()) {
      final String content = await file.readAsString();
      return ProfilesData.fromJsonString(content);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String authorName =
        prefs.getString('default_author') ?? 'Default';

    final ProfilesData data =
        ProfilesData.defaultData(authorName: authorName);
    await _saveProfiles(data);
    return data;
  }

  Future<void> _saveProfiles(ProfilesData data) async {
    final String basePath = await getBasePath();
    final Directory baseDir = Directory(basePath);
    if (!baseDir.existsSync()) {
      await baseDir.create(recursive: true);
    }
    final File file = File(p.join(basePath, StorageRoot.profilesFileName));
    await file.writeAsString(data.toJsonString());
  }

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

    final String profileDir = await getProfileDir(id);
    await Directory(profileDir).create(recursive: true);

    final ProfilesData updated = data.copyWith(
      profiles: <Profile>[...data.profiles, profile],
    );
    await _saveProfiles(updated);

    _log.info('Created profile: ${profile.name} (${profile.id})');
    return profile;
  }

  /// Throws when deleting the last profile. If the active profile is
  /// deleted, switches to the first remaining one.
  Future<void> deleteProfile(String profileId) async {
    final ProfilesData data = await loadProfiles();

    if (data.profiles.length <= 1) {
      throw StateError('Cannot delete the last profile');
    }

    final String profileDir = await getProfileDir(profileId);
    final Directory dir = Directory(profileDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    final List<Profile> remaining = data.profiles
        .where((Profile p) => p.id != profileId)
        .toList();

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

  Future<void> updateProfile(Profile profile) async {
    final ProfilesData data = await loadProfiles();
    final List<Profile> updated = data.profiles.map((Profile p) {
      if (p.id == profile.id) return profile;
      return p;
    }).toList();

    await _saveProfiles(data.copyWith(profiles: updated));
    _log.info('Updated profile: ${profile.name} (${profile.id})');
  }

  Future<void> switchProfile(String profileId) async {
    final ProfilesData data = await loadProfiles();
    await _saveProfiles(data.copyWith(currentProfileId: profileId));
    _log.info('Switched to profile: $profileId');
  }

  Future<String> getProfileDir(String profileId) async {
    final String basePath = await getBasePath();
    return p.join(basePath, StorageRoot.profilesFolderName, profileId);
  }

  Future<String> getDatabasePath(String profileId) async {
    final String dir = await getProfileDir(profileId);
    return p.join(dir, StorageRoot.dbFileName);
  }

  Future<String> getImageCachePath(String profileId) async {
    final String dir = await getProfileDir(profileId);
    return p.join(dir, _imageCacheFolderName);
  }

  /// Migrates pre-profile data into the default profile. Runs only when an
  /// old database exists and the profiles/ folder does not.
  Future<bool> migrateIfNeeded() async {
    final String basePath = await getBasePath();
    final File oldDb = File(p.join(basePath, StorageRoot.dbFileName));
    final Directory profilesDir =
        Directory(p.join(basePath, StorageRoot.profilesFolderName));

    if (!oldDb.existsSync() || profilesDir.existsSync()) {
      return false;
    }

    _log.info('Migrating existing database to profile system...');

    final String defaultDir =
        p.join(basePath, StorageRoot.profilesFolderName, 'default');
    await Directory(defaultDir).create(recursive: true);

    await oldDb.rename(p.join(defaultDir, StorageRoot.dbFileName));

    final Directory oldCache =
        Directory(p.join(basePath, _imageCacheFolderName));
    if (oldCache.existsSync()) {
      await oldCache.rename(p.join(defaultDir, _imageCacheFolderName));
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String authorName =
        prefs.getString('default_author') ?? 'Default';

    final ProfilesData data =
        ProfilesData.defaultData(authorName: authorName);
    await _saveProfiles(data);

    _log.info('Migration complete: profile "$authorName" created');
    return true;
  }

  /// Pass [currentDb] for the current profile so the open sqflite singleton
  /// connection is reused; other profiles are opened separately (read-only).
  Future<ProfileStats> getProfileStats(
    String profileId, {
    DatabaseService? currentDb,
  }) async {
    final String dbPath = await getDatabasePath(profileId);
    final File dbFile = File(dbPath);

    if (!dbFile.existsSync()) return ProfileStats.empty;

    try {
      if (currentDb != null) {
        final int collectionsCount = await currentDb.getCollectionCount();
        final int itemsCount = await currentDb.getTotalItemCount();
        return ProfileStats(
          collectionsCount: collectionsCount,
          itemsCount: itemsCount,
        );
      }

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

  /// Restarts the app after a profile switch. Desktop: spawns a new process
  /// and exits. Android: closes the DB and recreates [ProviderScope] via
  /// [AppRestartScope], which resets all providers and shows the SplashScreen.
  static Future<void> restartApp(BuildContext context, WidgetRef ref) async {
    if (kIsMobile) {
      // The DB must be closed before ProviderScope is recreated
      final DatabaseService db = ref.read(databaseServiceProvider);
      await db.close();

      if (!context.mounted) return;
      await AppRestartScope.restart(context);
    } else {
      final String exe = Platform.resolvedExecutable;
      await Process.start(exe, <String>[], mode: ProcessStartMode.detached);
      exit(0);
    }
  }
}
