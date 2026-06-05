import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/collections/models/collections_index.dart';
import 'xcoll_file.dart';

/// Raw GitHub content base URL for the collections repo.
const String _kRepoBaseUrl =
    'https://raw.githubusercontent.com/hacan359/tonkatsu-collections/main';

final Provider<CollectionBrowserService> collectionBrowserServiceProvider =
    Provider<CollectionBrowserService>(
  (Ref ref) => CollectionBrowserService(),
);

/// Downloads the collections catalog and files from the GitHub repo.
///
/// Fetches `index.json` metadata, then downloads and parses collection files
/// in `.xcoll`, `.xcollx` and `.zip` formats.
class CollectionBrowserService {
  CollectionBrowserService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  CollectionsIndex? _cachedIndex;

  /// Fetches the collections index (`index.json`), cached in memory.
  /// Pass [forceRefresh] to bypass the cache.
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

  /// Downloads a collection file and parses it as an [XcollFile].
  ///
  /// Supports `.xcoll`, `.xcollx` (JSON) and `.zip` (archived collection).
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

  void clearCache() {
    _cachedIndex = null;
  }

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

  /// Downloads a ZIP archive, extracts the .xcoll/.xcollx inside and parses it.
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

class CollectionBrowserException implements Exception {
  const CollectionBrowserException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'CollectionBrowserException: $message';
}
