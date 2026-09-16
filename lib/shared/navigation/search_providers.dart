import 'package:core/models/media_type.dart';
import 'package:core/utils/meta_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'nav_tab.dart';

/// Search query for the Home (All Items) tab.
final StateProvider<String> homeSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Search query for the Wishlist tab.
final StateProvider<String> wishlistSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Search query for the Tier Lists tab.
final StateProvider<String> tierListsSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Search query for the Collections tab.
final StateProvider<String> collectionsSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Search query for the Search tab (IGDB/TMDB API search).
final StateProvider<String> searchTabQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Search query for the Settings tab.
final StateProvider<String> settingsSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Note text filter of the likes page; the page is the only hub section that
/// searches, so it is also the only one that may claim the top-bar field.
final StateProvider<String> likesSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Raised while the likes page is on top of the hub's navigator.
final StateProvider<bool> likesSearchActiveProvider =
    StateProvider<bool>((Ref ref) => false);

/// Shared by Home and Collections so a mode picked on one tab carries over;
/// not persisted, every launch starts with the plain title search.
final StateProvider<SearchMode> searchModeProvider =
    StateProvider<SearchMode>((Ref ref) => SearchMode.title);

/// Popped by the item detail screen when a metadata chip is tapped; the
/// screen that pushed it decides where the query lands.
class MetaSearchRequest {
  const MetaSearchRequest(this.query);

  final String query;
}

/// Turns a tapped chip value into a meta search on [queryProvider]. With
/// [narrow], a query already in meta mode grows by one AND group instead.
void applyMetaSearch(
  WidgetRef ref,
  StateProvider<String> queryProvider,
  String term, {
  bool narrow = true,
}) {
  final bool narrowing =
      narrow && ref.read(searchModeProvider) == SearchMode.meta;
  final String current = ref.read(queryProvider);
  ref.read(searchModeProvider.notifier).state = SearchMode.meta;
  ref.read(queryProvider.notifier).state =
      narrowing ? appendMetaTerm(current, term) : metaTermFor(term);
}

/// One-shot for screens that cannot filter themselves (Search, Releases):
/// consumed by [AppShell], which opens Home in meta mode with the query.
final StateProvider<MetaSearchRequest?> homeMetaSearchRequestProvider =
    StateProvider<MetaSearchRequest?>((Ref ref) => null);

/// App level so [AppShell] can focus the [AppTopBar] field programmatically
/// for type-to-search.
final Provider<FocusNode> appTopBarFocusProvider = Provider<FocusNode>((
  Ref ref,
) {
  final FocusNode node = FocusNode(debugLabel: 'AppTopBar-search');
  ref.onDispose(node.dispose);
  return node;
});

/// Empty means the normal "open details, pick a collection" flow; a non-empty
/// set makes a tap add the result straight into every collection listed.
final StateProvider<Set<int>> searchTargetCollectionsProvider =
    StateProvider<Set<int>>((Ref ref) => <int>{});

/// One-shot: set from another tab, then consumed and reset to `null` by
/// [AppShell].
class SearchTabRequest {
  const SearchTabRequest({
    this.query,
    this.mediaType,
    this.sourceId,
    this.collectionId,
    this.filterValues,
  });

  /// Query to prefill (and run). When null/empty the Search tab opens empty.
  final String? query;

  /// Media type to preselect, with every source of it active.
  final MediaType? mediaType;

  /// Narrows to one provider instead of the whole [mediaType]. Null keeps all.
  final String? sourceId;

  /// Collection to add results into; preselected in
  /// [searchTargetCollectionsProvider].
  final int? collectionId;

  /// Own filter values to preset on [sourceId] (filter key → value); ignored
  /// without a source, a shared value has no single owner.
  final Map<String, Object?>? filterValues;
}

/// Pending [SearchTabRequest]; see [SearchTabRequest].
final StateProvider<SearchTabRequest?> searchTabRequestProvider =
    StateProvider<SearchTabRequest?>((Ref ref) => null);

/// Describes the search context for one tab.
class SearchContext {
  const SearchContext({
    required this.queryProvider,
    required this.hint,
    this.supportsMetaSearch = false,
  });

  /// Where the current query is read from and written to.
  final StateProvider<String> queryProvider;

  /// Placeholder shown in the search field for this tab.
  final String hint;

  /// Whether the tab filters library items and honours [searchModeProvider].
  final bool supportsMetaSearch;
}

/// The context the shared field serves right now. With the hub open the tab
/// underneath is hidden, so its search must not be reachable either.
SearchContext? activeSearchContext({
  required NavTab tab,
  required bool personalizationOpen,
  required bool likesSearchActive,
  required BuildContext context,
}) {
  if (!personalizationOpen) return searchContextFor(tab, context);
  if (!likesSearchActive) return null;
  return SearchContext(
    queryProvider: likesSearchQueryProvider,
    hint: S.of(context).appBarSearchHint,
    supportsMetaSearch: true,
  );
}

/// Returns the search context for [tab], or `null` if the tab does not
/// support search yet.
SearchContext? searchContextFor(NavTab tab, BuildContext context) {
  final S loc = S.of(context);
  switch (tab) {
    case NavTab.home:
      return SearchContext(
        queryProvider: homeSearchQueryProvider,
        hint: loc.appBarSearchHint,
        supportsMetaSearch: true,
      );
    case NavTab.wishlist:
      return SearchContext(
        queryProvider: wishlistSearchQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.tierLists:
      return SearchContext(
        queryProvider: tierListsSearchQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.settings:
      return SearchContext(
        queryProvider: settingsSearchQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.collections:
      return SearchContext(
        queryProvider: collectionsSearchQueryProvider,
        hint: loc.appBarSearchHint,
        supportsMetaSearch: true,
      );
    case NavTab.search:
      return SearchContext(
        queryProvider: searchTabQueryProvider,
        hint: loc.appBarSearchHint,
      );
    case NavTab.releases:
      return null;
  }
}
