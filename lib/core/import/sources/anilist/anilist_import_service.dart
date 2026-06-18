// Imports anime/manga from a public AniList user list via GraphQL.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

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
import '../../../api/anilist_api.dart';
import '../../../database/database_service.dart';
import '../../../services/import_service.dart';
import '../../import_columns.dart';
import '../../import_source.dart';
import '../../import_writer.dart';

/// Import behavior when a matching item already exists in the collection.
enum ImportMode {
  /// Skip existing items, add only new ones.
  newOnly,

  /// Overwrite fields on existing items with remote values.
  overwrite,
}

/// Provider for [AniListImportService].
final Provider<AniListImportService> aniListImportServiceProvider =
    Provider<AniListImportService>((Ref ref) {
  return AniListImportService(
    aniListApi: ref.watch(aniListApiProvider),
    database: ref.watch(databaseServiceProvider),
    repository: ref.watch(collectionRepositoryProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

class AniListImportOptions extends ImportOptions {
  const AniListImportOptions({
    required this.userName,
    required this.mode,
    required this.author,
    required this.newCollectionName,
    this.includeAnime = true,
    this.includeManga = true,
    super.collectionId,
  });

  final String userName;
  final ImportMode mode;

  /// Author / name for a freshly created collection.
  final String author;
  final String newCollectionName;

  final bool includeAnime;
  final bool includeManga;
}

/// AniList import on the shared import layer.
///
/// Fetches public user lists for anime and manga via GraphQL (no OAuth) and
/// writes them through [ImportWriter] in one batch. AniList rows already carry
/// AniList ids, so there is no title search and no wishlist fallback. Hard
/// errors (unknown user, private profile, API failure) are thrown so the UI can
/// localize them.
class AniListImportService implements ImportSource {
  AniListImportService({
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

  static final Logger _log = Logger('AniListImportService');

  final AniListApi _aniList;
  final DatabaseService _db;
  final ImportWriter _writer;

  @override
  String get displayName => 'AniList';

  /// Throws [AniListUserNotFoundException] / [AniListPrivateProfileException] /
  /// [AniListApiException] when the AniList API call fails, [FormatException]
  /// when the lists are empty, and [ArgumentError] when nothing is selected.
  @override
  Future<UniversalImportResult> import(
    covariant AniListImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    if (!options.includeAnime && !options.includeManga) {
      throw ArgumentError(
        'At least one of includeAnime / includeManga must be true',
      );
    }

    List<AniListListEntry> animeEntries = <AniListListEntry>[];
    List<AniListListEntry> mangaEntries = <AniListListEntry>[];

    if (options.includeAnime) {
      onProgress?.call(const ImportProgress(
        stage: ImportStage.fetchingAnime,
        current: 0,
        total: 0,
      ));
      animeEntries = await _aniList.fetchUserMediaList(
        userName: options.userName,
        type: MediaType.anime,
      );
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingAnime,
        current: animeEntries.length,
        total: animeEntries.length,
      ));
    }

    if (options.includeManga) {
      onProgress?.call(const ImportProgress(
        stage: ImportStage.fetchingManga,
        current: 0,
        total: 0,
      ));
      mangaEntries = await _aniList.fetchUserMediaList(
        userName: options.userName,
        type: MediaType.manga,
      );
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingManga,
        current: mangaEntries.length,
        total: mangaEntries.length,
      ));
    }

    final int totalEntries = animeEntries.length + mangaEntries.length;
    if (totalEntries == 0) {
      throw const FormatException('No entries found in AniList lists');
    }

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

    // Create the collection only after a successful fetch.
    final Collection? collection = await _writer.resolveCollection(
      collectionId: options.collectionId,
      newCollectionName: options.newCollectionName,
      author: options.author,
    );
    if (collection == null) {
      return const UniversalImportResult.failure(
        sourceName: 'AniList',
        error: 'Collection not found',
      );
    }

    onProgress?.call(ImportProgress(
      stage: ImportStage.addingItems,
      current: 0,
      total: totalEntries,
    ));

    final List<AniListListEntry> allEntries = <AniListListEntry>[
      ...animeEntries,
      ...mangaEntries,
    ];
    final ImportWriteResult write = await _writer.writeItems(
      collectionId: collection.id,
      candidates: <ImportCandidate>[
        for (final AniListListEntry entry in allEntries)
          _candidate(entry, options.mode),
      ],
      onItem: (int processed, int total, int imported, int updated,
          String? label) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: processed,
          total: total,
          currentItem: label,
          imported: imported,
          updated: updated,
        ));
      },
    );

    onProgress?.call(ImportProgress(
      stage: ImportStage.completed,
      current: 1,
      total: 1,
      imported: sumByType(write.importedByType),
      updated: sumByType(write.updatedByType),
    ));

    _log.info(
      'AniList import complete for "${options.userName}": '
      'imported ${write.importedByType}, updated ${write.updatedByType} '
      '(total $totalEntries)',
    );

    return UniversalImportResult(
      sourceName: 'AniList',
      success: true,
      collection: collection,
      importedByType: write.importedByType,
      updatedByType: write.updatedByType,
      skipped: write.skipped,
    );
  }

  ImportCandidate _candidate(AniListListEntry entry, ImportMode mode) {
    final ItemStatus status = _mapStatus(entry.rawStatus);
    return ImportCandidate(
      mediaType: entry.mediaType,
      externalId: entry.mediaId,
      platformId: null,
      label: entry.anime?.title ?? entry.manga?.title ?? '#${entry.mediaId}',
      insertRow: _insertRow(entry, status),
      changedFields: (CollectionItem existing) => mode == ImportMode.newOnly
          ? const <String, dynamic>{}
          : _changedFields(entry, existing),
    );
  }

  Map<String, dynamic> _insertRow(AniListListEntry entry, ItemStatus status) {
    final _ResolvedProgress progress = _resolveProgress(entry, status);
    final double? rating = _resolveRating(entry.scoreRaw100);
    final _ResolvedDates dates = _resolveDates(entry, status);
    final String comment = _buildUserComment(entry);
    return <String, dynamic>{
      'media_type': entry.mediaType.value,
      'external_id': entry.mediaId,
      'status': status.value,
      if (progress.currentEpisode > 0)
        'current_episode': progress.currentEpisode,
      if (progress.currentSeason > 0) 'current_season': progress.currentSeason,
      'user_rating': ?rating,
      'started_at': ?epochSeconds(dates.startedAt),
      'completed_at': ?epochSeconds(dates.completedAt),
      'last_activity_at': ?epochSeconds(dates.lastActivityAt),
      if (comment.isNotEmpty) 'user_comment': comment,
    };
  }

  /// Overwrite-mode re-sync: bump status without downgrading, keep max progress,
  /// keep earliest start / latest completion, refresh rating and comment.
  Map<String, dynamic> _changedFields(
    AniListListEntry entry,
    CollectionItem existing,
  ) {
    final ItemStatus status = _mapStatus(entry.rawStatus);
    final Map<String, dynamic> fields = <String, dynamic>{};

    final ItemStatus? newStatus = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: status,
    );
    if (newStatus != null) {
      fields.addAll(statusDateColumns(newStatus, existing));
    }

    final _ResolvedProgress remote = _resolveProgress(entry, status);
    final int newEpisode = remote.currentEpisode > existing.currentEpisode
        ? remote.currentEpisode
        : existing.currentEpisode;
    final int newSeason = remote.currentSeason > existing.currentSeason
        ? remote.currentSeason
        : existing.currentSeason;
    if (newEpisode != existing.currentEpisode ||
        newSeason != existing.currentSeason) {
      if (newEpisode > 0) fields['current_episode'] = newEpisode;
      if (newSeason > 0) fields['current_season'] = newSeason;
    }

    final double? rating = _resolveRating(entry.scoreRaw100);
    if (rating != null && rating != existing.userRating) {
      fields['user_rating'] = rating;
    }

    final _ResolvedDates remoteDates = _resolveDates(entry, status);
    DateTime? newStarted = existing.startedAt;
    DateTime? newCompleted = existing.completedAt;
    if (remoteDates.startedAt != null &&
        (newStarted == null || remoteDates.startedAt!.isBefore(newStarted))) {
      newStarted = remoteDates.startedAt;
    }
    if (remoteDates.completedAt != null &&
        (newCompleted == null ||
            remoteDates.completedAt!.isAfter(newCompleted))) {
      newCompleted = remoteDates.completedAt;
    }
    if (newStarted != existing.startedAt ||
        newCompleted != existing.completedAt) {
      if (newStarted != null) fields['started_at'] = epochSeconds(newStarted);
      if (newCompleted != null) {
        fields['completed_at'] = epochSeconds(newCompleted);
      }
      fields['last_activity_at'] =
          epochSeconds(entry.updatedAt ?? DateTime.now());
    }

    final String comment = _buildUserComment(entry);
    if (comment.isNotEmpty) fields['user_comment'] = comment;

    return fields;
  }

  _ResolvedProgress _resolveProgress(
    AniListListEntry entry,
    ItemStatus status,
  ) {
    int currentEpisode = entry.progress;
    int currentSeason =
        entry.mediaType == MediaType.manga ? entry.progressVolumes : 0;

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
