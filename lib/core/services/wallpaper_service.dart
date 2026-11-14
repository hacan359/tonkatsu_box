import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_extension.dart';

typedef WallpaperDirResolver = Future<String> Function();
typedef WallpaperImagePicker = Future<String?> Function(String dialogTitle);

class WallpaperSaveException implements Exception {
  const WallpaperSaveException(this.message);

  final String message;

  @override
  String toString() => 'WallpaperSaveException: $message';
}

final Provider<WallpaperService> wallpaperServiceProvider =
    Provider<WallpaperService>((Ref ref) => WallpaperService());

/// Keeps a copy of the picked image, so moving or deleting the original
/// never blanks the frame.
class WallpaperService {
  WallpaperService({
    WallpaperDirResolver? resolveDir,
    WallpaperImagePicker? pickImage,
  }) : _resolveDir = resolveDir ?? _defaultDir,
       _pickImage = pickImage ?? _defaultPick;

  static final Logger _log = Logger('WallpaperService');

  static const String folderName = 'wallpaper';

  final WallpaperDirResolver _resolveDir;
  final WallpaperImagePicker _pickImage;

  static Future<String> _defaultDir() async {
    final Directory appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, folderName);
  }

  static Future<String?> _defaultPick(String dialogTitle) async {
    final PlatformFile? picked = await FilePicker.pickFile(
      type: FileType.image,
      dialogTitle: dialogTitle,
    );
    return picked?.path;
  }

  /// Returns the saved copy's path, or null on cancel. [oldPath] is removed
  /// only after the copy succeeds.
  Future<String?> pickAndSave({
    required String dialogTitle,
    String? oldPath,
  }) async {
    final String? source = await _pickImage(dialogTitle);
    if (source == null) return null;

    final String dir = await _resolveDir();
    final String ext = sanitizeImageExtension(
      p.extension(source).replaceFirst('.', ''),
    );
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final String target = p.join(dir, 'wallpaper_$ts.$ext');
    try {
      await Directory(dir).create(recursive: true);
      await File(source).copy(target);
    } on FileSystemException catch (e) {
      _log.warning('Failed to copy wallpaper from $source: ${e.message}', e);
      throw WallpaperSaveException(e.message);
    }

    if (oldPath != null && oldPath != target) await delete(oldPath);
    return target;
  }

  /// Ignores paths outside the wallpaper folder: a stale or hand-edited
  /// setting must never delete a file the app did not create.
  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final String dir = await _resolveDir();
    if (!p.isWithin(dir, path)) return;
    final File file = File(path);
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException catch (e) {
      _log.fine('Failed to delete wallpaper $path: ${e.message}');
    }
  }
}
