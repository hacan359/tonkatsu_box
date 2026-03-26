// Сервис для полного бэкапа и восстановления данных приложения.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/wishlist_item.dart';
import 'config_service.dart';
import 'export_service.dart';
import 'import_service.dart';
import 'xcoll_file.dart';

/// Версия формата бэкапа.
const int backupFormatVersion = 1;

/// Провайдер для сервиса бэкапа.
final Provider<BackupService> backupServiceProvider =
    Provider<BackupService>((Ref ref) {
  return BackupService(
    exportService: ref.watch(exportServiceProvider),
    importService: ref.watch(importServiceProvider),
    configService: ref.watch(configServiceProvider),
    collectionRepo: ref.watch(collectionRepositoryProvider),
    wishlistRepo: ref.watch(wishlistRepositoryProvider),
  );
});

/// Callback для отслеживания прогресса бэкапа/восстановления.
typedef BackupProgressCallback = void Function(BackupProgress progress);

/// Прогресс операции бэкапа/восстановления.
class BackupProgress {
  /// Создаёт экземпляр [BackupProgress].
  const BackupProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.collectionName,
  });

  /// Текущий этап.
  final String stage;

  /// Текущий элемент.
  final int current;

  /// Общее количество.
  final int total;

  /// Название текущей коллекции (если применимо).
  final String? collectionName;
}

/// Результат операции бэкапа.
class BackupResult {
  /// Создаёт экземпляр [BackupResult].
  const BackupResult({
    required this.success,
    this.filePath,
    this.error,
    this.collectionsCount = 0,
    this.itemsCount = 0,
  });

  /// Успешный результат.
  const BackupResult.success(
    String path, {
    int collections = 0,
    int items = 0,
  })  : success = true,
        filePath = path,
        error = null,
        collectionsCount = collections,
        itemsCount = items;

  /// Неуспешный результат.
  const BackupResult.failure(String message)
      : success = false,
        filePath = null,
        error = message,
        collectionsCount = 0,
        itemsCount = 0;

  /// Отменённая операция.
  const BackupResult.cancelled()
      : success = false,
        filePath = null,
        error = null,
        collectionsCount = 0,
        itemsCount = 0;

  /// Успешность операции.
  final bool success;

  /// Путь к файлу.
  final String? filePath;

  /// Сообщение об ошибке.
  final String? error;

  /// Количество коллекций в бэкапе.
  final int collectionsCount;

  /// Количество элементов в бэкапе.
  final int itemsCount;

  /// Возвращает true, если операция была отменена.
  bool get isCancelled => !success && error == null;
}

/// Результат восстановления из бэкапа.
class RestoreResult {
  /// Создаёт экземпляр [RestoreResult].
  const RestoreResult({
    required this.success,
    this.error,
    this.collectionsRestored = 0,
    this.itemsRestored = 0,
    this.wishlistRestored = 0,
    this.settingsRestored = false,
  });

  /// Успешный результат.
  const RestoreResult.success({
    int collections = 0,
    int items = 0,
    int wishlist = 0,
    bool settings = false,
  })  : success = true,
        error = null,
        collectionsRestored = collections,
        itemsRestored = items,
        wishlistRestored = wishlist,
        settingsRestored = settings;

  /// Неуспешный результат.
  const RestoreResult.failure(String message)
      : success = false,
        error = message,
        collectionsRestored = 0,
        itemsRestored = 0,
        wishlistRestored = 0,
        settingsRestored = false;

  /// Отменённая операция.
  const RestoreResult.cancelled()
      : success = false,
        error = null,
        collectionsRestored = 0,
        itemsRestored = 0,
        wishlistRestored = 0,
        settingsRestored = false;

  /// Успешность операции.
  final bool success;

  /// Сообщение об ошибке.
  final String? error;

  /// Количество восстановленных коллекций.
  final int collectionsRestored;

  /// Количество восстановленных элементов.
  final int itemsRestored;

  /// Количество восстановленных элементов вишлиста.
  final int wishlistRestored;

  /// Были ли восстановлены настройки.
  final bool settingsRestored;

  /// Возвращает true, если операция была отменена.
  bool get isCancelled => !success && error == null;
}

/// Метаданные ZIP-бэкапа (из manifest.json).
class BackupManifest {
  /// Создаёт экземпляр [BackupManifest].
  const BackupManifest({
    required this.version,
    required this.created,
    required this.collectionsCount,
    required this.itemsCount,
    required this.wishlistCount,
    required this.includesConfig,
    this.profileName,
    this.appVersion,
  });

  /// Парсит manifest из JSON.
  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      version: json['version'] as int? ?? 1,
      created: DateTime.parse(json['created'] as String),
      collectionsCount: json['collections_count'] as int? ?? 0,
      itemsCount: json['items_count'] as int? ?? 0,
      wishlistCount: json['wishlist_count'] as int? ?? 0,
      includesConfig: json['includes_config'] as bool? ?? false,
      profileName: json['profile_name'] as String?,
      appVersion: json['app_version'] as String?,
    );
  }

  /// Версия формата.
  final int version;

  /// Дата создания бэкапа.
  final DateTime created;

  /// Количество коллекций.
  final int collectionsCount;

  /// Количество элементов.
  final int itemsCount;

  /// Количество элементов вишлиста.
  final int wishlistCount;

  /// Содержит ли настройки.
  final bool includesConfig;

  /// Имя профиля.
  final String? profileName;

  /// Версия приложения.
  final String? appVersion;
}

/// Сервис для полного бэкапа и восстановления данных.
///
/// Создаёт ZIP-архив со всеми коллекциями (full export + user data),
/// вишлистом и настройками. Позволяет восстановить всё одной операцией.
class BackupService {
  /// Создаёт экземпляр [BackupService].
  BackupService({
    required ExportService exportService,
    required ImportService importService,
    required ConfigService configService,
    required CollectionRepository collectionRepo,
    required WishlistRepository wishlistRepo,
  })  : _exportService = exportService,
        _importService = importService,
        _configService = configService,
        _collectionRepo = collectionRepo,
        _wishlistRepo = wishlistRepo;

  static final Logger _log = Logger('BackupService');

  final ExportService _exportService;
  final ImportService _importService;
  final ConfigService _configService;
  final CollectionRepository _collectionRepo;
  final WishlistRepository _wishlistRepo;

  // ==================== Backup ====================

  /// Создаёт полный бэкап всех данных и сохраняет как ZIP.
  Future<BackupResult> createBackup({
    BackupProgressCallback? onProgress,
  }) async {
    try {
      // 1. Собираем все коллекции
      final List<Collection> collections = await _collectionRepo.getAll();

      // 2. Экспортируем каждую коллекцию
      final Archive archive = Archive();
      int totalItems = 0;

      for (int i = 0; i < collections.length; i++) {
        final Collection collection = collections[i];
        onProgress?.call(BackupProgress(
          stage: 'collections',
          current: i,
          total: collections.length,
          collectionName: collection.name,
        ));

        final List<CollectionItem> items =
            await _collectionRepo.getItemsWithData(collection.id);
        totalItems += items.length;

        final XcollFile xcoll = await _exportService.createFullExport(
          collection,
          items,
          collection.id,
          includeUserData: true,
        );

        final String json = xcoll.toJsonString();
        final List<int> jsonBytes = utf8.encode(json);
        final String fileName = _collectionFileName(i, collection.name);
        archive.addFile(ArchiveFile(
          'collections/$fileName',
          jsonBytes.length,
          jsonBytes,
        ));
      }

      // 3. Вишлист
      onProgress?.call(const BackupProgress(
        stage: 'wishlist',
        current: 0,
        total: 1,
      ));

      final List<WishlistItem> wishlistItems =
          await _wishlistRepo.getAll(includeResolved: true);
      final List<Map<String, dynamic>> wishlistJson = wishlistItems
          .map((WishlistItem item) => _wishlistItemToExport(item))
          .toList();
      final String wishlistStr =
          const JsonEncoder.withIndent('  ').convert(wishlistJson);
      final List<int> wishlistBytes = utf8.encode(wishlistStr);
      archive.addFile(ArchiveFile(
        'wishlist.json',
        wishlistBytes.length,
        wishlistBytes,
      ));

      // 4. Настройки
      final Map<String, Object> config = _configService.collectSettings();
      final String configStr =
          const JsonEncoder.withIndent('  ').convert(config);
      final List<int> configBytes = utf8.encode(configStr);
      archive.addFile(ArchiveFile(
        'config.json',
        configBytes.length,
        configBytes,
      ));

      // 5. Манифест
      final Map<String, dynamic> manifest = <String, dynamic>{
        'version': backupFormatVersion,
        'created': DateTime.now().toUtc().toIso8601String(),
        'collections_count': collections.length,
        'items_count': totalItems,
        'wishlist_count': wishlistItems.length,
        'includes_config': true,
      };
      final String manifestStr =
          const JsonEncoder.withIndent('  ').convert(manifest);
      final List<int> manifestBytes = utf8.encode(manifestStr);
      archive.addFile(ArchiveFile(
        'manifest.json',
        manifestBytes.length,
        manifestBytes,
      ));

      // 6. Кодируем ZIP
      onProgress?.call(BackupProgress(
        stage: 'saving',
        current: collections.length,
        total: collections.length,
      ));

      final List<int> zipBytes = ZipEncoder().encode(archive);

      // 7. Сохраняем файл
      final String dateSuffix = _dateSuffix();
      final bool useAny = Platform.isAndroid || Platform.isIOS;
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: 'tonkatsu-backup-$dateSuffix.zip',
        type: useAny ? FileType.any : FileType.custom,
        allowedExtensions: useAny ? null : <String>['zip'],
        bytes: Uint8List.fromList(zipBytes),
      );

      if (outputPath == null) {
        return const BackupResult.cancelled();
      }

      // На десктопе записываем сами
      if (!Platform.isAndroid && !Platform.isIOS) {
        final String finalPath =
            outputPath.endsWith('.zip') ? outputPath : '$outputPath.zip';
        final File file = File(finalPath);
        await file.writeAsBytes(zipBytes);
        return BackupResult.success(
          finalPath,
          collections: collections.length,
          items: totalItems,
        );
      }

      return BackupResult.success(
        outputPath,
        collections: collections.length,
        items: totalItems,
      );
    } on FileSystemException catch (e) {
      return BackupResult.failure('Failed to save backup: ${e.message}');
    } catch (e) {
      _log.warning('Backup failed', e);
      return BackupResult.failure('Backup failed: $e');
    }
  }

  // ==================== Restore ====================

  /// Читает манифест из ZIP-бэкапа без импорта.
  Future<BackupManifest?> readManifest(String zipPath) async {
    try {
      final List<int> bytes = File(zipPath).readAsBytesSync();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      for (final ArchiveFile file in archive) {
        if (file.name == 'manifest.json' && file.isFile) {
          final String content = utf8.decode(file.content as List<int>);
          final Map<String, dynamic> json =
              jsonDecode(content) as Map<String, dynamic>;
          return BackupManifest.fromJson(json);
        }
      }

      return null;
    } catch (e) {
      _log.warning('Failed to read manifest', e);
      return null;
    }
  }

  /// Восстанавливает данные из ZIP-бэкапа.
  Future<RestoreResult> restoreFromBackup({
    required String zipPath,
    bool restoreSettings = false,
    bool restoreWishlist = true,
    BackupProgressCallback? onProgress,
  }) async {
    try {
      final List<int> bytes = File(zipPath).readAsBytesSync();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      // Разбираем содержимое архива
      final Map<String, String> collectionFiles = <String, String>{};
      String? wishlistContent;
      String? configContent;

      for (final ArchiveFile file in archive) {
        if (!file.isFile) continue;
        final String content = utf8.decode(file.content as List<int>);

        if (file.name.startsWith('collections/') &&
            file.name.endsWith('.xcollx')) {
          collectionFiles[file.name] = content;
        } else if (file.name == 'wishlist.json') {
          wishlistContent = content;
        } else if (file.name == 'config.json') {
          configContent = content;
        }
      }

      // Импорт коллекций
      int collectionsRestored = 0;
      int itemsRestored = 0;
      final List<String> sortedKeys = collectionFiles.keys.toList()..sort();

      for (int i = 0; i < sortedKeys.length; i++) {
        final String fileName = sortedKeys[i];
        final String content = collectionFiles[fileName]!;

        onProgress?.call(BackupProgress(
          stage: 'collections',
          current: i,
          total: sortedKeys.length,
        ));

        try {
          final XcollFile xcoll = XcollFile.fromJsonString(content);
          final ImportResult result =
              await _importService.importFromXcoll(xcoll);
          if (result.success) {
            collectionsRestored++;
            itemsRestored += result.itemsImported ?? 0;
          }
        } catch (e) {
          _log.warning('Failed to import $fileName', e);
        }
      }

      // Восстановление вишлиста
      int wishlistRestored = 0;
      if (restoreWishlist && wishlistContent != null) {
        onProgress?.call(const BackupProgress(
          stage: 'wishlist',
          current: 0,
          total: 1,
        ));
        wishlistRestored = await _restoreWishlist(wishlistContent);
      }

      // Восстановление настроек
      bool settingsApplied = false;
      if (restoreSettings && configContent != null) {
        onProgress?.call(const BackupProgress(
          stage: 'settings',
          current: 0,
          total: 1,
        ));

        final Map<String, Object?> config =
            jsonDecode(configContent) as Map<String, Object?>;
        final int applied = await _configService.applySettings(config);
        settingsApplied = applied > 0;
      }

      return RestoreResult.success(
        collections: collectionsRestored,
        items: itemsRestored,
        wishlist: wishlistRestored,
        settings: settingsApplied,
      );
    } on ArchiveException {
      return const RestoreResult.failure('Invalid backup archive');
    } on FormatException catch (e) {
      return RestoreResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      _log.warning('Restore failed', e);
      return RestoreResult.failure('Restore failed: $e');
    }
  }

  // ==================== Helpers ====================

  /// Конвертирует WishlistItem в Map для экспорта.
  Map<String, dynamic> _wishlistItemToExport(WishlistItem item) {
    return <String, dynamic>{
      'text': item.text,
      'media_type_hint': item.mediaTypeHint?.value,
      'note': item.note,
      'is_resolved': item.isResolved,
      'created_at': item.createdAt.millisecondsSinceEpoch ~/ 1000,
      'resolved_at': item.resolvedAt != null
          ? item.resolvedAt!.millisecondsSinceEpoch ~/ 1000
          : null,
    };
  }

  /// Восстанавливает вишлист из JSON. Дедупликация по тексту.
  Future<int> _restoreWishlist(String jsonContent) async {
    final List<dynamic> items = jsonDecode(jsonContent) as List<dynamic>;
    int restored = 0;

    for (final dynamic item in items) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final String text = data['text'] as String;

      // Дедупликация: не добавлять если уже есть с таким текстом
      final WishlistItem? existing =
          await _wishlistRepo.findUnresolved(text);
      if (existing != null) continue;

      final String? mediaTypeHint = data['media_type_hint'] as String?;
      await _wishlistRepo.add(
        text: text,
        mediaTypeHint: mediaTypeHint != null
            ? MediaType.fromString(mediaTypeHint)
            : null,
        note: data['note'] as String?,
      );
      restored++;
    }

    return restored;
  }

  /// Генерирует имя файла для коллекции в архиве.
  String _collectionFileName(int index, String name) {
    final String sanitized = name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase();
    final String padded = '${index + 1}'.padLeft(3, '0');
    return '${padded}_$sanitized.xcollx';
  }

  /// Генерирует суффикс даты для имени файла.
  String _dateSuffix() {
    final DateTime now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
