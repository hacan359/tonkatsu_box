// Сервис импорта данных из оффлайн-выгрузки Trakt.tv (ZIP).

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/tv_show.dart';
import '../api/tmdb_api.dart';
import '../database/database_service.dart';
import 'import_service.dart';

// ---------------------------------------------------------------------------
// Публичные модели
// ---------------------------------------------------------------------------

/// Информация о содержимом Trakt ZIP-архива.
class TraktZipInfo {
  /// Создаёт экземпляр [TraktZipInfo].
  const TraktZipInfo({
    required this.isValid,
    this.username = '',
    this.watchedMovieCount = 0,
    this.watchedShowCount = 0,
    this.ratedMovieCount = 0,
    this.ratedShowCount = 0,
    this.watchlistCount = 0,
    this.error,
  });

  /// Невалидный результат с ошибкой.
  const TraktZipInfo.invalid(String message)
      : isValid = false,
        username = '',
        watchedMovieCount = 0,
        watchedShowCount = 0,
        ratedMovieCount = 0,
        ratedShowCount = 0,
        watchlistCount = 0,
        error = message;

  /// ZIP прошёл валидацию.
  final bool isValid;

  /// Имя пользователя Trakt (из корневой папки).
  final String username;

  /// Количество просмотренных фильмов.
  final int watchedMovieCount;

  /// Количество просмотренных сериалов.
  final int watchedShowCount;

  /// Количество оценённых фильмов.
  final int ratedMovieCount;

  /// Количество оценённых сериалов.
  final int ratedShowCount;

  /// Количество элементов в вишлисте.
  final int watchlistCount;

  /// Ошибка валидации (если есть).
  final String? error;

  /// Общее количество элементов.
  int get totalItems =>
      watchedMovieCount +
      watchedShowCount +
      ratedMovieCount +
      ratedShowCount +
      watchlistCount;
}

/// Параметры импорта, выбранные пользователем.
class TraktImportOptions {
  /// Создаёт экземпляр [TraktImportOptions].
  const TraktImportOptions({
    required this.zipPath,
    this.collectionId,
    this.importWatched = true,
    this.importRatings = true,
    this.importWatchlist = true,
  });

  /// Путь к ZIP-файлу.
  final String zipPath;

  /// ID целевой коллекции (null = создать новую).
  final int? collectionId;

  /// Импортировать просмотренные фильмы и сериалы.
  final bool importWatched;

  /// Импортировать рейтинги.
  final bool importRatings;

  /// Импортировать вишлист.
  final bool importWatchlist;
}

/// Результат импорта Trakt.
class TraktImportResult {
  /// Создаёт экземпляр [TraktImportResult].
  const TraktImportResult({
    required this.success,
    this.collection,
    this.itemsImported = 0,
    this.itemsSkipped = 0,
    this.itemsUpdated = 0,
    this.wishlistItemsAdded = 0,
    this.errors = const <String>[],
    this.error,
  });

  /// Успешный результат.
  const TraktImportResult.success({
    required Collection this.collection,
    required this.itemsImported,
    this.itemsSkipped = 0,
    this.itemsUpdated = 0,
    this.wishlistItemsAdded = 0,
    this.errors = const <String>[],
  })  : success = true,
        error = null;

  /// Неудачный результат.
  const TraktImportResult.failure(String message)
      : success = false,
        collection = null,
        itemsImported = 0,
        itemsSkipped = 0,
        itemsUpdated = 0,
        wishlistItemsAdded = 0,
        errors = const <String>[],
        error = message;

  /// Импорт завершился успешно.
  final bool success;

  /// Коллекция, в которую был выполнен импорт.
  final Collection? collection;

  /// Количество добавленных элементов.
  final int itemsImported;

  /// Количество пропущенных элементов (нет TMDB ID / ошибка TMDB).
  final int itemsSkipped;

  /// Количество обновлённых элементов (конфликт-резолюция).
  final int itemsUpdated;

  /// Количество элементов, добавленных в вишлист.
  final int wishlistItemsAdded;

  /// Ошибки по отдельным элементам.
  final List<String> errors;

  /// Фатальная ошибка (если импорт не удался).
  final String? error;
}

// ---------------------------------------------------------------------------
// Приватные модели (парсинг Trakt JSON)
// ---------------------------------------------------------------------------

class _TraktMovie {
  const _TraktMovie({
    required this.title,
    required this.tmdbId,
    required this.year,
    this.lastWatchedAt,
  });

  final String title;
  final int? tmdbId;
  final int year;
  final DateTime? lastWatchedAt;
}

class _TraktShow {
  const _TraktShow({
    required this.title,
    required this.tmdbId,
    this.lastWatchedAt,
    this.seasons = const <_TraktSeason>[],
  });

  final String title;
  final int? tmdbId;
  final DateTime? lastWatchedAt;
  final List<_TraktSeason> seasons;
}

class _TraktSeason {
  const _TraktSeason({
    required this.number,
    this.episodes = const <_TraktEpisode>[],
  });

  final int number;
  final List<_TraktEpisode> episodes;
}

class _TraktEpisode {
  const _TraktEpisode({
    required this.number,
    this.lastWatchedAt,
  });

  final int number;
  final DateTime? lastWatchedAt;
}

class _TraktRating {
  const _TraktRating({
    required this.title,
    required this.tmdbId,
    required this.rating,
    required this.type,
  });

  final String title;
  final int? tmdbId;
  final int rating;
  final String type; // 'movie' | 'show'
}

class _TraktWatchlistEntry {
  const _TraktWatchlistEntry({
    required this.title,
    required this.tmdbId,
    required this.type,
  });

  final String title;
  final int? tmdbId;
  final String type; // 'movie' | 'show'
}

// ---------------------------------------------------------------------------
// Провайдер
// ---------------------------------------------------------------------------

/// Провайдер сервиса импорта Trakt.
final Provider<TraktZipImportService> traktZipImportServiceProvider =
    Provider<TraktZipImportService>((Ref ref) {
  return TraktZipImportService(
    tmdbApi: ref.watch(tmdbApiProvider),
    repository: ref.watch(collectionRepositoryProvider),
    database: ref.watch(databaseServiceProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Сервис
// ---------------------------------------------------------------------------

/// Сервис для импорта данных из оффлайн-выгрузки Trakt.tv.
///
/// Читает ZIP-архив, парсит JSON файлы, загружает медиа из TMDB API,
/// добавляет элементы в коллекцию с конфликт-резолюцией.
class TraktZipImportService {
  /// Создаёт экземпляр [TraktZipImportService].
  TraktZipImportService({
    required TmdbApi tmdbApi,
    required CollectionRepository repository,
    required DatabaseService database,
    required WishlistRepository wishlistRepository,
  })  : _tmdbApi = tmdbApi,
        _repository = repository,
        _database = database,
        _wishlistRepository = wishlistRepository;

  final TmdbApi _tmdbApi;
  final CollectionRepository _repository;
  final DatabaseService _database;
  final WishlistRepository _wishlistRepository;

  /// Приоритет статусов для конфликт-резолюции.
  static const Map<ItemStatus, int> _statusPriority = <ItemStatus, int>{
    ItemStatus.notStarted: 0,
    ItemStatus.planned: 1,
    ItemStatus.inProgress: 2,
    ItemStatus.completed: 3,
  };

  // ---------------------------------------------------------------------------
  // Публичные методы
  // ---------------------------------------------------------------------------

  /// Валидирует ZIP-архив.
  ///
  /// Проверяет структуру, находит username, считает элементы.
  Future<TraktZipInfo> validateZip(String zipPath) async {
    try {
      final ({Map<String, String> files, String username}) archive =
          _readArchive(zipPath);
      if (archive.files.isEmpty) {
        return const TraktZipInfo.invalid('No JSON files found in archive');
      }

      final Map<String, String> files = archive.files;
      final String username = archive.username;

      int watchedMovieCount = 0;
      int watchedShowCount = 0;
      int ratedMovieCount = 0;
      int ratedShowCount = 0;
      int watchlistCount = 0;

      final String? watchedMovies = files['watched/watched-movies.json'];
      if (watchedMovies != null) {
        final List<dynamic> list =
            jsonDecode(watchedMovies) as List<dynamic>;
        watchedMovieCount = list.length;
      }

      final String? watchedShows = files['watched/watched-shows.json'];
      if (watchedShows != null) {
        final List<dynamic> list =
            jsonDecode(watchedShows) as List<dynamic>;
        watchedShowCount = list.length;
      }

      final String? ratingsMovies = files['ratings/ratings-movies.json'];
      if (ratingsMovies != null) {
        final List<dynamic> list =
            jsonDecode(ratingsMovies) as List<dynamic>;
        ratedMovieCount = list.length;
      }

      final String? ratingsShows = files['ratings/ratings-shows.json'];
      if (ratingsShows != null) {
        final List<dynamic> list =
            jsonDecode(ratingsShows) as List<dynamic>;
        ratedShowCount = list.length;
      }

      final String? watchlist = files['lists/watchlist.json'];
      if (watchlist != null) {
        final List<dynamic> list =
            jsonDecode(watchlist) as List<dynamic>;
        watchlistCount = list.length;
      }

      final int total = watchedMovieCount +
          watchedShowCount +
          ratedMovieCount +
          ratedShowCount +
          watchlistCount;

      return TraktZipInfo(
        isValid: total > 0,
        username: username,
        watchedMovieCount: watchedMovieCount,
        watchedShowCount: watchedShowCount,
        ratedMovieCount: ratedMovieCount,
        ratedShowCount: ratedShowCount,
        watchlistCount: watchlistCount,
      );
    } on ArchiveException {
      return const TraktZipInfo.invalid('Invalid ZIP archive');
    } on FormatException {
      return const TraktZipInfo.invalid('Invalid JSON in archive');
    } on FileSystemException {
      return const TraktZipInfo.invalid('Cannot read file');
    } on Exception catch (e) {
      return TraktZipInfo.invalid('Error: $e');
    }
  }

  /// Импортирует данные из Trakt ZIP-архива.
  Future<TraktImportResult> importFromZip({
    required TraktImportOptions options,
    ImportProgressCallback? onProgress,
  }) async {
    try {
      // 1. Чтение ZIP
      onProgress?.call(const ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 1,
        message: 'Reading ZIP archive...',
      ));

      final ({Map<String, String> files, String username}) archive =
          _readArchive(options.zipPath);
      if (archive.files.isEmpty) {
        return const TraktImportResult.failure('No data found in archive');
      }

      final Map<String, String> files = archive.files;
      final String username = archive.username;

      // 2. Парсинг JSON
      final List<_TraktMovie> watchedMovies = options.importWatched
          ? _parseWatchedMovies(files['watched/watched-movies.json'])
          : <_TraktMovie>[];

      final List<_TraktShow> watchedShows = options.importWatched
          ? _parseWatchedShows(files['watched/watched-shows.json'])
          : <_TraktShow>[];

      final List<_TraktRating> movieRatings = options.importRatings
          ? _parseRatings(files['ratings/ratings-movies.json'], 'movie')
          : <_TraktRating>[];

      final List<_TraktRating> showRatings = options.importRatings
          ? _parseRatings(files['ratings/ratings-shows.json'], 'show')
          : <_TraktRating>[];

      final List<_TraktWatchlistEntry> watchlistEntries =
          options.importWatchlist
              ? _parseWatchlist(files['lists/watchlist.json'])
              : <_TraktWatchlistEntry>[];

      // Собираем уникальные TMDB ID
      final Set<int> movieTmdbIds = <int>{};
      final Set<int> showTmdbIds = <int>{};

      for (final _TraktMovie m in watchedMovies) {
        if (m.tmdbId != null) movieTmdbIds.add(m.tmdbId!);
      }
      for (final _TraktShow s in watchedShows) {
        if (s.tmdbId != null) showTmdbIds.add(s.tmdbId!);
      }
      for (final _TraktRating r in movieRatings) {
        if (r.tmdbId != null) movieTmdbIds.add(r.tmdbId!);
      }
      for (final _TraktRating r in showRatings) {
        if (r.tmdbId != null) showTmdbIds.add(r.tmdbId!);
      }
      for (final _TraktWatchlistEntry e in watchlistEntries) {
        if (e.tmdbId != null) {
          if (e.type == 'movie') {
            movieTmdbIds.add(e.tmdbId!);
          } else {
            showTmdbIds.add(e.tmdbId!);
          }
        }
      }

      // 3. Загрузка из TMDB + определение анимации
      final Map<int, Movie> fetchedMovies = <int, Movie>{};
      final Map<int, TvShow> fetchedShows = <int, TvShow>{};
      final Map<int, bool> movieIsAnimation = <int, bool>{};
      final Map<int, bool> showIsAnimation = <int, bool>{};
      final List<String> errors = <String>[];

      final int totalToFetch = movieTmdbIds.length + showTmdbIds.length;
      int fetchProgress = 0;

      for (final int tmdbId in movieTmdbIds) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingMovies,
          current: fetchProgress,
          total: totalToFetch,
          message: 'Fetching movie $tmdbId...',
        ));

        try {
          final Movie? movie = await _tmdbApi.getMovie(tmdbId);
          if (movie != null) {
            fetchedMovies[tmdbId] = movie;
            await _database.upsertMovie(movie);
            movieIsAnimation[tmdbId] = _isAnimationByGenres(movie.genres);
          }
        } on Exception {
          // Не удалось загрузить — пропускаем
        }
        fetchProgress++;
      }

      for (final int tmdbId in showTmdbIds) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingTvShows,
          current: fetchProgress,
          total: totalToFetch,
          message: 'Fetching TV show $tmdbId...',
        ));

        try {
          final TvShow? tvShow = await _tmdbApi.getTvShow(tmdbId);
          if (tvShow != null) {
            fetchedShows[tmdbId] = tvShow;
            await _database.upsertTvShow(tvShow);
            showIsAnimation[tmdbId] = _isAnimationByGenres(tvShow.genres);
          }
        } on Exception {
          // Не удалось загрузить — пропускаем
        }
        fetchProgress++;
      }

      // 4. Создать или использовать коллекцию
      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 0,
        total: 1,
        message: 'Preparing collection...',
      ));

      final int collectionId;
      final Collection collection;

      if (options.collectionId != null) {
        collectionId = options.collectionId!;
        final Collection? existing =
            await _repository.getById(collectionId);
        if (existing == null) {
          return const TraktImportResult.failure('Collection not found');
        }
        collection = existing;
      } else {
        collection = await _repository.create(
          name: 'Trakt: $username',
          author: username,
        );
        collectionId = collection.id;
      }

      // 5. Импорт элементов
      int itemsImported = 0;
      int itemsSkipped = 0;
      int itemsUpdated = 0;

      final int totalItems = watchedMovies.length + watchedShows.length;
      int itemProgress = 0;

      // 5a. Watched movies
      for (final _TraktMovie traktMovie in watchedMovies) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: itemProgress,
          total: totalItems,
          message: 'Importing "${traktMovie.title}"...',
        ));

        if (traktMovie.tmdbId == null) {
          errors.add('Skipped "${traktMovie.title}" (no TMDB ID)');
          itemsSkipped++;
          itemProgress++;
          continue;
        }

        if (!fetchedMovies.containsKey(traktMovie.tmdbId)) {
          errors.add(
            'Skipped "${traktMovie.title}" (TMDB data not available)',
          );
          itemsSkipped++;
          itemProgress++;
          continue;
        }

        final bool isAnim = movieIsAnimation[traktMovie.tmdbId] ?? false;
        final MediaType mediaType =
            isAnim ? MediaType.animation : MediaType.movie;
        final int? platformId = isAnim ? AnimationSource.movie : null;

        final _ImportItemResult result = await _importOrUpdateItem(
          collectionId: collectionId,
          mediaType: mediaType,
          externalId: traktMovie.tmdbId!,
          platformId: platformId,
          status: ItemStatus.completed,
          completedAt: traktMovie.lastWatchedAt,
        );

        switch (result) {
          case _ImportItemResult.added:
            itemsImported++;
          case _ImportItemResult.updated:
            itemsUpdated++;
          case _ImportItemResult.skipped:
            itemsSkipped++;
        }

        itemProgress++;
      }

      // 5b. Watched shows
      for (final _TraktShow traktShow in watchedShows) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: itemProgress,
          total: totalItems,
          message: 'Importing "${traktShow.title}"...',
        ));

        if (traktShow.tmdbId == null) {
          errors.add('Skipped "${traktShow.title}" (no TMDB ID)');
          itemsSkipped++;
          itemProgress++;
          continue;
        }

        if (!fetchedShows.containsKey(traktShow.tmdbId)) {
          errors.add(
            'Skipped "${traktShow.title}" (TMDB data not available)',
          );
          itemsSkipped++;
          itemProgress++;
          continue;
        }

        final bool isAnim = showIsAnimation[traktShow.tmdbId] ?? false;
        final MediaType mediaType =
            isAnim ? MediaType.animation : MediaType.tvShow;
        final int? platformId = isAnim ? AnimationSource.tvShow : null;

        final ItemStatus showStatus = _resolveShowStatus(traktShow);

        final _ImportItemResult result = await _importOrUpdateItem(
          collectionId: collectionId,
          mediaType: mediaType,
          externalId: traktShow.tmdbId!,
          platformId: platformId,
          status: showStatus,
          completedAt: showStatus == ItemStatus.completed
              ? traktShow.lastWatchedAt
              : null,
        );

        switch (result) {
          case _ImportItemResult.added:
            itemsImported++;
          case _ImportItemResult.updated:
            itemsUpdated++;
          case _ImportItemResult.skipped:
            itemsSkipped++;
        }

        itemProgress++;
      }

      // 6. Импорт эпизодов
      if (options.importWatched && watchedShows.isNotEmpty) {
        int episodeProgress = 0;
        int totalEpisodes = 0;
        for (final _TraktShow s in watchedShows) {
          for (final _TraktSeason season in s.seasons) {
            totalEpisodes += season.episodes.length;
          }
        }

        for (final _TraktShow traktShow in watchedShows) {
          if (traktShow.tmdbId == null) continue;

          for (final _TraktSeason season in traktShow.seasons) {
            for (final _TraktEpisode episode in season.episodes) {
              onProgress?.call(ImportProgress(
                stage: ImportStage.addingItems,
                current: episodeProgress,
                total: totalEpisodes,
                message: 'Importing episodes for "${traktShow.title}"...',
              ));

              await _database.markEpisodeWatched(
                collectionId,
                traktShow.tmdbId!,
                season.number,
                episode.number,
              );
              episodeProgress++;
            }
          }
        }
      }

      // 7. Применение рейтингов
      if (options.importRatings) {
        final List<_TraktRating> allRatings = <_TraktRating>[
          ...movieRatings,
          ...showRatings,
        ];

        for (int i = 0; i < allRatings.length; i++) {
          final _TraktRating rating = allRatings[i];

          onProgress?.call(ImportProgress(
            stage: ImportStage.addingItems,
            current: i,
            total: allRatings.length,
            message: 'Applying rating for "${rating.title}"...',
          ));

          if (rating.tmdbId == null) continue;

          final ({MediaType mediaType, int? platformId}) resolved =
              _resolveMediaType(
            isMovie: rating.type == 'movie',
            movieIsAnimation: movieIsAnimation,
            showIsAnimation: showIsAnimation,
            tmdbId: rating.tmdbId!,
          );

          // Ищем существующий элемент
          final CollectionItem? existing = await _repository.findItem(
            collectionId: collectionId,
            mediaType: resolved.mediaType,
            externalId: rating.tmdbId!,
          );

          if (existing != null) {
            // Обновляем рейтинг только если локальный не установлен
            if (existing.userRating == null) {
              await _database.updateItemUserRating(
                existing.id,
                rating.rating.clamp(1, 10),
              );
              itemsUpdated++;
            }
          } else {
            // Элемент не существует — нужно ли добавлять?
            // Если данные TMDB есть — добавляем с рейтингом
            final bool hasData = rating.type == 'movie'
                ? fetchedMovies.containsKey(rating.tmdbId)
                : fetchedShows.containsKey(rating.tmdbId);

            if (hasData) {
              final int? itemId = await _repository.addItem(
                collectionId: collectionId,
                mediaType: resolved.mediaType,
                externalId: rating.tmdbId!,
                platformId: resolved.platformId,
              );
              if (itemId != null) {
                await _database.updateItemUserRating(
                  itemId,
                  rating.rating.clamp(1, 10),
                );
                itemsImported++;
              }
            }
          }
        }
      }

      // 8. Импорт вишлиста
      int wishlistItemsAdded = 0;

      if (options.importWatchlist && watchlistEntries.isNotEmpty) {
        for (int i = 0; i < watchlistEntries.length; i++) {
          final _TraktWatchlistEntry entry = watchlistEntries[i];

          onProgress?.call(ImportProgress(
            stage: ImportStage.addingItems,
            current: i,
            total: watchlistEntries.length,
            message: 'Adding "${entry.title}" to wishlist...',
          ));

          if (entry.tmdbId != null) {
            final ({MediaType mediaType, int? platformId}) resolved =
                _resolveMediaType(
              isMovie: entry.type == 'movie',
              movieIsAnimation: movieIsAnimation,
              showIsAnimation: showIsAnimation,
              tmdbId: entry.tmdbId!,
            );

            // Проверяем, нет ли уже в коллекции
            final CollectionItem? existing = await _repository.findItem(
              collectionId: collectionId,
              mediaType: resolved.mediaType,
              externalId: entry.tmdbId!,
            );

            if (existing == null) {
              final bool hasData = entry.type == 'movie'
                  ? fetchedMovies.containsKey(entry.tmdbId)
                  : fetchedShows.containsKey(entry.tmdbId);

              if (hasData) {
                final int? itemId = await _repository.addItem(
                  collectionId: collectionId,
                  mediaType: resolved.mediaType,
                  externalId: entry.tmdbId!,
                  platformId: resolved.platformId,
                  status: ItemStatus.planned,
                );
                if (itemId != null) {
                  itemsImported++;
                  continue;
                }
              }
            } else {
              // Элемент уже есть — пропускаем
              continue;
            }
          }

          // Фоллбэк: добавляем в Wishlist как текст
          final MediaType hint = entry.type == 'movie'
              ? MediaType.movie
              : MediaType.tvShow;

          await _wishlistRepository.add(
            text: entry.title,
            mediaTypeHint: hint,
          );
          wishlistItemsAdded++;
        }
      }

      // 9. Готово
      onProgress?.call(const ImportProgress(
        stage: ImportStage.completed,
        current: 1,
        total: 1,
      ));

      return TraktImportResult.success(
        collection: collection,
        itemsImported: itemsImported,
        itemsSkipped: itemsSkipped,
        itemsUpdated: itemsUpdated,
        wishlistItemsAdded: wishlistItemsAdded,
        errors: errors,
      );
    } on Exception catch (e) {
      return TraktImportResult.failure('Import failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Приватные методы
  // ---------------------------------------------------------------------------

  /// Читает ZIP-архив: извлекает JSON файлы и username за один проход.
  ({Map<String, String> files, String username}) _readArchive(String zipPath) {
    final List<int> bytes = File(zipPath).readAsBytesSync();
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    final Map<String, String> files = <String, String>{};
    String username = 'Unknown';

    for (final ArchiveFile file in archive) {
      final List<String> parts = file.name.split('/');

      if (username == 'Unknown' &&
          parts.isNotEmpty &&
          parts[0].isNotEmpty) {
        username = parts[0];
      }

      if (file.isFile && file.name.endsWith('.json') && parts.length >= 2) {
        final String relativePath = parts.sublist(1).join('/');
        final String content = utf8.decode(file.content as List<int>);
        files[relativePath] = content;
      }
    }

    return (files: files, username: username);
  }

  /// Парсит watched-movies.json.
  List<_TraktMovie> _parseWatchedMovies(String? json) {
    if (json == null || json.isEmpty) return <_TraktMovie>[];

    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    final List<_TraktMovie> result = <_TraktMovie>[];

    for (final dynamic item in list) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final Map<String, dynamic>? movieData =
          data['movie'] as Map<String, dynamic>?;
      if (movieData == null) continue;

      final Map<String, dynamic>? ids =
          movieData['ids'] as Map<String, dynamic>?;
      final int? tmdbId = ids?['tmdb'] as int?;

      DateTime? lastWatchedAt;
      final String? lastWatched = data['last_watched_at'] as String?;
      if (lastWatched != null) {
        lastWatchedAt = DateTime.tryParse(lastWatched);
      }

      result.add(_TraktMovie(
        title: movieData['title'] as String? ?? 'Unknown',
        tmdbId: tmdbId,
        year: movieData['year'] as int? ?? 0,
        lastWatchedAt: lastWatchedAt,
      ));
    }

    return result;
  }

  /// Парсит watched-shows.json.
  List<_TraktShow> _parseWatchedShows(String? json) {
    if (json == null || json.isEmpty) return <_TraktShow>[];

    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    final List<_TraktShow> result = <_TraktShow>[];

    for (final dynamic item in list) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final Map<String, dynamic>? showData =
          data['show'] as Map<String, dynamic>?;
      if (showData == null) continue;

      final Map<String, dynamic>? ids =
          showData['ids'] as Map<String, dynamic>?;
      final int? tmdbId = ids?['tmdb'] as int?;

      DateTime? lastWatchedAt;
      final String? lastWatched = data['last_watched_at'] as String?;
      if (lastWatched != null) {
        lastWatchedAt = DateTime.tryParse(lastWatched);
      }

      final List<_TraktSeason> seasons = <_TraktSeason>[];
      final List<dynamic>? seasonsData =
          data['seasons'] as List<dynamic>?;
      if (seasonsData != null) {
        for (final dynamic seasonItem in seasonsData) {
          final Map<String, dynamic> seasonData =
              seasonItem as Map<String, dynamic>;
          final int seasonNumber = seasonData['number'] as int? ?? 0;

          final List<_TraktEpisode> episodes = <_TraktEpisode>[];
          final List<dynamic>? episodesData =
              seasonData['episodes'] as List<dynamic>?;
          if (episodesData != null) {
            for (final dynamic epItem in episodesData) {
              final Map<String, dynamic> epData =
                  epItem as Map<String, dynamic>;

              DateTime? epWatchedAt;
              final String? epWatched =
                  epData['last_watched_at'] as String?;
              if (epWatched != null) {
                epWatchedAt = DateTime.tryParse(epWatched);
              }

              episodes.add(_TraktEpisode(
                number: epData['number'] as int? ?? 0,
                lastWatchedAt: epWatchedAt,
              ));
            }
          }

          seasons.add(_TraktSeason(
            number: seasonNumber,
            episodes: episodes,
          ));
        }
      }

      result.add(_TraktShow(
        title: showData['title'] as String? ?? 'Unknown',
        tmdbId: tmdbId,
        lastWatchedAt: lastWatchedAt,
        seasons: seasons,
      ));
    }

    return result;
  }

  /// Парсит ratings-movies.json или ratings-shows.json.
  List<_TraktRating> _parseRatings(String? json, String type) {
    if (json == null || json.isEmpty) return <_TraktRating>[];

    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    final List<_TraktRating> result = <_TraktRating>[];

    final String mediaKey = type == 'movie' ? 'movie' : 'show';

    for (final dynamic item in list) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final Map<String, dynamic>? mediaData =
          data[mediaKey] as Map<String, dynamic>?;
      if (mediaData == null) continue;

      final Map<String, dynamic>? ids =
          mediaData['ids'] as Map<String, dynamic>?;
      final int? tmdbId = ids?['tmdb'] as int?;
      final int rating = (data['rating'] as int? ?? 0).clamp(1, 10);

      result.add(_TraktRating(
        title: mediaData['title'] as String? ?? 'Unknown',
        tmdbId: tmdbId,
        rating: rating,
        type: type,
      ));
    }

    return result;
  }

  /// Парсит watchlist.json.
  List<_TraktWatchlistEntry> _parseWatchlist(String? json) {
    if (json == null || json.isEmpty) return <_TraktWatchlistEntry>[];

    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    final List<_TraktWatchlistEntry> result = <_TraktWatchlistEntry>[];

    for (final dynamic item in list) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final String type = data['type'] as String? ?? 'movie';
      final String mediaKey = type == 'movie' ? 'movie' : 'show';

      final Map<String, dynamic>? mediaData =
          data[mediaKey] as Map<String, dynamic>?;
      if (mediaData == null) continue;

      final Map<String, dynamic>? ids =
          mediaData['ids'] as Map<String, dynamic>?;
      final int? tmdbId = ids?['tmdb'] as int?;

      result.add(_TraktWatchlistEntry(
        title: mediaData['title'] as String? ?? 'Unknown',
        tmdbId: tmdbId,
        type: type,
      ));
    }

    return result;
  }

  /// Определяет, является ли элемент анимацией по жанрам.
  static bool _isAnimationByGenres(List<String>? genres) {
    if (genres == null || genres.isEmpty) return false;
    return genres.any(
      (String g) => g.toLowerCase() == 'animation' || g == '16',
    );
  }

  /// Определяет MediaType и platformId для фильма/сериала с учётом анимации.
  static ({MediaType mediaType, int? platformId}) _resolveMediaType({
    required bool isMovie,
    required Map<int, bool> movieIsAnimation,
    required Map<int, bool> showIsAnimation,
    required int tmdbId,
  }) {
    final bool isAnim = isMovie
        ? (movieIsAnimation[tmdbId] ?? false)
        : (showIsAnimation[tmdbId] ?? false);

    if (isAnim) {
      return (
        mediaType: MediaType.animation,
        platformId: isMovie ? AnimationSource.movie : AnimationSource.tvShow,
      );
    }
    return (
      mediaType: isMovie ? MediaType.movie : MediaType.tvShow,
      platformId: null,
    );
  }

  /// Определяет статус сериала по просмотренным эпизодам.
  ItemStatus _resolveShowStatus(_TraktShow show) {
    if (show.seasons.isEmpty) {
      // Нет данных по эпизодам, но есть plays — считаем completed
      return ItemStatus.completed;
    }

    bool hasAnyEpisode = false;
    for (final _TraktSeason season in show.seasons) {
      if (season.episodes.isNotEmpty) {
        hasAnyEpisode = true;
        break;
      }
    }

    if (!hasAnyEpisode) return ItemStatus.completed;

    // Если есть хотя бы один эпизод — считаем inProgress
    // (точное определение completed требует знания общего числа эпизодов
    // шоу, которое мы не можем надёжно получить из Trakt export)
    return ItemStatus.inProgress;
  }

  /// Проверяет, имеет ли новый статус более высокий приоритет.
  static bool _isHigherStatus(ItemStatus newStatus, ItemStatus existing) {
    // Не перезаписываем dropped — пользователь решил осознанно
    if (existing == ItemStatus.dropped) return false;

    final int newPriority = _statusPriority[newStatus] ?? 0;
    final int existingPriority = _statusPriority[existing] ?? 0;
    return newPriority > existingPriority;
  }

  /// Импортирует или обновляет элемент с конфликт-резолюцией.
  Future<_ImportItemResult> _importOrUpdateItem({
    required int collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    required ItemStatus status,
    DateTime? completedAt,
  }) async {
    // Проверяем, существует ли элемент
    final CollectionItem? existing = await _repository.findItem(
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
    );

    if (existing == null) {
      // Новый элемент
      final int? itemId = await _repository.addItem(
        collectionId: collectionId,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
        status: status,
      );

      if (itemId == null) return _ImportItemResult.skipped;

      // Устанавливаем даты
      if (completedAt != null) {
        await _database.updateItemActivityDates(
          itemId,
          completedAt: completedAt,
          lastActivityAt: completedAt,
        );
      }

      return _ImportItemResult.added;
    }

    // Конфликт-резолюция
    bool updated = false;

    // Статус: повышаем если Trakt "выше"
    if (_isHigherStatus(status, existing.status)) {
      await _repository.updateItemStatus(
        existing.id,
        status,
        mediaType: mediaType,
      );
      updated = true;
    }

    // completedAt: устанавливаем если локальный null
    if (completedAt != null && existing.completedAt == null) {
      await _database.updateItemActivityDates(
        existing.id,
        completedAt: completedAt,
      );
      updated = true;
    }

    return updated ? _ImportItemResult.updated : _ImportItemResult.skipped;
  }
}

/// Результат импорта отдельного элемента.
enum _ImportItemResult { added, updated, skipped }
