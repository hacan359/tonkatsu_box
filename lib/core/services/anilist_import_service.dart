// Imports anime/manga from a public AniList user list via GraphQL.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/anime.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/manga.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/universal_import_result.dart';
import '../api/anilist_api.dart';
import '../database/database_service.dart';

/// Stage of AniList import.
enum AniListImportStage {
  /// Fetching anime list from AniList.
  fetchingAnime,

  /// Fetching manga list from AniList.
  fetchingManga,

  /// Writing entries into the collection.
  matchingEntries,

  /// Import finished.
  completed,
}

/// Progress of AniList import.
class AniListImportProgress {
  /// Creates an [AniListImportProgress].
  const AniListImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.currentName,
    this.importedCount = 0,
    this.updatedCount = 0,
  });

  /// Current stage.
  final AniListImportStage stage;

  /// Current progress.
  final int current;

  /// Total count.
  final int total;

  /// Title currently being processed.
  final String? currentName;

  /// Number of imported titles.
  final int importedCount;

  /// Number of updated titles (re-import).
  final int updatedCount;

  /// Progress as fraction (0.0 – 1.0).
  double get progress => total > 0 ? current / total : 0;
}

/// Result of AniList import.
class AniListImportResult {
  /// Creates an [AniListImportResult].
  const AniListImportResult({
    required this.imported,
    required this.updated,
    required this.total,
    required this.collectionId,
    required this.animeImported,
    required this.mangaImported,
    required this.animeUpdated,
    required this.mangaUpdated,
    required this.userName,
  });

  /// Total imported.
  final int imported;

  /// Total updated.
  final int updated;

  /// Total entries fetched.
  final int total;

  /// Import collection ID.
  final int collectionId;

  /// Anime imported.
  final int animeImported;

  /// Manga imported.
  final int mangaImported;

  /// Anime updated.
  final int animeUpdated;

  /// Manga updated.
  final int mangaUpdated;

  /// AniList username the import was made from.
  final String userName;
}

/// Provider for [AniListImportService].
final Provider<AniListImportService> aniListImportServiceProvider =
    Provider<AniListImportService>((Ref ref) {
  return AniListImportService(
    aniListApi: ref.watch(aniListApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

/// AniList import service.
///
/// Fetches public user lists for anime and manga via GraphQL and writes
/// them into a collection. No OAuth — works with any public profile.
class AniListImportService {
  /// Creates an [AniListImportService].
  AniListImportService({
    required AniListApi aniListApi,
    required DatabaseService database,
  })  : _aniList = aniListApi,
        _db = database;

  static final Logger _log = Logger('AniListImportService');

  final AniListApi _aniList;
  final DatabaseService _db;

  /// Imports AniList user lists into a collection.
  ///
  /// At least one of [includeAnime] / [includeManga] must be true.
  /// Either [collectionId] or [createCollection] must be provided.
  ///
  /// Throws [AniListUserNotFoundException] / [AniListPrivateProfileException]
  /// / [AniListApiException] when the AniList API call fails.
  Future<AniListImportResult> importUserLists({
    required String userName,
    required ImportMode mode,
    bool includeAnime = true,
    bool includeManga = true,
    int? collectionId,
    Future<int> Function()? createCollection,
    required void Function(AniListImportProgress) onProgress,
  }) async {
    if (!includeAnime && !includeManga) {
      throw ArgumentError(
        'At least one of includeAnime / includeManga must be true',
      );
    }
    if (collectionId == null && createCollection == null) {
      throw ArgumentError(
        'Either collectionId or createCollection must be provided',
      );
    }

    List<AniListListEntry> animeEntries = <AniListListEntry>[];
    List<AniListListEntry> mangaEntries = <AniListListEntry>[];

    if (includeAnime) {
      onProgress(const AniListImportProgress(
        stage: AniListImportStage.fetchingAnime,
        current: 0,
        total: 0,
      ));
      animeEntries = await _aniList.fetchUserMediaList(
        userName: userName,
        type: MediaType.anime,
      );
      onProgress(AniListImportProgress(
        stage: AniListImportStage.fetchingAnime,
        current: animeEntries.length,
        total: animeEntries.length,
      ));
    }

    if (includeManga) {
      onProgress(const AniListImportProgress(
        stage: AniListImportStage.fetchingManga,
        current: 0,
        total: 0,
      ));
      mangaEntries = await _aniList.fetchUserMediaList(
        userName: userName,
        type: MediaType.manga,
      );
      onProgress(AniListImportProgress(
        stage: AniListImportStage.fetchingManga,
        current: mangaEntries.length,
        total: mangaEntries.length,
      ));
    }

    final int totalEntries = animeEntries.length + mangaEntries.length;
    if (totalEntries == 0) {
      throw const FormatException('No entries found in AniList lists');
    }

    // Create the collection only after a successful fetch.
    final int targetCollectionId = collectionId ?? await createCollection!();

    final List<Anime> animeMedia = animeEntries
        .where((AniListListEntry e) => e.anime != null)
        .map((AniListListEntry e) => e.anime!)
        .toList();
    final List<Manga> mangaMedia = mangaEntries
        .where((AniListListEntry e) => e.manga != null)
        .map((AniListListEntry e) => e.manga!)
        .toList();
    await Future.wait<void>(<Future<void>>[
      if (animeMedia.isNotEmpty) _db.animeDao.upsertAnimes(animeMedia),
      if (mangaMedia.isNotEmpty) _db.mangaDao.upsertMangas(mangaMedia),
    ]);

    final List<AniListListEntry> allEntries = <AniListListEntry>[
      ...animeEntries,
      ...mangaEntries,
    ];

    int imported = 0;
    int updated = 0;
    int animeImported = 0;
    int mangaImported = 0;
    int animeUpdated = 0;
    int mangaUpdated = 0;

    int processed = 0;
    for (final AniListListEntry entry in allEntries) {
      processed++;
      onProgress(AniListImportProgress(
        stage: AniListImportStage.matchingEntries,
        current: processed,
        total: allEntries.length,
        currentName: _entryTitle(entry),
        importedCount: imported,
        updatedCount: updated,
      ));

      final ItemStatus status = _mapStatus(entry.rawStatus);

      final CollectionItem? existing = await _db.findCollectionItem(
        collectionId: targetCollectionId,
        mediaType: entry.mediaType,
        externalId: entry.mediaId,
      );

      if (existing != null) {
        if (mode == ImportMode.newOnly) {
          continue;
        }
        await _updateExistingItem(existing, entry, status);
        updated++;
        if (entry.mediaType == MediaType.anime) {
          animeUpdated++;
        } else {
          mangaUpdated++;
        }
        continue;
      }

      final int? itemId = await _db.addItemToCollection(
        collectionId: targetCollectionId,
        mediaType: entry.mediaType,
        externalId: entry.mediaId,
        status: status,
      );

      if (itemId != null) {
        await _writeEntryToItem(itemId, entry, status);
      }

      imported++;
      if (entry.mediaType == MediaType.anime) {
        animeImported++;
      } else {
        mangaImported++;
      }
    }

    onProgress(AniListImportProgress(
      stage: AniListImportStage.completed,
      current: allEntries.length,
      total: allEntries.length,
      importedCount: imported,
      updatedCount: updated,
    ));

    _log.info(
      'AniList import complete for "$userName": '
      '$imported imported, $updated updated (total $totalEntries)',
    );

    return AniListImportResult(
      imported: imported,
      updated: updated,
      total: totalEntries,
      collectionId: targetCollectionId,
      animeImported: animeImported,
      mangaImported: mangaImported,
      animeUpdated: animeUpdated,
      mangaUpdated: mangaUpdated,
      userName: userName,
    );
  }

  Future<void> _writeEntryToItem(
    int itemId,
    AniListListEntry entry,
    ItemStatus status,
  ) async {
    final _ResolvedProgress progress = _resolveProgress(entry, status);
    if (progress.currentEpisode > 0 || progress.currentSeason > 0) {
      await _db.updateItemProgress(
        itemId,
        currentEpisode:
            progress.currentEpisode > 0 ? progress.currentEpisode : null,
        currentSeason:
            progress.currentSeason > 0 ? progress.currentSeason : null,
      );
    }

    final double? rating = _resolveRating(entry.scoreRaw100);
    if (rating != null) {
      await _db.updateItemUserRating(itemId, rating);
    }

    final _ResolvedDates dates = _resolveDates(entry, status);
    if (dates.startedAt != null ||
        dates.completedAt != null ||
        dates.lastActivityAt != null) {
      await _db.updateItemActivityDates(
        itemId,
        startedAt: dates.startedAt,
        completedAt: dates.completedAt,
        lastActivityAt: dates.lastActivityAt,
      );
    }

    final String comment = _buildUserComment(entry);
    if (comment.isNotEmpty) {
      await _db.updateItemUserComment(itemId, comment);
    }
  }

  Future<void> _updateExistingItem(
    CollectionItem existing,
    AniListListEntry entry,
    ItemStatus status,
  ) async {
    final ItemStatus? newStatus = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: status,
    );
    if (newStatus != null) {
      await _db.updateItemStatus(
        existing.id,
        newStatus,
        mediaType: existing.mediaType,
      );
    }

    // Progress: keep max so we never regress local state.
    final _ResolvedProgress remoteProgress = _resolveProgress(entry, status);
    final int newEpisode =
        remoteProgress.currentEpisode > existing.currentEpisode
            ? remoteProgress.currentEpisode
            : existing.currentEpisode;
    final int newSeason = remoteProgress.currentSeason > existing.currentSeason
        ? remoteProgress.currentSeason
        : existing.currentSeason;
    if (newEpisode != existing.currentEpisode ||
        newSeason != existing.currentSeason) {
      await _db.updateItemProgress(
        existing.id,
        currentEpisode: newEpisode > 0 ? newEpisode : null,
        currentSeason: newSeason > 0 ? newSeason : null,
      );
    }

    final double? rating = _resolveRating(entry.scoreRaw100);
    if (rating != null && rating != existing.userRating) {
      await _db.updateItemUserRating(existing.id, rating);
    }

    // Dates: keep earliest start, latest completion.
    final _ResolvedDates remoteDates = _resolveDates(entry, status);
    DateTime? newStarted = existing.startedAt;
    DateTime? newCompleted = existing.completedAt;
    if (remoteDates.startedAt != null) {
      if (newStarted == null || remoteDates.startedAt!.isBefore(newStarted)) {
        newStarted = remoteDates.startedAt;
      }
    }
    if (remoteDates.completedAt != null) {
      if (newCompleted == null ||
          remoteDates.completedAt!.isAfter(newCompleted)) {
        newCompleted = remoteDates.completedAt;
      }
    }
    if (newStarted != existing.startedAt ||
        newCompleted != existing.completedAt) {
      await _db.updateItemActivityDates(
        existing.id,
        startedAt: newStarted,
        completedAt: newCompleted,
        lastActivityAt: entry.updatedAt ?? DateTime.now(),
      );
    }

    final String comment = _buildUserComment(entry);
    if (comment.isNotEmpty) {
      await _db.updateItemUserComment(existing.id, comment);
    }
  }

  _ResolvedProgress _resolveProgress(
    AniListListEntry entry,
    ItemStatus status,
  ) {
    int currentEpisode = entry.progress;
    int currentSeason = entry.mediaType == MediaType.manga
        ? entry.progressVolumes
        : 0;

    if (status == ItemStatus.completed) {
      if (entry.mediaType == MediaType.anime) {
        final int total = entry.anime?.episodes ?? 0;
        if (total > currentEpisode) currentEpisode = total;
      } else {
        final int chaps = entry.manga?.chapters ?? 0;
        if (chaps > currentEpisode) currentEpisode = chaps;
        final int vols = entry.manga?.volumes ?? 0;
        if (vols > currentSeason) currentSeason = vols;
      }
    }

    return _ResolvedProgress(
      currentEpisode: currentEpisode,
      currentSeason: currentSeason,
    );
  }

  _ResolvedDates _resolveDates(AniListListEntry entry, ItemStatus status) {
    DateTime? startedAt = entry.startedAt;
    DateTime? completedAt = entry.completedAt;

    if (status == ItemStatus.completed) {
      completedAt ??= startedAt ?? entry.updatedAt ?? DateTime.now();
      startedAt ??= completedAt;
    }

    return _ResolvedDates(
      startedAt: startedAt,
      completedAt: completedAt,
      lastActivityAt: entry.updatedAt ?? DateTime.now(),
    );
  }

  /// Normalizes AniList POINT_100 score to a 1.0..10.0 rating (step 0.1).
  static double? _resolveRating(int? scoreRaw100) {
    if (scoreRaw100 == null || scoreRaw100 <= 0) return null;
    final double normalized = scoreRaw100 / 10.0;
    if (normalized < 1.0) return 1.0;
    if (normalized > 10.0) return 10.0;
    return normalized;
  }

  String _buildUserComment(AniListListEntry entry) {
    final List<String> lines = <String>[];

    final String aniPath =
        entry.mediaType == MediaType.anime ? 'anime' : 'manga';
    lines.add('[AniList](https://anilist.co/$aniPath/${entry.mediaId})');

    if (entry.repeat > 0) {
      final String label = entry.mediaType == MediaType.anime
          ? 'Rewatched times'
          : 'Reread times';
      lines.add('$label: ${entry.repeat}');
    }

    if (entry.mediaType == MediaType.manga && entry.progressVolumes > 0) {
      lines.add('Volumes read: ${entry.progressVolumes}');
    }

    if (entry.notes != null) {
      lines.add('');
      lines.add(entry.notes!);
    }

    return lines.join('\n');
  }

  String _entryTitle(AniListListEntry entry) {
    if (entry.anime != null) return entry.anime!.title;
    if (entry.manga != null) return entry.manga!.title;
    return '#${entry.mediaId}';
  }

  static ItemStatus _mapStatus(String raw) {
    final String s = raw.toUpperCase().trim();
    switch (s) {
      case 'CURRENT':
      case 'REPEATING':
        return ItemStatus.inProgress;
      case 'COMPLETED':
        return ItemStatus.completed;
      case 'PLANNING':
        return ItemStatus.planned;
      case 'DROPPED':
      case 'PAUSED':
        return ItemStatus.dropped;
      default:
        _log.warning('Unknown AniList status: "$raw" → notStarted');
        return ItemStatus.notStarted;
    }
  }
}

/// Import behavior when a matching item already exists in the collection.
enum ImportMode {
  /// Skip existing items, add only new ones.
  newOnly,

  /// Overwrite fields on existing items with remote values.
  overwrite,
}

class _ResolvedProgress {
  const _ResolvedProgress({
    required this.currentEpisode,
    required this.currentSeason,
  });

  final int currentEpisode;
  final int currentSeason;
}

class _ResolvedDates {
  const _ResolvedDates({
    required this.startedAt,
    required this.completedAt,
    required this.lastActivityAt,
  });

  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;
}

/// Converts [AniListImportResult] to [UniversalImportResult].
extension AniListImportResultToUniversal on AniListImportResult {
  /// Maps to the universal result.
  UniversalImportResult toUniversal({Collection? collection}) {
    final Map<MediaType, int> importedByType = <MediaType, int>{};
    final Map<MediaType, int> updatedByType = <MediaType, int>{};

    if (animeImported > 0) importedByType[MediaType.anime] = animeImported;
    if (mangaImported > 0) importedByType[MediaType.manga] = mangaImported;
    if (animeUpdated > 0) updatedByType[MediaType.anime] = animeUpdated;
    if (mangaUpdated > 0) updatedByType[MediaType.manga] = mangaUpdated;

    return UniversalImportResult(
      sourceName: 'AniList',
      success: true,
      collection: collection,
      collectionId: collectionId,
      importedByType: importedByType,
      wishlistedByType: const <MediaType, int>{},
      updatedByType: updatedByType,
      skipped: (total - imported - updated).clamp(0, total),
    );
  }
}
