// Сервис для загрузки каталога и файлов коллекций из GitHub.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/collections/models/collections_index.dart';
import 'xcoll_file.dart';

/// URL-база репозитория коллекций (raw GitHub content).
const String _kRepoBaseUrl =
    'https://raw.githubusercontent.com/hacan359/tonkatsu-collections/main';

/// Провайдер сервиса каталога коллекций.
final Provider<CollectionBrowserService> collectionBrowserServiceProvider =
    Provider<CollectionBrowserService>(
  (Ref ref) => CollectionBrowserService(),
);

/// Сервис для загрузки каталога и файлов коллекций из GitHub-репозитория.
///
/// Загружает `index.json` с метаданными, скачивает и парсит файлы коллекций
/// в формате `.xcoll`, `.xcollx` и `.zip`.
class CollectionBrowserService {
  /// Создаёт экземпляр [CollectionBrowserService].
  CollectionBrowserService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Кэш индекса в памяти (сбрасывается при рестарте приложения).
  CollectionsIndex? _cachedIndex;

  /// Загружает индекс коллекций (`index.json`).
  ///
  /// Кэширует результат в памяти. Используйте [forceRefresh] для
  /// принудительного обновления.
  Future<CollectionsIndex> fetchIndex({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedIndex != null) {
      return _cachedIndex!;
    }

    try {
      final Response<String> response =
          await _dio.get<String>('$_kRepoBaseUrl/index.json');
      final Map<String, dynamic> json =
          jsonDecode(response.data!) as Map<String, dynamic>;
      final CollectionsIndex index = CollectionsIndex.fromJson(json);
      _cachedIndex = index;
      return index;
    } on DioException catch (e) {
      throw CollectionBrowserException(
        'Failed to fetch collections index',
        e,
      );
    }
  }

  /// Скачивает файл коллекции и парсит как [XcollFile].
  ///
  /// Поддерживает `.xcoll`, `.xcollx` (JSON) и `.zip` (архив с коллекцией).
  Future<XcollFile> downloadCollection(
    RemoteCollection collection, {
    void Function(int received, int total)? onProgress,
  }) async {
    final String url = '$_kRepoBaseUrl/${collection.file}';

    try {
      if (collection.file.endsWith('.zip')) {
        return _downloadAndExtractZip(url, onProgress: onProgress);
      }
      return _downloadJson(url, onProgress: onProgress);
    } on DioException catch (e) {
      throw CollectionBrowserException(
        'Failed to download collection: ${collection.name}',
        e,
      );
    }
  }

  /// Очищает кэш индекса.
  void clearCache() {
    _cachedIndex = null;
  }

  /// Скачивает JSON-файл коллекции (.xcoll / .xcollx).
  Future<XcollFile> _downloadJson(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final Response<String> response = await _dio.get<String>(
      url,
      onReceiveProgress: onProgress,
    );
    return XcollFile.fromJsonString(response.data!);
  }

  /// Скачивает ZIP-архив, извлекает .xcoll/.xcollx и парсит.
  Future<XcollFile> _downloadAndExtractZip(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );

    final Uint8List bytes = Uint8List.fromList(response.data!);
    final Archive archive = ZipDecoder().decodeBytes(bytes);

    for (final ArchiveFile file in archive) {
      if (!file.isFile) continue;
      final String name = file.name.toLowerCase();
      if (name.endsWith('.xcoll') || name.endsWith('.xcollx')) {
        final String content = utf8.decode(file.content as List<int>);
        return XcollFile.fromJsonString(content);
      }
    }

    throw const CollectionBrowserException(
      'No .xcoll/.xcollx file found inside zip archive',
    );
  }
}

/// Исключение сервиса каталога коллекций.
class CollectionBrowserException implements Exception {
  /// Создаёт экземпляр [CollectionBrowserException].
  const CollectionBrowserException(this.message, [this.cause]);

  /// Сообщение об ошибке.
  final String message;

  /// Исходная причина ошибки.
  final Object? cause;

  @override
  String toString() => 'CollectionBrowserException: $message';
}
