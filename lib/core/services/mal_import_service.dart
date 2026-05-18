// Imports anime/manga from MyAnimeList XML export.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

import '../../shared/models/anime.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/manga.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/universal_import_result.dart';
import '../../shared/models/wishlist_item.dart';
import '../../shared/models/wishlist_tag.dart';
import '../api/anilist_api.dart';
import '../database/database_service.dart';

/// Stage of MyAnimeList import.
enum MalImportStage {
  /// Parsing XML files.
  readingFiles,

  /// Resolving MAL → AniList IDs for anime.
  resolvingAnime,

  /// Resolving MAL → AniList IDs for manga.
  resolvingManga,

  /// Waiting out an AniList rate-limit window before retrying.
  rateLimitWait,

  /// Writing entries into the collection.
  matchingEntries,

  /// Import finished.
  completed,
}

/// Progress of MyAnimeList import.
class MalImportProgress {
  /// Creates a [MalImportProgress].
  const MalImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.currentName,
    this.importedCount = 0,
    this.wishlistedCount = 0,
    this.updatedCount = 0,
    this.failedLookupCount = 0,
    this.rateLimitWaitSeconds,
    this.rateLimitAttempt,
    this.rateLimitMaxAttempts,
  });

  /// Current stage.
  final MalImportStage stage;

  /// Current progress.
  final int current;

  /// Total count.
  final int total;

  /// Title currently being processed.
  final String? currentName;

  /// Number of imported titles.
  final int importedCount;

  /// Number of titles added to wishlist (not found on AniList).
  final int wishlistedCount;

  /// Number of updated titles (re-import).
  final int updatedCount;

  /// Number of MAL entries whose AniList lookup failed (after retries).
  /// Such entries are skipped, not wishlisted — retry import to resolve them.
  final int failedLookupCount;

  /// Seconds to wait on the current [MalImportStage.rateLimitWait] step.
  final int? rateLimitWaitSeconds;

  /// Current retry attempt (1-based) when [stage] is [MalImportStage.rateLimitWait].
  final int? rateLimitAttempt;

  /// Total retry attempts available when [stage] is [MalImportStage.rateLimitWait].
  final int? rateLimitMaxAttempts;

  /// Progress as fraction (0.0 – 1.0).
  double get progress => total > 0 ? current / total : 0;
}

/// Result of MyAnimeList import.
class MalImportResult {
  /// Creates a [MalImportResult].
  const MalImportResult({
    required this.imported,
    required this.wishlisted,
    required this.updated,
    required this.total,
    required this.collectionId,
    required this.animeImported,
    required this.mangaImported,
    required this.animeWishlisted,
    required this.mangaWishlisted,
    required this.animeUpdated,
    required this.mangaUpdated,
    this.animeFailedLookup = 0,
    this.mangaFailedLookup = 0,
  });

  /// Total imported.
  final int imported;

  /// Total wishlisted.
  final int wishlisted;

  /// Total updated.
  final int updated;

  /// Total entries in files (after filtering).
  final int total;

  /// Import collection ID.
  final int collectionId;

  /// Anime imported.
  final int animeImported;

  /// Manga imported.
  final int mangaImported;

  /// Anime wishlisted.
  final int animeWishlisted;

  /// Manga wishlisted.
  final int mangaWishlisted;

  /// Anime updated.
  final int animeUpdated;

  /// Manga updated.
  final int mangaUpdated;

  /// Anime whose AniList lookup failed (after retries). Skipped, not wishlisted.
  final int animeFailedLookup;

  /// Manga whose AniList lookup failed (after retries). Skipped, not wishlisted.
  final int mangaFailedLookup;

  /// Total failed lookups across both kinds.
  int get failedLookup => animeFailedLookup + mangaFailedLookup;
}

/// Type of parsed XML file.
enum MalFileKind {
  /// Anime list.
  anime,

  /// Manga list.
  manga,
}

/// Result of parsing a single XML file.
class MalParsedFile {
  /// Creates a [MalParsedFile].
  const MalParsedFile({
    required this.kind,
    required this.entries,
    required this.userName,
  });

  /// Content type.
  final MalFileKind kind;

  /// Parsed entries.
  final List<MalEntry> entries;

  /// MAL user name.
  final String userName;
}

/// Entry from MAL export.
class MalEntry {
  /// Creates a [MalEntry].
  const MalEntry({
    required this.malId,
    required this.title,
    required this.kind,
    required this.status,
    this.score,
    this.watchedEpisodes = 0,
    this.readChapters = 0,
    this.readVolumes = 0,
    this.totalEpisodesXml,
    this.totalChaptersXml,
    this.totalVolumesXml,
    this.startDate,
    this.finishDate,
    this.tags,
    this.timesWatched = 0,
    this.comments,
  });

  /// MAL ID (`series_animedb_id` / `manga_mangadb_id`).
  final int malId;

  /// Title name.
  final String title;

  /// Entry kind.
  final MalFileKind kind;

  /// Mapped status.
  final ItemStatus status;

  /// User score (1-10) or null.
  final int? score;

  /// Watched episodes (anime only).
  final int watchedEpisodes;

  /// Read chapters (manga only).
  final int readChapters;

  /// Read volumes (manga only).
  final int readVolumes;

  /// Total episodes from XML (used to top up on Completed when AniList lacks the count).
  final int? totalEpisodesXml;

  /// Total chapters from XML.
  final int? totalChaptersXml;

  /// Total volumes from XML.
  final int? totalVolumesXml;

  /// Start date of watching/reading.
  final DateTime? startDate;

  /// Finish date of watching/reading.
  final DateTime? finishDate;

  /// User tags (raw comma-separated string).
  final String? tags;

  /// Number of rewatches/rereads.
  final int timesWatched;

  /// User comment.
  final String? comments;
}

/// Provider for [MalImportService].
final Provider<MalImportService> malImportServiceProvider =
    Provider<MalImportService>((Ref ref) {
  return MalImportService(
    aniListApi: ref.watch(aniListApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

/// MyAnimeList import service.
class MalImportService {
  /// Creates a [MalImportService].
  MalImportService({
    required AniListApi aniListApi,
    required DatabaseService database,
  })  : _aniList = aniListApi,
        _db = database;

  static final Logger _log = Logger('MalImportService');

  final AniListApi _aniList;
  final DatabaseService _db;

  /// Parses a MAL export XML file.
  ///
  /// Throws [FormatException] on invalid XML.
  Future<MalParsedFile> parseFile(File file) async {
    final String content = await file.readAsString();
    return parseString(content);
  }

  /// Parses a MAL export XML string.
  MalParsedFile parseString(String content) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(content);
    } on XmlException catch (e) {
      throw FormatException('Invalid XML: ${e.message}');
    }

    final XmlElement root = doc.rootElement;
    if (root.name.local != 'myanimelist') {
      throw const FormatException(
        'Not a MyAnimeList export (expected <myanimelist> root)',
      );
    }

    final XmlElement? myInfo = root.getElement('myinfo');
    final String userName = myInfo?.getElement('user_name')?.innerText ?? '';
    final String exportType =
        myInfo?.getElement('user_export_type')?.innerText.trim() ?? '';

    final MalFileKind kind;
    if (exportType == '1') {
      kind = MalFileKind.anime;
    } else if (exportType == '2') {
      kind = MalFileKind.manga;
    } else {
      // Fallback when user_export_type is missing: infer kind from first child.
      final XmlElement? firstAnime = root.getElement('anime');
      final XmlElement? firstManga = root.getElement('manga');
      if (firstAnime != null) {
        kind = MalFileKind.anime;
      } else if (firstManga != null) {
        kind = MalFileKind.manga;
      } else {
        throw const FormatException(
          'Unknown MAL export type (no <anime> or <manga> entries)',
        );
      }
    }

    final List<MalEntry> entries = <MalEntry>[];
    final String entryTag = kind == MalFileKind.anime ? 'anime' : 'manga';
    for (final XmlElement node in root.findElements(entryTag)) {
      final MalEntry? entry = _parseEntry(node, kind);
      if (entry != null) entries.add(entry);
    }

    return MalParsedFile(
      kind: kind,
      entries: entries,
      userName: userName,
    );
  }

  MalEntry? _parseEntry(XmlElement node, MalFileKind kind) {
    final String idTag =
        kind == MalFileKind.anime ? 'series_animedb_id' : 'manga_mangadb_id';
    final String titleTag =
        kind == MalFileKind.anime ? 'series_title' : 'manga_title';
    const String totalAnimeTag = 'series_episodes';
    const String totalMangaChaptersTag = 'manga_chapters';
    const String totalMangaVolumesTag = 'manga_volumes';

    final int? malId = _parseInt(node.getElement(idTag)?.innerText);
    if (malId == null || malId <= 0) return null;

    final String title = node.getElement(titleTag)?.innerText.trim() ?? '';
    if (title.isEmpty) return null;

    final ItemStatus status = _mapStatus(
      node.getElement('my_status')?.innerText.trim() ?? '',
    );

    final int? scoreRaw = _parseInt(node.getElement('my_score')?.innerText);
    final int? score = (scoreRaw == null || scoreRaw <= 0) ? null : scoreRaw;

    final int watchedEpisodes = kind == MalFileKind.anime
        ? _parseInt(node.getElement('my_watched_episodes')?.innerText) ?? 0
        : 0;
    final int readChapters = kind == MalFileKind.manga
        ? _parseInt(node.getElement('my_read_chapters')?.innerText) ?? 0
        : 0;
    final int readVolumes = kind == MalFileKind.manga
        ? _parseInt(node.getElement('my_read_volumes')?.innerText) ?? 0
        : 0;

    final int? totalEpisodes = kind == MalFileKind.anime
        ? _parseInt(node.getElement(totalAnimeTag)?.innerText)
        : null;
    final int? totalChapters = kind == MalFileKind.manga
        ? _parseInt(node.getElement(totalMangaChaptersTag)?.innerText)
        : null;
    final int? totalVolumes = kind == MalFileKind.manga
        ? _parseInt(node.getElement(totalMangaVolumesTag)?.innerText)
        : null;

    final DateTime? startDate =
        _parseDate(node.getElement('my_start_date')?.innerText);
    final DateTime? finishDate =
        _parseDate(node.getElement('my_finish_date')?.innerText);

    final String? tagsRaw = node.getElement('my_tags')?.innerText.trim();
    final String? tags = (tagsRaw == null || tagsRaw.isEmpty) ? null : tagsRaw;

    final String timesField = kind == MalFileKind.anime
        ? 'my_times_watched'
        : 'my_times_read';
    final int timesWatched =
        _parseInt(node.getElement(timesField)?.innerText) ?? 0;

    final String? commentsRaw =
        node.getElement('my_comments')?.innerText.trim();
    final String? comments =
        (commentsRaw == null || commentsRaw.isEmpty) ? null : commentsRaw;

    return MalEntry(
      malId: malId,
      title: title,
      kind: kind,
      status: status,
      score: score,
      watchedEpisodes: watchedEpisodes,
      readChapters: readChapters,
      readVolumes: readVolumes,
      totalEpisodesXml: (totalEpisodes != null && totalEpisodes > 0)
          ? totalEpisodes
          : null,
      totalChaptersXml: (totalChapters != null && totalChapters > 0)
          ? totalChapters
          : null,
      totalVolumesXml:
          (totalVolumes != null && totalVolumes > 0) ? totalVolumes : null,
      startDate: startDate,
      finishDate: finishDate,
      tags: tags,
      timesWatched: timesWatched,
      comments: comments,
    );
  }

  /// Imports MAL exports into a collection.
  ///
  /// At least one of [animeFile] / [mangaFile] must be provided.
  /// Either [collectionId] or [createCollection] must be provided.
  ///
  /// When [overwriteExistingItems] is `false` (default), entries already
  /// present in the target collection are left untouched — user's status,
  /// rating, progress, dates and notes survive re-imports. New entries from
  /// the export are still added. When `true`, existing items are merged with
  /// MAL data via the standard merge rules (status priority, max progress,
  /// earliest/latest dates, MAL rating wins, MAL comment overwrites).
  Future<MalImportResult> importFiles({
    File? animeFile,
    File? mangaFile,
    int? collectionId,
    Future<int> Function()? createCollection,
    bool overwriteExistingItems = false,
    required void Function(MalImportProgress) onProgress,
  }) async {
    if (animeFile == null && mangaFile == null) {
      throw ArgumentError('At least one file (anime or manga) must be provided');
    }
    if (collectionId == null && createCollection == null) {
      throw ArgumentError(
        'Either collectionId or createCollection must be provided',
      );
    }

    onProgress(const MalImportProgress(
      stage: MalImportStage.readingFiles,
      current: 0,
      total: 0,
    ));

    MalParsedFile? animeParsed;
    MalParsedFile? mangaParsed;
    if (animeFile != null) {
      animeParsed = await parseFile(animeFile);
      if (animeParsed.kind != MalFileKind.anime) {
        throw const FormatException(
          'Anime file does not contain anime entries',
        );
      }
    }
    if (mangaFile != null) {
      mangaParsed = await parseFile(mangaFile);
      if (mangaParsed.kind != MalFileKind.manga) {
        throw const FormatException(
          'Manga file does not contain manga entries',
        );
      }
    }

    final List<MalEntry> animeEntries = animeParsed?.entries ?? <MalEntry>[];
    final List<MalEntry> mangaEntries = mangaParsed?.entries ?? <MalEntry>[];
    final int totalEntries = animeEntries.length + mangaEntries.length;

    if (totalEntries == 0) {
      throw const FormatException('No entries found in MAL export');
    }

    // One auto-tag per import run, stamped on every unmatched entry so the
    // user can later filter or wipe this whole batch from the wishlist.
    final String importTag = buildImportTag('MyAnimeList');

    // Create the collection only after parsing succeeds to avoid empty leftovers.
    final int targetCollectionId = collectionId ?? await createCollection!();

    final Map<int, Anime> animeByMal = <int, Anime>{};
    final Set<int> animeFailedIds = <int>{};
    if (animeEntries.isNotEmpty) {
      onProgress(MalImportProgress(
        stage: MalImportStage.resolvingAnime,
        current: 0,
        total: animeEntries.length,
      ));
      // Mirror the last reported batch progress into the rate-limit pause so
      // the global counter doesn't snap back to 0 / total while we're waiting.
      int lastDone = 0;
      final int totalAnime = animeEntries.length;
      final AniListMalLookupResult<Anime> result =
          await _aniList.getAnimeByMalIdsTolerant(
        animeEntries.map((MalEntry e) => e.malId).toList(),
        onRateLimit: (Duration wait, int attempt) {
          onProgress(MalImportProgress(
            stage: MalImportStage.rateLimitWait,
            current: lastDone,
            total: totalAnime,
            rateLimitWaitSeconds: wait.inSeconds,
            rateLimitAttempt: attempt,
            rateLimitMaxAttempts: AniListApi.maxRateLimitRetries,
          ));
        },
        onBatchProgress: (int done, int total) {
          lastDone = done;
          onProgress(MalImportProgress(
            stage: MalImportStage.resolvingAnime,
            current: done,
            total: total,
          ));
        },
      );
      animeByMal.addAll(result.resolved);
      animeFailedIds.addAll(result.failedIds);
    }

    final Map<int, Manga> mangaByMal = <int, Manga>{};
    final Set<int> mangaFailedIds = <int>{};
    if (mangaEntries.isNotEmpty) {
      onProgress(MalImportProgress(
        stage: MalImportStage.resolvingManga,
        current: 0,
        total: mangaEntries.length,
      ));
      int lastDone = 0;
      final int totalManga = mangaEntries.length;
      final AniListMalLookupResult<Manga> result =
          await _aniList.getMangaByMalIdsTolerant(
        mangaEntries.map((MalEntry e) => e.malId).toList(),
        onRateLimit: (Duration wait, int attempt) {
          onProgress(MalImportProgress(
            stage: MalImportStage.rateLimitWait,
            current: lastDone,
            total: totalManga,
            rateLimitWaitSeconds: wait.inSeconds,
            rateLimitAttempt: attempt,
            rateLimitMaxAttempts: AniListApi.maxRateLimitRetries,
          ));
        },
        onBatchProgress: (int done, int total) {
          lastDone = done;
          onProgress(MalImportProgress(
            stage: MalImportStage.resolvingManga,
            current: done,
            total: total,
          ));
        },
      );
      mangaByMal.addAll(result.resolved);
      mangaFailedIds.addAll(result.failedIds);
    }

    if (animeByMal.isNotEmpty) {
      await _db.upsertAnimes(animeByMal.values.toList());
    }
    if (mangaByMal.isNotEmpty) {
      await _db.upsertMangas(mangaByMal.values.toList());
    }

    int imported = 0;
    int wishlisted = 0;
    int updated = 0;
    int animeImported = 0;
    int mangaImported = 0;
    int animeWishlisted = 0;
    int mangaWishlisted = 0;
    int animeUpdated = 0;
    int mangaUpdated = 0;
    int animeFailedLookup = 0;
    int mangaFailedLookup = 0;

    int processed = 0;
    final List<MalEntry> allEntries = <MalEntry>[
      ...animeEntries,
      ...mangaEntries,
    ];

    for (final MalEntry entry in allEntries) {
      processed++;
      onProgress(MalImportProgress(
        stage: MalImportStage.matchingEntries,
        current: processed,
        total: allEntries.length,
        currentName: entry.title,
        importedCount: imported,
        wishlistedCount: wishlisted,
        updatedCount: updated,
        failedLookupCount: animeFailedLookup + mangaFailedLookup,
      ));

      // Lookup failed at AniList (rate-limit / network) — skip, don't wishlist.
      // Re-running the import will retry these once AniList is reachable.
      final bool lookupFailed = entry.kind == MalFileKind.anime
          ? animeFailedIds.contains(entry.malId)
          : mangaFailedIds.contains(entry.malId);
      if (lookupFailed) {
        if (entry.kind == MalFileKind.anime) {
          animeFailedLookup++;
        } else {
          mangaFailedLookup++;
        }
        continue;
      }

      final int? aniListId = entry.kind == MalFileKind.anime
          ? animeByMal[entry.malId]?.id
          : mangaByMal[entry.malId]?.id;

      if (aniListId == null) {
        await _addToWishlist(entry, importTag);
        wishlisted++;
        if (entry.kind == MalFileKind.anime) {
          animeWishlisted++;
        } else {
          mangaWishlisted++;
        }
        continue;
      }

      final MediaType mediaType = entry.kind == MalFileKind.anime
          ? MediaType.anime
          : MediaType.manga;

      // Dedup on re-import: update existing item instead of duplicating.
      final CollectionItem? existing = await _db.findCollectionItem(
        collectionId: targetCollectionId,
        mediaType: mediaType,
        externalId: aniListId,
      );

      if (existing != null) {
        if (overwriteExistingItems) {
          await _updateExistingItem(
            existing,
            entry,
            aniListAnime: animeByMal[entry.malId],
            aniListManga: mangaByMal[entry.malId],
          );
        }
        // When overwrite is off we still count this as "updated" semantically
        // — the entry was matched against the local collection, just left
        // intact so the user's edits survive.
        updated++;
        if (entry.kind == MalFileKind.anime) {
          animeUpdated++;
        } else {
          mangaUpdated++;
        }
        continue;
      }

      final int? itemId = await _db.addItemToCollection(
        collectionId: targetCollectionId,
        mediaType: mediaType,
        externalId: aniListId,
        status: entry.status,
      );

      if (itemId != null) {
        await _writeMalDataToItem(
          itemId,
          entry,
          aniListAnime: animeByMal[entry.malId],
          aniListManga: mangaByMal[entry.malId],
        );
      }

      imported++;
      if (entry.kind == MalFileKind.anime) {
        animeImported++;
      } else {
        mangaImported++;
      }
    }

    onProgress(MalImportProgress(
      stage: MalImportStage.completed,
      current: allEntries.length,
      total: allEntries.length,
      importedCount: imported,
      wishlistedCount: wishlisted,
      updatedCount: updated,
      failedLookupCount: animeFailedLookup + mangaFailedLookup,
    ));

    _log.info(
      'MAL import complete: $imported imported, $wishlisted wishlisted, '
      '$updated updated, ${animeFailedLookup + mangaFailedLookup} '
      'lookup failures (total $totalEntries)',
    );

    return MalImportResult(
      imported: imported,
      wishlisted: wishlisted,
      updated: updated,
      total: totalEntries,
      collectionId: targetCollectionId,
      animeImported: animeImported,
      mangaImported: mangaImported,
      animeWishlisted: animeWishlisted,
      mangaWishlisted: mangaWishlisted,
      animeUpdated: animeUpdated,
      mangaUpdated: mangaUpdated,
      animeFailedLookup: animeFailedLookup,
      mangaFailedLookup: mangaFailedLookup,
    );
  }

  Future<void> _writeMalDataToItem(
    int itemId,
    MalEntry entry, {
    Anime? aniListAnime,
    Manga? aniListManga,
  }) async {
    final _ResolvedProgress progress = _resolveProgress(
      entry,
      aniListAnime: aniListAnime,
      aniListManga: aniListManga,
    );

    if (progress.currentEpisode > 0 || progress.currentSeason > 0) {
      await _db.updateItemProgress(
        itemId,
        currentEpisode: progress.currentEpisode > 0
            ? progress.currentEpisode
            : null,
        currentSeason:
            progress.currentSeason > 0 ? progress.currentSeason : null,
      );
    }

    if (entry.score != null) {
      await _db.updateItemUserRating(itemId, entry.score);
    }

    final _ResolvedDates dates = _resolveDates(entry);
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
    MalEntry entry, {
    Anime? aniListAnime,
    Manga? aniListManga,
  }) async {
    final ItemStatus? newStatus = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: entry.status,
    );
    if (newStatus != null) {
      await _db.updateItemStatus(
        existing.id,
        newStatus,
        mediaType: existing.mediaType,
      );
    }

    // Progress: take max(local, MAL) so we never regress user's watch state.
    final _ResolvedProgress malProgress = _resolveProgress(
      entry,
      aniListAnime: aniListAnime,
      aniListManga: aniListManga,
    );
    final int newEpisode =
        malProgress.currentEpisode > existing.currentEpisode
            ? malProgress.currentEpisode
            : existing.currentEpisode;
    final int newSeason = malProgress.currentSeason > existing.currentSeason
        ? malProgress.currentSeason
        : existing.currentSeason;
    if (newEpisode != existing.currentEpisode ||
        newSeason != existing.currentSeason) {
      await _db.updateItemProgress(
        existing.id,
        currentEpisode: newEpisode > 0 ? newEpisode : null,
        currentSeason: newSeason > 0 ? newSeason : null,
      );
    }

    // MAL rating wins when set (treated as fresher source on re-import).
    if (entry.score != null && entry.score != existing.userRating) {
      await _db.updateItemUserRating(existing.id, entry.score);
    }

    // Dates: keep earliest start and latest completion across sources.
    final _ResolvedDates malDates = _resolveDates(entry);
    DateTime? newStarted = existing.startedAt;
    DateTime? newCompleted = existing.completedAt;

    if (malDates.startedAt != null) {
      if (newStarted == null || malDates.startedAt!.isBefore(newStarted)) {
        newStarted = malDates.startedAt;
      }
    }
    if (malDates.completedAt != null) {
      if (newCompleted == null || malDates.completedAt!.isAfter(newCompleted)) {
        newCompleted = malDates.completedAt;
      }
    }

    if (newStarted != existing.startedAt ||
        newCompleted != existing.completedAt) {
      await _db.updateItemActivityDates(
        existing.id,
        startedAt: newStarted,
        completedAt: newCompleted,
        lastActivityAt: DateTime.now(),
      );
    }

    final String comment = _buildUserComment(entry);
    if (comment.isNotEmpty) {
      await _db.updateItemUserComment(existing.id, comment);
    }
  }

  Future<void> _addToWishlist(MalEntry entry, String importTag) async {
    final String note = _buildWishlistNote(entry);
    final MediaType mediaType = entry.kind == MalFileKind.anime
        ? MediaType.anime
        : MediaType.manga;

    final WishlistItem? existing =
        await _db.findUnresolvedWishlistItem(entry.title);

    if (existing != null) {
      // Stamp the current import tag onto previously-untagged items so the
      // existing dump gets retro-grouped; never overwrite a tag the user (or
      // an earlier import) already set.
      final bool needsTag = existing.tag == null;
      final bool noteChanged = note != existing.note;
      if (needsTag || noteChanged) {
        await _db.updateWishlistItem(
          existing.id,
          note: noteChanged ? note : null,
          tag: needsTag ? importTag : null,
        );
      }
      return;
    }

    await _db.addWishlistItem(
      text: entry.title,
      mediaTypeHint: mediaType,
      note: note,
      tag: importTag,
    );
  }

  _ResolvedProgress _resolveProgress(
    MalEntry entry, {
    Anime? aniListAnime,
    Manga? aniListManga,
  }) {
    int currentEpisode = 0;
    int currentSeason = 0;

    if (entry.kind == MalFileKind.anime) {
      currentEpisode = entry.watchedEpisodes;
      if (entry.status == ItemStatus.completed) {
        // Completed should reflect full length; fall back to XML total when AniList has none.
        final int total = aniListAnime?.episodes ?? entry.totalEpisodesXml ?? 0;
        if (total > currentEpisode) currentEpisode = total;
      }
    } else {
      currentEpisode = entry.readChapters;
      currentSeason = entry.readVolumes;
      if (entry.status == ItemStatus.completed) {
        final int chaps =
            aniListManga?.chapters ?? entry.totalChaptersXml ?? 0;
        if (chaps > currentEpisode) currentEpisode = chaps;
        final int vols = aniListManga?.volumes ?? entry.totalVolumesXml ?? 0;
        if (vols > currentSeason) currentSeason = vols;
      }
    }

    return _ResolvedProgress(
      currentEpisode: currentEpisode,
      currentSeason: currentSeason,
    );
  }

  _ResolvedDates _resolveDates(MalEntry entry) {
    DateTime? startedAt = entry.startDate;
    DateTime? completedAt = entry.finishDate;

    if (entry.status == ItemStatus.completed) {
      completedAt ??= entry.startDate ?? DateTime.now();
      startedAt ??= completedAt;
    }

    return _ResolvedDates(
      startedAt: startedAt,
      completedAt: completedAt,
      lastActivityAt: DateTime.now(),
    );
  }

  String _buildUserComment(MalEntry entry) {
    final List<String> lines = <String>[];

    final String malPath =
        entry.kind == MalFileKind.anime ? 'anime' : 'manga';
    lines.add('[MyAnimeList](https://myanimelist.net/$malPath/${entry.malId})');

    if (entry.tags != null) {
      final List<String> tagList = entry.tags!
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
      if (tagList.isNotEmpty) {
        lines.add('Tags: ${tagList.join(', ')}');
      }
    }

    if (entry.kind == MalFileKind.anime) {
      lines.add('Rewatched times: ${entry.timesWatched}');
    } else {
      lines.add('Reread times: ${entry.timesWatched}');
      if (entry.readVolumes > 0) {
        lines.add('Volumes read: ${entry.readVolumes}');
      }
    }

    if (entry.comments != null) {
      lines.add('');
      lines.add(entry.comments!);
    }

    return lines.join('\n');
  }

  String _buildWishlistNote(MalEntry entry) {
    final List<String> lines = <String>[];

    final String malPath =
        entry.kind == MalFileKind.anime ? 'anime' : 'manga';
    lines.add('[MyAnimeList](https://myanimelist.net/$malPath/${entry.malId})');

    final String statusLabel = _statusLabel(entry.status);
    lines.add('Status: $statusLabel');

    if (entry.score != null) {
      lines.add('Score: ${entry.score}/10');
    }

    if (entry.tags != null) {
      final List<String> tagList = entry.tags!
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
      if (tagList.isNotEmpty) {
        lines.add('Tags: ${tagList.join(', ')}');
      }
    }

    if (entry.kind == MalFileKind.anime && entry.watchedEpisodes > 0) {
      lines.add('Watched: ${entry.watchedEpisodes} ep');
    }
    if (entry.kind == MalFileKind.manga &&
        (entry.readChapters > 0 || entry.readVolumes > 0)) {
      lines.add(
        'Read: ${entry.readChapters} ch / ${entry.readVolumes} vol',
      );
    }

    final String rewatchedLabel = entry.kind == MalFileKind.anime
        ? 'Rewatched times'
        : 'Reread times';
    lines.add('$rewatchedLabel: ${entry.timesWatched}');

    if (entry.comments != null) {
      lines.add('');
      lines.add(entry.comments!);
    }

    return lines.join('\n');
  }

  static String _statusLabel(ItemStatus status) {
    switch (status) {
      case ItemStatus.notStarted:
        return 'Not started';
      case ItemStatus.inProgress:
        return 'In progress';
      case ItemStatus.completed:
        return 'Completed';
      case ItemStatus.dropped:
        return 'Dropped';
      case ItemStatus.planned:
        return 'Planned';
    }
  }

  static int? _parseInt(String? raw) {
    if (raw == null) return null;
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    final String trimmed = raw.trim();
    // MAL uses '0000-00-00' as a sentinel for "no date".
    if (trimmed.isEmpty || trimmed == '0000-00-00') return null;
    try {
      final DateTime parsed = DateTime.parse(trimmed);
      // MAL dates have no timezone; treat as UTC to avoid local-shift drift.
      return DateTime.utc(parsed.year, parsed.month, parsed.day);
    } on FormatException {
      return null;
    }
  }

  static ItemStatus _mapStatus(String raw) {
    final String s = raw.toLowerCase().trim();
    switch (s) {
      case 'watching':
      case 'reading':
        return ItemStatus.inProgress;
      case 'completed':
        return ItemStatus.completed;
      case 'on-hold':
      case 'on hold':
        // MAL "on hold" has no direct equivalent; map to planned as closest intent.
        return ItemStatus.planned;
      case 'dropped':
        return ItemStatus.dropped;
      case 'plan to watch':
      case 'plan to read':
        return ItemStatus.planned;
      default:
        _log.warning('Unknown MAL status: "$raw" → notStarted');
        return ItemStatus.notStarted;
    }
  }
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

/// Converts [MalImportResult] to [UniversalImportResult].
extension MalImportResultToUniversal on MalImportResult {
  /// Maps to the universal result.
  UniversalImportResult toUniversal({Collection? collection}) {
    final Map<MediaType, int> importedByType = <MediaType, int>{};
    final Map<MediaType, int> wishlistedByType = <MediaType, int>{};
    final Map<MediaType, int> updatedByType = <MediaType, int>{};

    if (animeImported > 0) importedByType[MediaType.anime] = animeImported;
    if (mangaImported > 0) importedByType[MediaType.manga] = mangaImported;
    if (animeWishlisted > 0) {
      wishlistedByType[MediaType.anime] = animeWishlisted;
    }
    if (mangaWishlisted > 0) {
      wishlistedByType[MediaType.manga] = mangaWishlisted;
    }
    if (animeUpdated > 0) updatedByType[MediaType.anime] = animeUpdated;
    if (mangaUpdated > 0) updatedByType[MediaType.manga] = mangaUpdated;

    return UniversalImportResult(
      sourceName: 'MyAnimeList',
      success: true,
      collection: collection,
      collectionId: collectionId,
      importedByType: importedByType,
      wishlistedByType: wishlistedByType,
      updatedByType: updatedByType,
      skipped: (total - imported - wishlisted - updated).clamp(0, total),
    );
  }
}
