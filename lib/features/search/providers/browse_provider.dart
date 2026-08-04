import 'package:core/models/media_type.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_error_extract.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/common_filter.dart';
import '../models/search_source.dart';
import '../sources/search_sources.dart';

/// SharedPreferences keys for persisting Browse state.
abstract final class BrowseSettingsKeys {
  /// Pre-0.41 key holding a single source id; read once to derive [mediaType].
  static const String sourceId = 'browse_source_id';

  static const String mediaType = 'browse_media_type';
}

/// A value picked in a shared filter, with its per-source spelling. Sources
/// absent from [targets] cannot answer it and drop out of the query.
class CommonSelection {
  const CommonSelection({required this.semantic, required this.targets});

  final FilterSemantic semantic;
  final Map<String, CommonFilterTarget> targets;
}

class BrowseState {
  const BrowseState({
    required this.mediaType,
    this.disabledSourceIds = const <String>{},
    this.ownFilterValues = const <String, Map<String, Object?>>{},
    this.commonSelections = const <String, CommonSelection>{},
    this.sortBy,
    this.sortSourceId,
    this.itemsBySource = const <String, List<Object>>{},
    this.loadingSourceIds = const <String>{},
    this.isLoadingMore = false,
    this.pages = const <String, int>{},
    this.moreBySource = const <String, bool>{},
    this.errors = const <String, ApiError>{},
    this.loadedSignatures = const <String, String>{},
    this.searchQuery = '',
  });

  final MediaType mediaType;

  /// Sources the user switched off. Empty means all of [sources] — so a newly
  /// registered source is on by default.
  final Set<String> disabledSourceIds;

  /// Source id → its own (non-shared) filter values.
  final Map<String, Map<String, Object?>> ownFilterValues;

  /// Shared filter key → what the user picked there.
  final Map<String, CommonSelection> commonSelections;

  /// Raw API sort value. Belongs to [sortSourceId]'s vocabulary — IGDB's
  /// `rating desc` means nothing to TMDB.
  final String? sortBy;

  /// Provider [sortBy] was picked for; null when nothing was picked.
  final String? sortSourceId;

  final Map<String, List<Object>> itemsBySource;

  /// Sources with a request in flight. Tracked per source, not as one flag:
  /// AniList answers at once while Kitsu takes seconds, and the slow one has to
  /// show it is working instead of reading as "returned nothing".
  final Set<String> loadingSourceIds;

  final bool isLoadingMore;

  final Map<String, int> pages;

  final Map<String, bool> moreBySource;

  /// Failures per source — one dead provider must not blank the screen.
  final Map<String, ApiError> errors;

  /// Request signature each source's results came from. A source whose current
  /// signature still matches is never asked again, so hiding and showing a
  /// provider costs nothing.
  final Map<String, String> loadedSignatures;

  final String searchQuery;

  List<SearchSource> get sources => searchSourcesFor(mediaType);

  MediaTypeFilters get filters => filtersForMediaType(mediaType);

  /// Sources with at least one own filter set. Non-empty means the query was
  /// narrowed to them: nobody else can answer a filter they do not have.
  Set<String> get ownFilterOwners => <String>{
        for (final MapEntry<String, Map<String, Object?>> entry
            in ownFilterValues.entries)
          if (entry.value.values.any(_isSet)) entry.key,
      };

  List<SearchSource> get activeSources {
    final Set<String> narrowed = ownFilterOwners;
    return sources.where((SearchSource source) {
      if (disabledSourceIds.contains(source.id)) return false;
      if (narrowed.isNotEmpty && !narrowed.contains(source.id)) return false;
      for (final CommonSelection selection in commonSelections.values) {
        if (!selection.targets.containsKey(source.id)) return false;
      }
      return true;
    }).toList();
  }

  /// Sources hidden by a shared value they cannot answer — MangaBaka has no
  /// "cancelled", Kitsu no "hiatus". Shown as dimmed chips so a shortened
  /// result set does not read as "nothing found".
  Set<String> get unsupportedSourceIds => <String>{
        for (final SearchSource source in sources)
          for (final CommonSelection selection in commonSelections.values)
            if (!selection.targets.containsKey(source.id)) source.id,
      };

  /// Filter values handed to [SearchSource.fetch] for one source: its own plus
  /// every shared pick translated into that provider's key and value.
  Map<String, Object?> filterValuesFor(String sourceId) {
    final Map<String, Object?> values = <String, Object?>{
      ...?ownFilterValues[sourceId],
    };
    for (final CommonSelection selection in commonSelections.values) {
      final CommonFilterTarget? target = selection.targets[sourceId];
      if (target != null) values[target.filterKey] = target.value;
    }
    return values;
  }

  /// Own filter values actually set, across every source.
  int get ownFilterCount => ownFilterValues.values.fold(
        0,
        (int sum, Map<String, Object?> values) =>
            sum + values.values.where(_isSet).length,
      );

  int get activeFilterCount => commonSelections.length + ownFilterCount;

  bool get hasFilters => commonSelections.isNotEmpty || ownFilterCount > 0;

  bool get hasSearchQuery => searchQuery.trim().length >= 2;

  /// True when no active source can answer filters alone — books, where every
  /// provider is search-only. Filters without a query would return nothing.
  bool get textQueryOnly =>
      activeSources.isNotEmpty &&
      activeSources.every((SearchSource s) => !s.supportsBrowse);

  bool get hasActiveQuery => hasSearchQuery || hasFilters;

  List<Object> get items => <Object>[
        for (final SearchSource source in activeSources)
          ...?itemsBySource[source.id],
      ];

  bool isSourceLoading(String sourceId) => loadingSourceIds.contains(sourceId);

  bool get isLoading => loadingSourceIds.isNotEmpty;

  bool get isEmpty => items.isEmpty && !isLoading;

  /// With several sources the app holds page one of each and cannot order the
  /// union honestly, so several answering rules sort out.
  bool get isSingleSource => activeSources.length == 1;

  /// Provider the sort speaks for: [sortBy] holds its vocabulary and [setSort]
  /// applies to it. Falls back to the primary so the bar always has options.
  SearchSource? get sortSource {
    final List<SearchSource> active = activeSources;
    if (active.isNotEmpty) return active.first;
    return sources.isEmpty ? null : sources.first;
  }

  /// TMDB and friends ignore sort on a search response, so offering it would be
  /// a control that does nothing.
  bool get sortIgnoredDuringSearch =>
      hasSearchQuery && !(sortSource?.supportsSortDuringSearch ?? true);

  bool get canSort => isSingleSource && !sortIgnoredDuringSearch;

  /// Independent of how many sources are active, so switching providers on and
  /// off does not silently change what a source would be asked for.
  String sortByFor(SearchSource source) =>
      (sortSourceId == source.id && sortBy != null)
          ? sortBy!
          : source.defaultSort.apiValue;

  String get effectiveSortBy {
    final SearchSource? source = sortSource;
    return source == null ? '' : sortByFor(source);
  }

  static bool _isSet(Object? value) =>
      value != null && (value is! List<Object> || value.isNotEmpty);

  BrowseState copyWith({
    MediaType? mediaType,
    Set<String>? disabledSourceIds,
    Map<String, Map<String, Object?>>? ownFilterValues,
    Map<String, CommonSelection>? commonSelections,
    String? sortBy,
    String? sortSourceId,
    Map<String, List<Object>>? itemsBySource,
    Set<String>? loadingSourceIds,
    bool? isLoadingMore,
    Map<String, int>? pages,
    Map<String, bool>? moreBySource,
    Map<String, ApiError>? errors,
    Map<String, String>? loadedSignatures,
    String? searchQuery,
    bool clearSortBy = false,
  }) {
    return BrowseState(
      mediaType: mediaType ?? this.mediaType,
      disabledSourceIds: disabledSourceIds ?? this.disabledSourceIds,
      ownFilterValues: ownFilterValues ?? this.ownFilterValues,
      commonSelections: commonSelections ?? this.commonSelections,
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      sortSourceId:
          clearSortBy ? null : (sortSourceId ?? this.sortSourceId),
      itemsBySource: itemsBySource ?? this.itemsBySource,
      loadingSourceIds: loadingSourceIds ?? this.loadingSourceIds,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pages: pages ?? this.pages,
      moreBySource: moreBySource ?? this.moreBySource,
      errors: errors ?? this.errors,
      loadedSignatures: loadedSignatures ?? this.loadedSignatures,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final NotifierProvider<BrowseNotifier, BrowseState> browseProvider =
    NotifierProvider<BrowseNotifier, BrowseState>(BrowseNotifier.new);

class BrowseNotifier extends Notifier<BrowseState> {
  late SharedPreferences _prefs;

  /// Monotonic counter guarding against race conditions: every new operation
  /// increments it, and a per-source result whose generation no longer matches
  /// is discarded, so a slow provider cannot write into a newer query.
  int _generation = 0;

  @override
  BrowseState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return BrowseState(mediaType: _restoreMediaType());
  }

  MediaType _restoreMediaType() {
    final String? saved = _prefs.getString(BrowseSettingsKeys.mediaType);
    if (saved != null) {
      for (final MediaType type in searchableMediaTypes) {
        if (type.name == saved) return type;
      }
    }
    // Pre-0.41 installs stored a source id; every source knows its media type,
    // and all sources of it come on, which is the point of the new screen.
    final String? legacy = _prefs.getString(BrowseSettingsKeys.sourceId);
    if (legacy != null) return getSearchSourceById(legacy).outputMediaType;
    return searchableMediaTypes.first;
  }

  /// Switching the type resets filters and content but keeps the text query —
  /// the new type has different filters, while what the user typed still holds.
  void setMediaType(MediaType type) {
    _generation++;
    final String preservedQuery = state.searchQuery;
    state = BrowseState(mediaType: type, searchQuery: preservedQuery);
    _prefs.setString(BrowseSettingsKeys.mediaType, type.name);
    if (state.hasSearchQuery) _fetch();
  }

  /// Opens [sourceId]'s media type narrowed to that one source — the entry
  /// point for "search on this exact provider" requests from other tabs.
  void setSource(String sourceId) {
    final SearchSource source = getSearchSourceById(sourceId);
    _generation++;
    final String preservedQuery = state.searchQuery;
    state = BrowseState(
      mediaType: source.outputMediaType,
      searchQuery: preservedQuery,
      disabledSourceIds: <String>{
        for (final SearchSource other in searchSourcesFor(source.outputMediaType))
          if (other.id != sourceId) other.id,
      },
    );
    _prefs.setString(
      BrowseSettingsKeys.mediaType,
      source.outputMediaType.name,
    );
    if (state.hasSearchQuery) _fetch();
  }

  /// Leaves only [sourceId] active — the "show all from this provider" action
  /// on a section header, which also brings back sorting. Its results are
  /// already loaded, so this costs no requests.
  Future<void> narrowTo(String sourceId) async {
    state = state.copyWith(
      disabledSourceIds: <String>{
        for (final SearchSource other in state.sources)
          if (other.id != sourceId) other.id,
      },
    );
    await _fetch();
  }

  /// Switching a provider off only hides it: its results are kept, so switching
  /// it back on costs nothing. Switching on a provider with no results yet
  /// fetches that one alone.
  Future<void> toggleSource(String sourceId) async {
    final Set<String> disabled = <String>{...state.disabledSourceIds};
    if (!disabled.remove(sourceId)) disabled.add(sourceId);
    // Leaving nothing enabled would show an empty screen with no way back.
    if (disabled.length >= state.sources.length) return;

    state = state.copyWith(disabledSourceIds: disabled);
    await _fetch();
  }

  Future<void> setOwnFilter(
    String sourceId,
    String key,
    Object? value,
  ) async {
    final Map<String, Map<String, Object?>> updated =
        <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> entry
          in state.ownFilterValues.entries)
        entry.key: Map<String, Object?>.from(entry.value),
    };
    (updated[sourceId] ??= <String, Object?>{})[key] = value;

    state = state.copyWith(ownFilterValues: updated);
    await _fetch();
  }

  Future<void> setCommonFilter(
    String key,
    CommonSelection? selection,
  ) async {
    final Map<String, CommonSelection> updated =
        Map<String, CommonSelection>.from(state.commonSelections);
    if (selection == null) {
      updated.remove(key);
    } else {
      updated[key] = selection;
    }

    state = state.copyWith(commonSelections: updated);
    await _fetch();
  }

  Future<void> setSort(String sortBy) async {
    final SearchSource? source = state.canSort ? state.sortSource : null;
    if (source == null) return;
    state = state.copyWith(sortBy: sortBy, sortSourceId: source.id);
    await _fetch();
  }

  void clearFilters() {
    _generation++;
    state = state.copyWith(
      ownFilterValues: const <String, Map<String, Object?>>{},
      commonSelections: const <String, CommonSelection>{},
      // The generation bump discards whatever is in flight, so its loading
      // marks have to go with it or a source shimmers forever.
      loadingSourceIds: const <String>{},
      clearSortBy: true,
    );

    // A remaining text query still warrants a reload with text only.
    if (state.hasSearchQuery) _fetch();
  }

  /// Updates the text query without triggering a search. Used to sync the text
  /// from the controller right before a filter change.
  void setSearchQuery(String query) {
    final String trimmed = query.trim();
    if (trimmed.length < 2 || state.searchQuery == trimmed) return;
    state = state.copyWith(searchQuery: trimmed);
  }

  Future<void> search(String query) async {
    if (query.trim().length < 2) return;
    state = state.copyWith(searchQuery: query.trim());
    await _fetch();
  }

  void clearSearch() {
    _generation++;
    state = state.copyWith(
      searchQuery: '',
      loadingSourceIds: const <String>{},
    );

    // Remaining filters still warrant a reload with filters only.
    if (state.hasFilters) _fetch();
  }

  /// Re-asks every active source even if nothing changed — the Retry action.
  Future<void> refresh() async {
    final Map<String, String> signatures =
        Map<String, String>.from(state.loadedSignatures);
    for (final SearchSource source in state.activeSources) {
      signatures.remove(source.id);
    }
    state = state.copyWith(loadedSignatures: signatures);
    if (state.hasActiveQuery) await _fetch();
  }

  /// Everything that decides one source's result: the query, the filter values
  /// it actually receives, and its sort. Deliberately independent of how many
  /// sources are active, so hiding a provider does not invalidate the others.
  @visibleForTesting
  String signatureOf(String sourceId) =>
      _signature(getSearchSourceById(sourceId));

  String _signature(SearchSource source) {
    final Map<String, Object?> values = state.filterValuesFor(source.id);
    final List<String> keys = values.keys.toList()..sort();
    return <String>[
      state.hasSearchQuery ? state.searchQuery : '',
      state.sortByFor(source),
      for (final String key in keys) '$key=${values[key]}',
    ].join('|');
  }

  /// Asks only the sources whose signature no longer matches their results.
  /// Turning a provider off and on, or narrowing to one and back, therefore
  /// costs nothing; only a real change to the query refetches, and only the
  /// sources that change.
  Future<void> _fetch() async {
    if (!state.hasActiveQuery) return;

    final Map<SearchSource, String> stale = <SearchSource, String>{};
    for (final SearchSource source in state.activeSources) {
      final String signature = _signature(source);
      if (state.loadedSignatures[source.id] == signature &&
          state.itemsBySource.containsKey(source.id)) {
        continue;
      }
      stale[source] = signature;
    }
    if (stale.isEmpty) {
      // Nothing pending for an active source, so any mark left over from a
      // superseded batch is stale.
      if (state.isLoading) {
        state = state.copyWith(loadingSourceIds: const <String>{});
      }
      return;
    }

    final int gen = ++_generation;
    final Map<String, List<Object>> items =
        Map<String, List<Object>>.from(state.itemsBySource);
    final Map<String, int> pages = Map<String, int>.from(state.pages);
    final Map<String, bool> more = Map<String, bool>.from(state.moreBySource);
    final Map<String, ApiError> errors =
        Map<String, ApiError>.from(state.errors);
    final Map<String, String> signatures =
        Map<String, String>.from(state.loadedSignatures);
    for (final SearchSource source in stale.keys) {
      items.remove(source.id);
      pages.remove(source.id);
      more.remove(source.id);
      errors.remove(source.id);
      signatures.remove(source.id);
    }

    state = state.copyWith(
      loadingSourceIds: <String>{
        for (final SearchSource source in stale.keys) source.id,
      },
      itemsBySource: items,
      pages: pages,
      moreBySource: more,
      errors: errors,
      loadedSignatures: signatures,
    );

    await Future.wait(
      stale.entries.map(
        (MapEntry<SearchSource, String> entry) => _fetchOne(
          entry.key,
          gen,
          page: 1,
          signature: entry.value,
        ),
      ),
    );

    if (_generation != gen) return;
    state = state.copyWith(loadingSourceIds: const <String>{});
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore) return;

    final Map<String, int> startPages = state.pages;
    final List<SearchSource> pending = state.activeSources
        .where((SearchSource s) => state.moreBySource[s.id] ?? false)
        .toList();
    if (pending.isEmpty) return;

    final int gen = ++_generation;
    state = state.copyWith(isLoadingMore: true);

    await Future.wait(
      pending.map(
        (SearchSource source) => _fetchOne(
          source,
          gen,
          page: (startPages[source.id] ?? 1) + 1,
          signature: state.loadedSignatures[source.id],
        ),
      ),
    );

    if (_generation != gen) return;
    state = state.copyWith(isLoadingMore: false);
  }

  /// Fetches one source and merges its slice as soon as it lands, so a fast
  /// provider renders without waiting for a slow one.
  Future<void> _fetchOne(
    SearchSource source,
    int gen, {
    required int page,
    required String? signature,
  }) async {
    try {
      final BrowseResult result = await source.fetch(
        ref,
        query: state.hasSearchQuery ? state.searchQuery : null,
        filterValues: state.filterValuesFor(source.id),
        sortBy: state.sortByFor(source),
        page: page,
      );

      if (_generation != gen) return;

      final Map<String, List<Object>> items =
          Map<String, List<Object>>.from(state.itemsBySource);
      items[source.id] = page == 1
          ? result.items
          : <Object>[...?items[source.id], ...result.items];

      state = state.copyWith(
        itemsBySource: items,
        loadingSourceIds: _doneLoading(source.id),
        pages: Map<String, int>.from(state.pages)..[source.id] = page,
        moreBySource: Map<String, bool>.from(state.moreBySource)
          ..[source.id] = result.hasMore,
        errors: Map<String, ApiError>.from(state.errors)..remove(source.id),
        loadedSignatures: signature == null
            ? null
            : (Map<String, String>.from(state.loadedSignatures)
              ..[source.id] = signature),
      );
    } on Exception catch (e) {
      if (_generation != gen) return;
      state = state.copyWith(
        errors: Map<String, ApiError>.from(state.errors)
          ..[source.id] = extractApiError(e),
        loadingSourceIds: _doneLoading(source.id),
        moreBySource: Map<String, bool>.from(state.moreBySource)
          ..[source.id] = false,
      );
    }
  }

  Set<String> _doneLoading(String sourceId) =>
      <String>{...state.loadingSourceIds}..remove(sourceId);
}
