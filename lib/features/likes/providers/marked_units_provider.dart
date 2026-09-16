import 'package:core/models/collection_item.dart';
import 'package:core/models/marked_unit.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/item_search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../home/providers/all_items_provider.dart';

/// One title on the likes page: the item, every mark on its units, and the
/// replay counter — a mark on the title itself rather than on a unit.
class MarkedUnitGroup {
  const MarkedUnitGroup({
    required this.item,
    required this.units,
    this.rewatchCount = 0,
  });

  final CollectionItem item;

  /// In reading order (type, season, number), not by date — "S1 E3, S1 E7"
  /// scans better than a shuffle by when each was liked.
  final List<MarkedUnit> units;

  /// Mirrors `rewatch_count`, where 0 means "finished once": only a count
  /// above zero is a replay, so 0 doubles as "no replay row".
  final int rewatchCount;

  bool get isReplayed => rewatchCount > 0;

  /// The freshest activity in the group; groups are ordered by it. A title
  /// that only carries replays has no mark dates to go by.
  DateTime get latest => units.isEmpty
      ? item.lastActivityAt ?? item.completedAt ?? item.addedAt
      : units
          .map((MarkedUnit u) => u.mark.likedAt ?? u.mark.updatedAt)
          .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);

  MarkedUnitGroup copyWith({List<MarkedUnit>? units, int? rewatchCount}) =>
      MarkedUnitGroup(
        item: item,
        units: units ?? this.units,
        rewatchCount: rewatchCount ?? this.rewatchCount,
      );
}

/// `latest` reduces over the units, so it is read once per group rather
/// than twice per comparison.
List<MarkedUnitGroup> _newestFirst(Iterable<MarkedUnitGroup> groups) {
  final List<(DateTime, MarkedUnitGroup)> keyed = <(DateTime, MarkedUnitGroup)>[
    for (final MarkedUnitGroup g in groups) (g.latest, g),
  ];
  keyed.sort(
    ((DateTime, MarkedUnitGroup) a, (DateTime, MarkedUnitGroup) b) =>
        b.$1.compareTo(a.$1),
  );
  return <MarkedUnitGroup>[for (final (DateTime, MarkedUnitGroup) k in keyed) k.$2];
}

/// Every marked unit in the library, grouped by title, newest group first.
/// Two DAO calls per load; everything downstream is filtered in memory.
final AsyncNotifierProvider<MarkedUnitsNotifier, List<MarkedUnitGroup>>
    markedUnitsProvider =
    AsyncNotifierProvider<MarkedUnitsNotifier, List<MarkedUnitGroup>>(
  MarkedUnitsNotifier.new,
);

class MarkedUnitsNotifier extends AsyncNotifier<List<MarkedUnitGroup>> {
  @override
  Future<List<MarkedUnitGroup>> build() async {
    final DatabaseService db = ref.watch(databaseServiceProvider);
    final List<MarkedUnit> units = await db.itemMarkDao.getAllMarks();
    if (units.isEmpty) return const <MarkedUnitGroup>[];

    final Map<int, List<MarkedUnit>> byItem = <int, List<MarkedUnit>>{};
    for (final MarkedUnit u in units) {
      byItem.putIfAbsent(u.mark.itemId, () => <MarkedUnit>[]).add(u);
    }
    final List<CollectionItem> items =
        await db.collectionDao.getItemsWithDataByRowIds(byItem.keys.toList());

    return _newestFirst(<MarkedUnitGroup>[
      for (final CollectionItem item in items)
        if (byItem[item.id] case final List<MarkedUnit> marks)
          MarkedUnitGroup(item: item, units: _inReadingOrder(marks)),
    ]);
  }

  static List<MarkedUnit> _inReadingOrder(List<MarkedUnit> marks) {
    final List<MarkedUnit> sorted = List<MarkedUnit>.of(marks);
    sorted.sort((MarkedUnit a, MarkedUnit b) {
      final int byType = a.mark.unitType.compareTo(b.mark.unitType);
      if (byType != 0) return byType;
      final int byParent = a.mark.parentNumber.compareTo(b.mark.parentNumber);
      if (byParent != 0) return byParent;
      return a.mark.unitNumber.compareTo(b.mark.unitNumber);
    });
    return sorted;
  }
}

/// `rewatch_count` follows MAL "times watched": `null` is untracked and `0` is
/// "finished once", so only a value above zero counts as a replay.
final Provider<AsyncValue<List<CollectionItem>>> rewatchedItemsProvider =
    Provider<AsyncValue<List<CollectionItem>>>((Ref ref) {
  return ref.watch(visibleAllItemsProvider).whenData(
        (List<CollectionItem> items) => <CollectionItem>[
          for (final CollectionItem i in items)
            if ((i.rewatchCount ?? 0) > 0) i,
        ],
      );
});

/// Marks and replays in one list of titles, newest first. A replayed title
/// with no marks joins as a group of its own.
final Provider<AsyncValue<List<MarkedUnitGroup>>> likesEntriesProvider =
    Provider<AsyncValue<List<MarkedUnitGroup>>>((Ref ref) {
  // A library that failed to load must not blank the marks: replays are the
  // optional half of the page.
  final List<CollectionItem> replayed =
      ref.watch(rewatchedItemsProvider).valueOrNull ?? const <CollectionItem>[];
  return ref.watch(markedUnitsProvider).whenData(
        (List<MarkedUnitGroup> groups) => _withReplays(groups, replayed),
      );
});

List<MarkedUnitGroup> _withReplays(
  List<MarkedUnitGroup> groups,
  List<CollectionItem> replayed,
) {
  if (replayed.isEmpty) return groups;
  final Map<int, MarkedUnitGroup> byItem = <int, MarkedUnitGroup>{
    for (final MarkedUnitGroup g in groups) g.item.id: g,
  };
  for (final CollectionItem item in replayed) {
    final int count = item.rewatchCount ?? 0;
    byItem[item.id] = byItem[item.id]?.copyWith(rewatchCount: count) ??
        MarkedUnitGroup(
          item: item,
          units: const <MarkedUnit>[],
          rewatchCount: count,
        );
  }
  return _newestFirst(byItem.values);
}

/// What a mark carries; the page filters by it. A replay marks the title, the
/// other two mark a unit.
enum LikesKind { liked, noted, rewatched }

/// Kept apart from the data so a toggle never refetches (on web every fetch is
/// a round trip); the query itself comes from the shared top-bar field.
class LikesFilter {
  const LikesFilter({
    this.kinds = const <LikesKind>{},
    this.types = const <MediaType>{},
    this.query = '',
    this.itemSearch,
  });

  /// Empty means every kind; a selection narrows to the picked ones, so
  /// replays alone, replays with likes and likes alone are all reachable.
  final Set<LikesKind> kinds;

  /// Empty means every type.
  final Set<MediaType> types;

  /// Matched against note text and unit names, case-insensitively.
  final String query;

  /// The library matcher (title, tags, comments, creators, meta query), so
  /// the page finds whatever the Home search finds.
  final ItemSearch? itemSearch;

  bool get isDefault => kinds.isEmpty && types.isEmpty && query.isEmpty;

  LikesFilter copyWith({
    Set<LikesKind>? kinds,
    Set<MediaType>? types,
    String? query,
    ItemSearch? itemSearch,
  }) {
    return LikesFilter(
      kinds: kinds ?? this.kinds,
      types: types ?? this.types,
      query: query ?? this.query,
      itemSearch: itemSearch ?? this.itemSearch,
    );
  }

  bool _wants(LikesKind kind) => kinds.isEmpty || kinds.contains(kind);

  bool _kindAllows(MarkedUnit unit) {
    if (kinds.isEmpty) return true;
    return (_wants(LikesKind.liked) && unit.mark.isFavorite) ||
        (_wants(LikesKind.noted) && unit.mark.note != null);
  }

  bool _unitMatchesQuery(MarkedUnit unit, String q) {
    final String? note = unit.mark.note;
    final String? title = unit.unitTitle;
    return (note != null && note.toLowerCase().contains(q)) ||
        (title != null && title.toLowerCase().contains(q));
  }

  /// A title matching the query keeps all its units; otherwise only the units
  /// whose own text matches survive, and titles left empty are dropped.
  List<MarkedUnitGroup> apply(List<MarkedUnitGroup> groups) {
    final String q = query.trim().toLowerCase();
    return <MarkedUnitGroup>[
      for (final MarkedUnitGroup g in groups)
        if (types.isEmpty || types.contains(g.item.mediaType))
          if (_kept(g, q) case final MarkedUnitGroup kept
              when kept.units.isNotEmpty || kept.isReplayed)
            kept,
    ];
  }

  /// A replay row carries no text of its own, so a query reaches it only
  /// through the title.
  MarkedUnitGroup _kept(MarkedUnitGroup g, String q) {
    final bool hasQuery = q.isNotEmpty;
    final bool titleHit = hasQuery && (itemSearch?.matches(g.item) ?? false);
    final List<MarkedUnit> units = <MarkedUnit>[
      for (final MarkedUnit u in g.units)
        if (_kindAllows(u) &&
            (!hasQuery || titleHit || _unitMatchesQuery(u, q)))
          u,
    ];
    final bool keepReplays =
        _wants(LikesKind.rewatched) && (!hasQuery || titleHit);
    return g.copyWith(units: units, rewatchCount: keepReplays ? null : 0);
  }
}

final NotifierProvider<LikesFilterNotifier, LikesFilter> likesFilterProvider =
    NotifierProvider<LikesFilterNotifier, LikesFilter>(
  LikesFilterNotifier.new,
);

class LikesFilterNotifier extends Notifier<LikesFilter> {
  @override
  LikesFilter build() => const LikesFilter();

  void toggleKind(LikesKind kind) {
    final Set<LikesKind> next = Set<LikesKind>.of(state.kinds);
    if (!next.remove(kind)) next.add(kind);
    state = state.copyWith(kinds: next);
  }

  void toggleType(MediaType type) {
    final Set<MediaType> next = Set<MediaType>.of(state.types);
    if (!next.remove(type)) next.add(type);
    state = state.copyWith(types: next);
  }

  void reset() => state = const LikesFilter();
}

/// The groups the page renders: data through the current filter plus the
/// top-bar query, matched the same way Home matches its items.
final Provider<AsyncValue<List<MarkedUnitGroup>>> filteredMarkedUnitsProvider =
    Provider<AsyncValue<List<MarkedUnitGroup>>>((Ref ref) {
  final String query = ref.watch(likesSearchQueryProvider).trim();
  final LikesFilter filter = ref.watch(likesFilterProvider).copyWith(
        query: query,
        itemSearch: ref.watch(itemSearchProvider(query)),
      );
  return ref
      .watch(likesEntriesProvider)
      .whenData((List<MarkedUnitGroup> groups) => filter.apply(groups));
});

/// Media types that actually carry marks or replays — the chips the page offers.
final Provider<List<MediaType>> markedMediaTypesProvider =
    Provider<List<MediaType>>((Ref ref) {
  final List<MarkedUnitGroup> groups =
      ref.watch(likesEntriesProvider).valueOrNull ?? const <MarkedUnitGroup>[];
  final Set<MediaType> present = <MediaType>{
    for (final MarkedUnitGroup g in groups) g.item.mediaType,
  };
  return <MediaType>[
    for (final MediaType t in MediaType.values)
      if (present.contains(t)) t,
  ];
});
