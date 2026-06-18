// Imports anime/manga from MyAnimeList XML export.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../data/repositories/wishlist_repository.dart';
import '../../../../shared/models/anime.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/item_status_logic.dart';
import '../../../../shared/models/manga.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/universal_import_result.dart';
import '../../../../shared/models/wishlist_tag.dart';
import '../../../api/anilist_api.dart';
import '../../../database/database_service.dart';
import '../../../services/import_service.dart';
import '../../import_columns.dart';
import '../../import_source.dart';
import '../../import_writer.dart';

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

  /// User score (1.0-10.0) or null.
  final double? score;

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
    repository: ref.watch(collectionRepositoryProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

class MalImportOptions extends ImportOptions {
  const MalImportOptions({
    this.animeFile,
    this.mangaFile,
    required this.author,
    required this.newCollectionName,
    this.overwriteExistingItems = false,
    super.collectionId,
  });

  final File? animeFile;
  final File? mangaFile;

  /// Author / name for a freshly created collection.
  final String author;
  final String newCollectionName;

  /// When `false` (default), entries already present in the target collection
  /// are left untouched (counted as skipped). When `true`, existing items are
  /// merged with MAL data (status priority, max progress, earliest/latest
  /// dates, MAL rating wins, MAL comment overwrites).
  final bool overwriteExistingItems;
}

/// MyAnimeList import on the shared import layer.
///
/// Parses MAL XML exports, resolves MAL ids to AniList media via a tolerant
/// batch lookup (the AniList API owns the rate-limit retry; this just relays its
/// progress), then writes everything through [ImportWriter] in one batch.
/// Unmatched titles fall back to the wishlist; entries whose lookup failed are
/// skipped so a later re-import can retry them.
class MalImportService implements ImportSource {
  MalImportService({
    required AniListApi aniListApi,
    required DatabaseService database,
    required CollectionRepository repository,
    required WishlistRepository wishlistRepository,
  })  : _aniList = aniListApi,
        _db = database,
        _writer = ImportWriter(
          collections: repository,
          wishlist: wishlistRepository,
        );

  static final Logger _log = Logger('MalImportService');

  final AniListApi _aniList;
  final DatabaseService _db;
  final ImportWriter _writer;

  @override
  String get displayName => 'MyAnimeList';

  /// Parses a MAL export XML file. Throws [FormatException] on invalid XML.
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

    return MalParsedFile(kind: kind, entries: entries, userName: userName);
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
    final double? score =
        (scoreRaw == null || scoreRaw <= 0) ? null : scoreRaw.toDouble();

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

    final String timesField =
        kind == MalFileKind.anime ? 'my_times_watched' : 'my_times_read';
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
      totalEpisodesXml:
          (totalEpisodes != null && totalEpisodes > 0) ? totalEpisodes : null,
      totalChaptersXml:
          (totalChapters != null && totalChapters > 0) ? totalChapters : null,
      totalVolumesXml:
          (totalVolumes != null && totalVolumes > 0) ? totalVolumes : null,
      startDate: startDate,
      finishDate: finishDate,
      tags: tags,
      timesWatched: timesWatched,
      comments: comments,
    );
  }

  @override
  Future<UniversalImportResult> import(
    covariant MalImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    if (options.animeFile == null && options.mangaFile == null) {
      throw ArgumentError('At least one file (anime or manga) must be provided');
    }

    onProgress?.call(const ImportProgress(
      stage: ImportStage.reading,
      current: 0,
      total: 0,
    ));

    MalParsedFile? animeParsed;
    MalParsedFile? mangaParsed;
    if (options.animeFile != null) {
      animeParsed = await parseFile(options.animeFile!);
      if (animeParsed.kind != MalFileKind.anime) {
        throw const FormatException('Anime file does not contain anime entries');
      }
    }
    if (options.mangaFile != null) {
      mangaParsed = await parseFile(options.mangaFile!);
      if (mangaParsed.kind != MalFileKind.manga) {
        throw const FormatException('Manga file does not contain manga entries');
      }
    }

    final List<MalEntry> animeEntries = animeParsed?.entries ?? <MalEntry>[];
    final List<MalEntry> mangaEntries = mangaParsed?.entries ?? <MalEntry>[];
    final int totalEntries = animeEntries.length + mangaEntries.length;
    if (totalEntries == 0) {
      throw const FormatException('No entries found in MAL export');
    }

    // One auto-tag per import run, stamped on every unmatched entry so the user
    // can later filter or wipe this whole batch from the wishlist.
    final String importTag = buildImportTag('MyAnimeList');

    final Map<int, Anime> animeByMal = <int, Anime>{};
    final Set<int> animeFailedIds = <int>{};
    if (animeEntries.isNotEmpty) {
      final int totalAnime = animeEntries.length;
      int lastDone = 0;
      final AniListMalLookupResult<Anime> result =
          await _aniList.getAnimeByMalIdsTolerant(
        animeEntries.map((MalEntry e) => e.malId).toList(),
        onRateLimit: (Duration wait, int attempt) => onProgress?.call(
          ImportProgress(
            stage: ImportStage.fetchingAnime,
            current: lastDone,
            total: totalAnime,
            retryWaitSeconds: wait.inSeconds,
            retryAttempt: attempt,
            retryMaxAttempts: AniListApi.maxRateLimitRetries,
          ),
        ),
        onBatchProgress: (int done, int total) {
          lastDone = done;
          onProgress?.call(ImportProgress(
            stage: ImportStage.fetchingAnime,
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
      final int totalManga = mangaEntries.length;
      int lastDone = 0;
      final AniListMalLookupResult<Manga> result =
          await _aniList.getMangaByMalIdsTolerant(
        mangaEntries.map((MalEntry e) => e.malId).toList(),
        onRateLimit: (Duration wait, int attempt) => onProgress?.call(
          ImportProgress(
            stage: ImportStage.fetchingManga,
            current: lastDone,
            total: totalManga,
            retryWaitSeconds: wait.inSeconds,
            retryAttempt: attempt,
            retryMaxAttempts: AniListApi.maxRateLimitRetries,
          ),
        ),
        onBatchProgress: (int done, int total) {
          lastDone = done;
          onProgress?.call(ImportProgress(
            stage: ImportStage.fetchingManga,
            current: done,
            total: total,
          ));
        },
      );
      mangaByMal.addAll(result.resolved);
      mangaFailedIds.addAll(result.failedIds);
    }

    if (animeByMal.isNotEmpty) {
      await _db.animeDao.upsertAnimes(animeByMal.values.toList());
    }
    if (mangaByMal.isNotEmpty) {
      await _db.mangaDao.upsertMangas(mangaByMal.values.toList());
    }

    // Create the collection only after parsing/resolving to avoid empty leftovers.
    final Collection? collection = await _writer.resolveCollection(
      collectionId: options.collectionId,
      newCollectionName: options.newCollectionName,
      author: options.author,
    );
    if (collection == null) {
      return const UniversalImportResult.failure(
        sourceName: 'MyAnimeList',
        error: 'Collection not found',
      );
    }

    onProgress?.call(ImportProgress(
      stage: ImportStage.addingItems,
      current: 0,
      total: totalEntries,
    ));

    final List<MalEntry> allEntries = <MalEntry>[
      ...animeEntries,
      ...mangaEntries,
    ];
    final List<ImportCandidate> candidates = <ImportCandidate>[];
    final List<WishlistCandidate> wishlist = <WishlistCandidate>[];

    for (final MalEntry entry in allEntries) {
      final bool lookupFailed = entry.kind == MalFileKind.anime
          ? animeFailedIds.contains(entry.malId)
          : mangaFailedIds.contains(entry.malId);
      if (lookupFailed) {
        // Skip — re-running the import retries these once AniList is reachable.
        continue;
      }

      final MediaType mediaType = entry.kind == MalFileKind.anime
          ? MediaType.anime
          : MediaType.manga;
      final int? aniListId = entry.kind == MalFileKind.anime
          ? animeByMal[entry.malId]?.id
          : mangaByMal[entry.malId]?.id;

      if (aniListId == null) {
        wishlist.add(WishlistCandidate(
          text: entry.title,
          mediaType: mediaType,
          note: _buildWishlistNote(entry),
        ));
        continue;
      }

      candidates.add(_candidate(
        entry,
        aniListId,
        mediaType,
        anime: animeByMal[entry.malId],
        manga: mangaByMal[entry.malId],
        overwrite: options.overwriteExistingItems,
      ));
    }

    final int wishlistCount = wishlist.length;
    final ImportWriteResult write = await _writer.writeItems(
      collectionId: collection.id,
      candidates: candidates,
      onItem: (int processed, int total, int imported, int updated,
          String? label) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: processed,
          total: total,
          currentItem: label,
          imported: imported,
          updated: updated,
          wishlisted: wishlistCount,
        ));
      },
    );
    final Map<MediaType, int> wishlistedByType = await _writer.writeWishlist(
      entries: wishlist,
      tag: importTag,
    );

    final int imported = sumByType(write.importedByType);
    final int updated = sumByType(write.updatedByType);
    final int wishlisted = sumByType(wishlistedByType);
    final int skipped =
        (totalEntries - imported - updated - wishlisted).clamp(0, totalEntries);

    onProgress?.call(ImportProgress(
      stage: ImportStage.completed,
      current: 1,
      total: 1,
      imported: imported,
      updated: updated,
      wishlisted: wishlisted,
    ));

    _log.info(
      'MAL import complete: $imported imported, $wishlisted wishlisted, '
      '$updated updated, $skipped skipped (total $totalEntries)',
    );

    return UniversalImportResult(
      sourceName: 'MyAnimeList',
      success: true,
      collection: collection,
      importedByType: write.importedByType,
      updatedByType: write.updatedByType,
      wishlistedByType: wishlistedByType,
      skipped: skipped,
    );
  }

  ImportCandidate _candidate(
    MalEntry entry,
    int aniListId,
    MediaType mediaType, {
    Anime? anime,
    Manga? manga,
    required bool overwrite,
  }) {
    return ImportCandidate(
      mediaType: mediaType,
      externalId: aniListId,
      platformId: null,
      label: entry.title,
      insertRow:
          _insertRow(entry, aniListId, mediaType, anime: anime, manga: manga),
      changedFields: (CollectionItem existing) => overwrite
          ? _changedFields(entry, existing, anime: anime, manga: manga)
          : const <String, dynamic>{},
    );
  }

  Map<String, dynamic> _insertRow(
    MalEntry entry,
    int aniListId,
    MediaType mediaType, {
    Anime? anime,
    Manga? manga,
  }) {
    final _ResolvedProgress progress =
        _resolveProgress(entry, aniListAnime: anime, aniListManga: manga);
    final _ResolvedDates dates = _resolveDates(entry);
    final String comment = _buildUserComment(entry);
    return <String, dynamic>{
      'media_type': mediaType.value,
      'external_id': aniListId,
      'status': entry.status.value,
      if (progress.currentEpisode > 0)
        'current_episode': progress.currentEpisode,
      if (progress.currentSeason > 0) 'current_season': progress.currentSeason,
      'user_rating': ?entry.score,
      'started_at': ?epochSeconds(dates.startedAt),
      'completed_at': ?epochSeconds(dates.completedAt),
      'last_activity_at': ?epochSeconds(dates.lastActivityAt),
      if (comment.isNotEmpty) 'user_comment': comment,
    };
  }

  /// Overwrite-mode re-sync: bump status without downgrading, keep max
  /// progress, keep earliest start / latest completion, MAL rating wins, MAL
  /// comment overwrites.
  Map<String, dynamic> _changedFields(
    MalEntry entry,
    CollectionItem existing, {
    Anime? anime,
    Manga? manga,
  }) {
    final Map<String, dynamic> fields = <String, dynamic>{};

    final ItemStatus? newStatus = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: entry.status,
    );
    if (newStatus != null) {
      fields.addAll(statusDateColumns(newStatus, existing));
    }

    final _ResolvedProgress malProgress =
        _resolveProgress(entry, aniListAnime: anime, aniListManga: manga);
    final int newEpisode = malProgress.currentEpisode > existing.currentEpisode
        ? malProgress.currentEpisode
        : existing.currentEpisode;
    final int newSeason = malProgress.currentSeason > existing.currentSeason
        ? malProgress.currentSeason
        : existing.currentSeason;
    if (newEpisode != existing.currentEpisode ||
        newSeason != existing.currentSeason) {
      if (newEpisode > 0) fields['current_episode'] = newEpisode;
      if (newSeason > 0) fields['current_season'] = newSeason;
    }

    if (entry.score != null && entry.score != existing.userRating) {
      fields['user_rating'] = entry.score;
    }

    final _ResolvedDates malDates = _resolveDates(entry);
    DateTime? newStarted = existing.startedAt;
    DateTime? newCompleted = existing.completedAt;
    if (malDates.startedAt != null &&
        (newStarted == null || malDates.startedAt!.isBefore(newStarted))) {
      newStarted = malDates.startedAt;
    }
    if (malDates.completedAt != null &&
        (newCompleted == null || malDates.completedAt!.isAfter(newCompleted))) {
      newCompleted = malDates.completedAt;
    }
    if (newStarted != existing.startedAt ||
        newCompleted != existing.completedAt) {
      if (newStarted != null) fields['started_at'] = epochSeconds(newStarted);
      if (newCompleted != null) {
        fields['completed_at'] = epochSeconds(newCompleted);
      }
      fields['last_activity_at'] = epochSeconds(DateTime.now());
    }

    final String comment = _buildUserComment(entry);
    if (comment.isNotEmpty) fields['user_comment'] = comment;

    return fields;
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
        final int chaps = aniListManga?.chapters ?? entry.totalChaptersXml ?? 0;
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

    final String malPath = entry.kind == MalFileKind.anime ? 'anime' : 'manga';
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

    final String malPath = entry.kind == MalFileKind.anime ? 'anime' : 'manga';
    lines.add('[MyAnimeList](https://myanimelist.net/$malPath/${entry.malId})');

    lines.add('Status: ${_statusLabel(entry.status)}');

    if (entry.score != null) {
      lines.add('Score: ${entry.score!.toStringAsFixed(0)}/10');
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
      lines.add('Read: ${entry.readChapters} ch / ${entry.readVolumes} vol');
    }

    final String rewatchedLabel =
        entry.kind == MalFileKind.anime ? 'Rewatched times' : 'Reread times';
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
