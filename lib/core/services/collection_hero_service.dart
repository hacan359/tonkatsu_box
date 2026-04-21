// Сервис для работы с hero-изображениями коллекций.
//
// Картинки хранятся в `<appSupport>/collections/hero_<id>_<ts>.<ext>`.
// В БД хранится только filename — абсолютный путь резолвится через
// `resolve(fileName)` из [CollectionHeroService].

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Имя каталога внутри `<appSupport>`.
const String _heroDirName = 'collections';

/// Провайдер корневого каталога hero-изображений (абсолютный путь).
///
/// Перекрывается в `main.dart` значением, полученным при старте приложения.
final Provider<String> collectionsHeroDirProvider = Provider<String>(
  (Ref ref) => throw UnimplementedError(
    'collectionsHeroDirProvider must be overridden in main()',
  ),
);

/// Провайдер сервиса hero-изображений.
final Provider<CollectionHeroService> collectionHeroServiceProvider =
    Provider<CollectionHeroService>(
  (Ref ref) => CollectionHeroService(
    rootDir: ref.watch(collectionsHeroDirProvider),
  ),
);

/// Сервис для выбора, сохранения и удаления hero-изображений коллекций.
class CollectionHeroService {
  /// Создаёт [CollectionHeroService].
  const CollectionHeroService({required String rootDir}) : _rootDir = rootDir;

  static final Logger _log = Logger('CollectionHeroService');

  final String _rootDir;

  /// Инициализирует каталог `<appSupport>/collections/` и возвращает его путь.
  ///
  /// Вызывается один раз при старте приложения.
  static Future<String> resolveRoot() async {
    final Directory appDir = await getApplicationSupportDirectory();
    final Directory dir = Directory(p.join(appDir.path, _heroDirName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Возвращает абсолютный путь к файлу по имени из БД.
  ///
  /// Если [fileName] `null` или пуст — возвращает `null`.
  String? resolve(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    return p.join(_rootDir, fileName);
  }

  /// Возвращает абсолютный путь для нового файла с указанным именем.
  String absolutePathFor(String fileName) => p.join(_rootDir, fileName);

  /// Открывает пикер, копирует выбранный файл в каталог коллекций.
  ///
  /// Старый файл (если передан [oldFileName]) удаляется после успешного копирования.
  /// Возвращает имя нового файла (для сохранения в БД) или `null` при отмене.
  Future<String?> pickAndSave({
    required int collectionId,
    String? oldFileName,
  }) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: 'Cover image',
    );
    if (result == null || result.files.isEmpty) return null;

    final PlatformFile picked = result.files.first;
    final String? sourcePath = picked.path;
    if (sourcePath == null) return null;

    final String ext = (picked.extension ?? p.extension(picked.name))
        .replaceFirst('.', '')
        .toLowerCase();
    final String safeExt = _sanitizeExtension(ext);
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final String fileName = 'hero_${collectionId}_$ts.$safeExt';
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

  /// Сохраняет [bytes] как hero-файл коллекции.
  ///
  /// Используется при импорте `.xcollx` и восстановлении из бэкапа.
  Future<String> saveBytes({
    required int collectionId,
    required List<int> bytes,
    required String extension,
  }) async {
    final String safeExt = _sanitizeExtension(extension);
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final String fileName = 'hero_${collectionId}_$ts.$safeExt';
    await File(absolutePathFor(fileName)).writeAsBytes(bytes);
    return fileName;
  }

  /// Удаляет файл, если он существует.
  Future<void> delete(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;
    final File f = File(absolutePathFor(fileName));
    if (f.existsSync()) {
      try {
        await f.delete();
      } on FileSystemException catch (e) {
        _log.fine('Failed to delete $fileName: ${e.message}');
      }
    }
  }

  /// Возвращает список всех hero-файлов в каталоге.
  ///
  /// Используется для бэкапа.
  List<File> listAll() {
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
