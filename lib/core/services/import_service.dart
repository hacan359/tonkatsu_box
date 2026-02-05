import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/collection_repository.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/game.dart';
import '../api/igdb_api.dart';
import '../database/database_service.dart';
import 'rcoll_file.dart';

/// Провайдер для сервиса импорта.
final Provider<ImportService> importServiceProvider =
    Provider<ImportService>((Ref ref) {
  return ImportService(
    repository: ref.watch(collectionRepositoryProvider),
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

/// Результат импорта.
class ImportResult {
  /// Создаёт экземпляр [ImportResult].
  const ImportResult({
    required this.success,
    this.collection,
    this.gamesImported,
    this.error,
  });

  /// Успешный результат.
  const ImportResult.success(Collection col, int games)
      : success = true,
        collection = col,
        gamesImported = games,
        error = null;

  /// Неуспешный результат.
  const ImportResult.failure(String message)
      : success = false,
        collection = null,
        gamesImported = null,
        error = message;

  /// Отменённый импорт.
  const ImportResult.cancelled()
      : success = false,
        collection = null,
        gamesImported = null,
        error = null;

  /// Успешность операции.
  final bool success;

  /// Импортированная коллекция.
  final Collection? collection;

  /// Количество импортированных игр.
  final int? gamesImported;

  /// Сообщение об ошибке.
  final String? error;

  /// Возвращает true, если импорт был отменён.
  bool get isCancelled => !success && error == null;
}

/// Callback для отслеживания прогресса импорта.
typedef ImportProgressCallback = void Function(ImportProgress progress);

/// Состояние прогресса импорта.
class ImportProgress {
  /// Создаёт экземпляр [ImportProgress].
  const ImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.message,
  });

  /// Текущий этап.
  final ImportStage stage;

  /// Текущий прогресс.
  final int current;

  /// Общее количество.
  final int total;

  /// Сообщение о статусе.
  final String? message;

  /// Возвращает процент выполнения (0.0-1.0).
  double get progress => total > 0 ? current / total : 0;
}

/// Этапы импорта.
enum ImportStage {
  /// Чтение файла.
  reading('Reading file...'),

  /// Загрузка данных игр из IGDB.
  fetchingGames('Fetching game data...'),

  /// Кэширование игр.
  cachingGames('Caching games...'),

  /// Создание коллекции.
  creatingCollection('Creating collection...'),

  /// Добавление игр.
  addingGames('Adding games...'),

  /// Завершено.
  completed('Import completed');

  const ImportStage(this.description);

  /// Описание этапа.
  final String description;
}

/// Сервис для импорта коллекций из .rcoll файлов.
class ImportService {
  /// Создаёт экземпляр [ImportService].
  ImportService({
    required CollectionRepository repository,
    required IgdbApi igdbApi,
    required DatabaseService database,
  })  : _repository = repository,
        _igdbApi = igdbApi,
        _database = database;

  final CollectionRepository _repository;
  final IgdbApi _igdbApi;
  final DatabaseService _database;

  /// Открывает диалог выбора файла и парсит .rcoll.
  ///
  /// Возвращает [RcollFile] или null если отменено.
  /// Throws [FormatException] если файл невалидный.
  Future<RcollFile?> pickAndParseFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Collection',
      type: FileType.custom,
      allowedExtensions: <String>['rcoll', 'json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final String? filePath = result.files.first.path;
    if (filePath == null) {
      throw const FormatException('Could not read file path');
    }

    return parseFile(File(filePath));
  }

  /// Парсит .rcoll файл.
  ///
  /// Throws [FormatException] если файл невалидный.
  Future<RcollFile> parseFile(File file) async {
    if (!await file.exists()) {
      throw const FormatException('File does not exist');
    }

    final String content = await file.readAsString();
    return RcollFile.fromJsonString(content);
  }

  /// Импортирует коллекцию из .rcoll файла.
  ///
  /// [onProgress] — callback для отслеживания прогресса.
  ///
  /// Возвращает [ImportResult] с результатом операции.
  Future<ImportResult> importFromFile({
    ImportProgressCallback? onProgress,
  }) async {
    try {
      // Этап 1: Выбор и чтение файла
      onProgress?.call(const ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 1,
      ));

      final RcollFile? rcoll = await pickAndParseFile();
      if (rcoll == null) {
        return const ImportResult.cancelled();
      }

      return importFromRcoll(rcoll, onProgress: onProgress);
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  /// Импортирует коллекцию из [RcollFile].
  ///
  /// [onProgress] — callback для отслеживания прогресса.
  Future<ImportResult> importFromRcoll(
    RcollFile rcoll, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      final List<int> gameIds = rcoll.gameIds;

      // Этап 2: Загрузка данных игр из IGDB
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 0,
        total: gameIds.length,
        message: 'Fetching ${gameIds.length} games from IGDB...',
      ));

      List<Game> games = <Game>[];
      if (gameIds.isNotEmpty) {
        try {
          games = await _igdbApi.getGamesByIds(gameIds);
        } on IgdbApiException catch (e) {
          return ImportResult.failure('Failed to fetch games from IGDB: ${e.message}');
        }
      }

      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingGames,
        current: games.length,
        total: gameIds.length,
        message: 'Fetched ${games.length} games',
      ));

      // Этап 3: Кэширование игр
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingGames,
        current: 0,
        total: games.length,
      ));

      for (int i = 0; i < games.length; i++) {
        await _database.upsertGame(games[i]);
        onProgress?.call(ImportProgress(
          stage: ImportStage.cachingGames,
          current: i + 1,
          total: games.length,
        ));
      }

      // Этап 4: Создание коллекции
      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 0,
        total: 1,
      ));

      final Collection collection = await _repository.create(
        name: rcoll.name,
        author: rcoll.author,
        type: CollectionType.imported,
      );

      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 1,
        total: 1,
      ));

      // Этап 5: Добавление игр в коллекцию
      int addedCount = 0;
      for (int i = 0; i < rcoll.games.length; i++) {
        final RcollGame rcollGame = rcoll.games[i];

        onProgress?.call(ImportProgress(
          stage: ImportStage.addingGames,
          current: i,
          total: rcoll.games.length,
        ));

        final int? gameId = await _repository.addGame(
          collectionId: collection.id,
          igdbId: rcollGame.igdbId,
          platformId: rcollGame.platformId,
          authorComment: rcollGame.comment,
        );

        if (gameId != null) {
          addedCount++;
        }
      }

      // Этап 6: Завершено
      onProgress?.call(ImportProgress(
        stage: ImportStage.completed,
        current: addedCount,
        total: rcoll.games.length,
        message: 'Imported $addedCount games',
      ));

      return ImportResult.success(collection, addedCount);
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }
}
