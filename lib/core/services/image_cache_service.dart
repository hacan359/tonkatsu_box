import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/profile.dart';
import 'profile_service.dart';
import 'storage_root.dart';

class _CacheKeys {
  static const String customCachePath = 'image_cache_path';
  static const String cacheEnabled = 'image_cache_enabled';
}

enum ImageType {
  gameCover('game_covers'),

  moviePoster('movie_posters'),

  tvShowPoster('tv_show_posters'),

  canvasImage('canvas_images'),

  mangaCover('manga_covers'),

  vnCover('vn_covers'),

  animeCover('anime_covers'),

  bookCover('book_covers'),

  customCover('custom_covers');

  const ImageType(this.folder);

  final String folder;
}

final Provider<ImageCacheService> imageCacheServiceProvider =
    Provider<ImageCacheService>((Ref ref) {
  return ImageCacheService();
});

/// Caches images locally; when caching is enabled, cached files are served
/// instead of the network so images keep working offline.
class ImageCacheService {
  static final Logger _log = Logger('ImageCacheService');
  final Dio _dio = Dio();

  Future<String> getBaseCachePath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? customPath = prefs.getString(_CacheKeys.customCachePath);

    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }

    final String basePath = (await StorageRoot.resolve()).path;

    // If the profile system is initialized, the cache lives in the profile folder
    final File profilesFile =
        File(p.join(basePath, StorageRoot.profilesFileName));
    if (profilesFile.existsSync()) {
      final ProfileService profileService = ProfileService();
      final ProfilesData data = await profileService.loadProfiles();
      return p.join(
        basePath,
        StorageRoot.profilesFolderName,
        data.currentProfileId,
        StorageRoot.imageCacheFolderName,
      );
    }

    return p.join(basePath, StorageRoot.imageCacheFolderName);
  }

  Future<String> getCachePath(ImageType type) async {
    final String basePath = await getBaseCachePath();
    return p.join(basePath, type.folder);
  }

  Future<void> setCachePath(String path) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_CacheKeys.customCachePath, path);
  }

  Future<void> resetCachePath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_CacheKeys.customCachePath);
  }

  Future<bool> isCacheEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_CacheKeys.cacheEnabled) ?? true;
  }

  Future<void> setCacheEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_CacheKeys.cacheEnabled, enabled);
  }

  Future<String> getLocalImagePath(ImageType type, String imageId) async {
    final String cachePath = await getCachePath(type);
    return p.join(cachePath, '$imageId.png');
  }

  /// Returns null if the file does not exist or is empty.
  Future<Uint8List?> readImageBytes(ImageType type, String imageId) async {
    final String path = await getLocalImagePath(type, imageId);
    final File file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) {
      return null;
    }
    return file.readAsBytes();
  }

  /// Rejects empty data to avoid creating 0-byte files.
  /// Returns true on success.
  Future<bool> saveImageBytes(
    ImageType type,
    String imageId,
    Uint8List bytes,
  ) async {
    if (bytes.isEmpty) return false;
    try {
      final String path = await getLocalImagePath(type, imageId);
      final File file = File(path);
      final Directory dir = file.parent;
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      _log.warning('Failed to save image bytes: $imageId', e);
      return false;
    }
  }

  Future<bool> isImageCached(ImageType type, String imageId) async {
    final String path = await getLocalImagePath(type, imageId);
    final File file = File(path);
    return file.existsSync() && _isValidImageFile(file);
  }

  /// Tolerates files locked by another process on Windows.
  Future<void> deleteImage(ImageType type, String imageId) async {
    final String path = await getLocalImagePath(type, imageId);
    final File file = File(path);
    if (file.existsSync()) {
      await _tryDelete(file);
    }
  }

  /// Returns the local path when a valid cached file exists; otherwise the
  /// remote URL, with isMissing = true (when caching is on) so callers can
  /// download in the background.
  Future<ImageResult> getImageUri({
    required ImageType type,
    required String imageId,
    required String remoteUrl,
  }) async {
    final bool enabled = await isCacheEnabled();

    if (!enabled) {
      return ImageResult(uri: remoteUrl, isLocal: false, isMissing: false);
    }

    final String localPath = await getLocalImagePath(type, imageId);
    final File file = File(localPath);

    if (file.existsSync() && _isValidImageFile(file)) {
      return ImageResult(uri: localPath, isLocal: true, isMissing: false);
    }

    return ImageResult(uri: remoteUrl, isLocal: false, isMissing: true);
  }

  /// Checks the magic bytes and the end-of-file marker to catch files
  /// truncated during download. Supports JPEG, PNG, and WebP.
  bool _isValidImageFile(File file) {
    if (!file.existsSync()) return false;
    final int length = file.lengthSync();
    if (length < 12) return false;

    final RandomAccessFile raf = file.openSync();
    try {
      final Uint8List header = raf.readSync(12);

      // JPEG: starts FF D8 FF, ends FF D9
      if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
        raf.setPositionSync(length - 2);
        final Uint8List tail = raf.readSync(2);
        return tail[0] == 0xFF && tail[1] == 0xD9;
      }

      // PNG: starts 89 50 4E 47, ends with IEND (49 45 4E 44 AE 42 60 82)
      if (header[0] == 0x89 &&
          header[1] == 0x50 &&
          header[2] == 0x4E &&
          header[3] == 0x47) {
        if (length < 20) return false;
        raf.setPositionSync(length - 8);
        final Uint8List tail = raf.readSync(8);
        return tail[0] == 0x49 &&
            tail[1] == 0x45 &&
            tail[2] == 0x4E &&
            tail[3] == 0x44 &&
            tail[4] == 0xAE &&
            tail[5] == 0x42 &&
            tail[6] == 0x60 &&
            tail[7] == 0x82;
      }

      // WebP: RIFF....WEBP — verify the declared size
      if (header[0] == 0x52 &&
          header[1] == 0x49 &&
          header[2] == 0x46 &&
          header[3] == 0x46 &&
          header[8] == 0x57 &&
          header[9] == 0x45 &&
          header[10] == 0x42 &&
          header[11] == 0x50) {
        // RIFF header stores the data size in bytes 4-7 (little-endian)
        final int declaredSize =
            header[4] | header[5] << 8 | header[6] << 16 | header[7] << 24;
        // Actual size = declaredSize + 8 (RIFF + size bytes)
        return length >= declaredSize + 8;
      }

      return false;
    } finally {
      raf.closeSync();
    }
  }

  /// Deletes the file, ignoring Windows file-lock errors.
  Future<void> _tryDelete(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // The file may be locked by another process (Windows). Skip it;
      // the next download will overwrite it.
    }
  }

  Future<bool> downloadImage({
    required ImageType type,
    required String imageId,
    required String remoteUrl,
  }) async {
    try {
      final String localPath = await getLocalImagePath(type, imageId);
      final File file = File(localPath);

      final Directory dir = file.parent;
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      await _dio.download(remoteUrl, localPath);

      if (!_isValidImageFile(file)) {
        await _tryDelete(file);
        return false;
      }

      return true;
    } catch (e) {
      _log.warning('Failed to download image: $imageId', e);
      // Remove the invalid/partial file left by the failed download
      final String localPath = await getLocalImagePath(type, imageId);
      final File partial = File(localPath);
      if (partial.existsSync()) {
        await _tryDelete(partial);
      }
      return false;
    }
  }

  /// Returns the number of successfully downloaded images.
  Future<int> downloadImages({
    required ImageType type,
    required List<ImageDownloadTask> tasks,
    void Function(int current, int total)? onProgress,
  }) async {
    int downloaded = 0;
    for (int i = 0; i < tasks.length; i++) {
      final ImageDownloadTask task = tasks[i];
      final bool success = await downloadImage(
        type: type,
        imageId: task.imageId,
        remoteUrl: task.remoteUrl,
      );
      if (success) downloaded++;
      onProgress?.call(i + 1, tasks.length);
    }
    return downloaded;
  }

  Future<void> clearCache() async {
    final String basePath = await getBaseCachePath();
    final Directory dir = Directory(basePath);

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> clearCacheForType(ImageType type) async {
    final String cachePath = await getCachePath(type);
    final Directory dir = Directory(cachePath);

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  Future<int> getCacheSize() async {
    final String basePath = await getBaseCachePath();
    final Directory dir = Directory(basePath);

    if (!dir.existsSync()) return 0;

    int size = 0;
    await for (final FileSystemEntity entity in dir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  Future<int> getCachedCount() async {
    final String basePath = await getBaseCachePath();
    final Directory dir = Directory(basePath);

    if (!dir.existsSync()) return 0;

    int count = 0;
    await for (final FileSystemEntity entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.png')) {
        count++;
      }
    }
    return count;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ImageResult {
  const ImageResult({
    required this.uri,
    required this.isLocal,
    required this.isMissing,
  });

  /// Local file path or remote URL.
  final String? uri;

  final bool isLocal;

  /// True when caching is on but no valid local file exists.
  final bool isMissing;
}

class ImageDownloadTask {
  const ImageDownloadTask({
    required this.imageId,
    required this.remoteUrl,
  });

  /// Image id, used as the cache file name (without extension).
  final String imageId;

  final String remoteUrl;
}
