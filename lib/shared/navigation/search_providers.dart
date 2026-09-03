import 'package:core/models/media_type.dart';
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
