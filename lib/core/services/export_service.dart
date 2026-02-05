import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/collection.dart';
import '../../shared/models/collection_game.dart';
import 'rcoll_file.dart';

/// Провайдер для сервиса экспорта.
final Provider<ExportService> exportServiceProvider =
    Provider<ExportService>((Ref ref) {
  return ExportService();
});

/// Результат экспорта.
class ExportResult {
  /// Создаёт экземпляр [ExportResult].
  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
  });

  /// Успешный результат.
  const ExportResult.success(String path)
      : success = true,
        filePath = path,
        error = null;

  /// Неуспешный результат.
  const ExportResult.failure(String message)
      : success = false,
        filePath = null,
        error = message;

  /// Отменённый экспорт.
  const ExportResult.cancelled()
      : success = false,
        filePath = null,
        error = null;

  /// Успешность операции.
  final bool success;

  /// Путь к сохранённому файлу.
  final String? filePath;

  /// Сообщение об ошибке.
  final String? error;

  /// Возвращает true, если экспорт был отменён.
  bool get isCancelled => !success && error == null;
}

/// Сервис для экспорта коллекций в .rcoll формат.
class ExportService {
  /// Создаёт .rcoll файл из коллекции.
  RcollFile createRcollFile(Collection collection, List<CollectionGame> games) {
    final List<RcollGame> rcollGames = games
        .map((CollectionGame g) => RcollGame(
              igdbId: g.igdbId,
              platformId: g.platformId,
              comment: g.authorComment,
            ))
        .toList();

    return RcollFile(
      version: rcollFormatVersion,
      name: collection.name,
      author: collection.author,
      created: collection.createdAt,
      games: rcollGames,
    );
  }

  /// Экспортирует коллекцию в JSON строку.
  String exportToJson(Collection collection, List<CollectionGame> games) {
    final RcollFile rcoll = createRcollFile(collection, games);
    return rcoll.toJsonString();
  }

  /// Экспортирует коллекцию в файл.
  ///
  /// Открывает диалог выбора места сохранения и сохраняет .rcoll файл.
  /// Возвращает [ExportResult] с результатом операции.
  Future<ExportResult> exportToFile(
    Collection collection,
    List<CollectionGame> games,
  ) async {
    try {
      final String json = exportToJson(collection, games);
      final String suggestedName = _sanitizeFileName(collection.name);

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Collection',
        fileName: '$suggestedName.rcoll',
        type: FileType.custom,
        allowedExtensions: <String>['rcoll'],
      );

      if (outputPath == null) {
        return const ExportResult.cancelled();
      }

      // Убеждаемся что расширение .rcoll
      final String finalPath =
          outputPath.endsWith('.rcoll') ? outputPath : '$outputPath.rcoll';

      final File file = File(finalPath);
      await file.writeAsString(json);

      return ExportResult.success(finalPath);
    } on FileSystemException catch (e) {
      return ExportResult.failure('Failed to save file: ${e.message}');
    } catch (e) {
      return ExportResult.failure('Export failed: $e');
    }
  }

  /// Очищает название файла от недопустимых символов.
  String _sanitizeFileName(String name) {
    // Заменяем недопустимые символы на underscore
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .trim();
  }
}
