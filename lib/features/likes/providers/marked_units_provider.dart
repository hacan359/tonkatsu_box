import 'package:core/models/collection_item.dart';
import 'package:core/models/marked_unit.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tag.dart';
import 'package:core/utils/item_search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../collections/providers/item_tags_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../settings/providers/settings_provider.dart';

/// One title on the likes page: the item and every mark on its units.
class MarkedUnitGroup {
  const MarkedUnitGroup({required this.item, required this.units});

  final CollectionItem item;

  /// In reading order (type, season, number), not by date — "S1 E3, S1 E7"
  /// scans better than a shuffle by when each was liked.
  final List<MarkedUnit> units;

  /// The freshest activity in the group; groups are ordered by it.
  DateTime get latest => units
      .map((MarkedUnit u) => u.mark.likedAt ?? u.mark.updatedAt)
      .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);

  MarkedUnitGroup copyWith({List<MarkedUnit>? units}) =>
      MarkedUnitGroup(item: item, units: units ?? this.units);
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

    final List<MarkedUnitGroup> groups = <MarkedUnitGroup>[
      for (final CollectionItem item in items)
        if (byItem[item.id] case final List<MarkedUnit> marks)
          MarkedUnitGroup(item: item, units: _inReadingOrder(marks)),
    ];
    groups.sort(
      (MarkedUnitGroup a, MarkedUnitGroup b) => b.latest.compareTo(a.latest),
    );
    return groups;
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

/// What a mark carries; the page filters by it.
enum LikesKind { liked, noted }

/// The page's filter state. Lives apart from the data so a toggle never
/// refetches — on web every fetch is a round trip. The query comes from the
/// shared top-bar field, not from here.
class LikesFilter {
  const LikesFilter({
    this.kinds = const <LikesKind>{},
    this.types = const <MediaType>{},
    this.query = '',
    this.itemSearch,
  });

  /// Empty or full means every mark; one kind narrows to it.
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

  bool _kindAllows(MarkedUnit unit) {
    if (kinds.isEmpty || kinds.length == LikesKind.values.length) return true;
    return kinds.contains(LikesKind.liked)
        ? unit.mark.isFavorite
        : unit.mark.note != null;
  }

  bool _unitMatchesQuery(MarkedUnit unit) {
    final String q = query.toLowerCase();
    final String? note = unit.mark.note;
    final String? title = unit.unitTitle;
    return (note != null && note.toLowerCase().contains(q)) ||
        (title != null && title.toLowerCase().contains(q));
  }

  /// Applies the filter to grouped data, dropping titles left with no units.
  /// A title that matches the query keeps all its units; otherwise only the
  /// units whose own text matches survive.
  List<MarkedUnitGroup> apply(List<MarkedUnitGroup> groups) {
    final String q = query.trim();
    return <MarkedUnitGroup>[
      for (final MarkedUnitGroup g in groups)
        if (types.isEmpty || types.contains(g.item.mediaType))
          if (_keptUnits(g, q.isNotEmpty) case final List<MarkedUnit> kept
              when kept.isNotEmpty)
            g.copyWith(units: kept),
    ];
  }

  List<MarkedUnit> _keptUnits(MarkedUnitGroup g, bool hasQuery) {
    final bool titleHit = hasQuery && (itemSearch?.matches(g.item) ?? false);
    return <MarkedUnit>[
      for (final MarkedUnit u in g.units)
        if (_kindAllows(u) && (!hasQuery || titleHit || _unitMatchesQuery(u)))
          u,
    ];
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
  final Map<int, Tag> tags = ref.watch(allTagsMapProvider);
  final ItemSearch itemSearch = ItemSearch(
    query: query,
    mode: ref.watch(searchModeProvider),
    itemTags: ref.watch(itemTagsProvider).valueOrNull ?? <int, List<int>>{},
    tagNames: <int, String>{
      for (final Tag tag in tags.values) tag.id: tag.name,
    },
    titleLanguage: ref.watch(sharedPreferencesProvider).animeMangaTitleLanguage,
  );
  final LikesFilter filter = ref.watch(likesFilterProvider).copyWith(
        query: query,
        itemSearch: itemSearch,
      );
  return ref
      .watch(markedUnitsProvider)
      .whenData((List<MarkedUnitGroup> groups) => filter.apply(groups));
});

/// Media types that actually carry marks — the chips the page offers.
final Provider<List<MediaType>> markedMediaTypesProvider =
    Provider<List<MediaType>>((Ref ref) {
  final List<MarkedUnitGroup> groups =
      ref.watch(markedUnitsProvider).valueOrNull ?? const <MarkedUnitGroup>[];
  final Set<MediaType> present = <MediaType>{
    for (final MarkedUnitGroup g in groups) g.item.mediaType,
  };
  return <MediaType>[
    for (final MediaType t in MediaType.values)
      if (present.contains(t)) t,
  ];
});
