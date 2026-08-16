import 'dart:async';

import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';

/// Filter state of the mood-grid item picker, kept between openings so
/// filling a large grid doesn't reset the filter and search on every cell.
class MoodGridPickerSession {
  const MoodGridPickerSession({
    this.collectionId,
    this.query = '',
    this.revision = 0,
  });

  /// Selected collection filter. `null` = all collections.
  final int? collectionId;

  final String query;

  /// Bumped when a background refresh lands, so an open picker re-reads
  /// the cache without resetting its scroll window.
  final int revision;

  MoodGridPickerSession copyWith({
    int? collectionId,
    bool clearCollection = false,
    String? query,
    int? revision,
  }) {
    return MoodGridPickerSession(
      collectionId:
          clearCollection ? null : (collectionId ?? this.collectionId),
      query: query ?? this.query,
      revision: revision ?? this.revision,
    );
  }
}

/// autoDispose: the grid detail screen holds a listener while on screen;
/// leaving the grid resets the session and the item cache.
final AutoDisposeNotifierProvider<MoodGridPickerSessionNotifier,
        MoodGridPickerSession> moodGridPickerSessionProvider =
    NotifierProvider.autoDispose<MoodGridPickerSessionNotifier,
        MoodGridPickerSession>(
  MoodGridPickerSessionNotifier.new,
);

class MoodGridPickerSessionNotifier
    extends AutoDisposeNotifier<MoodGridPickerSession> {
  final Map<int?, List<CollectionItem>> _itemsCache =
      <int?, List<CollectionItem>>{};
  bool _disposed = false;

  @override
  MoodGridPickerSession build() {
    ref.onDispose(() => _disposed = true);
    return const MoodGridPickerSession();
  }

  void setCollection(int? id) {
    state = state.copyWith(collectionId: id, clearCollection: id == null);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  /// Cached list returns instantly; [refresh] reloads in the background and
  /// bumps the session revision (revision re-reads pass false to not loop).
  Future<List<CollectionItem>> itemsForCurrentFilter({
    bool refresh = true,
  }) async {
    final int? id = state.collectionId;
    final List<CollectionItem>? cached = _itemsCache[id];
    if (cached == null) {
      return _loadAndCache(id);
    }
    if (refresh) {
      unawaited(_refreshInBackground(id));
    }
    return cached;
  }

  Future<List<CollectionItem>> _loadAndCache(int? id) async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<CollectionItem> items = id == null
        ? await db.getAllCollectionItemsWithData()
        : await db.getCollectionItemsWithData(id);
    final List<CollectionItem> deduped = _dedupeByIdentity(items);
    _itemsCache[id] = deduped;
    return deduped;
  }

  Future<void> _refreshInBackground(int? id) async {
    await _loadAndCache(id);
    if (_disposed) return;
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Items present in several collections collapse to the first occurrence —
  /// the picker cares about identity, not membership.
  List<CollectionItem> _dedupeByIdentity(List<CollectionItem> items) {
    final Set<String> seen = <String>{};
    final List<CollectionItem> out = <CollectionItem>[];
    for (final CollectionItem item in items) {
      // platformId disambiguates only animation (movie- vs tv-based). NULL
      // source means the type's default, so legacy rows match explicit ones.
      final String animationKey = item.mediaType == MediaType.animation
          ? ':${item.platformId}'
          : '';
      final DataSource source = item.source ?? item.mediaType.defaultSource;
      final String key = '${item.mediaType.value}:${item.externalId}:'
          '${source.name}$animationKey';
      if (seen.add(key)) out.add(item);
    }
    return out;
  }
}
