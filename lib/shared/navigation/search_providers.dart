// Contextual search providers for the global [AppTopBar].
//
// Each search-capable tab has its own query [StateProvider], which keeps the
// input per tab. [searchContextFor] returns the current tab's search context
// (which provider to listen to, which hint to show), or null when the tab does
// not support search.

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

/// Shared [FocusNode] for the [AppTopBar] text field.
///
/// Lives at app level: used by [AppTopBar] for the input and by [AppShell]
/// to focus programmatically on type-to-search (start typing — focus the bar).
final Provider<FocusNode> appTopBarFocusProvider = Provider<FocusNode>((
  Ref ref,
) {
  final FocusNode node = FocusNode(debugLabel: 'AppTopBar-search');
  ref.onDispose(node.dispose);
  return node;
});

/// Collections that items added from the Search tab go into, shown as a
/// multi-select chip row under the filter bar. Empty means the normal "open
/// details, pick a collection in the sheet" flow; a non-empty set switches the
/// tab into "tap a result to add it straight into all of these" mode. Prefilled
/// when search is opened from a collection's "add items"; cleared whenever the
/// Search tab is entered plainly.
final StateProvider<Set<int>> searchTargetCollectionsProvider =
    StateProvider<Set<int>>((Ref ref) => <int>{});

/// One-shot request to open the Search tab, optionally prefilled. Set from
/// another tab (Wishlist, a collection) instead of pushing a separate search
/// screen; consumed and reset to `null` by [AppShell].
class SearchTabRequest {
  /// Creates a [SearchTabRequest].
  const SearchTabRequest({this.query, this.sourceId, this.collectionId});

  /// Query to prefill (and run). When null/empty the Search tab opens empty.
  final String? query;

  /// Browse source to preselect (e.g. `games`), or null to keep the current.
  final String? sourceId;

  /// Collection to add results into; preselected in
  /// [searchTargetCollectionsProvider].
  final int? collectionId;
}

/// Pending [SearchTabRequest]; see [SearchTabRequest].
final StateProvider<SearchTabRequest?> searchTabRequestProvider =
    StateProvider<SearchTabRequest?>((Ref ref) => null);

/// Describes the search context for one tab.
class SearchContext {
  /// Creates a [SearchContext].
  const SearchContext({
    required this.queryProvider,
    required this.hint,
  });

  /// Where the current query is read from and written to.
  final StateProvider<String> queryProvider;

  /// Placeholder shown in the search field for this tab.
  final String hint;
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
