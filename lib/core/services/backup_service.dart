import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/calendar_entry.dart';
import '../../shared/models/mood_grid.dart';
import '../../shared/models/mood_grid_cell.dart';
import '../../shared/models/tracked_release.dart';
import '../../shared/models/wishlist_item.dart';
import '../../shared/models/tracker_game_data.dart';
import '../../shared/models/tracker_profile.dart';
import '../database/dao/mood_grid_dao.dart';
import '../database/dao/tracker_dao.dart';
import '../database/database_service.dart';
import 'config_service.dart';
import 'export_service.dart';
import 'import_service.dart';
import 'xcoll_file.dart';

const int backupFormatVersion = 3;

final Provider<BackupService> backupServiceProvider =
    Provider<BackupService>((Ref ref) {
  return BackupService(
    database: ref.watch(databaseServiceProvider),
    exportService: ref.watch(exportServiceProvider),
    importService: ref.watch(importServiceProvider),
    configService: ref.watch(configServiceProvider),
    collectionRepo: ref.watch(collectionRepositoryProvider),
    wishlistRepo: ref.watch(wishlistRepositoryProvider),
    trackerDao: ref.watch(trackerDaoProvider),
    moodGridDao: ref.watch(moodGridDaoProvider),
  );
});

/// `true` while a restore is mid-flight. Read by the app shell to block
/// `AppLifecycleListener.onExitRequested` so a desktop user can't close the
/// window while SQLite is still writing.
final StateProvider<bool> restoreInProgressProvider =
    StateProvider<bool>((Ref ref) => false);

typedef BackupProgressCallback = void Function(BackupProgress progress);

class BackupProgress {
  const BackupProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.collectionName,
  });

  final String stage;

  final int current;

  final int total;

  final String? collectionName;
}

class BackupResult {
  const BackupResult({
    required this.success,
    this.filePath,
    this.error,
    this.collectionsCount = 0,
    this.itemsCount = 0,
  });

  const BackupResult.success(
    String path, {
    int collections = 0,
    int items = 0,
  })  : success = true,
        filePath = path,
        error = null,
        collectionsCount = collections,
        itemsCount = items;

  const BackupResult.failure(String message)
      : success = false,
        filePath = null,
        error = message,
        collectionsCount = 0,
        itemsCount = 0;

  const BackupResult.cancelled()
      : success = false,
        filePath = null,
        error = null,
        collectionsCount = 0,
        itemsCount = 0;

  final bool success;

  final String? filePath;

  final String? error;

  final int collectionsCount;

  final int itemsCount;

  /// Cancelled = not successful but with no error message.
  bool get isCancelled => !success && error == null;
}

class RestoreResult {
  const RestoreResult({
    required this.success,
    this.error,
    this.collectionsRestored = 0,
    this.itemsRestored = 0,
    this.wishlistRestored = 0,
    this.settingsRestored = false,
  });

  const RestoreResult.success({
    int collections = 0,
    int items = 0,
    int wishlist = 0,
    bool settings = false,
  })  : success = true,
        error = null,
        collectionsRestored = collections,
        itemsRestored = items,
        wishlistRestored = wishlist,
        settingsRestored = settings;

  const RestoreResult.failure(String message)
      : success = false,
        error = message,
        collectionsRestored = 0,
        itemsRestored = 0,
        wishlistRestored = 0,
        settingsRestored = false;

  const RestoreResult.cancelled()
      : success = false,
        error = null,
        collectionsRestored = 0,
        itemsRestored = 0,
        wishlistRestored = 0,
        settingsRestored = false;

  final bool success;

  final String? error;

  final int collectionsRestored;

  final int itemsRestored;

  final int wishlistRestored;

  final bool settingsRestored;

  /// Cancelled = not successful but with no error message.
  bool get isCancelled => !success && error == null;
}

/// ZIP backup metadata, read from manifest.json.
class BackupManifest {
  const BackupManifest({
    required this.version,
    required this.created,
    required this.collectionsCount,
    required this.itemsCount,
    required this.wishlistCount,
    required this.includesConfig,
    this.profileName,
    this.appVersion,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      version: json['version'] as int? ?? 1,
      created: DateTime.parse(json['created'] as String),
      collectionsCount: json['collections_count'] as int? ?? 0,
      itemsCount: json['items_count'] as int? ?? 0,
      wishlistCount: json['wishlist_count'] as int? ?? 0,
      includesConfig: json['includes_config'] as bool? ?? false,
      profileName: json['profile_name'] as String?,
      appVersion: json['app_version'] as String?,
    );
  }

  final int version;

  final DateTime created;

  final int collectionsCount;

  final int itemsCount;

  final int wishlistCount;

  final bool includesConfig;

  final String? profileName;

  final String? appVersion;
}

/// Full backup and restore of app data.
///
/// Builds a ZIP archive with all collections (full export + user data),
/// the wishlist and settings, restorable in a single operation.
class BackupService {
  BackupService({
    required DatabaseService database,
    required ExportService exportService,
    required ImportService importService,
    required ConfigService configService,
    required CollectionRepository collectionRepo,
    required WishlistRepository wishlistRepo,
    TrackerDao? trackerDao,
    MoodGridDao? moodGridDao,
  })  : _database = database,
        _exportService = exportService,
        _importService = importService,
        _configService = configService,
        _collectionRepo = collectionRepo,
        _wishlistRepo = wishlistRepo,
        _trackerDao = trackerDao,
        _moodGridDao = moodGridDao;

  static final Logger _log = Logger('BackupService');

  final DatabaseService _database;
  final ExportService _exportService;
  final ImportService _importService;
  final ConfigService _configService;
  final CollectionRepository _collectionRepo;
  final TrackerDao? _trackerDao;
  final MoodGridDao? _moodGridDao;
  final WishlistRepository _wishlistRepo;

  /// Creates a full backup of all data and saves it as a ZIP.
  Future<BackupResult> createBackup({
    BackupProgressCallback? onProgress,
  }) async {
    try {
      // 1. All collections.
      final List<Collection> collections = await _collectionRepo.getAll();

      // 2. Full export of each collection.
      final Archive archive = Archive();
      int totalItems = 0;

      for (int i = 0; i < collections.length; i++) {
        final Collection collection = collections[i];
        onProgress?.call(BackupProgress(
          stage: 'collections',
          current: i,
          total: collections.length,
          collectionName: collection.name,
        ));

        final List<CollectionItem> items =
            await _collectionRepo.getItemsWithData(collection.id);
        totalItems += items.length;

        final XcollFile xcoll = await _exportService.createFullExport(
          collection,
          items,
          collection.id,
          includeUserData: true,
        );

        final String json = xcoll.toJsonString();
        final List<int> jsonBytes = utf8.encode(json);
        final String fileName = _collectionFileName(i, collection.name);
        archive.addFile(ArchiveFile(
          'collections/$fileName',
          jsonBytes.length,
          jsonBytes,
        ));
      }

      // 3. Wishlist.
      onProgress?.call(const BackupProgress(
        stage: 'wishlist',
        current: 0,
        total: 1,
      ));

      final List<WishlistItem> wishlistItems =
          await _wishlistRepo.getAll(includeResolved: true);
      final List<Map<String, dynamic>> wishlistJson = wishlistItems
          .map((WishlistItem item) => _wishlistItemToExport(item))
          .toList();
      final String wishlistStr =
          const JsonEncoder.withIndent('  ').convert(wishlistJson);
      final List<int> wishlistBytes = utf8.encode(wishlistStr);
      archive.addFile(ArchiveFile(
        'wishlist.json',
        wishlistBytes.length,
        wishlistBytes,
      ));

      // 4. Tracker data (RA, Steam profiles + game data)
      if (_trackerDao != null) {
        final List<TrackerProfile> profiles =
            await _trackerDao.getAllProfiles();
        final List<TrackerGameData> gameData = <TrackerGameData>[];
        for (final TrackerProfile p in profiles) {
          gameData.addAll(
            await _trackerDao.getAllGameData(p.trackerType),
          );
        }
        if (profiles.isNotEmpty || gameData.isNotEmpty) {
          final Map<String, dynamic> trackerExport = <String, dynamic>{
            'profiles': profiles.map(
              (TrackerProfile p) => p.toDb(),
            ).toList(),
            'game_data': gameData.map(
              (TrackerGameData d) => d.toDb(),
            ).toList(),
          };
          final String trackerStr =
              const JsonEncoder.withIndent('  ').convert(trackerExport);
          final List<int> trackerBytes = utf8.encode(trackerStr);
          archive.addFile(ArchiveFile(
            'tracker_data.json',
            trackerBytes.length,
            trackerBytes,
          ));
        }
      }

      // 5. Mood grids — visual award grids, not bound to any collection.
      if (_moodGridDao != null) {
        final List<MoodGrid> grids = await _moodGridDao.getAllMoodGrids();
        if (grids.isNotEmpty) {
          final List<Map<String, dynamic>> moodGridsExport =
              <Map<String, dynamic>>[];
          for (final MoodGrid grid in grids) {
            final List<MoodGridCell> cells =
                await _moodGridDao.getCells(grid.id);
            final Map<String, dynamic> entry = grid.toExport();
            entry['cells'] = cells
                .map((MoodGridCell c) => c.toExport())
                .toList();
            moodGridsExport.add(entry);
          }
          final String moodGridsStr = const JsonEncoder.withIndent('  ')
              .convert(moodGridsExport);
          final List<int> moodGridsBytes = utf8.encode(moodGridsStr);
          archive.addFile(ArchiveFile(
            'mood_grids.json',
            moodGridsBytes.length,
            moodGridsBytes,
          ));
        }
      }

      // 6. Calendar — release subscriptions and manual calendar entries.
      // Both are keyed by item identity, independent of collections.
      final List<TrackedRelease> trackedReleases =
          await _database.trackedReleaseDao.getAll();
      final List<CalendarEntry> calendarEntries =
          await _database.calendarEntryDao.getAll();
      if (trackedReleases.isNotEmpty || calendarEntries.isNotEmpty) {
        final Map<String, dynamic> calendarJson = <String, dynamic>{
          'tracked_releases': trackedReleases
              .map((TrackedRelease t) => t.toDb())
              .toList(),
          'calendar_entries':
              calendarEntries.map((CalendarEntry e) => e.toDb()).toList(),
        };
        final List<int> calendarBytes = utf8.encode(
          const JsonEncoder.withIndent('  ').convert(calendarJson),
        );
        archive.addFile(ArchiveFile(
          'calendar.json',
          calendarBytes.length,
          calendarBytes,
        ));
      }

      // 6b. Watch progress — aggregated by show (collection-agnostic), so it
      // restores onto whichever collections later hold the show.
      final List<Map<String, Object?>> watched =
          await _database.tvShowDao.getAllWatchedEpisodes();
      if (watched.isNotEmpty) {
        final List<int> watchedBytes = utf8.encode(
          const JsonEncoder.withIndent('  ').convert(watched),
        );
        archive.addFile(ArchiveFile(
          'watched_episodes.json',
          watchedBytes.length,
          watchedBytes,
        ));
      }

      // 7. Settings.
      final Map<String, Object> config = _configService.collectSettings();
      final String configStr =
          const JsonEncoder.withIndent('  ').convert(config);
      final List<int> configBytes = utf8.encode(configStr);
      archive.addFile(ArchiveFile(
        'config.json',
        configBytes.length,
        configBytes,
      ));

      // 8. Manifest.
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String appVersion = packageInfo.version;
      final Map<String, dynamic> manifest = <String, dynamic>{
        'version': backupFormatVersion,
        'created': DateTime.now().toUtc().toIso8601String(),
        'collections_count': collections.length,
        'items_count': totalItems,
        'wishlist_count': wishlistItems.length,
        'includes_config': true,
        'app_version': appVersion,
      };
      final String manifestStr =
          const JsonEncoder.withIndent('  ').convert(manifest);
      final List<int> manifestBytes = utf8.encode(manifestStr);
      archive.addFile(ArchiveFile(
        'manifest.json',
        manifestBytes.length,
        manifestBytes,
      ));

      // 9. Encode the ZIP.
      onProgress?.call(BackupProgress(
        stage: 'saving',
        current: collections.length,
        total: collections.length,
      ));

      final List<int> zipBytes = ZipEncoder().encode(archive);

      // 10. Save the file.
      final String dateSuffix = _dateSuffix();
      final bool useAny = Platform.isAndroid || Platform.isIOS;
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: 'tonkatsu-backup-v$appVersion-$dateSuffix.zip',
        type: useAny ? FileType.any : FileType.custom,
        allowedExtensions: useAny ? null : <String>['zip'],
        bytes: Uint8List.fromList(zipBytes),
      );

      if (outputPath == null) {
        return const BackupResult.cancelled();
      }

      // On desktop the file must be written manually (mobile uses SAF).
      if (!Platform.isAndroid && !Platform.isIOS) {
        final String finalPath =
            outputPath.endsWith('.zip') ? outputPath : '$outputPath.zip';
        final File file = File(finalPath);
        await file.writeAsBytes(zipBytes);
        return BackupResult.success(
          finalPath,
          collections: collections.length,
          items: totalItems,
        );
      }

      return BackupResult.success(
        outputPath,
        collections: collections.length,
        items: totalItems,
      );
    } on FileSystemException catch (e) {
      return BackupResult.failure('Failed to save backup: ${e.message}');
    } catch (e) {
      _log.warning('Backup failed', e);
      return BackupResult.failure('Backup failed: $e');
    }
  }

  /// Reads the manifest from a ZIP backup without importing anything.
  Future<BackupManifest?> readManifest(String zipPath) async {
    try {
      final List<int> bytes = File(zipPath).readAsBytesSync();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      for (final ArchiveFile file in archive) {
        if (file.name == 'manifest.json' && file.isFile) {
          final String content = utf8.decode(file.content as List<int>);
          final Map<String, dynamic> json =
              jsonDecode(content) as Map<String, dynamic>;
          return BackupManifest.fromJson(json);
        }
      }

      return null;
    } catch (e) {
      _log.warning('Failed to read manifest', e);
      return null;
    }
  }

  Future<RestoreResult> restoreFromBackup({
    required String zipPath,
    bool restoreSettings = false,
    bool restoreWishlist = true,
    BackupProgressCallback? onProgress,
  }) async {
    try {
      final List<int> bytes = File(zipPath).readAsBytesSync();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      final Map<String, String> collectionFiles = <String, String>{};
      String? wishlistContent;
      String? configContent;
      String? trackerContent;
      String? moodGridsContent;
      String? calendarContent;
      String? watchedContent;

      for (final ArchiveFile file in archive) {
        if (!file.isFile) continue;
        final String content = utf8.decode(file.content as List<int>);

        if (file.name.startsWith('collections/') &&
            file.name.endsWith('.xcollx')) {
          collectionFiles[file.name] = content;
        } else if (file.name == 'wishlist.json') {
          wishlistContent = content;
        } else if (file.name == 'config.json') {
          configContent = content;
        } else if (file.name == 'tracker_data.json') {
          trackerContent = content;
        } else if (file.name == 'mood_grids.json') {
          moodGridsContent = content;
        } else if (file.name == 'calendar.json') {
          calendarContent = content;
        } else if (file.name == 'watched_episodes.json') {
          watchedContent = content;
        }
      }

      int collectionsRestored = 0;
      int itemsRestored = 0;
      final List<String> sortedKeys = collectionFiles.keys.toList()..sort();

      for (int i = 0; i < sortedKeys.length; i++) {
        final String fileName = sortedKeys[i];
        final String content = collectionFiles[fileName]!;

        // Reported BEFORE work: progress shows "starting item i+1 of N" so
        // the UI never claims completion while a write is still in flight.
        String? collectionName;
        try {
          final XcollFile xcoll = XcollFile.fromJsonString(content);
          collectionName = xcoll.name;
          onProgress?.call(BackupProgress(
            stage: 'collections',
            current: i,
            total: sortedKeys.length,
            collectionName: collectionName,
          ));

          final ImportResult result =
              await _importService.importFromXcoll(xcoll);
          if (result.success) {
            collectionsRestored++;
            itemsRestored += result.itemsImported ?? 0;
          }
        } catch (e) {
          _log.warning('Failed to import $fileName', e);
        }

        // Post-work progress: now i+1 is fully durable.
        onProgress?.call(BackupProgress(
          stage: 'collections',
          current: i + 1,
          total: sortedKeys.length,
          collectionName: collectionName,
        ));
      }

      int wishlistRestored = 0;
      if (restoreWishlist && wishlistContent != null) {
        onProgress?.call(const BackupProgress(
          stage: 'wishlist',
          current: 0,
          total: 1,
        ));
        wishlistRestored = await _restoreWishlist(wishlistContent);
      }

      bool settingsApplied = false;
      if (restoreSettings && configContent != null) {
        onProgress?.call(const BackupProgress(
          stage: 'settings',
          current: 0,
          total: 1,
        ));

        final Map<String, Object?> config =
            jsonDecode(configContent) as Map<String, Object?>;
        final int applied = await _configService.applySettings(config);
        settingsApplied = applied > 0;
      }

      if (trackerContent != null && _trackerDao != null) {
        try {
          await _restoreTrackerData(trackerContent);
        } catch (e) {
          _log.warning('Failed to restore tracker data', e);
        }
      }

      // Mood grids — created fresh; ids in the backup file are not preserved.
      if (moodGridsContent != null && _moodGridDao != null) {
        try {
          await _restoreMoodGrids(moodGridsContent);
        } catch (e) {
          _log.warning('Failed to restore mood grids', e);
        }
      }

      // Calendar — release subscriptions and manual entries, keyed by identity.
      if (calendarContent != null) {
        try {
          await _restoreCalendar(calendarContent);
        } catch (e) {
          _log.warning('Failed to restore calendar', e);
        }
      }

      // Watch progress — re-applied to the restored collections by show id.
      if (watchedContent != null) {
        try {
          await _restoreWatchedEpisodes(watchedContent);
        } catch (e) {
          _log.warning('Failed to restore watched episodes', e);
        }
      }

      // Anchor: callers can show a "still finishing up" banner. Reported
      // before returning so the UI never claims completion while the future
      // is still resolving (DB closes its journal between this point and
      // the actual return).
      onProgress?.call(const BackupProgress(
        stage: 'finalizing',
        current: 1,
        total: 1,
      ));

      // Force-flush WAL into the main DB file so a user deleting the
      // `-wal` sidecar afterwards can't lose tail-of-restore writes
      // (wishlist + mood grids land last and are the most exposed).
      try {
        final Database db = await _database.database;
        await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (e) {
        _log.warning('WAL checkpoint after restore failed', e);
      }

      return RestoreResult.success(
        collections: collectionsRestored,
        items: itemsRestored,
        wishlist: wishlistRestored,
        settings: settingsApplied,
      );
    } on ArchiveException {
      return const RestoreResult.failure('Invalid backup archive');
    } on FormatException catch (e) {
      return RestoreResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      _log.warning('Restore failed', e);
      return RestoreResult.failure('Restore failed: $e');
    }
  }

  Map<String, dynamic> _wishlistItemToExport(WishlistItem item) {
    return <String, dynamic>{
      'text': item.text,
      'media_type_hint': item.mediaTypeHint?.value,
      'note': item.note,
      'is_resolved': item.isResolved,
      'created_at': item.createdAt.millisecondsSinceEpoch ~/ 1000,
      'resolved_at': item.resolvedAt != null
          ? item.resolvedAt!.millisecondsSinceEpoch ~/ 1000
          : null,
      'tag': item.tag,
    };
  }

  /// Restores the wishlist from JSON, deduplicating by item text.
  Future<int> _restoreWishlist(String jsonContent) async {
    final List<dynamic> items = jsonDecode(jsonContent) as List<dynamic>;
    int restored = 0;

    for (final dynamic item in items) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      final String text = data['text'] as String;

      // Skip items whose text already exists unresolved.
      final WishlistItem? existing =
          await _wishlistRepo.findUnresolved(text);
      if (existing != null) continue;

      final String? mediaTypeHint = data['media_type_hint'] as String?;
      await _wishlistRepo.add(
        text: text,
        mediaTypeHint: mediaTypeHint != null
            ? MediaType.fromString(mediaTypeHint)
            : null,
        note: data['note'] as String?,
        tag: data['tag'] as String?,
      );
      restored++;
    }

    return restored;
  }

  String _collectionFileName(int index, String name) {
    final String sanitized = name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase();
    final String padded = '${index + 1}'.padLeft(3, '0');
    return '${padded}_$sanitized.xcollx';
  }

  Future<void> _restoreTrackerData(String jsonContent) async {
    final Map<String, dynamic> data =
        jsonDecode(jsonContent) as Map<String, dynamic>;

    final List<dynamic> profiles =
        data['profiles'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic p in profiles) {
      final TrackerProfile profile =
          TrackerProfile.fromDb(p as Map<String, dynamic>);
      await _trackerDao!.upsertProfile(profile);
    }

    final List<dynamic> gameDataList =
        data['game_data'] as List<dynamic>? ?? <dynamic>[];
    final List<TrackerGameData> items = gameDataList
        .map((dynamic d) =>
            TrackerGameData.fromDb(d as Map<String, dynamic>))
        .toList();
    await _trackerDao!.upsertGameDataBatch(items);
  }

  /// Restores mood grids from a JSON payload. New ids are auto-generated;
  /// cell positions, labels and item references are preserved verbatim.
  Future<void> _restoreMoodGrids(String jsonContent) async {
    final List<dynamic> list = jsonDecode(jsonContent) as List<dynamic>;
    for (final dynamic raw in list) {
      final Map<String, dynamic> entry = raw as Map<String, dynamic>;
      final MoodGrid base = MoodGrid.fromExport(entry);
      final MoodGrid created = await _moodGridDao!.createMoodGrid(
        name: base.name,
        rows: base.rows,
        cols: base.cols,
      );
      final List<MoodGridCell> existingCells =
          await _moodGridDao.getCells(created.id);
      final Map<int, MoodGridCell> byPosition = <int, MoodGridCell>{
        for (final MoodGridCell c in existingCells) c.position: c,
      };

      final List<dynamic> cellsJson =
          (entry['cells'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic cellRaw in cellsJson) {
        final MoodGridCell cellData =
            MoodGridCell.fromExport(cellRaw as Map<String, dynamic>);
        final MoodGridCell? target = byPosition[cellData.position];
        if (target == null) continue;
        if (cellData.label != null) {
          await _moodGridDao.setCellLabel(target.id, cellData.label);
        }
        if (cellData.mediaType != null && cellData.externalId != null) {
          await _moodGridDao.setCellItem(
            cellId: target.id,
            mediaType: cellData.mediaType!,
            externalId: cellData.externalId!,
            platformId: cellData.platformId,
            source: cellData.source,
          );
        }
      }
    }
  }

  /// Restores release subscriptions and manual calendar entries. Both are
  /// keyed by item identity, so re-inserting by identity is enough.
  Future<void> _restoreCalendar(String jsonContent) async {
    final Map<String, dynamic> map =
        jsonDecode(jsonContent) as Map<String, dynamic>;

    final List<dynamic> tracked =
        (map['tracked_releases'] as List<dynamic>?) ?? <dynamic>[];
    for (final dynamic raw in tracked) {
      final TrackedRelease tr =
          TrackedRelease.fromDb(raw as Map<String, dynamic>);
      await _database.trackedReleaseDao
          .subscribe(tr.externalId, tr.source, tr.mediaType);
    }

    final List<dynamic> entries =
        (map['calendar_entries'] as List<dynamic>?) ?? <dynamic>[];
    for (final dynamic raw in entries) {
      await _database.calendarEntryDao
          .upsert(CalendarEntry.fromDb(raw as Map<String, dynamic>));
    }
  }

  /// Restores watch progress. Backed up by show id (collection-agnostic), so
  /// each watched episode is re-applied to every restored collection holding
  /// that TV show or anime.
  Future<void> _restoreWatchedEpisodes(String jsonContent) async {
    final List<dynamic> list = jsonDecode(jsonContent) as List<dynamic>;
    // Episodes of the same show repeat; memoize the lookup per show id.
    final Map<int, List<CollectionItem>> itemsByShow =
        <int, List<CollectionItem>>{};
    for (final dynamic raw in list) {
      final Map<String, dynamic> m = raw as Map<String, dynamic>;
      final int showId = m['show_id'] as int;
      final int season = m['season_number'] as int;
      final int episode = m['episode_number'] as int;
      final int? watchedAt = m['watched_at'] as int?;

      final List<CollectionItem> items = itemsByShow[showId] ??=
          <CollectionItem>[
        ...await _database.collectionDao.findAllCollectionItems(
          mediaType: MediaType.tvShow,
          externalId: showId,
        ),
        ...await _database.collectionDao.findAllCollectionItems(
          mediaType: MediaType.animation,
          externalId: showId,
        ),
      ];
      for (final CollectionItem item in items) {
        final int? collectionId = item.collectionId;
        if (collectionId == null) continue;
        await _database.tvShowDao.markEpisodeWatchedAt(
          collectionId,
          showId,
          season,
          episode,
          watchedAt,
        );
      }
    }
  }

  String _dateSuffix() {
    final DateTime now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
