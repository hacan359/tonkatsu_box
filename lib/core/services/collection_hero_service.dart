import 'dart:io';

import 'package:core/api/image_proxy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/constants/platform_features.dart';
import '../selfhost/server_origin.dart';
import 'image_cache_service.dart';
import 'storage_root.dart';

/// Overridden in `main.dart` with the value resolved at app startup.
final Provider<String> collectionsHeroDirProvider = Provider<String>(
  (Ref ref) => throw UnimplementedError(
    'collectionsHeroDirProvider must be overridden in main()',
  ),
);

final Provider<CollectionHeroService> collectionHeroServiceProvider =
    Provider<CollectionHeroService>(
  (Ref ref) => CollectionHeroService(
    rootDir: ref.watch(collectionsHeroDirProvider),
    imageCache: ref.watch(imageCacheServiceProvider),
  ),
);

class CollectionHeroService {
  const CollectionHeroService({required String rootDir, ImageCacheService? imageCache})
      : _rootDir = rootDir,
        _imageCache = imageCache;

  static final Logger _log = Logger('CollectionHeroService');

  final String _rootDir;

  /// Carries hero bytes to the server's image cache on web; unused on
  /// desktop, where heroes are plain files next to the database.
  final ImageCacheService? _imageCache;

  /// Resolves `<dataRoot>/collections/`, creating it if needed, and migrates
  /// hero images left in the legacy `<appSupport>` location. Startup-only.
  static Future<String> resolveRoot() async {
    final StorageRootResolution root = await StorageRoot.resolve();
    final String newDir =
        p.join(root.path, StorageRoot.collectionsFolderName);
    // No filesystem on web: the dir is virtual and legacy migration moot.
    if (kIsWebBuild) return newDir;
    await Directory(newDir).create(recursive: true);

    final Directory appDir = await getApplicationSupportDirectory();
    final String legacyDir =
        p.join(appDir.path, StorageRoot.collectionsFolderName);
    await migrateLegacyHeroImages(legacyDir: legacyDir, newDir: newDir);

    return newDir;
  }

  /// Moves `hero_*` files into [newDir] without clobbering, then removes a
  /// drained [legacyDir]. Idempotent: no-op when legacy == new, absent, empty.
  @visibleForTesting
  static Future<void> migrateLegacyHeroImages({
    required String legacyDir,
    required String newDir,
  }) async {
    if (p.equals(legacyDir, newDir)) return;
    final Directory legacy = Directory(legacyDir);
    if (!legacy.existsSync()) return;

    for (final FileSystemEntity entity in legacy.listSync(followLinks: false)) {
      if (entity is! File) continue;
      if (!p.basename(entity.path).startsWith('hero_')) continue;
      final String target = p.join(newDir, p.basename(entity.path));
      if (File(target).existsSync()) continue;
      try {
        await entity.rename(target);
      } on FileSystemException {
        // Cross-volume rename fails when the data root is on another drive;
        // fall back to copy + delete.
        await entity.copy(target);
        await entity.delete();
      }
    }

    try {
      if (legacy.listSync(followLinks: false).isEmpty) {
        await legacy.delete();
      }
    } on FileSystemException catch (e) {
      _log.fine('Could not remove drained legacy hero dir: ${e.message}');
    }
  }

  String? resolve(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    // On web the hero lives in the server's image cache, so the resolved
    // location is a URL; render sites branch on the scheme.
    if (kIsWebBuild) {
      return imageProxyUrl(
        baseUrl: serverBaseUrl(),
        type: ImageType.collectionHero,
        imageId: fileName,
      );
    }
    return p.join(_rootDir, fileName);
  }

  String absolutePathFor(String fileName) => p.join(_rootDir, fileName);

  /// Old file ([oldFileName]) is deleted only after the copy succeeds.
  /// Returns the new filename to store in the DB, or `null` on cancel.
  Future<String?> pickAndSave({
    required int collectionId,
    String? oldFileName,
  }) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: 'Cover image',
      // A browser pick has no path — the bytes are all there is.
      withData: kIsWebBuild,
    );
    if (result == null || result.files.isEmpty) return null;

    final PlatformFile picked = result.files.first;

    final String ext = (picked.extension ?? p.extension(picked.name))
        .replaceFirst('.', '')
        .toLowerCase();
    final String safeExt = _sanitizeExtension(ext);
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final String fileName = 'hero_${collectionId}_$ts.$safeExt';

    if (kIsWebBuild) {
      final Uint8List? bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) return null;
      final bool ok = await _imageCache?.saveImageBytes(
            ImageType.collectionHero,
            fileName,
            bytes,
          ) ??
          false;
      return ok ? fileName : null;
    }

    final String? sourcePath = picked.path;
    if (sourcePath == null) return null;
    final String target = absolutePathFor(fileName);

    try {
      await File(sourcePath).copy(target);
    } on FileSystemException catch (e) {
      _log.warning('Failed to copy hero image: ${e.message}', e);
      return null;
    }

    if (oldFileName != null && oldFileName != fileName) {
      await delete(oldFileName);
    }

    return fileName;
  }

  /// Used when importing `.xcollx` and restoring from a backup.
  Future<String> saveBytes({
    required int collectionId,
    required List<int> bytes,
    required String extension,
  }) async {
    final String safeExt = _sanitizeExtension(extension);
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final String fileName = 'hero_${collectionId}_$ts.$safeExt';
    if (kIsWebBuild) {
      await _imageCache?.saveImageBytes(
        ImageType.collectionHero,
        fileName,
        Uint8List.fromList(bytes),
      );
      return fileName;
    }
    await File(absolutePathFor(fileName)).writeAsBytes(bytes);
    return fileName;
  }

  Future<void> delete(String? fileName) async {
    if (fileName == null || fileName.isEmpty || kIsWebBuild) return;
    final File f = File(absolutePathFor(fileName));
    if (f.existsSync()) {
      try {
        await f.delete();
      } on FileSystemException catch (e) {
        _log.fine('Failed to delete $fileName: ${e.message}');
      }
    }
  }

  /// Used for backups.
  List<File> listAll() {
    if (kIsWebBuild) return <File>[];
    final Directory d = Directory(_rootDir);
    if (!d.existsSync()) return <File>[];
    return d
        .listSync(followLinks: false)
        .whereType<File>()
        .where((File f) =>
            p.basename(f.path).startsWith('hero_'))
        .toList();
  }

  String _sanitizeExtension(String ext) {
    const Set<String> allowed = <String>{
      'png',
      'jpg',
      'jpeg',
      'webp',
      'gif',
      'bmp',
    };
    final String clean = ext.toLowerCase().replaceAll(
          RegExp('[^a-z0-9]'),
          '',
        );
    return allowed.contains(clean) ? clean : 'png';
  }
}
