import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ключи для SharedPreferences.
class _CacheKeys {
  static const String customCachePath = 'image_cache_path';
  static const String cacheEnabled = 'image_cache_enabled';
}

/// Типы изображений для кэширования.
enum ImageType {
  /// Логотипы платформ.
  platformLogo('platform_logos'),

  /// Обложки игр.
  gameCover('game_covers'),

  /// Постеры фильмов.
  moviePoster('movie_posters'),

  /// Постеры сериалов.
  tvShowPoster('tv_show_posters');

  const ImageType(this.folder);

  /// Имя папки для данного типа.
  final String folder;
}

/// Провайдер сервиса кэширования изображений.
final Provider<ImageCacheService> imageCacheServiceProvider =
    Provider<ImageCacheService>((Ref ref) {
  return ImageCacheService();
});

/// Сервис для локального кэширования изображений.
///
/// Поддерживает кэширование логотипов платформ и обложек игр.
/// При включённом кэшировании изображения сохраняются локально
/// и используются в оффлайн режиме.
class ImageCacheService {
  final Dio _dio = Dio();

  /// Возвращает базовый путь к директории кэша.
  Future<String> getBaseCachePath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? customPath = prefs.getString(_CacheKeys.customCachePath);

    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }

    // Путь по умолчанию
    final Directory appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'xerabora', 'image_cache');
  }

  /// Возвращает путь к директории для конкретного типа изображений.
  Future<String> getCachePath(ImageType type) async {
    final String basePath = await getBaseCachePath();
    return p.join(basePath, type.folder);
  }

  /// Устанавливает кастомный путь к кэшу.
  Future<void> setCachePath(String path) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_CacheKeys.customCachePath, path);
  }

  /// Сбрасывает путь к кэшу на значение по умолчанию.
  Future<void> resetCachePath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_CacheKeys.customCachePath);
  }

  /// Возвращает включено ли кэширование.
  Future<bool> isCacheEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_CacheKeys.cacheEnabled) ?? false;
  }

  /// Устанавливает состояние кэширования.
  Future<void> setCacheEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_CacheKeys.cacheEnabled, enabled);
  }

  /// Возвращает путь к локальному файлу изображения.
  Future<String> getLocalImagePath(ImageType type, String imageId) async {
    final String cachePath = await getCachePath(type);
    return p.join(cachePath, '$imageId.png');
  }

  /// Проверяет есть ли изображение в кэше.
  Future<bool> isImageCached(ImageType type, String imageId) async {
    final String path = await getLocalImagePath(type, imageId);
    return File(path).existsSync();
  }

  /// Возвращает результат получения изображения.
  ///
  /// Логика:
  /// - Кэширование выключено: возвращает удалённый URL
  /// - Кэширование включено + файл есть: возвращает локальный путь
  /// - Кэширование включено + файла нет: возвращает удалённый URL
  ///   с isMissing = true для фоновой загрузки
  Future<ImageResult> getImageUri({
    required ImageType type,
    required String imageId,
    required String remoteUrl,
  }) async {
    final bool enabled = await isCacheEnabled();

    if (!enabled) {
      // Кэширование выключено - используем удалённый URL
      return ImageResult(uri: remoteUrl, isLocal: false, isMissing: false);
    }

    // Кэширование включено - проверяем локальный файл
    final String localPath = await getLocalImagePath(type, imageId);
    final File file = File(localPath);

    if (file.existsSync() && file.lengthSync() > 0) {
      return ImageResult(uri: localPath, isLocal: true, isMissing: false);
    }

    // Файл отсутствует — показать из сети, пометить как отсутствующий в кэше
    return ImageResult(uri: remoteUrl, isLocal: false, isMissing: true);
  }

  /// Скачивает изображение в кэш.
  Future<bool> downloadImage({
    required ImageType type,
    required String imageId,
    required String remoteUrl,
  }) async {
    try {
      final String localPath = await getLocalImagePath(type, imageId);
      final File file = File(localPath);

      // Создаём директорию если не существует
      final Directory dir = file.parent;
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      // Скачиваем файл
      await _dio.download(remoteUrl, localPath);

      // Проверяем что файл не пустой (битое скачивание)
      if (file.existsSync() && file.lengthSync() == 0) {
        await file.delete();
        return false;
      }

      return true;
    } catch (e) {
      // Удаляем частично скачанный файл при ошибке
      final String localPath = await getLocalImagePath(type, imageId);
      final File partial = File(localPath);
      if (partial.existsSync() && partial.lengthSync() == 0) {
        await partial.delete();
      }
      return false;
    }
  }

  /// Скачивает список изображений.
  ///
  /// Возвращает количество успешно скачанных.
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

  /// Очищает весь кэш изображений.
  Future<void> clearCache() async {
    final String basePath = await getBaseCachePath();
    final Directory dir = Directory(basePath);

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  /// Очищает кэш для конкретного типа изображений.
  Future<void> clearCacheForType(ImageType type) async {
    final String cachePath = await getCachePath(type);
    final Directory dir = Directory(cachePath);

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  /// Возвращает размер кэша в байтах.
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

  /// Возвращает количество файлов в кэше.
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

  /// Форматирует размер в читаемый вид.
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Результат получения изображения.
class ImageResult {
  /// Создаёт [ImageResult].
  const ImageResult({
    required this.uri,
    required this.isLocal,
    required this.isMissing,
  });

  /// URI изображения (локальный путь или удалённый URL).
  final String? uri;

  /// true если используется локальный файл.
  final bool isLocal;

  /// true если локальный файл отсутствует (кэш повреждён).
  final bool isMissing;
}

/// Задача для скачивания изображения.
class ImageDownloadTask {
  /// Создаёт [ImageDownloadTask].
  const ImageDownloadTask({
    required this.imageId,
    required this.remoteUrl,
  });

  /// ID изображения (имя файла без расширения).
  final String imageId;

  /// URL для скачивания.
  final String remoteUrl;
}
