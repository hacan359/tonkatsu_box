# Changelog

All notable changes to this project are documented in this file.

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Entries follow the [GNU Change Log style](https://www.gnu.org/prep/standards/html_node/Style-of-Change-Logs.html): a short topic line, an optional body describing the change, then a list of affected files with the names of classes / methods / variables in parentheses so each symbol is greppable.

## [Unreleased]

### Added

- **Add a date format setting for the whole app**

  Settings → Appearance now has a Date format option with four presets:
  ISO (2026-05-25), DMY with dots (25.05.2026), MDY with slashes
  (05/25/2026) and DMY with the localised month name (25 May 2026).
  The choice is applied wherever the app renders a `DateTime` to the
  user: collection card Activity Dates, episode tracker watched-date,
  and RetroAchievements unlock dates. Storage is unchanged — the
  setting only affects presentation. The preset id is persisted in
  `SharedPreferences` and is included in the config export / import.

  * lib/shared/utils/date_format_preset.dart (DateFormatPreset,
    DateFormatPreset.fromId, DateFormatPreset.format): New enum of
    presets backed by `intl.DateFormat` patterns.
  * lib/features/settings/providers/settings_provider.dart
    (SettingsKeys.dateFormat, SettingsKeys.dateFormatDefault,
    SettingsState.dateFormat, SettingsNotifier.setDateFormat,
    SettingsNotifier._loadFromPrefs, SettingsNotifier.clearSettings):
    Persist and expose the chosen preset id.
  * lib/features/settings/screens/settings_screen.dart
    (_SettingsScreenState._dateFormatLabel,
    _SettingsScreenState._showDateFormatPicker): New tile and picker
    dialog under Appearance.
  * lib/core/services/config_service.dart (ConfigService._settingsKeys):
    Add `SettingsKeys.dateFormat` to the exported keys.
  * lib/features/collections/widgets/activity_dates_section.dart
    (ActivityDatesSection, _DateRow): Switch from a hardcoded
    `_formatDate` to the preset chosen in settings; widget becomes
    `ConsumerWidget`.
  * lib/features/collections/widgets/episode_tracker_section.dart:
    Drop the hardcoded month array; format the watched-date through
    the preset.
  * lib/features/collections/widgets/ra_achievements_section.dart
    (_RaAchievementsSectionState._formatDate): Keep the relative
    today / yesterday / N days ago labels; format the older fallback
    through the preset.
  * lib/shared/widgets/media_detail_view.dart (MediaDetailView,
    _MediaDetailViewState, _MediaDetailViewState._buildActivityDatesRow,
    _MediaDetailViewState._buildDateChip, _formatActivityDate): Switch
    to `ConsumerStatefulWidget`; chip formatter takes a `formatter`
    closure so the preset is resolved once per row build.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb: Add
    `settingsDateFormat`, `settingsDateFormatSubtitle`.

- **Custom date picker dialog with calendar and text input side by side**

  Replaces Material `showDatePicker` for the Activity Dates picker:
  shows a `CalendarDatePicker` and a `TextField` (yyyy-MM-dd) at the
  same time, kept in sync. Tap a day on the calendar to fill the
  field; type a valid date in the field to move the calendar. The OK
  button is disabled while the typed value is empty, malformed, or out
  of range. Desktop lays them out in a row, Android stacks them with
  the text field on top so it stays visible above the keyboard.

  * lib/shared/widgets/dual_date_picker_dialog.dart
    (DualDatePickerDialog, _DualDatePickerDialogState, showDualDatePicker):
    New.
  * lib/features/collections/widgets/activity_dates_section.dart
    (ActivityDatesSection._pickDate),
    lib/shared/widgets/media_detail_view.dart
    (_MediaDetailViewState._pickActivityDate): Call `showDualDatePicker`
    instead of `showDatePicker`.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb: Add
    `dualDatePickerInputLabel`, `dualDatePickerOk`, `dualDatePickerCancel`,
    `dualDatePickerErrorEmpty`, `dualDatePickerErrorFormat`,
    `dualDatePickerErrorRange`.
### Fixed

- **Fix external links not opening on Android 11+**

  Buttons and links that should open a browser, mail client or dialer
  did nothing on Android. Starting with Android 11, apps must declare
  the intents they want to resolve via `<queries>` in the manifest;
  the previous manifest only declared `PROCESS_TEXT`, so
  `url_launcher`'s `canLaunchUrl` / `launchUrl` calls saw zero matching
  activities for `http` / `https` / `mailto` / `tel` and silently
  failed. The manifest now declares the standard `VIEW` intents for
  http and https, `SENDTO` for mailto, and `DIAL` for tel.

  * android/app/src/main/AndroidManifest.xml: Add `VIEW` (http, https),
    `SENDTO` (mailto), `DIAL` (tel) intents to the `<queries>` block.

## [0.30.0] - 2026-05-22

### Fixed

- **Stop the database from opening twice during startup**

  On cold start several providers may touch the `database` getter
  before the first `_initDatabase` future has settled. The previous
  cache-on-completion logic let each caller kick off its own open,
  and the second one would race `onUpgrade` and crash a non-idempotent
  migration (e.g. `ALTER TABLE … ADD COLUMN` saw the column already
  added by the first runner). The getter now single-flights: the
  first call assigns the in-flight future to `_opening`, every
  concurrent caller awaits the same future, and `_opening` is cleared
  on success (after `_database` is set) or on error (so a failed open
  can be retried).

  * lib/core/database/database_service.dart (DatabaseService.database,
    DatabaseService._opening): Replace the cache-on-completion getter
    with a single-flight pattern guarded by `_opening`.

### Added

- **Refresh a collection item from its source API on demand**

  Item detail's ⋮ menu gains a "Refresh from source" action that
  re-fetches the metadata and cover from IGDB (games), TMDB (movies,
  TV, animation), AniList (anime, manga) or VNDB (visual novels),
  upserts the fresh row into the cache tables, and deletes the
  cached image so it re-downloads with the new URL. Useful when a
  cover gets corrupted during sync, the source updated metadata, or
  a backup restore left stale rows. Custom items are skipped (no
  external source). The action is single-tap, surfaces success /
  not-found / unsupported / failed states via snackbar, and
  invalidates the open detail and collection lists so the UI shows
  the new data without a manual refresh.

  * lib/features/collections/helpers/collection_actions.dart
    (CollectionActions.refreshItemFromApi, _refreshItemWork,
    _RefreshOutcome, _RefreshMessage): New shared action that
    dispatches by `mediaType`, swaps in the matching API client,
    and reports the outcome via a context-free helper so UI feedback
    happens behind a single `context.mounted` check.
  * lib/features/collections/screens/item_detail_screen.dart
    (_ItemDetailScreenState._refreshFromApi): Menu entry plus
    handler that invalidates `collectionItemsNotifierProvider` after
    a successful refresh.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (refreshItemFromApi,
    refreshItemSuccess, refreshItemNotFound, refreshItemUnsupported,
    refreshItemFailed): New strings; regenerated
    `app_localizations*.dart`.

### Added

- **Select all visible items from the bulk action bar**

  After picking at least one item, a "Select all" text button appears
  in the bulk action bar next to the "N selected" counter. Tapping it
  extends the selection to every item currently visible after search
  and filters, so a "find then select everything matching" flow
  becomes one tap instead of clicking each card. The button hides
  when the visible set is already fully selected or when the host
  screen doesn't expose a visible-item count.

  * lib/features/collections/widgets/bulk_action_bar.dart
    (BulkActionBar): Add `visibleCount` and `onSelectAllVisible`
    parameters; render a `TextButton` between the counter and the
    existing actions when the callback is set and
    `visibleCount > items.length`.
  * lib/features/collections/widgets/collection_screen/collection_bulk_action_bar.dart
    (CollectionBulkActionBar): Accept `CollectionFilters? filters`
    and `List<CollectionTag> tags`, apply them to the full item list
    to derive the visible set, and wire the new callback to
    `CollectionSelectionNotifier.selectAll`.
  * lib/features/collections/screens/collection_screen.dart
    (_CollectionScreenState.build): Lift `CollectionFilters` and
    tags resolution above the bulk action bar so the bar gets the
    same filtered set as `CollectionItemsView`.
  * lib/features/home/screens/all_items_screen.dart
    (AllItemsScreen.build): Compute `visibleItems` via
    `_applyFilter` once, pass to the bulk action bar with
    `AllItemsSelectionNotifier.selectAll`, and reuse the same list
    inside `itemsAsync.when` instead of filtering twice.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (bulkSelectAllVisible):
    New label string; regenerated `app_localizations*.dart`.
  * test/features/collections/widgets/bulk_action_bar_test.dart: New.
    Cover the show/hide branches for the Select all button and
    confirm the callback fires on tap.

- **Reflect active filters in All Items media-type chevron counts**

  Counts shown next to each chevron on the home screen now drop and
  rise with the search query, status, platform and tag filters, so
  it's obvious how many of each type are currently visible. The
  "Hide empty media types" setting still keys off raw totals — a
  search that wipes out a category no longer makes the chevron itself
  disappear, matching how the collection filter bar already worked.

  * lib/features/home/screens/all_items_screen.dart
    (AllItemsScreen._applyFilter, AllItemsScreen._matchesNonTypeFilters,
    AllItemsScreen._countByMediaType, AllItemsScreen._rawTotalsByMediaType,
    AllItemsScreen._buildMediaTypeBar): Split filtering into a shared
    non-type predicate; chevron labels use a filter-aware count while
    chevron visibility under `hideEmptyMediaTypeChevrons` uses raw
    per-type totals.
  * test/features/home/screens/all_items_screen_test.dart
    (_FakeSettingsNotifier, "should keep chevrons with non-zero totals
    visible even when search filters them out"): Add a regression test
    that drives the search provider to a non-matching query and
    asserts the Games / Movies chevrons stay mounted.

### Changed

- **Split IgdbApi god class into layered files under `core/api/igdb/`**

  The 770-line `IgdbApi` is now a thin facade that delegates to four focused
  sub-APIs (transport+auth, games, platforms, genres) plus a shared types
  file. Public method signatures, constructor, provider and exception types
  are preserved 1:1, so all 18 call sites and 9 test files keep working
  without changes. Same pattern as the earlier AniList split.

  * lib/core/api/igdb_api.dart (IgdbApi): Rewritten as a facade that
    forwards `setCredentials`, `clearCredentials`, `getAccessToken`,
    `validateCredentials`, `fetchPlatforms`, `fetchPlatformsByIds`,
    `searchGames`, `multiSearchGamesByName`, `lookupSteamGames`,
    `getGameById`, `getGamesByIds`, `getTopGamesByPlatform`, `browseGames`,
    `fetchGenres`, `dispose`, `onTokenRefreshed` and `maxMultiQueryBatch`
    to the sub-APIs.
  * lib/core/api/igdb/igdb_http_client.dart (IgdbHttpClient): New.
    Owns Dio, credential state, Twitch OAuth (`getAccessToken`,
    `validateCredentials`), `post` with retry-on-401, `_tryRefreshToken`
    guarded by `_isRefreshing`, `handleDioException`, `ensureCredentials`.
  * lib/core/api/igdb/igdb_games_api.dart (IgdbGamesApi): New. Holds
    `_gameFields`, `maxMultiQueryBatch`, `_multiSearchLimit`,
    `_steamSource` and all game-domain methods.
  * lib/core/api/igdb/igdb_platforms_api.dart (IgdbPlatformsApi),
    igdb_genres_api.dart (IgdbGenresApi),
    igdb_types.dart (TwitchAuthResult, IgdbApiException,
    IgdbTokenRefreshedCallback): New, extracted as-is.
  * lib/core/api/igdb/README.md: New. Documents the layer breakdown and
    callouts on OAuth refresh, multiquery cap, Steam two-step lookup.

- **Replace raw collection dropdowns with the shared picker field**

  All places where the user picked one collection from a form
  (import screens for MAL / AniList / Trakt / Steam /
  RetroAchievements, in-app `.xcoll` import on the home screen,
  tier-list creation, browse-collections settings, mood grid
  picker) now use a single `CollectionPickerField` styled like the
  rest of the project's inputs. Tapping it opens the same
  collection-picker dialog used by the bulk "Move/Copy to
  collection" actions, so list overflow, sorting and search now
  behave consistently and the dialog no longer spills past the
  parent dialog edges. The mood-grid case additionally exposes an
  "All collections" entry via the new `nullLabel` / `nullIcon`
  options on the picker, which the underlying dialog renders with
  its own icon so it doesn't blur into the "Without Collection"
  tile.

  * lib/shared/widgets/collection_picker_field.dart
    (CollectionPickerField): New. Form-field shell that delegates
    to `showCollectionPickerDialog`, supports the optional
    `nullLabel` / `nullSubtitle` / `nullIcon` flow for "any/all"
    semantics and reactively renders the selected collection's
    name + author from `collectionsProvider`.
  * lib/shared/widgets/collection_picker_dialog.dart
    (showCollectionPickerDialog, _CollectionPickerContent,
    _CollectionPickerContentState._buildUncategorizedTile,
    _CollectionPickerContentState._buildLeadingIcon,
    _CollectionPickerContentState._buildIconBox): Accept optional
    `uncategorizedLabel` / `uncategorizedSubtitle` /
    `uncategorizedIcon` overrides and extract `_buildIconBox` so
    the relabelled tile no longer reuses the default "Uncategorized"
    subtitle or inbox icon.
  * lib/features/collections/screens/home_screen.dart,
    lib/features/settings/content/mal_import_content.dart,
    lib/features/settings/content/anilist_import_content.dart,
    lib/features/settings/content/trakt_import_content.dart,
    lib/features/settings/content/steam_import_content.dart,
    lib/features/settings/content/ra_import_content.dart,
    lib/features/settings/content/browse_collections_content.dart,
    lib/features/tier_lists/widgets/create_tier_list_dialog.dart:
    Drop the local `DropdownButton` / `DropdownButtonFormField` and
    its `DropdownMenuItem` wiring; route the selection through
    `CollectionPickerField`.
  * lib/features/tier_lists/widgets/mood_grid_item_picker.dart
    (MoodGridItemPickerState): Same migration, with `nullLabel`
    set to `l.moodGridPickerAllCollections` so the "All
    Collections" sentinel keeps its semantics.
  * test/shared/widgets/collection_picker_field_test.dart: New.
    Cover hint vs. selected vs. "all" rendering and verify a
    disabled field swallows taps.

- **Drop the author suffix from the mood-grid watermark**

  Mood-grid exports now read "made by Tonkatsu Box" without the
  trailing "— $authorName", matching the tier-list watermark.

  * lib/features/tier_lists/widgets/mood_grid_export_view.dart
    (MoodGridExportView, MoodGridExportView.authorName): Remove
    the `authorName` field and the conditional suffix.
  * lib/features/tier_lists/screens/mood_grid_detail_screen.dart:
    Stop reading `settingsNotifierProvider.authorName` and drop
    the now-unused `settings_provider` import.

- **Label bulk-move/copy leftovers as "Duplicates" instead of "Skipped"**

  A move or copy can only "skip" an item when the target already
  holds the same `(media_type, external_id)` pair (the UNIQUE index
  rejects the write). The previous wording made the count look like
  an opaque failure; renaming surfaces the real reason.

  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (bulkResult): Replace
    "Skipped" / "Пропущено" with "Duplicates" / "Дубликаты"; sync
    `app_localizations_en.dart` and `app_localizations_ru.dart`.

- **Split the AniList API god class into layered files**

  `anilist_api.dart` (1409 LOC) is now a thin facade that owns a
  `Dio` and delegates to four single-responsibility services under
  `lib/core/api/anilist/`. GraphQL strings, exception types, the
  Dio transport, media parsing, MAL→AniList lookup and user-list
  fetching each get their own file (≤220 LOC), and the duplicated
  `AniListAnimeGenreFilter` collapses into `AniListGenreFilter` via
  a `forAnime` flag. Field selection in every query drops the
  unused `meanScore`, `popularity`, `season`, `seasonYear`,
  `countryOfOrigin` and `nextAiringEpisode.airingAt` to save
  bandwidth. The public API (`AniListApi`, `aniListApiProvider`,
  exceptions, `AniListListEntry`, `AniListMalLookupResult`,
  `fetchUserMediaList`, MAL lookup variants) stays unchanged — no
  caller had to be touched.

  * lib/core/api/anilist_api.dart (AniListApi): 1409 LOC → 132.
    Now constructs `AniListGraphQLClient` once and forwards every
    method to `AniListMediaApi`, `AniListMalLookupApi` or
    `AniListUserListApi`. Re-exports types via
    `export 'anilist/anilist_types.dart'` so existing imports keep
    working.
  * lib/core/api/anilist/anilist_graphql_client.dart
    (AniListGraphQLClient.post, AniListGraphQLClient.unwrapData,
    AniListGraphQLClient.logErrors,
    AniListGraphQLClient._mapDioException,
    AniListGraphQLClient._parseRetryAfter): New. The single place
    that talks to `https://graphql.anilist.co` and converts
    `DioException` into typed AniList exceptions.
  * lib/core/api/anilist/anilist_queries.dart (AniListQueries,
    aniListMaxPerPage, aniListBatches): New. Holds the eight
    GraphQL strings as `static const`, the shared
    `perPage` cap, and the shared batching iterator reused by both
    media and MAL lookups.
  * lib/core/api/anilist/anilist_media_parser.dart
    (AniListMediaParser.animePage, AniListMediaParser.mangaPage,
    AniListMediaParser.fuzzyDate): New. Pure
    `Page { media }` decoders plus fuzzy-date parsing.
  * lib/core/api/anilist/anilist_media_api.dart (AniListMediaApi.searchManga,
    AniListMediaApi.browseManga, AniListMediaApi.browseAnime,
    AniListMediaApi.getMangaById, AniListMediaApi.getAnimeById,
    AniListMediaApi.getMangaByIds, AniListMediaApi.getAnimeByIds):
    New. Search, browse and id-lookup endpoints for both media
    types.
  * lib/core/api/anilist/anilist_mal_lookup_api.dart
    (AniListMalLookupApi.getAnimeByMalIds,
    AniListMalLookupApi.getMangaByMalIds,
    AniListMalLookupApi.getAnimeByMalIdsTolerant,
    AniListMalLookupApi.getMangaByMalIdsTolerant,
    AniListMalLookupApi._runBatchWithRetry): New. Holds the
    rate-limit retry loop and the failed-id bookkeeping that the
    MAL importer relies on.
  * lib/core/api/anilist/anilist_user_list_api.dart
    (AniListUserListApi.fetchUserMediaList,
    AniListUserListApi._translateUserErrors,
    AniListUserListApi._parseListEntry): New. `MediaListCollection`
    fetcher, custom-list dedup and `isAdult` filter.
  * lib/core/api/anilist/anilist_types.dart (AniListApiException,
    AniListRateLimitException, AniListUserNotFoundException,
    AniListPrivateProfileException, AniListMalLookupResult,
    AniListListEntry): New. Exceptions and data classes shared by
    every layer.
  * lib/core/api/anilist/README.md: New. Layer map, AniList docs
    link, batching/rate-limit/error-mapping notes.
  * lib/features/search/filters/anilist_genre_filter.dart
    (AniListGenreFilter): Accepts `forAnime` and switches
    `cacheKey` between `genre_anilist_anime` and `genre_anilist`.
  * lib/features/search/filters/anilist_anime_genre_filter.dart
    (AniListAnimeGenreFilter): Removed; the manga and anime
    variants shared 69 identical lines apart from `cacheKey`.
  * lib/features/search/sources/anilist_anime_source.dart
    (AniListAnimeSource.filters): Use
    `AniListGenreFilter(forAnime: true)` instead of the deleted
    sibling class.
  * lib/shared/models/anime.dart (Anime.fromJson),
    lib/shared/models/manga.dart (Manga.fromJson): Stop reading
    `meanScore`, `popularity`, `season`, `seasonYear`,
    `nextAiringEpisode.airingAt` (anime) and `countryOfOrigin`
    (manga). The fields and their DB columns stay nullable for
    backward compatibility with existing rows.
  * test/shared/models/anime_test.dart,
    test/shared/models/manga_test.dart: Drop the assertions for
    fields that no longer round-trip through `fromJson`.
  * test/features/search/filters/anilist_genre_filter_test.dart:
    Add a case for `forAnime: true` producing the anime cacheKey.

- **Split the wishlist screen god class**

  `_WishlistScreenState` shed its tag-header chrome, item tile, and
  AlertDialog boilerplate into reusable units under `widgets/`. Four
  repeated confirm/prompt dialogs collapse to one shared `_confirm`
  helper in `WishlistDialogs`. The tile's right-click / long-press
  context menu loses its string-keyed `case 'search' / 'edit' / ...`
  switch and now dispatches on a typed enum, matching the
  `_TagMenuChoice` sealed-class pattern that already lived in this
  file.

  * lib/features/wishlist/screens/wishlist_screen.dart
    (_WishlistScreenState): 994 LOC → 345. Extract `_promptTagForBulk`,
    `_promptRenameTag`, `_confirmDeleteTag`, `_confirmClearResolved`,
    inline delete-item confirm, and bulk-delete confirm to
    `WishlistDialogs`. Inline `_BulkAction` becomes public
    `WishlistBulkAction` exported by the header widget. Notifier calls
    + filter state updates stay on the screen so dialog helpers remain
    pure.
  * lib/features/wishlist/widgets/wishlist_dialogs.dart (WishlistDialogs.promptBulkTag,
    promptRenameTag, confirmDeleteTag, confirmClearResolved,
    confirmDeleteItem, confirmBulkDelete, _confirm): New. Each returns
    the user's pick and never touches the wishlist provider.
  * lib/features/wishlist/widgets/wishlist_tag_header.dart
    (WishlistTagHeader, WishlistBulkAction, _TagPickerSegment,
    _BulkActionsSegment, _TagMenuChoice, _TagMenuFilter, _TagMenuRename,
    _TagMenuDelete): New. Hosts the chevron filter bar + bulk-action
    dropdown previously inlined.
  * lib/features/wishlist/widgets/wishlist_tile.dart (WishlistTile,
    _TileAction): New. Context menu uses a typed `_TileAction` enum.

- **Split the create-custom-item dialog god class**

  `_CreateCustomItemDialogState` (~700 LOC) sheds the cover image
  preview / picker, the two private dialogs (searchable list and
  multi-select genre), and the form-result data class into focused
  files under `widgets/custom_item/`. The dialog's dead "My rating"
  star section is removed — `_userRating` was collected but never
  reached `CustomItemData`, so nothing was ever saved.

  * lib/features/collections/widgets/create_custom_item_dialog.dart
    (_CreateCustomItemDialogState): 1089 LOC → 538. Replace
    `_buildCoverPreview`, `_buildCoverPlaceholder`, `_pickCoverImage`
    with `CustomCoverPreview` and `pickCustomCoverImage`. Drop
    `_userRating` and `_buildRatingSection` (dead code). Re-export
    `CustomItemData` from its new home so call sites keep working.
  * lib/features/collections/widgets/custom_item/custom_item_data.dart
    (CustomItemData), cover_image_picker.dart (pickCustomCoverImage,
    CustomCoverPreview, CoverPickResult), searchable_list_dialog.dart
    (SearchableListDialog), multi_select_genre_dialog.dart
    (MultiSelectGenreDialog): New.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (customItemMyRating):
    Removed — the rating UI it labelled was deleted as dead code.
    Regenerated `app_localizations*.dart`.

- **Replace draggable FAB fan menu with a labeled pill stack**

  The popup menu attached to every draggable FAB no longer fans small
  unlabeled circles around the ⋮ button; it opens as a vertical column
  of [text + icon] pills anchored to the FAB's right edge. Each action's
  full localised label is visible inline, removing the touch-device
  reliance on tooltips. The stack scrolls within the available vertical
  room (minus the system status bar / nav bar) when there are more
  items than fit, and flips to opening downward if there's more room
  below the FAB. The tier-lists screen's create FAB also changes
  `Icons.leaderboard` → `Icons.add` so the trigger reads as "add" rather
  than "stats".

  * lib/shared/widgets/draggable_fab.dart (_FanMenuPage, _PillButton,
    _PillButtonState): Replace the radial `_FanMenuPage` (circular
    `_FanButton` icons distributed around the FAB) with a pill-stack
    layout. `_buildAnimatedPill` staggers each entry; the column is
    wrapped in `SingleChildScrollView` constrained by
    `MediaQuery.viewPaddingOf(context)` so it stays clear of system
    chrome. Drops `_FanButton` / `_FanButtonState` and the `dart:math`
    import that was only needed for the fan's angle math.
  * lib/features/tier_lists/screens/tier_lists_screen.dart
    (_TierListsScreenState.build): FAB main action icon
    `Icons.leaderboard` → `Icons.add`.

- **Lazy-render the collection table and react chevron counts to the active status**

  Opening a 500+ item collection in table mode no longer freezes ~500ms:
  the table body is now a `SliverList.builder` (and `SliverReorderableList`
  in manual sort) embedded in a shared `CustomScrollView`, so only the
  rows in the viewport are built. The type chevron bar above the table
  also reacts to the active status filter — picking "Completed" in the
  dropdown or cycling the in-table Status column reflects in the per-type
  counts. Chevrons that were visible before the filter stay visible even
  if their filtered count is zero, so the bar no longer jumps.

  * lib/features/collections/widgets/collection_table/collection_table_view.dart
    (CollectionTableView, _CollectionTableViewState._buildSortableSliver,
    _buildReorderableSliver, initState, didUpdateWidget): Replace
    `ListView.builder(shrinkWrap, NeverScrollable)` /
    `ReorderableListView.builder` with `SliverList.builder` /
    `SliverReorderableList`. Accept `heroHeader` so the collection hero
    becomes the first sliver, drop the outer `_withHeader(wrapInScroll)`
    wrapper. Outer horizontal scroll only kicks in when `maxWidth < 864`.
    Add `onFilterStatusChanged` callback, sync to null on mount and on
    items-identity change so the parent screen never holds a stale
    column-header filter.
  * lib/features/collections/widgets/collection_items_view.dart
    (CollectionItemsView, onTableFilterStatusChanged): Forward the
    table's status filter outward; drop `_withHeader` for table mode.
  * lib/features/collections/screens/collection_screen.dart
    (_CollectionScreenState._tableFilterStatus,
    _effectiveStatusForChevrons): Track the table column's status filter
    separately so the chevron bar reflects it; the dropdown still shows
    only the dropdown-selected status.
  * lib/features/collections/widgets/collection_filter_bar.dart
    (CollectionFilterBar.effectiveStatusForCounts,
    _CollectionFilterBarState._typeCounts, _totalCountFor): Split
    "visibility" (uses `CollectionStats` totals) from "displayed count"
    (filtered by status) so chevrons don't disappear when the filter
    zeroes a type.
  * lib/features/collections/widgets/collection_filter_sheet.dart,
    lib/features/settings/widgets/settings_group.dart: Wrap the
    decorated body in `Material(type: MaterialType.transparency)` so
    descendant `ListTile` / `RadioListTile` widgets find a Material
    ancestor before the styled `DecoratedBox` / `Container`, silencing
    "ListTile background color or ink splashes may be invisible".
  * test/features/collections/widgets/collection_table_view_test.dart:
    Drop the `find.byType(ListView)` assertion (sliver-based view no
    longer exposes one); rely on `takeException()` for the render-empty
    check.

- **Widen the collection table Status column**

  Status labels like "Backlog", "Want to watch", "Completed" no longer
  truncate to the leading icon. The column grows 96 → 140 px in both
  header and rows; the table's minimum width before horizontal scroll
  bumps 820 → 864 to keep everything aligned.

  * lib/features/collections/widgets/collection_table/table_header.dart,
    lib/features/collections/widgets/collection_table/table_row.dart:
    Status column width 96 → 140.
  * lib/features/collections/widgets/collection_table/collection_table_view.dart
    (_CollectionTableViewState._minTableWidth): 820 → 864.

- **Split the collection screen god class and unify the error state**

  The 984-line `_CollectionScreenState` shed its FAB tower, the bulk-action
  bar, the error state, the create-tier-list dialog, and the filter logic
  into reusable units under `widgets/collection_screen/`,
  `widgets/dialogs/`, and `helpers/`. The string-typed menu dispatch
  (`'custom_item'`, `'rename'`, …) became a `CollectionMenuAction` enum
  with an exhaustive switch. The new `CollectionErrorState` widget also
  replaces the byte-identical `_buildErrorState` that the collections home
  screen carried, so both screens now share a single retry view.

  * lib/features/collections/screens/collection_screen.dart
    (_CollectionScreenState._toggleLock, _handleMenuAction): 984 lines → 757.
    Lock toggle and menu dispatch became named handlers; the FAB builders,
    bulk-action Consumer, error state, and tier-list dialog moved out.
  * lib/features/collections/screens/home_screen.dart
    (_CollectionsHomeScreenState._buildErrorState): Removed — replaced
    inline with `CollectionErrorState`.
  * lib/features/collections/widgets/collection_screen/collection_screen_fab.dart
    (CollectionScreenFab, CollectionMenuAction): New widget owning the
    main FAB, primary action row, and secondary action list; the menu
    callback now takes a typed enum instead of a string.
  * lib/features/collections/widgets/collection_screen/collection_bulk_action_bar.dart
    (CollectionBulkActionBar): New ConsumerWidget that watches selection
    and items, short-circuits when empty, and renders `BulkActionBar`.
  * lib/features/collections/widgets/collection_screen/collection_error_state.dart
    (CollectionErrorState): New shared error view used by both the
    collection screen and the collections home screen.
  * lib/features/collections/widgets/dialogs/create_tier_list_dialog.dart
    (CreateTierListDialog.show): New helper — returns the trimmed name and
    disposes its `TextEditingController` via `whenComplete`.
  * lib/features/collections/helpers/collection_filters.dart
    (CollectionFilters, CollectionFilters.apply): New value type that
    holds the four filter sets plus the search query; pure function
    extracted from `_applyFilters`.

- **Split the item detail screen god class and drop the Activity & Progress wrapper**

  The 1488-line `_ItemDetailScreenState` shed seven independent widgets into
  `widgets/item_detail/`: the AppBar with its popup menu, the canvas pane
  with its SteamGridDB and VGMaps side panels, the media-config + chips
  builder, the RA badge, the pulsing RA link, the uncategorized banner,
  and the seasons-info row. The two near-duplicate
  "add from recommendations" handlers (movie / TV show) collapsed into one
  parameterised method. The ExpansionTile wrapper titled "Activity &
  Progress" disappeared too — each inner section (episode tracker, manga /
  anime progress, seasons info) already carries its own header, and the
  outer chrome only duplicated the activity-dates row just above it.

  * lib/features/collections/screens/item_detail_screen.dart
    (_ItemDetailScreenState._toggleLock, _handleMenuAction, _addRecommendation):
    1488 lines → 759. Lock toggle and popup-menu dispatch became named
    handlers; `_addMovieFromRecommendations` / `_addTvShowFromRecommendations`
    now delegate to a single generic helper parameterised by media type,
    `ownMapProvider`, and an `upsert` callback.
  * lib/features/collections/widgets/item_detail/item_detail_app_bar.dart
    (ItemDetailAppBar, ItemDetailMenuAction): New PreferredSize widget
    owning the lock / canvas / edit-custom buttons and the refresh /
    rename / move / clone / remove popup menu.
  * lib/features/collections/widgets/item_detail/item_detail_canvas_view.dart
    (ItemDetailCanvasView, _AnimatedSidePanel): New ConsumerWidget that
    holds the canvas plus the two animated side panels and unifies the
    SteamGridDB / VGMaps "add image" handlers behind a shared `_addImage`.
  * lib/features/collections/widgets/item_detail/item_detail_media_config.dart
    (ItemDetailMediaConfig, ItemDetailMediaConfig.from): New value type
    plus factory that builds cover URL, type label, info chips, backdrop,
    and progress flags off a `CollectionItem` + `BuildContext`.
  * lib/features/collections/widgets/item_detail/item_detail_ra_badge.dart
    (ItemDetailRaBadge): New ConsumerWidget that watches
    `trackerDetailProvider` and `raApiProvider` and renders the linked-RA
    logo, the pulsing link CTA, or `SizedBox.shrink()`.
  * lib/features/collections/widgets/item_detail/pulsing_ra_link.dart
    (PulsingRaLink), seasons_info.dart (SeasonsInfo),
    uncategorized_banner.dart (UncategorizedBanner): Extracted leaf
    widgets — previously private nested classes / build methods.
  * lib/shared/widgets/media_detail_view.dart
    (_MediaDetailViewState._buildExtraSectionsExpansion): Removed.
    `extraSections` now render inline with the same spacing as siblings.
  * test/features/collections/screens/item_detail_screen_test.dart,
    test/shared/widgets/media_detail_view_test.dart: Dropped the
    `expandExtraSections` tap helper and the "Activity & Progress" text
    assertions to match the new inline layout.

- **Refactor canvas dialogs and load the board in two phases**

  The 800-line `_CanvasViewState` shed all its dialog plumbing into a
  dedicated service; the remaining state class now only carries layout,
  gestures, and the build tree. The board also paints sooner: instead of
  blocking the first frame on the seven join queries that hydrate cover
  art and titles, it now renders a skeleton of positions and types as
  soon as the bare canvas rows are loaded, then swaps the hydrated items
  in on the next state tick. Personal (per-item) canvas uses the same
  two-phase shape for symmetry, even though its one-to-few items make
  the perf win negligible there.

  * lib/features/collections/widgets/canvas_item_actions.dart
    (CanvasItemActions.addText, CanvasItemActions.addImage,
    CanvasItemActions.addLink, CanvasItemActions.editItem,
    CanvasItemActions.editConnection): New service that owns the
    add/edit dialogs (text, image, link, edit-connection). Internal
    `_showAndApply` helper collapses the seven copies of the
    show-dialog → null-check → `context.mounted` check →
    forward-to-controller pattern.
  * lib/features/collections/widgets/canvas_view.dart
    (_CanvasViewState): Removed `_handleAddText`, `_handleAddImage`,
    `_handleAddLink`, `_handleEditItem`, `_editTextItem`,
    `_editImageItem`, `_editLinkItem`, `_handleEditConnection`
    (~120 lines). Call sites in `_onCanvasSecondaryTap`,
    `_onItemSecondaryTap`, `_showConnectionContextMenu` now delegate
    to a `late final` `_actions` field.
  * lib/data/repositories/canvas_repository.dart
    (CanvasRepository.enrichItems): New public wrapper around the
    existing `_enrichItemsWithMediaData`. Lets callers split skeleton
    load from media hydration without exposing the private method.
  * lib/features/collections/providers/canvas_provider.dart
    (CanvasNotifier._loadCanvas, CanvasNotifier._loadGeneration),
    lib/features/collections/providers/game_canvas_provider.dart
    (GameCanvasNotifier._loadCanvas, GameCanvasNotifier._loadGeneration):
    Two-phase load — phase 1 fetches positions / viewport / connections
    in parallel and updates state with `isLoading: false`, phase 2
    calls `enrichItems` and swaps in the hydrated list. A
    `_loadGeneration` counter discards phase-2 results from a load
    that was superseded by another reload.

- **Fix canvas regressions on first init, FAB overlap, and stale side-panel state**

  Anime and custom items on a freshly-created board used to open with
  empty cards (no cover, no title) because `CanvasItem.copyWith` in
  the init path silently dropped the `anime` and `customMedia` fields
  while accepting game / movie / TV show. Reloading the canvas hid the
  bug because the read path enriches from cache; first-render was the
  only window. The collection screen's ⋮ FAB also got moved inward
  on canvas mode so it stops landing on top of the canvas-side
  toolbar buttons (VgMaps, SteamGridDB, center-view, reset). And the
  SteamGridDB / VgMaps side panels stop carrying their previous search
  and browser state across canvases — both providers are keyed by
  `collectionId`, so per-item canvases inside the same collection used
  to inherit each other's queries until the panel was closed.

  * lib/data/repositories/canvas_repository.dart
    (CanvasRepository.initializeCanvas): Copy `anime` and
    `customMedia` through to the freshly-created `CanvasItem`s.
  * lib/features/collections/providers/game_canvas_provider.dart
    (GameCanvasNotifier._initializeWithCollectionItem): Copy `anime`
    through to the per-item canvas item.
  * lib/shared/widgets/draggable_fab.dart (DraggableFab.initialRight,
    DraggableFab.initialBottom): New constructor params let callers
    pre-position the FAB without breaking the user's drag-to-relocate
    state.
  * lib/features/collections/screens/collection_screen.dart
    (_CollectionScreenState.build): Pass `initialRight: 72` while in
    canvas mode and key the `DraggableFab` on `_isCanvasMode` so the
    position resets cleanly when the user toggles modes.
  * test/data/repositories/canvas_repository_test.dart
    (CanvasRepository.initializeCanvas should propagate every
    media-type field from CollectionItem): New table-driven test that
    walks every media-type-specific field. Adding a new media type
    requires adding a row here, so the «one type silently forgotten»
    class of bug can't reappear.
  * test/features/collections/providers/game_canvas_provider_test.dart:
    New file mirroring the same propagation check for the per-item
    canvas (seven media types, seven tests).
  * test/features/collections/providers/canvas_provider_test.dart:
    Updated mocks to cover the new `enrichItems` and the split
    `getItems`/`getGameCanvasItems` calls in the two-phase load.
  * lib/features/collections/providers/steamgriddb_panel_provider.dart
    (SteamGridDbPanelNotifier.closePanel): Reset search input,
    results, selection, and current images on close while preserving
    `imageCache`. Translated the file's dartdocs to English while
    touching it.
  * lib/features/collections/providers/vgmaps_panel_provider.dart
    (VgMapsPanelNotifier.closePanel): Reset to a fresh
    `VgMapsPanelState` on close so the captured image URL and the
    last-visited page don't bleed into the next canvas. Translated
    dartdocs to English.
  * test/features/collections/providers/steamgriddb_panel_provider_test.dart,
    test/features/collections/providers/vgmaps_panel_provider_test.dart:
    Add a regression test per panel that confirms `closePanel` wipes
    the search/browser side of the state and (for SteamGridDB) keeps
    `imageCache`.

- **Split search screen god class into per-source handlers and fix animation routing**

  `_SearchScreenState` shrank from ~1500 to ~400 lines. The seven near-duplicate
  blocks (`_onXTap` / `_addXToCollection` / `_addXToAnyCollection` /
  `_showXDetails`) per media type were extracted into focused handler classes
  sharing a `SearchCollectionAdder` that owns the picker → upsert → addItem →
  image cache → snackbar pipeline. The registry resolves handlers by item
  runtime type and supports a `registerForSource` override so the same model
  (e.g. `Game` from a future RAWG source) can plug in source-specific logic
  without touching the screen.

  Along the way three pre-existing animation-routing bugs were fixed. Every
  `SearchSource` now declares a fixed `outputMediaType`, which the grid and
  the Discover feed both consume — replacing hardcoded `MediaType.movie /
  tvShow` plus a per-item `_isAnimation(genres)` heuristic that silently
  misclassified TMDB items. As a result on the Animation tab both movies
  and TV shows now save as `MediaType.animation` (Discover-feed adds went
  in as `movie/tvShow` before). Lastly `isAnimationGenre` became locale-
  and case-aware: TMDB returns `"мультфильм"` (lowercase) for `ru-RU`, but
  our DAO capitalises the first letter on read, so the filter dropped
  every animation row — `«Аватар: Легенда об Аанге»` was missing from the
  Animation tab and simultaneously leaked into TV shows.

  * lib/features/search/services/search_collection_adder.dart
    (SearchCollectionAdder.addToCollection, SearchCollectionAdder.pickCollection,
    SearchCollectionAdder.collectedCollectionIdsAcross, PickedCollection):
    New shared service de-duplicating the add-to-collection pipeline; honours
    `context.mounted` between async hops. `collectedCollectionIdsAcross`
    unions two collected-id providers — replaces duplicated `Future.wait`
    blocks in Movie/TvShow handlers.
  * lib/features/search/handlers/media_action_handler.dart (MediaActionHandler):
    New flat (non-generic) contract — generics dropped to keep the registry
    type-erased; concrete handlers downcast internally.
  * lib/features/search/handlers/game_handler.dart (GameHandler),
    movie_handler.dart (MovieHandler), tv_show_handler.dart (TvShowHandler):
    New per-source handlers for the three media types with non-trivial logic.
    `MovieHandler` and `TvShowHandler` route both regular and
    `MediaType.animation` (with `AnimationSource.movie/tvShow` platform id);
    `TvShowHandler` keeps the post-add season/episode preload; `GameHandler`
    keeps the platform selection dialog.
  * lib/features/search/handlers/simple_media_handler.dart
    (SimpleMediaHandler): New generic single-source handler covering Anime,
    Manga, and VisualNovel — three near-identical handler files (~300 lines
    of duplication) collapsed into one parameterized class. Each model is
    wired in `MediaHandlers` via field extractors (`externalIdOf`,
    `titleOf`, `imageUrlOf`, `upsert`, `sheetBuilder`) and the matching
    `collected*IdsProvider`.
  * lib/features/search/handlers/media_handlers.dart (MediaHandlers,
    MediaHandlers.forItem, MediaHandlers.registerForSource, MediaHandlers.onTap,
    MediaHandlers.addToAnyCollection): New registry with two-level dispatch
    (`(sourceId, type)` then `type`).
  * lib/features/search/models/search_source.dart (SearchSource.outputMediaType):
    New abstract getter — each source declares the `MediaType` it produces
    so consumers no longer have to guess from runtime type or genres.
  * lib/features/search/sources/tmdb_movies_source.dart (TmdbMoviesSource.outputMediaType),
    tmdb_tv_source.dart (TmdbTvSource.outputMediaType),
    tmdb_anime_source.dart (TmdbAnimeSource.outputMediaType),
    igdb_games_source.dart (IgdbGamesSource.outputMediaType),
    anilist_anime_source.dart (AniListAnimeSource.outputMediaType),
    anilist_manga_source.dart (AniListMangaSource.outputMediaType),
    vndb_source.dart (VndbSource.outputMediaType): Override the getter
    with the source-declared `MediaType`.
  * lib/features/search/widgets/browse_grid.dart (BrowseGrid._buildCard):
    Use `state.source.outputMediaType` for every item branch; remove the
    `_isAnimation(TvShow)` helper, the per-item genre heuristic, and the
    `isAnimationGenre` import. Per-item `MediaType.movie/tvShow/game/...`
    hardcodes replaced with the parameterized `mediaType`.
  * lib/features/search/screens/search_screen.dart (_SearchScreenState,
    _SearchScreenState._buildContent): Removed all `_addX*` / `_onXTap` /
    `_showXDetails` methods (~1100 lines); `_onItemTap` now delegates to
    `MediaHandlers`. DiscoverFeed `onAddMovie`/`onAddTvShow` callbacks
    now use `browseState.source.outputMediaType` — previously hardcoded
    to `MediaType.movie`/`MediaType.tvShow`, which silently misclassified
    every recommendation added from the Animation tab.
  * lib/features/search/utils/genre_utils.dart (isAnimationGenre):
    Signature now `(String genre, Map<String, String> genreMap)` and the
    comparison is case-insensitive — matches the localised genre name
    returned by TMDB regardless of the DAO's `_capitalize` on read.
  * lib/features/search/sources/tmdb_anime_source.dart (TmdbAnimeSource._searchWithFilters),
    tmdb_tv_source.dart (TmdbTvSource.fetch): Pass the loaded `genreMap`
    to `isAnimationGenre`.
  * test/features/search/handlers/media_handlers_test.dart: New — locks down
    type-based dispatch, source-id override precedence, and the no-handler
    fallback.
  * test/features/search/handlers/tmdb_handlers_test.dart: New — covers the
    `MediaType.animation` branch of `MovieHandler`/`TvShowHandler`
    (verifies `platformId` becomes `AnimationSource.movie`/`tvShow`) and
    the TvShow post-add preload hook.
  * test/features/search/sources/source_output_media_type_test.dart: New —
    one-liner per source verifying the `outputMediaType` contract.
  * test/features/search/utils/genre_utils_test.dart: Extended for the new
    signature: localised genre map, case-insensitive matching, RU and EN
    samples.
  * test/features/search/models/search_source_test.dart (_TestSource.outputMediaType):
    Implement the new abstract getter on the in-test source.
  * test/helpers/fallbacks.dart (_FakeBuildContext): New mocktail fallback
    for `BuildContext`, needed by the handler tests.

- **Upgrade to Flutter 3.44.0 and fix table-view hero detachment**

  Bumps the project past the Flutter `onReorder → onReorderItem` rename so
  CI's `--fatal-infos` stops blocking release builds. The new callback
  adjusts `newIndex` internally for the removed-element offset, so the
  per-callsite `if (newIndex > oldIndex) newIndex -= 1` workaround is
  dropped. Three call sites of the new debug-only assertion
  «`ListTile` background color or ink splashes may be invisible» introduced
  by Flutter 3.44 are also rewired so descendants paint their ink on a
  proper Material ancestor. Finally the table-view hero banner stops
  «detaching» from the top of the screen on wide windows when the row
  count is small — the old `SingleChildScrollView` + `Column` mistakenly
  anchored its content to the bottom of the viewport on Flutter 3.44, so
  the wrap switches to a `CustomScrollView` mirroring the grid path.

  * lib/features/collections/widgets/collection_items_view.dart
    (CollectionItemsView._withHeader): Replace the inner
    `SingleChildScrollView(child: Column[header, body])` for table/reorder
    modes with a `CustomScrollView` of two `SliverToBoxAdapter`s. Hero
    stays glued to the top when content fits the viewport and still
    scrolls with the rows when it doesn't.
  * lib/features/collections/widgets/collection_items_view.dart,
    lib/features/collections/widgets/collection_table/collection_table_view.dart:
    Switch the inner `ReorderableListView.onReorder` to `onReorderItem`
    and drop the manual index normalisation.
  * lib/features/collections/widgets/rich/rich_collection_body.dart
    (_HeroImage.build): `BoxFit.cover` + `Alignment.topCenter` so the
    hero `SizedBox` always paints fully — the previous `BoxFit.fitWidth`
    left transparent strips above and below very wide banner images.
  * lib/shared/theme/app_theme.dart (_OpaquePageTransitionsBuilder.buildTransitions):
    Wrap every route's child in a transparent `Material` so any descendant
    `ListTile`/`ExpansionTile` has an ink ancestor — the tiled background
    `DecoratedBox` no longer sits directly between Material and ListTile.
  * lib/shared/widgets/media_detail_view.dart (MediaDetailView.build):
    Hoist the outer card fill from `Container.decoration.color` to a
    wrapping `Material`; the inner `Container` keeps only the border and
    radius so it no longer shadows ink splashes from the embedded
    «Activity & Progress» `ExpansionTile`.
  * lib/features/collections/widgets/steamgriddb_panel.dart
    (SteamGridDbPanel.build): Replace the outer `Container(color: ...)`
    with `SizedBox` + `Material`, fixing ink rendering for the search
    results `ListTile`s.
  * android/gradle.properties: Auto-added `android.builtInKotlin=false`
    and `android.newDsl=false` by Flutter migrator on upgrade to 3.44.
  * pubspec.lock: Bumped by `flutter upgrade` (Flutter 3.44.0 / Dart 3.12.0).

- **Surface the primary action of every floating menu as an always-visible button**

  The draggable FAB used to be a single ⋮ that hid every action — including
  "Add" — behind a tap. Each screen now ships a separate, always-visible
  primary button stacked under the ⋮ overflow so the most common action
  is one tap away: Add wishlist entry, Add profile, Create tier list,
  Add tier, Export mood grid image, New collection, Add items, Export
  gamepad log. The ⋮ stays for less-frequent operations and is rendered
  ~17% smaller above the primary button, with the fan menu now opening
  upward/leftward from it so it never overlaps the main button. The
  whole block drags together; tap targets are independent.

  * lib/shared/widgets/draggable_fab.dart (DraggableFab.mainAction,
    _DraggableFabState._buildButton, _DraggableFabState._blockWidth,
    _DraggableFabState._blockHeight, _DraggableFabState._showMenu): New
    `mainAction` parameter that renders an always-visible 48px button
    paired with a 40px ⋮ overflow. Each button hosts its own
    `GestureDetector` for tap routing while sharing pan state for the
    whole-block drag; menu anchor is computed from the ⋮ position so
    the fan radiates around it, not the main button.
  * lib/features/wishlist/screens/wishlist_screen.dart
    (_WishlistScreenState._buildAddItem, _buildFabItems): Add → main;
    toggle resolved + clear resolved stay under ⋮.
  * lib/features/settings/screens/profiles_screen.dart: Add profile →
    main; ⋮ is hidden when no other actions exist.
  * lib/features/tier_lists/screens/tier_lists_screen.dart: Create
    tier list → main; Create mood grid stays under ⋮.
  * lib/features/tier_lists/screens/tier_list_detail_screen.dart:
    Add tier → main; Export image + Clear all stay under ⋮.
  * lib/features/tier_lists/screens/mood_grid_detail_screen.dart:
    Export image → main; Rename + Delete stay under ⋮.
  * lib/features/collections/screens/home_screen.dart: New collection
    → main; Import / view toggle / sort stay under ⋮.
  * lib/features/collections/screens/collection_screen.dart
    (_CollectionScreenState._buildMainFabAction): Add items → main
    (only when editable and not in canvas mode); view toggles and
    secondary actions stay under ⋮.
  * lib/features/settings/screens/gamepad_debug_screen.dart: Export
    log → main; Clear logs stays under ⋮.

- **Make backup restore visibly atomic, faster, and impossible to interrupt by accident**

  Restoring a large backup used to look "done" while SQLite was still
  flushing the last collection's writes; closing the app at that point
  truncated the data. The restore flow now shows a modal,
  dismiss-locked progress dialog ("Restoring backup — do not close the
  app. This may take several minutes for large backups.") with a real
  per-collection counter and a final "Finishing up…" stage so the UI
  only goes away once the operation has actually returned. The
  `BackupProgress` callback is fired after each collection finishes
  (not before it starts), so the bar never claims completion ahead of
  the database write. On desktop, an `AppLifecycleListener` vetoes
  OS-level close requests for the duration of the restore (taskbar
  close, alt+F4), letting the user know to wait instead of corrupting
  data — kill -9 and power cuts still bypass this, but those are out
  of scope. At the very end of the restore the WAL is force-flushed
  via `PRAGMA wal_checkpoint(TRUNCATE)` so a user deleting the
  sidecar `-wal`/`-shm` files afterwards can't lose the tail-of-
  restore writes (wishlist + mood grids, which land last). The
  database now opens in WAL journal mode with
  `synchronous = NORMAL`, the SQLite-recommended durable-but-fast
  combination — restores (and every other write-heavy operation,
  including imports and canvas edits) run noticeably faster because
  commits batch into one fsync per checkpoint instead of one fsync
  per write.

  * lib/core/database/database_service.dart (DatabaseService._initDatabase):
    Issue `PRAGMA journal_mode = WAL` (via `rawQuery` — Android's
    SQLiteDatabase rejects PRAGMAs that return a result via `execute`)
    and `PRAGMA synchronous = NORMAL` in `onConfigure`. Single change,
    broad benefit — applies to every write the app makes, not just
    restore.
  * lib/core/services/backup_service.dart (BackupService,
    BackupService.restoreFromBackup, restoreInProgressProvider):
    Inject `DatabaseService` so the restore can issue a final
    `PRAGMA wal_checkpoint(TRUNCATE)` before returning; report
    `BackupProgress` after each collection import (so `current` only
    advances once the write is durable); emit a terminal
    `'finalizing'` stage before returning; expose a
    `StateProvider<bool>` that the app shell watches for the
    exit-veto.
  * lib/features/settings/screens/settings_screen.dart
    (_RestoreProgressDialog, _SettingsScreenState._handleRestore):
    Replace the loading snackbar with a `PopScope(canPop: false)`
    modal dialog driven by a `ValueNotifier<BackupProgress?>`; flip
    `restoreInProgressProvider` while the future is in flight.
  * lib/app.dart (TonkatsuBoxApp, _TonkatsuBoxAppState): Switch to
    `ConsumerStatefulWidget`; register an `AppLifecycleListener` whose
    `onExitRequested` returns `AppExitResponse.cancel` while
    `restoreInProgressProvider` is true.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (restoreProgressTitle,
    restoreProgressWarning, restoreStageReading,
    restoreStageCollections, restoreStageWishlist,
    restoreStageSettings, restoreStageFinalizing): New strings;
    regenerated `app_localizations*.dart`.

### Added

- **Group wishlist entries with tags, bulk-delete by tag, and search inside notes**

  The wishlist now carries an optional `tag` per entry so bulk-imported
  batches can be grouped, filtered, and removed in one action instead
  of cleaned up one by one. Every importer that may dump unmatched
  rows into the wishlist — MyAnimeList, Steam, RetroAchievements,
  Trakt — stamps every wishlist row it adds with an auto-generated tag
  of shape `<source>-<unix-ms>` (`MyAnimeList-...`, `Steam-...`,
  `RetroAchievements-...`, `Trakt-...`), guaranteed unique per run —
  two imports back-to-back never merge into the same bucket. The wishlist
  screen gets a full-width chevron filter bar in the same visual language
  as the collection / search screens: left segment picks the active tag
  (popup lists every tag with per-bucket counts and, when a specific tag
  is selected, "Rename tag" / "Delete tag and all entries" actions);
  right segment is bulk-actions — apply a tag to every visible entry,
  strip the tag, or delete the visible subset (each with a confirmation
  dialog). The free-text search now matches the `note` field in addition
  to the title, so "find by comment, then mass-tag/delete" works as one
  flow. The add/edit form has a new optional "Tag" input so users can
  drop a new entry directly into an existing group. Backup archives
  include the new column so `.xcoll(x)` restore round-trips it.

  * lib/core/database/schema.dart (DatabaseSchema.createWishlistTable):
    Add `tag TEXT` column to fresh-install wishlist DDL.
  * lib/core/database/migrations/migration_v40.dart (MigrationV40),
    lib/core/database/migrations/migration_registry.dart: New v40
    migration that adds `tag` on upgrade.
  * lib/core/database/database_service.dart: Bump schema version to 40;
    extend wishlist facade with `tag` / `clearTag` plumbing,
    `deleteWishlistItemsByTag`, `renameWishlistTag`.
  * lib/core/database/dao/wishlist_dao.dart (WishlistDao.addWishlistItem,
    WishlistDao.updateWishlistItem, WishlistDao.getWishlistItemsFiltered,
    WishlistDao.deleteWishlistItemsByTag, WishlistDao.renameWishlistTag,
    WishlistTagCount): Tag-aware CRUD; new filtered query consumes the
    `WishlistTagFilter` sealed type.
  * lib/shared/models/wishlist_item.dart (WishlistItem.tag,
    WishlistItem.copyWith, WishlistItem.fromDb, WishlistItem.toDb):
    Carry the new field end-to-end.
  * lib/shared/models/wishlist_tag.dart (WishlistTagFilter,
    WishlistTagFilterAll, WishlistTagFilterUntagged,
    WishlistTagFilterNamed, WishlistTagInfo, buildImportTag,
    parseWishlistTag): New — sealed filter type plus
    `%source%-<unix-ms>` auto-tag builder and parser used by the UI to
    render auto-tags as "Source — date time".
  * lib/data/repositories/wishlist_repository.dart
    (WishlistRepository.add, WishlistRepository.getAll,
    WishlistRepository.update, WishlistRepository.deleteByTag,
    WishlistRepository.renameTag): Tag-aware passthroughs.
  * lib/features/wishlist/providers/wishlist_provider.dart
    (WishlistNotifier.add, WishlistNotifier.updateItem,
    WishlistNotifier.deleteByTag, WishlistNotifier.renameTag,
    WishlistNotifier.applyTagToIds, WishlistNotifier.deleteIds,
    wishlistTagsProvider): Tag-aware mutations + bulk operations on a
    set of ids + derived provider that aggregates per-tag counts in
    memory (Untagged first, then most recent named tag).
  * lib/features/wishlist/screens/wishlist_screen.dart
    (_WishlistScreenState._tagFilter, _WishlistScreenState._applyFilters,
    _WishlistScreenState._promptRenameTag,
    _WishlistScreenState._confirmDeleteTag,
    _WishlistScreenState._runBulkAction,
    _WishlistScreenState._promptTagForBulk, _WishlistTagHeader,
    _TagPickerSegment, _BulkActionsSegment, _TagMenuChoice, _BulkAction):
    Full-width chevron filter bar built on `DropdownChevronSegment`
    (consistent with collection / search screens); extend the in-memory
    filter to honor `_tagFilter` and match the search query against
    `note` as well as `text`; bulk-actions popup wires apply / remove /
    delete over the currently visible subset.
  * lib/features/wishlist/widgets/add_wishlist_dialog.dart
    (WishlistDialogResult.tag, _AddWishlistFormState._tagController):
    Optional Tag input field on add/edit.
  * lib/core/services/mal_import_service.dart (MalImportService.importFiles,
    MalImportService._addToWishlist), lib/core/services/steam_import_service.dart
    (SteamImportService.importLibrary, SteamImportService._addToWishlist),
    lib/core/services/ra_import_service.dart (RaImportService._addToWishlistIfNotExists),
    lib/core/services/trakt_zip_import_service.dart
    (TraktZipImportService.importFromZip): Generate one
    `buildImportTag(<source>)` per import run and pass it through to
    every unmatched entry; on re-import only stamp a tag onto
    previously-untagged duplicates so user-assigned tags are preserved.
  * lib/core/services/backup_service.dart (BackupService._wishlistItemToExport,
    BackupService._restoreWishlist): Persist and restore the new column
    in `.xcoll(x)` archives.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (wishlistTagOptional,
    wishlistTagHint, wishlistTagAll, wishlistTagUntagged,
    wishlistTagFilterLabel, wishlistTagPlaceholder, wishlistTagManage,
    wishlistTagRename, wishlistTagDelete, wishlistTagDeleteConfirm,
    wishlistBulkActionsButton, wishlistBulkApplyTag,
    wishlistBulkApplyTagHint, wishlistBulkRemoveTag, wishlistBulkDelete,
    wishlistBulkDeleteConfirm, apply): New strings; regenerated
    `app_localizations*.dart`.
  * test/shared/models/wishlist_tag_test.dart: New — covers
    `buildImportTag` uniqueness, `parseWishlistTag` of auto-generated
    tags, multi-dash source names, manual tags, and trailing-dash /
    non-numeric edge cases.
  * test/core/services/mal_import_service_test.dart: Assert the
    auto-tag follows `MyAnimeList-<unix-ms>` and reaches
    `addWishlistItem`.

- **Harden MyAnimeList XML import against AniList rate limits and protect existing entries**

  Large MAL imports no longer dump everything into Wishlist when AniList
  throttles or hiccups mid-batch. Each AniList lookup batch now retries
  up to three times on HTTP 429, honoring `Retry-After` /
  `X-RateLimit-Reset` (falling back to the documented 60s window), and
  only the truly unresolvable ids are surfaced as a separate "skipped
  (AniList unreachable)" counter — those entries are left out of the
  collection so a future re-import can retry them, instead of being
  silently misclassified as wishlist items. The import progress UI
  shows the rate-limit countdown ("Лимит AniList достигнут — ждём
  N сек, попытка X/3") without resetting the global batch counter, and
  reports the skipped count alongside imported / wishlisted / updated.
  A new "Overwrite existing entries" toggle, off by default, protects
  user edits on re-import: matched items keep their local status,
  rating, progress, dates and comment; with the toggle on, the previous
  merge behaviour applies.

  * lib/core/api/anilist_api.dart (AniListApi.maxRateLimitRetries,
    AniListApi.getAnimeByMalIdsTolerant, AniListApi.getMangaByMalIdsTolerant,
    AniListRateLimitException, AniListMalLookupResult): New rate-limit aware
    lookup methods that return partial results plus a list of failed MAL
    ids, with `onRateLimit` / `onBatchProgress` callbacks so callers can
    surface wait countdowns. `_handleDioException` now parses retry
    headers and emits the typed `AniListRateLimitException`.
  * lib/core/services/mal_import_service.dart (MalImportService.importFiles,
    MalImportStage.rateLimitWait, MalImportProgress.failedLookupCount,
    MalImportProgress.rateLimitWaitSeconds, MalImportResult.animeFailedLookup,
    MalImportResult.mangaFailedLookup, MalImportResult.failedLookup):
    Switch to the tolerant lookups, track per-kind failed-lookup counts,
    propagate rate-limit progress without resetting the cumulative
    counter, and add the `overwriteExistingItems` parameter (default
    false) that bypasses `_updateExistingItem` so user data survives
    re-imports.
  * lib/features/settings/content/mal_import_content.dart
    (_MalImportContentState._overwriteExisting, _MalImportContentState._buildProgressSection):
    Add the "Overwrite existing entries" switch, render the new
    rateLimitWait stage with an indeterminate bar, and show the
    "skipped (AniList unreachable)" stat row.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (malImportRateLimitWait,
    malImportFailedLookup, malImportOverwriteExisting,
    malImportOverwriteExistingHint): New strings; regenerated
    `app_localizations*.dart`.
  * test/core/services/mal_import_service_test.dart: Cover the tolerant
    lookup result shape, the failed-lookup-is-skipped path, and the
    `overwriteExistingItems=false` no-op-on-existing path; existing
    dedup test now explicitly passes `overwriteExistingItems: true`.

## [0.29.0] - 2026-05-16

### Added

- **Rename any collection item without touching the API cache**

  Open an item's detail screen, use the overflow menu (⋮) and pick
  "Rename" to give it a custom display name — "Final Fantasy VII Remake
  Intergrade" can become "FF7R" in your Favorites while keeping the
  original title in Wishlist or another collection. The original cached
  title is shown as a subtitle inside the dialog so you can see what
  you're overriding, and a "Reset to original" button clears the
  override. The custom name is per-collection-item: shared cache rows
  (games, movies_cache, tv_shows_cache, …) keep the canonical API title
  so future IGDB / TMDB / AniList / RA resyncs don't overwrite the
  user's choice. Canvas boards inherit the override too — the title
  under each card on the board follows the rename. Custom items already
  have a full Edit dialog, so the Rename action is hidden for them.
  Mood grids show the original cached name (cells reference media by
  external id only, no collection-item linkage to inherit from).

  * lib/core/database/schema.dart (DatabaseSchema.createCollectionItemsTable):
    Add `override_name TEXT` column on fresh installs.
  * lib/core/database/migrations/migration_v39.dart (MigrationV39),
    lib/core/database/migrations/migration_registry.dart: New v39 migration
    that adds the `override_name` column on upgrade.
  * lib/core/database/database_service.dart (DatabaseService.setItemOverrideName):
    Bump schema version to 39; facade for the new DAO method.
  * lib/core/database/dao/collection_dao.dart (CollectionDao.setItemOverrideName):
    Trims input and treats empty / whitespace-only as NULL so callers
    can use the same method for both rename and reset.
  * lib/data/repositories/collection_repository.dart
    (CollectionRepository.setItemOverrideName): Repository pass-through.
  * lib/shared/models/collection_item.dart (CollectionItem.overrideName,
    CollectionItem.cachedName, CollectionItem.itemName, CollectionItem.copyWith,
    CollectionItem.toDb, CollectionItem.fromDb, CollectionItem.toExport,
    CollectionItem.fromExport, CollectionItem.internalDbFields):
    New `overrideName` field threaded through fromDb / toDb / copyWith
    (with a `clearOverrideName` sentinel) and through the export round-trip.
    `itemName` returns `overrideName ?? cachedName ?? typed-fallback`; the
    new public `cachedName` getter exposes the original media title so the
    rename UI can show the user what they're overriding. `toExport` emits
    `override_name` only when `includeUserData` is true and the override
    is non-null.
  * lib/features/collections/providers/collections_provider.dart
    (CollectionItemsNotifier.setOverrideName): Trims and updates state in
    place via copyWith, invalidates `allItemsNotifierProvider` so the
    All Items screen reflects the rename.
  * lib/features/collections/providers/canvas_provider.dart
    (CanvasNotifier._syncOverrideNames): Listens to
    `collectionItemsNotifierProvider` and patches `overrideName` on live
    canvas items by `(itemType, itemRefId)` so the collection board's card
    title updates immediately after a rename without a full reload — same
    matching key as the SQL join in `canvas_dao.getCanvasItems`.
  * lib/features/collections/providers/game_canvas_provider.dart
    (GameCanvasNotifier._syncOverrideName): Per-item canvas has no
    structural sync loop, so an analogous listener patches `overrideName`
    on items whose `collectionItemId` matches the current canvas key.
  * lib/features/collections/widgets/rename_item_dialog.dart
    (RenameItemDialog): New dialog with a pre-filled TextField, a subtitle
    showing the original cached name, and Save / Reset to original / Cancel
    buttons. Returns the trimmed text on Save, an empty string on Reset,
    null on Cancel. Content is wrapped in `SingleChildScrollView` and the
    subtitle uses `maxLines: 2 + ellipsis` so the dialog doesn't overflow
    on narrow screens or with long original titles.
  * lib/features/collections/screens/item_detail_screen.dart
    (_ItemDetailScreenState._renameItem, AppBar overflow menu):
    New menu entry "Rename" hidden for `MediaType.custom`. No SnackBar
    on success — the new title in the AppBar is confirmation enough.
  * lib/shared/models/canvas_item.dart (CanvasItem.overrideName,
    CanvasItem.mediaTitle, CanvasItem.copyWith, CanvasItem.fromDb):
    New transient `overrideName` field — loaded from a SQL join (never
    written back to `canvas_items`) and consulted first by `mediaTitle`.
    `copyWith` preserves it across media enrichment and accepts a
    `clearOverrideName` sentinel so live listeners can drop the override
    when a user resets the rename.
  * lib/core/database/dao/canvas_dao.dart (CanvasDao.getCanvasItems):
    Swap `db.query` for a `rawQuery` that pulls `override_name` from the
    matching `collection_items` row via a correlated subquery
    `(collection_id, media_type, external_id)` so canvas titles inherit
    the rename. Multi-platform games in the same collection share an
    override; the subquery picks any matching row with `LIMIT 1`.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (renameItem, renameDialogHint,
    renameOriginalLabel, renameResetToOriginal, renameSaved): New
    localisation keys for the dialog and the menu entries.
  * test/shared/models/collection_item_test.dart,
    test/shared/models/canvas_item_test.dart,
    test/core/database/dao/collection_dao_test.dart,
    test/core/database/dao/canvas_dao_test.dart,
    test/features/collections/providers/collections_provider_test.dart,
    test/features/collections/widgets/rename_item_dialog_test.dart:
    Round-trip, copyWith semantics, DAO trim / empty / whitespace / null
    branches, notifier state mutation, dialog Save / Reset / Cancel
    behaviour, and canvas SQL subquery shape.
    `test/helpers/builders.dart` (createTestCollectionItem) gains an
    `overrideName` parameter.

- **ScreenScraper media gallery on game cards**

  Game cards in the collection and the bottom sheet in search show a
  horizontal carousel of ScreenScraper assets — box art, wheel, marquee,
  title screen, gameplay screenshots, fanart, composite mixes. Tap any
  thumbnail to open a fullscreen viewer with pinch-zoom, swipe between
  images, on-screen prev/next arrows, ← / → / Esc keyboard shortcuts and
  tap-on-backdrop to close. The search bottom sheet shows screenshots
  only (smaller, decision-time context); the in-collection card shows the
  full set. Mouse drag and wheel scroll are wired for Windows so the
  carousel responds the same way it does on touch and trackpad.

  Lookups are lazy: the API is called only when the user opens a card,
  and only for IGDB platforms that ScreenScraper covers (NES, SNES, Mega
  Drive, PS1/PS2, PSP, GameCube, N64, Dreamcast, Saturn, Atari, Neo Geo,
  arcade and the other retro lines — modern platforms fall through and
  the section is hidden). Responses are cached on disk for 30 days
  including negative "not found" results, so repeat opens are
  instantaneous and the rate-limited quota is preserved.

  A new section in Settings → Credentials carries the user's
  `ssid` / `sspassword`. "Check quota" calls `ssuserInfos.php` and
  displays current requests-today, daily / per-minute limits, parallel
  threads and account level. Application-level `devid` / `devpassword`
  are injected at build time via
  `--dart-define=SCREENSCRAPER_DEV_ID` and
  `--dart-define=SCREENSCRAPER_DEV_PASSWORD`. There is no fallback: if
  either the developer or user credentials are missing, the gallery is
  hidden and "Check quota" is disabled.

  * lib/core/api/screenscraper_api.dart (ScreenScraperApi,
    ScreenScraperApiException, SsMedia, SsGame, SsUserQuota,
    screenScraperApiProvider): New API client over Dio with
    `searchGame`, `getUserInfo` and `setUserCredentials`. Both API
    methods throw `ScreenScraperApiException('Missing ScreenScraper
    credentials')` when either developer or user credentials are absent.
  * lib/core/services/screenscraper_cache_service.dart
    (ScreenScraperCacheService, screenScraperCacheServiceProvider): New
    disk cache under `<documents>/ss_cache/<key>.json` with a 30-day TTL
    and negative caching for misses.
  * lib/shared/constants/screenscraper_systemes.dart
    (ScreenScraperSystemes.forIgdbPlatform, ScreenScraperSystemes.isSupported):
    New mapping from IGDB platform id to ScreenScraper `systemeid` for
    the retro platforms SS actually covers.
  * lib/features/collections/providers/screenscraper_provider.dart
    (SsLookup, screenScraperGameProvider, ScreenScraperGameNotifier):
    New `AsyncNotifierProvider.family` keyed by game name + IGDB
    platform id. Returns null cheaply when developer creds, user creds
    or platform mapping are missing, and when the disk cache holds a
    negative marker.
  * lib/features/collections/widgets/screenscraper_gallery_section.dart
    (ScreenScraperGallerySection, ScreenScraperGalleryMode, _Thumbnail,
    _HorizontalScroll, _DesktopDragScrollBehavior, _FullscreenViewer,
    _NavArrow): New widget consuming the provider; renders loading,
    error, empty and data states.
  * lib/shared/widgets/media_detail_view.dart (MediaDetailView):
    New `mediaGallery` slot rendered between the comments layout and
    the activity-and-progress expansion so the gallery is always
    visible rather than hidden inside the collapsed extras section.
  * lib/features/collections/screens/item_detail_screen.dart: Pass the
    gallery widget through `mediaGallery` with the item's name and
    platform id.
  * lib/features/search/widgets/item_details_sheet.dart (ItemDetailsSheet,
    ItemDetailsSheet.game): Add `screenScraperGameName` and
    `screenScraperPlatformId` fields; the `.game(...)` factory picks
    the first SS-supported platform from the IGDB game and renders the
    screenshots-only mode below the description.
  * lib/features/settings/content/credentials_content.dart
    (_CredentialsContentState._buildScreenScraperSection,
    _CredentialsContentState._buildScreenScraperQuotaInfo,
    _CredentialsContentState._fetchScreenScraperQuota,
    _CredentialsContentState._saveScreenScraperCreds): New Credentials
    section with `ssid` and `sspassword` fields and a "Check quota"
    button that surfaces `SsUserQuota` from the API.
  * lib/features/settings/providers/settings_provider.dart
    (SettingsKeys.screenScraperSsid, SettingsKeys.screenScraperSspassword,
    SettingsState.screenScraperSsid, SettingsState.screenScraperSspassword,
    SettingsState.hasScreenScraperCreds,
    SettingsNotifier.setScreenScraperCredentials,
    SettingsNotifier._loadFromPrefs, SettingsNotifier.clearSettings):
    Persist the user credentials, push them into the API client on
    load and on every change, and wipe them with the rest on clear.
  * lib/shared/constants/api_defaults.dart (ApiDefaults.screenScraperDevId,
    ApiDefaults.screenScraperDevPassword, ApiDefaults.screenScraperSoftname,
    ApiDefaults.hasScreenScraperDevCreds): New `--dart-define`-driven
    constants for the shared developer credentials; `softname` is set to
    `tonkatsuBox`.
  * lib/shared/theme/app_assets.dart (AppAssets.iconScreenScraperColor),
    assets/images/icon_scrapper_color.png: New ScreenScraper logo used
    by the Settings section header.
  * .github/workflows/release.yml: Pass `SCREENSCRAPER_DEV_ID` and
    `SCREENSCRAPER_DEV_PASSWORD` secrets through `--dart-define` to all
    three Windows / Android APK / Android AAB build steps.

### Changed

- **Collection table view refactored into floating row cards**

  The 1375-line monolithic table widget is split into a focused module
  under `collection_table/` — one file per role (the view, the header,
  the row, the column enum, and four cell types). Visually the table
  chrome is removed: the outer surface card, the grey header strip,
  zebra striping and inter-cell borders are gone. Each row is a faint
  rounded `surfaceLight` card that floats on the page; the header sits
  above as a plain label strip. Column ordering and widths were tuned —
  name (flex 5) and tag (flex 2) are the only stretchy columns; platform
  (140), type (56), status (96), rating (60) and year (56) are fixed
  width and their content is centred. Tag moved to the trailing
  position. Rating renders an em-dash when unset. Minimum table width
  before horizontal scrolling kicks in rose from 600 to 820 so the
  title column stays readable on narrow windows.

  The table no longer holds its own vertical scroll: the body shrink-wraps
  to its content and the parent owns the scroll, so the collection hero
  scrolls together with the rows just like in grid mode. (`shrinkWrap`
  means the list isn't lazy — fine for typical collections, would need
  slivers for ten-thousand-item ones.)

  All Cyrillic dartdocs in the touched files were translated to English
  per the project comment policy.

  * lib/features/collections/widgets/collection_table_view.dart: Removed.
  * lib/features/collections/widgets/collection_table/collection_table_view.dart
    (CollectionTableView), table_header.dart (TableHeader), table_row.dart
    (TableRow), table_column.dart (TableColumn, kDragHandleWidth,
    kCheckboxColumnWidth, kThumbWidth, kThumbHeight, kThumbRadius),
    cells/thumbnail_cell.dart (ThumbnailCell), cells/rating_cell.dart
    (RatingCell), cells/status_cell.dart (StatusCell), cells/tag_cell.dart
    (TagCell): New module replacing the monolithic widget. Behaviour
    parity preserved: sortable / filterable columns, reorderable mode
    with drag handle, select-all tri-state checkbox, inline editing of
    status / tag / rating via popups.
  * lib/features/collections/widgets/collection_items_view.dart
    (CollectionItemsView, CollectionItemsView._withHeader, _TagGroup):
    Import re-pointed to the new module path. `_withHeader` grew a
    `wrapInScroll` flag that wraps the hero + body in a single
    `SingleChildScrollView` for table mode. Dartdocs and inline
    comments translated.
  * lib/shared/models/collection_item.dart (CollectionItem,
    CollectionItem._resolvedMedia, CollectionItem.copyWith): Dartdocs
    and inline comments translated to English; no behaviour change.
  * lib/shared/widgets/cached_image.dart (CachedImage): Dartdocs and
    inline comments translated; no behaviour change.
  * test/features/collections/widgets/collection_table_view_test.dart:
    Import re-pointed to the new module path; existing assertions
    unchanged.

### Added

- **Setting: hide empty media-type chevrons**

  New toggle in Settings → Appearance hides the chevron segments for
  media types that have zero items in the current view. Applies to the
  filter bar inside a collection and to the unified "all items"
  screen reachable from the home tab. Off by default; a currently
  selected type stays visible even if its count is zero so the user
  can still clear the filter.

  * lib/features/settings/providers/settings_provider.dart
    (SettingsKeys.hideEmptyMediaTypeChevrons, SettingsState.hideEmptyMediaTypeChevrons,
    SettingsNotifier.setHideEmptyMediaTypeChevrons): New setting plumbing
    mirroring `showRecommendations`.
  * lib/features/settings/screens/settings_screen.dart: New SettingsTile
    with a Switch under Appearance.
  * lib/features/collections/widgets/collection_filter_bar.dart
    (_CollectionFilterBarState._buildTypeChevronBar): Filter `_typeEntries`
    by count > 0 when the setting is on, keeping selected types visible.
  * lib/features/home/screens/all_items_screen.dart (_buildMediaTypeBar):
    Same filter applied to `_MediaTypeEntry` list.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb: New keys
    `settingsHideEmptyMediaTypeChevrons` and
    `settingsHideEmptyMediaTypeChevronsSubtitle`.

- **Mood Grid — visual N×M boards of items inside the Tier Lists section**

  A second board type alongside the existing ranked tier list. A grid is
  an editable N×M matrix of cells; each cell has an optional category
  label and one optional media item picked from any of the user's
  collections. The same item can appear in multiple cells. A grid is
  not bound to any collection and is not included in `.xcoll` /
  `.xcollx` exports — only in full app backups. The default preset is
  «About Me: Tonkatsu Box» (1×5 — Favorite Game / Movie / TV Show /
  Anime / Manga); a Blank option lets the user pick rows × cols.
  Tap a cell to open the item picker; right-click or long-press to
  edit the label, replace the item, or clear it. A compact stepper
  toolbar above the grid resizes rows and columns on the fly.
  Export-as-PNG renders the grid off-screen with a watermark
  matching the tier-list export style and saves via the system
  picker on every platform (SAF on Android, native dialog on
  desktop). Backups now include all mood grids and their cells.

  * lib/shared/models/mood_grid.dart (MoodGrid),
    lib/shared/models/mood_grid_cell.dart (MoodGridCell): New models
    with fromDb / toDb / fromExport / toExport / copyWith. Cells store
    `(mediaType, externalId, platformId)` directly with no FK on
    `collection_items` so the grid survives item deletion.
  * lib/core/database/schema.dart (DatabaseSchema.createMoodGridsTable,
    DatabaseSchema.createMoodGridCellsTable): New tables.
  * lib/core/database/migrations/migration_v36.dart (MigrationV36),
    lib/core/database/migrations/migration_registry.dart: Bump schema
    to v36.
  * lib/core/database/dao/mood_grid_dao.dart (MoodGridDao,
    MoodGridCellSpec): CRUD plus `resizeMoodGrid` that remaps cell
    positions to preserve (row, col) coordinates across grid resizes.
  * lib/core/database/database_service.dart (DatabaseService.moodGridDao,
    moodGridDaoProvider, DatabaseService.clearAllData): Wires the DAO
    and adds `mood_grid_cells` + `mood_grids` to the cascade clear.
  * lib/features/tier_lists/providers/mood_grids_provider.dart
    (MoodGridsNotifier, moodGridsProvider, MoodGridPreset,
    aboutMeTonkatsuBoxCells, kDefaultMoodGridTitle),
    lib/features/tier_lists/providers/mood_grid_detail_provider.dart
    (MoodGridDetailNotifier, MoodGridDetailState,
    moodGridDetailProvider): List + per-grid detail providers with
    optimistic state mutation.
  * lib/features/tier_lists/screens/mood_grid_detail_screen.dart
    (MoodGridDetailScreen): Detail screen with stepper resize bar,
    tap-to-pick cells, right-click / long-press context menu, PNG
    export, rename and delete.
  * lib/features/tier_lists/widgets/mood_grid_view.dart (MoodGridView),
    mood_grid_cell_widget.dart (MoodGridCellWidget),
    mood_grid_cell_media.dart (MoodGridCellMedia,
    resolveMoodGridCellMedia), mood_grid_export_view.dart
    (MoodGridExportView), mood_grid_item_picker.dart
    (showMoodGridItemPicker, MoodGridItemPickerResult),
    create_mood_grid_dialog.dart (CreateMoodGridDialog): Grid
    rendering, off-screen export with watermark, modal item picker
    over all collections with optional collection filter, and the
    create dialog with preset + size selector.
  * lib/features/tier_lists/screens/tier_lists_screen.dart
    (_BoardEntry, _mergeAndSort, _MoodGridCard, _showCreateMoodGridDialog):
    Lists ranked tier lists and mood grids side by side sorted by
    creation date with type badges; FAB exposes both create flows.
  * lib/core/services/backup_service.dart (BackupService, _restoreMoodGrids,
    backupFormatVersion): Backup archive now includes `mood_grids.json`
    with cells. Bumped `backupFormatVersion` to 2; restore is
    backward-compatible with v1 archives (mood-grids section is
    optional and skipped when absent).
  * lib/features/settings/content/database_content.dart: Invalidate
    `moodGridsProvider` after Reset Database.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb: Mood Grid UI strings
    (moodGridCreate, moodGridPresetAboutMe, moodGridBadge,
    moodGridAddRow, moodGridShrinkTitle, moodGridPickItem, etc.).

- **Import anime and manga lists from a public AniList username**

  New entry in Settings → Import alongside MyAnimeList / Steam / RA / Trakt.
  No OAuth required — `MediaListCollection` GraphQL endpoint returns every
  list (Watching / Completed / Planning / etc.) for any public profile in
  one call. The form takes a username, lets you toggle anime / manga,
  pick `Add new only` vs `Overwrite existing`, and target a new or
  existing collection. The username is remembered across sessions.
  AniList statuses map onto xerabora's five `ItemStatus` values:
  CURRENT / REPEATING → inProgress, COMPLETED → completed, PLANNING →
  planned, DROPPED / PAUSED → dropped. POINT_100 scores are normalised
  to the local 1..10 scale; 0 is treated as "unrated". On `COMPLETED`
  entries, episode / chapter / volume counters top up to the AniList
  totals (mirrors MAL importer semantics). `isAdult` media and AniList
  custom lists are filtered out to avoid duplicates.

  * lib/core/api/anilist_api.dart (AniListApi.fetchUserMediaList,
    AniListListEntry, AniListUserNotFoundException,
    AniListPrivateProfileException, AniListApi._parseListEntry,
    AniListApi._parseFuzzyDate): New `MediaListCollection` GraphQL
    queries (anime + manga) and DTO; HTTP 404 and GraphQL
    "not found" / "private" errors map to typed exceptions.
  * lib/core/services/anilist_import_service.dart
    (AniListImportService, AniListImportProgress, AniListImportResult,
    AniListImportStage, ImportMode, aniListImportServiceProvider): New
    service. Deduplicates against existing items by
    (collectionId, mediaType, externalId); upserts the nested `Anime`
    and `Manga` graphs in parallel before writing entries.
  * lib/features/settings/screens/anilist_import_screen.dart,
    lib/features/settings/content/anilist_import_content.dart
    (AniListImportScreen, AniListImportContent): New screen and form.
  * lib/features/settings/screens/settings_screen.dart: Adds AniList
    tile to the Import group.
  * lib/features/settings/providers/settings_provider.dart
    (SettingsKeys.aniListUsername): Persists the last-used AniList
    username after a successful import.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb: AniList import UI strings
    (settingsAniListImport, aniListImportTitle,
    aniListImportUsername, aniListImportInclude, aniListImportMode,
    aniListImportImported, aniListImportUpdated,
    aniListImportUserNotFound, aniListImportPrivateProfile, etc.).

### Changed

- **Higher-quality AniList covers in collections and search**

  AniList exposes three cover sizes (`extraLarge` ≈ 460×650,
  `large` ≈ 230×325, `medium` ≈ 100×146). The app was requesting only
  `large` / `medium` in GraphQL queries and, worse, the per-anime / manga
  `thumbUrl` used in collection grids and detail screens preferred
  `medium`, producing visibly blurry posters compared to the AniList
  website. All 10 GraphQL `coverImage` selections now include
  `extraLarge`, the models pick it with a `large` fallback, and the
  collection-item resolver prefers `coverUrl` over `coverUrlMedium`.
  Existing cached models keep their old URLs until the next upsert.

  * lib/core/api/anilist_api.dart: Adds `extraLarge` to every
    `coverImage` GraphQL selection (search, browse, by-id, by-MAL-id,
    user-list queries).
  * lib/shared/models/anime.dart (Anime.fromJson),
    lib/shared/models/manga.dart (Manga.fromJson): Prefer `extraLarge`
    with `large` fallback.
  * lib/shared/models/collection_item.dart (_resolvedMedia anime/manga
    cases): `thumbUrl` falls through `coverUrl ?? coverUrlMedium`.

- **Localization polish: capitalized Russian TMDB genres, plural search tabs, English-only code comments**

  TMDB seeds Russian genre names in lowercase (`боевик`, `комедия`); they
  now render with a capital letter wherever the genre map is consumed
  (filters, item details, resolved item rows). Search source tabs were
  using singular labels (`Фильм`, `Игра`, `Сериал`, `Анимация`) shared
  with detail screens — they now use dedicated plural keys
  (`Фильмы`, `Игры`, `Сериалы`, `Анимация`), with English equivalents
  (`Movies`, `Games`, `TV Shows`, `Animation`) staying the same shape.
  In parallel, code comments across the largest lib files and every
  test file with Cyrillic comments were translated to English (or
  removed where they only restated the symbol name); the `finish` skill
  now codifies the rule so future diffs stay clean.

  * lib/core/database/dao/movie_dao.dart (MovieDao.getTmdbGenreMap,
    MovieDao._capitalize): Capitalize first letter on read so downstream
    consumers (filter chips, ID→name resolution in `CollectionDao`) all
    see Title Case.
  * lib/l10n/app_ru.arb, lib/l10n/app_en.arb (searchSourceGames,
    searchSourceMovies, searchSourceTvShows, searchSourceAnimation): New
    plural labels for search source tabs.
  * lib/features/search/sources/igdb_games_source.dart,
    tmdb_movies_source.dart, tmdb_tv_source.dart, tmdb_anime_source.dart
    (label): Switched from singular `mediaType*` to plural
    `searchSource*` keys.
  * .claude/skills/finish/SKILL.md: New "Comment style" section
    enforcing English-only, WHY-only, ≤1-line comments project-wide.

### Added

- **Bulk actions across collections and All Items**

  Selection now works everywhere items are shown: the collection table
  view gets a checkbox column (header has a tristate select-all for the
  currently visible rows), the collection grid / list / manual-reorder
  views and the All Items home grid get a Google-Photos-style checkmark
  overlay in the top-left corner of each card (subtle on hover, brand-
  filled when selected, with a brand-tinted border around the card).
  While at least one item is selected, tapping any other card toggles
  selection instead of opening the detail screen. On every screen,
  selecting one or more items reveals the same bulk action bar with:
  move to another collection, copy to another collection, change status
  (status popup), and remove. Inside a single collection, when sort is
  manual, the bar also shows move-to-top / move-to-bottom. All bulk
  operations live in a single helper (`BulkOperations`) so they can be
  invoked from any screen — they call the existing single-item
  repository methods in a loop, accumulate affected collections / media
  types / tier lists, and run the provider invalidation **once** at the
  end. N items no longer trigger N redundant reloads. Status update
  path uses `AllItemsNotifier`'s existing `updateStatusLocally` so the
  home grid does not have to refetch; each affected collection notifier
  is invalidated once.

  * lib/features/collections/helpers/bulk_operations.dart (BulkOperations,
    BulkOperations.removeItems, BulkOperations.moveItemsToCollection,
    BulkOperations.cloneItemsToCollection, BulkOperations.updateItemsStatus,
    BulkOperations._invalidateAfterMutation, BulkOperations._resolveTargetTagId):
    New. Collection-agnostic helper — takes `List<CollectionItem>`
    (each item carries its own `collectionId` and `mediaType`) and a
    `WidgetRef`; correctly invalidates the union of affected source
    collections plus the target.
  * lib/features/collections/providers/collection_selection_provider.dart
    (CollectionSelectionNotifier, collectionSelectionProvider): New.
    Per-collection `Set<int>` of selected ids (toggle / selectAll /
    clear / removeIds), family-keyed by `int?`.
  * lib/features/collections/providers/all_items_selection_provider.dart
    (AllItemsSelectionNotifier, allItemsSelectionProvider): New.
    Global selection for the All Items home screen.
  * lib/features/collections/providers/collections_provider.dart
    (CollectionItemsNotifier.moveItemsToTop, CollectionItemsNotifier.moveItemsToBottom,
    CollectionItemsNotifier._moveItemsToEdge): New methods that stay on
    the notifier because they need single-collection `sort_order`
    context. They preserve the relative order of the selected group.
  * lib/features/collections/widgets/bulk_action_bar.dart (BulkActionBar):
    New. Reads its `List<CollectionItem>` and an `onClearSelection`
    callback from the parent — fully selection-provider-agnostic.
    Move-to-top / move-to-bottom only render when a `collectionId`
    is supplied and that collection is in manual sort.
  * lib/features/collections/widgets/selectable_poster_card.dart
    (SelectablePosterCard, _CheckCircle): New. Overlay wrapper that
    adds the corner check-circle and brand border for grid views.
  * lib/features/collections/widgets/collection_table_view.dart
    (CollectionTableView, _TableHeader, _TableRow): Add `selectedIds`,
    `onToggleSelect`, `onToggleSelectAll` parameters. New checkbox
    column in the header (tristate select-all) and in each row.
    Selected rows get a brand-tinted background.
  * lib/features/collections/widgets/collection_items_view.dart
    (CollectionItemsView.build, CollectionItemsView._buildListTile,
    CollectionItemsView._buildPosterCard, CollectionItemsView._buildReorderableList):
    Wire all four item views (table, grid, list, reorderable) to
    `collectionSelectionProvider`. Grid / list / reorderable wrap each
    poster or tile in `SelectablePosterCard`; when a selection is
    active, tapping a card toggles selection instead of opening the
    detail screen.
  * lib/features/collections/screens/collection_screen.dart: Mount
    `BulkActionBar` between the title bar and the item list whenever
    the user can edit and the selection is non-empty (any view mode).
    Passes the selected items list + `onClearSelection` callback.
  * lib/features/home/screens/all_items_screen.dart
    (_AllItemsScreenState.build, _AllItemsScreenState._buildGridView):
    Wrap each `MediaPosterCard` in `SelectablePosterCard`; while a
    selection is active, tapping a card toggles selection instead of
    opening detail. Mount `BulkActionBar` above the grid when the
    selection is non-empty.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (bulkSelected,
    bulkClearSelection, bulkMove, bulkCopy, bulkChangeStatus,
    bulkRemoveConfirm, bulkResult, bulkRemoved, bulkStatusUpdated): New.
  * test/features/collections/providers/collection_selection_provider_test.dart:
    New. 6 cases covering toggle, selectAll, clear, removeIds, and
    family isolation between collections.

- **Move-to-top / move-to-bottom for collection items in manual sort**

  When the collection is sorted manually (Custom order), the row context
  menu (right-click on desktop, long-press on mobile) now includes two new
  entries — «В начало списка» and «В конец списка» — that jump the item to
  the first or last position in one click instead of dragging through the
  whole list. The entries are hidden in other sort modes, where they would
  have no visible effect.

  * lib/features/collections/providers/collections_provider.dart
    (CollectionItemsNotifier.moveItemToTop, CollectionItemsNotifier.moveItemToBottom):
    New. Locate the item by id, no-op when already at the edge or missing,
    delegate to `reorderItem` so the existing sort_order renumbering and
    persistence path is reused.
  * lib/features/collections/widgets/collection_items_view.dart
    (CollectionItemsView._showItemContextMenu): Read `collectionSortProvider`
    inside the menu builder; prepend two `PopupMenuItem` entries plus a
    divider when `sortMode == manual && canEdit`; wire the new `moveToTop`
    / `moveToBottom` switch cases to the notifier.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (moveToTop, moveToBottom): New.
  * test/features/collections/providers/collections_provider_move_test.dart:
    New. 8 cases covering move-to-top and move-to-bottom for first/middle/
    last items, no-op at edges, and no-op for unknown id.

- **Import anime and manga lists from MyAnimeList XML export**

  New Settings → Import → MyAnimeList screen accepts the official XML export (`myanimelist.net/panel.php?go=export`), batch-resolves MAL IDs to AniList via `idMal_in` (50 per request, ~75 s for a 5k-entry library), and writes results into a target collection. AniList becomes the canonical record; the MAL link is preserved as a markdown footer in `user_comment`. Status mapping: Watching/Reading → in-progress, Completed → completed, On-Hold and Plan to Watch/Read → planned, Dropped → dropped. When a `Completed` entry has missing watched-episode counts or dates, the importer back-fills them from the AniList totals and from `my_start_date` / `my_finish_date`. Re-import deduplicates on `(collection_id, media_type, external_id)` and merges instead of duplicating: status uses `mergeExternalStatus` (won't downgrade `completed`, won't touch `dropped`), progress is `max(local, mal)`, started/completed dates take the earliest start and latest finish, `user_comment` is rebuilt from the latest MAL data. Titles missing on AniList go to the wishlist with a note containing the MAL link, status, score, tags, and comments — re-import updates the existing wishlist row instead of duplicating it.

  * lib/core/services/mal_import_service.dart (MalImportService, MalEntry, MalParsedFile, MalImportProgress, MalImportResult, MalImportStage, MalFileKind, MalImportResultToUniversal): New. XML parser, MAL→AniList resolver, dedup-aware writer with wishlist fallback.
  * lib/core/api/anilist_api.dart (AniListApi.getAnimeByMalIds, AniListApi.getMangaByMalIds): New batch lookups via `idMal_in` GraphQL filter; returns `Map<int malId, Anime|Manga>` so callers can correlate exports.
  * lib/features/settings/screens/mal_import_screen.dart (MalImportScreen), lib/features/settings/content/mal_import_content.dart (MalImportContent): New. Picks up to two XML files (auto-detects anime vs manga via `<user_export_type>`), routes to either a new collection or an existing one, and shows three-stage progress (resolving anime / resolving manga / matching entries) before navigating to `ImportResultScreen`.
  * lib/features/settings/screens/settings_screen.dart: Add MyAnimeList tile to the Import section.
  * lib/shared/theme/app_assets.dart (AppAssets.iconMalColor): New, points to `assets/images/MyAnimeList_Logo.png`.
  * assets/images/MyAnimeList_Logo.png: New brand asset.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb: Add `settingsMalImport` plus 21 `malImport*` keys.
  * pubspec.yaml: Add direct `xml: ^6.5.0` dependency.
  * test/core/services/mal_import_service_test.dart: 18 tests covering XML parsing (anime/manga, status mapping, validation, kind fallback), `Completed` back-fill, unmatched-to-wishlist with MAL markdown link, and re-import dedup that updates instead of inserting.

- **Content language picker in welcome wizard with UI-language autosync**

  The wizard language step now lets the user pick the TMDB content
  language (used for movie / TV descriptions) directly, instead of
  silently keeping the previous `ru-RU` default while the UI is set
  to English. Tapping a UI-language option also auto-applies the
  matching content language (English → `en-US`, Russian → `ru-RU`)
  until the user picks a content language by hand — after that the
  manual choice sticks and toggling the UI language stops touching
  it. The same picker now drives the Settings → Content language
  dialog, so adding a new locale flows through both surfaces from a
  single source.

  * lib/shared/constants/tmdb_content_languages.dart (TmdbContentLanguage,
    kTmdbContentLanguages, defaultContentLanguageForUi): New. Single
    extensible list of supported TMDB locales plus the UI → content
    fallback map; new pairs (UI locale + matching `xx-YY` translation)
    are added here in one place.
  * lib/features/welcome/widgets/welcome_step_language.dart
    (WelcomeStepLanguage, _WelcomeStepLanguageState._onUiLanguageSelected,
    _WelcomeStepLanguageState._onContentLanguageSelected,
    _ContentLanguageDropdown): Convert to `ConsumerStatefulWidget`;
    add a styled dropdown bound to `tmdbLanguage`; track a
    `_contentLangTouched` flag so UI-language taps only seed the
    content language while the user hasn't customized it.
  * lib/features/settings/screens/settings_screen.dart
    (_SettingsScreenState._contentLanguageLabel,
    _SettingsScreenState._showContentLanguagePicker): Drop the two
    hardcoded `en-US` / `ru-RU` branches; iterate `kTmdbContentLanguages`
    for both the tile value and the picker dialog.
  * test/shared/constants/tmdb_content_languages_test.dart: New. Verifies
    list non-emptiness, code uniqueness, IETF BCP 47 code format, and
    `defaultContentLanguageForUi` mapping (including unknown-code
    fallback to `en-US`).
  * test/features/welcome/widgets/welcome_step_language_test.dart: Add
    tests for dropdown presence, content-language save, UI → content
    autosync for both `en` and `ru`, and that a manual dropdown pick
    disables the autosync on subsequent UI-language taps.

### Changed

- **Unified brand-icon rendering across settings, welcome wizard, and search**

  Settings API-keys screen now uses a wizard-style section header (logo + description, e.g. "Game search (IGDB)") instead of a text-only badge. Integration and Import tiles show the full-colour brand logo (GitHub, Trakt, Steam, RetroAchievements, Kodi, Discord) on a neutral plate, matching the welcome-wizard step. Search source dropdown and filter bar render the same brand PNGs in place of generic Material icons. Monochrome glyphs (simpleicons) stay for header badges that need `ColorFilter` tinting for active/inactive state.

  * assets/images/icon_anilist_color.png, icon_discord_color.png, icon_github.png, icon_igdb_color.png, icon_kodi_color.png, icon_steam_color.png, icon_steamgriddb_color.png, icon_tmdb_color.png, icon_trakt_color.png, icon_vndb_color.png: New. Normalised 128×128 PNGs (dashboardicons + official brand kits), trimmed alpha, 10% uniform margin. IGDB mark whitened for visibility on dark plates.
  * assets/images/ra_logo.png: Re-normalised to match.
  * assets/images/icon_kodi.svg: Replaced the dashboardicons variant with a simpleicons mono SVG to drop the embedded `<style>` block that `flutter_svg` flags as "unhandled element".
  * assets/images/icon_ra.svg, icon_steam.svg, icon_trakt.svg: Removed (no longer referenced).
  * lib/shared/theme/app_assets.dart (AppAssets): Add `iconDiscordColor`, `iconKodiColor`, `iconSteamColor`, `iconTraktColor`, `iconRaColor`, `iconGithub`, `iconTmdbColor`, `iconIgdbColor`, `iconSteamGridDbColor`, `iconAnilistColor`, `iconVndbColor`; drop unused mono `iconSteam`, `iconTrakt`, `iconRa`.
  * lib/shared/models/data_source.dart (DataSource.iconAsset): New field — brand PNG path per source.
  * lib/shared/widgets/source_badge.dart (SourceBadge): Render brand logo left of the label when `source.iconAsset` is set.
  * lib/features/settings/widgets/settings_tile.dart (_LeadingBubble): Route `.png` assets through `Image.asset`, `.svg` through `SvgPicture.asset`; bump asset scale multiplier to 1.8× for visual parity with Material icons.
  * lib/features/settings/screens/settings_screen.dart: GitHub / Trakt / Steam / RA import tiles, Kodi integration tile, and Discord Rich Presence tile switch to colored PNGs. Author-name bubble now tracks compact-screen sizing like `SettingsTile`.
  * lib/features/settings/content/credentials_content.dart (_CredentialsContentState._buildSourceHeader): New wizard-style header (`[logo] description (BrandName)`) replaces per-section `SourceBadge` row for IGDB / SteamGridDB / TMDB.
  * lib/features/welcome/widgets/welcome_step_api_keys.dart (_ApiSection, _BuiltInKeySection): Accept optional `iconAsset`; render brand PNG with tooltip instead of a text tag chip.
  * lib/features/search/models/search_source.dart (SearchSource.iconAsset): New virtual getter, defaults to `null`.
  * lib/features/search/sources/igdb_games_source.dart, tmdb_movies_source.dart, tmdb_tv_source.dart, tmdb_anime_source.dart, anilist_anime_source.dart, anilist_manga_source.dart, vndb_source.dart: Override `iconAsset` with the corresponding brand PNG.
  * lib/features/search/sources/search_sources.dart (SourceGroupEntry): Add `groupIconAsset` field; populate from the first source of each group.
  * lib/features/search/widgets/source_dropdown.dart (SourceDropdown, _sourceGlyph): Render brand PNG (22 px for current source, 20 px for group headers) when asset is set.
  * lib/features/search/widgets/filter_bar.dart: Render group brand PNG (20 px) in the filter-bar popup.

### Fixed

- **RetroAchievements sync now respects manual RA↔IGDB links and reports wishlist count honestly**

  Previously, when a game went to the wishlist because IGDB couldn't match it by name, manually adding the game and linking it to RA via the achievement card had no effect on subsequent syncs — the same game was offered to the wishlist again every run, because the importer only matched via `IgdbApi.multiSearchGamesByName` and never read the `tracker_game_data` table it was already writing to. Now the importer pre-fetches all RA→IGDB rows from `tracker_game_data` before searching IGDB and reuses the cached `Game` instead of doing a name-based lookup; broken links (cached `Game` missing) fall back to the existing IGDB search path. The result struct also separates `unmatched` (no IGDB match and no manual link) from `wishlisted` (rows actually inserted this run), so when `addToWishlist` is off or the wishlist row already existed, the result screen no longer claims new wishlist additions. Progress UI now splits the IGDB lookup phase (`searchingGames`) from the collection-write phase (`matchingGames`) instead of running both under the same stage.

  * lib/core/services/ra_import_service.dart (RaImportService.importFromProfile, RaImportService._resolveIgdbGame, RaImportService._addToWishlistIfNotExists, RaImportStage, RaImportResult, RaImportResultToUniversal): Pre-fetch `tracker_game_data` for `TrackerType.ra`, build `raIdToIgdbId` map, split `games` into linked/unlinked, only batch-search the unlinked subset. New `_resolveIgdbGame` helper picks the cached `Game` for linked entries and falls back to a single IGDB search when the local cache misses. `_addToWishlistIfNotExists` now returns `bool` so the caller increments `wishlisted` only when a new row was actually inserted. `RaImportResult` gains a `wishlisted` field; `toUniversal()` reads `wishlistedByType` from `wishlisted` instead of `unmatched`. New `RaImportStage.searchingGames` covers IGDB lookup; `matchingGames` is reserved for the collection writes. `_trackerDao` is now required (was nullable) — needed for the link lookup to work outside tests.
  * lib/features/settings/content/ra_import_content.dart (_RaImportContentState._buildProgressSection): Render the new `searchingGames` stage with `l.raImportSearchingIgdb`.
  * lib/l10n/app_en.arb, lib/l10n/app_ru.arb (raImportSearchingIgdb): New string for the IGDB-search progress stage.
  * test/core/services/ra_import_service_test.dart: New cases — manual link skips IGDB and reuses cached game; broken manual link falls back to IGDB search; `wishlisted=0` when `addToWishlist=false`; `wishlisted=0` when the wishlist row already existed; `RaImportResult.wishlisted` constructor + `toUniversal` mapping. Existing progress test updated to assert `searchingGames` and `matchingGames` both fire.

### Fixed

- **Tracker progress is now scoped per platform, not per IGDB game**

  External tracker data (RetroAchievements progress, achievements, award
  state, last-played timestamps) was keyed by IGDB game id alone, so a
  single multi-platform game in the collection could only ever hold one
  set of stats — syncing a second platform install silently overwrote
  the first one and its history was lost. Each platform install now
  owns its own tracker row: the unique index gains
  `COALESCE(platform_id, -1)`, the model carries `platformId`, and the
  UI scopes its lookups by the current `CollectionItem.platformId`.
  Refreshing one install's status / dates no longer touches sibling
  installs of the same IGDB game. On migration the legacy
  `platform_id = NULL` rows are backfilled from the user's
  `collection_items` when exactly one platform install of that game
  exists; ambiguous rows are dropped so stale data can't leak across
  platforms. Backups and `.xcoll` / `.xcollx` exports/imports round-trip
  the new column automatically; archives produced by older versions are
  tolerated (the fallback lookup still picks up NULL rows restored from
  legacy backups).

  * lib/core/database/schema.dart (DatabaseSchema.createTrackerGameDataTable):
    Add `platform_id INTEGER` column; replace the
    `idx_tracker_game_data_unique` index with one that includes
    `COALESCE(platform_id, -1)` so distinct platforms keep distinct rows.
  * lib/core/database/migrations/migration_v37.dart (MigrationV37),
    lib/core/database/migrations/migration_registry.dart: New v37
    migration that adds the column and rebuilds the unique index in place.
  * lib/core/database/migrations/migration_v38.dart (MigrationV38):
    Backfills `platform_id` on legacy tracker rows by joining each NULL
    row against `collection_items`: unambiguous matches (exactly one
    platform in the user's collection for that IGDB game) get filled in,
    everything else is dropped together with its orphaned achievements
    so the legacy fallback can't leak data across platform installs.
  * lib/core/database/database_service.dart: Bump schema version to 38.
    `getItemIdsByExternalId` gains `platformId` + `filterByPlatform` and
    returns `platform_id` alongside id/collectionId so the sync code can
    address one platform install at a time.
  * lib/shared/models/tracker_game_data.dart (TrackerGameData,
    TrackerGameData.fromDb, TrackerGameData.toDb, TrackerGameData.copyWith):
    New `platformId` field threaded through fromDb / toDb / copyWith.
    `copyWith` adds a `clearPlatformId` sentinel for explicit null-set.
    All dartdocs translated to English.
  * lib/core/database/dao/tracker_dao.dart (TrackerDao.getGameData,
    TrackerDao.getGameDataForAnyPlatform, TrackerDao.deleteGameData):
    `getGameData` accepts optional `platformId`. New
    `getGameDataForAnyPlatform` returns every platform variant for a
    given IGDB game. `deleteGameData` accepts `platformId` /
    `allPlatforms` so per-platform unlink is possible; achievements for
    a `tracker_game_id` are dropped only when no other tracker row still
    references them.
  * lib/features/collections/providers/tracker_provider.dart (TrackerKey,
    TrackerDetailNotifier): Provider family key switched from `int` to a
    `({int gameId, int? platformId})` record. The notifier reads the
    per-platform row first and falls back to the legacy
    platform-agnostic row when none exists. `unlinkRaGame` deletes only
    the current platform's row; `_syncToCollectionItems` filters
    `CollectionItem`s by `platformId` so PS2 progress doesn't bleed into
    a GameCube row.
  * lib/features/collections/widgets/ra_achievements_section.dart
    (RaAchievementsSection): New `platformId` widget property; every
    `trackerDetailProvider(...)` call now uses the composite key.
  * lib/features/collections/screens/item_detail_screen.dart: Pass
    `(gameId: item.externalId, platformId: item.platformId)` everywhere
    the tracker provider is read or watched, and forward `platformId`
    to `RaAchievementsSection`.
  * lib/core/services/tracker_sync_service.dart
    (TrackerSyncService.fullSyncRa, ra_to_igdb_mapper import): Bulk RA
    sync derives the IGDB platform id from `raGame.consoleId` via
    `RaToIgdbMapper.primaryIgdbPlatformId` and writes it onto the
    upserted `TrackerGameData`.
  * lib/core/services/ra_import_service.dart
    (RaImportService.importFromProfile,
    RaImportService._saveTrackerGameData): Same platform derivation
    applied to the import flow; the in-collection duplicate check now
    passes the derived `platformId` to `findCollectionItem` so a second
    platform install of the same IGDB title creates a fresh row instead
    of overwriting the first one.
  * test/shared/models/tracker_game_data_test.dart (TrackerGameData),
    test/core/database/dao/tracker_dao_test.dart (TrackerDao): New —
    14 tests covering fromDb/toDb round-trip (with platformId, NULL,
    missing key), copyWith semantics, per-platform upsert isolation,
    NULL bucket behaviour, and the new delete variants including the
    achievements-cleanup branch.

## [0.28.0] - 2026-04-23

### Added

- **Personalized collections with cover image, description, and rich hero banner**

  Opt-in "Rich collection view" toggle in Settings gives each collection a hero section with cover image, title, and description on the home grid and the collection screen. Cover is chosen via a new Edit dialog; files live in `<appSupport>/collections/` and travel inside `.xcollx` as a separate section (not in JSON), preserving export-format compatibility. Collections without a custom cover fall back deterministically to one of 3 bundled default banners (`id % 3`). 11 localization keys EN+RU.

  * lib/core/database/migrations/migration_v35.dart: New. Adds `hero_image_path` column to `collections`.
  * lib/core/services/collection_hero_service.dart (CollectionHeroService): New. Stores hero images as `hero_<id>_<ts>.<ext>` under `<appSupport>`.
  * lib/features/collections/widgets/collection_hero_background.dart (CollectionHeroBackground), rich_hero_banner.dart (RichHeroBanner), classic_collection_card.dart, rich_collection_card.dart, collection_card_shell.dart, collection_card_overlay.dart: New. Shared shell (focus / hover / border) and text overlay across both card variants; `CollectionHeroBackground` exposes `soft` / `standard` gradient presets with DPR-aware cache width.
  * lib/features/collections/widgets/edit_collection_dialog.dart (EditCollectionDialog): New. Name + description + image picker with live preview and "Remove image" action.
  * lib/features/collections/providers/rich_collections_enabled_provider.dart (richCollectionsEnabledProvider): New.
  * lib/features/collections/screens/collection_screen.dart: Hero banner is a sliver that scrolls with the grid rather than a pinned header.
  * lib/core/services/export_service.dart, import_service.dart: Carry hero binary as a separate `.xcollx` section.

- **Right-click context menu on the Collections screen**

  Right-click on empty space (between or below cards) opens a popup with the primary FAB actions: Create new collection, Import collection, Toggle grid/list view. The card-level right-click menu (Open / Rename / Delete) keeps priority on cards via the gesture arena.

  * lib/features/collections/screens/home_screen.dart: Add empty-space right-click handler.

- **Right-click context menu on All Items**

  Right-click on a poster opens Move to collection / Copy to collection / Remove, mirroring the menu inside a collection. The editability check is shared between the context menu and the item detail sheet.

  * lib/features/collections/screens/all_items_screen.dart (_isItemEditable): Extract shared predicate; delegate menu actions to `CollectionActions` for identical dialogs, snackbars, and invalidation.

- **Inline status switcher in item context menus**

  Both the collection's right-click menu and the All Items right-click menu grow a bottom row showing all five statuses as a horizontal "piano" of coloured segments. One tap updates the status without leaving the menu. Labels adapt to media type (Playing for games / Watching for movies & TV). Status change patches the list locally so the All Items grid no longer flashes through `AsyncLoading` on every tap.

  * lib/features/collections/widgets/status_chip_row.dart (StatusChipRow, statusChipPopupMenuEntries, tryDecodeStatusMenuValue): Expose `height` parameter; add helpers for menu-entry + value decoding reused by both call sites.
  * lib/features/collections/widgets/collection_items_view.dart, lib/features/collections/screens/all_items_screen.dart: Wire the status row into both context menus.
  * lib/shared/models/collection_item.dart (CollectionItem.withStatus): New.
  * lib/features/collections/providers/all_items_provider.dart (AllItemsNotifier.updateStatusLocally): New. Local patch avoids a full reload.

- **"Remember credentials" checkbox on Steam Import**

  Opt-in toggle under the API key / Steam ID fields persists both values (plus the flag itself) in `SharedPreferences` and prefills them on reopen. Unchecking clears the saved pair so stale data isn't left behind. Prefs writes are `unawaited` so they don't delay the import start.

  * lib/features/imports/widgets/steam_import_content.dart: Add remember-me toggle + prefill logic.
  * lib/features/settings/providers/settings_provider.dart: Persistence keys.
  * lib/l10n/app_en.arb, app_ru.arb: Toggle label + help text.

- **Search now matches user notes and author review**

  In-collection search bar and the All Items global search compare against `CollectionItem.userComment` and `CollectionItem.authorComment`, in addition to `itemName` and tag names. Case-insensitive.

  * lib/features/collections/screens/collection_screen.dart, all_items_screen.dart: Extend search predicate.

- **TMDB search filters expanded**

  Movies / TV / Anime tabs gain four new / upgraded filters on top of the existing genre + year: multi-select genre (OR match), Min rating (Any / 6+ / 7+ / 8+ / 9+ on the 1–10 scale, sent as `vote_average.gte`), Min votes (Any / 100 / 500 / 1000 / 5000, sent as `vote_count.gte`; previously hardcoded to the "Top rated" sort and not user-adjustable), Original language (10 languages, sent as `with_original_language`). Paired with Min rating, Min votes filters out "10/10 with one vote" noise. 13 localization keys EN+RU.

  * lib/core/api/tmdb_api.dart (TmdbApi.discoverMovies, TmdbApi.discoverTvShows): Accept new `voteAverageGte`, `voteCountGte`, `originalLanguage` params.
  * lib/features/search/filters/tmdb_genre_filter.dart (TmdbGenreFilter): Enable multi-select.
  * lib/features/search/filters/min_rating_filter.dart (MinRatingFilter), min_votes_filter.dart (MinVotesFilter), tmdb_language_filter.dart (TmdbLanguageFilter): New.
  * lib/features/search/sources/tmdb_movies_source.dart, tmdb_tv_source.dart, tmdb_anime_source.dart: Wire new filters; client-side genre fallback on text search supports multi-genre.

- **AniList search filters expanded**

  Anime tab goes from 2 filters (genre, status) to 4: multi-select genre (`genre_in: [String]`), anime format (`MediaFormat`), and year via `startDate` bounds — reliable across all anime, including older and cancelled titles where `seasonYear` is null. Manga tab goes from 2 to 4: multi-select genre, status (`MediaStatus`, with manga-specific labels), and year range via the same bounds. `MangaFormatFilter` is limited to AniList-valid values; MANHWA / MANHUA / LIGHT_NOVEL are not members of AniList's `MediaFormat` enum and were removed.

  * lib/core/api/anilist_api.dart (AniListApi.browseAnime, AniListApi.browseManga): Change `$genre: String` → `$genres: [String]`; add `$format`, `$status`, `$startDateGreater`, `$startDateLesser` GraphQL vars.
  * lib/features/search/filters/anilist_anime_format_filter.dart (AniListAnimeFormatFilter), anilist_manga_status_filter.dart (AniListMangaStatusFilter): New.
  * lib/features/search/filters/manga_format_filter.dart (MangaFormatFilter.options): Limit to MANGA, NOVEL, ONE_SHOT.
  * lib/features/search/filters/anilist_anime_genre_filter.dart, anilist_genre_filter.dart: Enable multi-select.
  * lib/features/search/sources/anilist_anime_source.dart, anilist_manga_source.dart: Wire new filters.

- **IGDB search filters expanded**

  Games tab goes from 3 filters (genre, platform, year) to 5: multi-select genre (IGDB syntax `genres = (12,31)` for OR match; previously single `genres = (12)`), Min rating (6+ / 7+ / 8+ / 9+ on the 1–10 scale, converted ×10 before hitting IGDB's native 0–100 `rating >= N`), Game mode (Single player / Multiplayer / Co-operative / Split screen / MMO / Battle Royale; canonical IGDB IDs 1-6; sent as `game_modes = (1,3)`).

  * lib/core/api/igdb_api.dart (IgdbApi.searchGames, IgdbApi.browseGames): Accept `List<int>? genreIds / gameModeIds` and `int? minRating`.
  * lib/features/search/filters/igdb_min_rating_filter.dart (IgdbMinRatingFilter), igdb_game_mode_filter.dart (IgdbGameModeFilter): New.
  * lib/features/search/filters/igdb_genre_filter.dart (IgdbGenreFilter): Enable multi-select.
  * lib/features/search/sources/igdb_games_source.dart: Wire new filters; convert Min rating UI value ×10 before the API call.

- **Year filter extended and more granular**

  Shared `YearFilter` used by TMDB / AniList / IGDB now lists individual years from the current year down to 1980 (was: down to 2000), with decade buckets for 1970s and 1960s for truly retro (Atari era). Popover is `searchable` since the list is long. Previously users had no way to pick e.g. 1995 directly — had to fall back to the "1990s" bucket. New localization keys EN+RU cover anime formats, manga statuses, and game modes.

  * lib/features/search/filters/year_filter.dart (YearFilter.options, YearFilter.searchable): Extend range to 1980; enable searchable popover.
  * lib/l10n/app_en.arb, app_ru.arb: Add labels for new filter values.

### Changed

- **Prune visual-overfit asserts across the test suite**

  The suite had ~1000 assertions that pinned tests to specific colours, icon constants, font sizes, paddings, and structural wrapper widgets (Container / SizedBox / Padding). Every one of those would have broken on a cosmetic redesign without a real behavioural change. Kept what verifies behaviour — data flowing to UI, callbacks firing, conditional show / hide on state change, prop pass-through, collaborator calls; dropped what only pinned visuals. ~190 tests removed or collapsed; 4617 tests still green.

  * test/shared/theme/app_colors_test.dart, app_typography_test.dart, app_theme_test.dart: Delete. Every assertion compared a theme token to its own hard-coded value.
  * test/shared/widgets/media_poster_card_test.dart, shimmer_loading_test.dart, star_rating_bar_test.dart, dual_rating_badge_test.dart, screen_app_bar_test.dart: Rewrite around behaviour. Drop icon sizes, elevation / clipBehavior / border width + colour, ColoredBox alpha overlays, hard-coded child-count structural probes.
  * test/shared/extensions/snackbar_extension_test.dart: Keep type → matching icon contract, loading replaces icon with CircularProgressIndicator, action / duration / hideSnack semantics. Drop icon / message / border colour probes, fontSize 13, SnackBar elevation 4, behavior / dismissDirection.
  * test/shared/models/item_status_test.dart: Keep enum contract, value / fromString + fallbacks, sortPriority ordering / uniqueness, and the "every status has a unique icon" invariant. Drop the specific `AppColors.X` / `Icons.X` mappings.
  * test/features/welcome/widgets/welcome_step_intro_test.dart, welcome_step_how_it_works_test.dart, step_indicator_test.dart: Collapse to smoke tests + behavioural toggles (pending / active / done swaps number ↔ checkmark, onTap fires). Drop colour / size / static-label probes on content pages.
  * test/features/collections/widgets/vgmaps_panel_test.dart, steamgriddb_panel_test.dart, canvas_image_item_test.dart, canvas_text_item_test.dart: Drop chrome-visibility asserts (close / arrow_back / arrow_forward / home / refresh / search / image_search / map) and layout probes (SizedBox.expand width / height, Card clipBehavior antiAlias, Padding 8, "text has no Container background"). Behavioural coverage retained: canGoBack / canGoForward disable state, error-state conditional icon, captured-image bar flow with Add-to-Board callback.
  * test/features/search/widgets/discover_row_test.dart, test/features/tier_lists/widgets/tier_row_test.dart: Replace SizedBox / TierItemCard structural probes with positive absence checks.

- **Tags are preserved when moving or copying an item between collections**

  Right-click Move / Copy remap the item's tag to the target collection by name (case-insensitive, Unicode-safe via Dart `toLowerCase`, so «РПГ» matches «рпг»). If a tag with the same name already exists, the item is linked to it; otherwise a new tag is created with the source tag's colour. Previously tags were silently dropped on move, and Clone copied a stale `tag_id` referencing a tag from a different collection. Moves to uncategorised still clear the tag.

  * lib/data/daos/tag_dao.dart (TagDao.findTagByNameCaseInsensitive, TagDao.resolveOrCreateInCollection): New.
  * lib/data/daos/collection_dao.dart (CollectionDao.cloneItemToCollection): Null `tag_id` in the copied row.
  * lib/features/collections/providers/collections_provider.dart (CollectionItemsNotifier.moveItem, CollectionItemsNotifier.cloneItem): Accept optional `sourceTagId`; resolve and write the target tag once (no clear-then-set round-trip); invalidate `collectionTagsProvider` when a new tag was created.
  * lib/features/collections/widgets/collection_actions.dart: Pass `sourceTagId` from the source item.

- **Tap anywhere on the review / notes block to edit**

  Author review and personal notes sections on the item detail screen enter editing mode on a single tap, whether empty or populated. Markdown links inside the rendered text keep working because their `TapGestureRecognizer` wins the gesture arena over the ancestor `InkWell`. Author review stays non-interactive for read-only collections. Trade-off: drag-selection of rendered text is no longer available — users copy from the TextField after entering edit mode.

  * lib/shared/widgets/media_detail_view.dart: Wrap review / notes in `InkWell`; gate author review edit on `canEdit`.

- **Vague UI terms renamed per user feedback**

  «Список» (Wishlist nav tab) → «Желаемое» in Russian. «Профили» / «Профиль» in Settings → «Профили приложения» / «Автор коллекций» (EN: "App profiles" / "Collection author"), resolving the ambiguity between multi-user profiles and the collection author name. «элемент» → «тайтл» across 27 strings (including plural forms): FAB labels, stats, snackbars, tier lists, tags, imports, wishlist, all-items. "Element" is retained on the canvas where it refers to board primitives (text / sticker / link), not collection items.

  * lib/l10n/app_en.arb, app_ru.arb: Rename keys / update values.

- **Kodi settings screen fully localized**

  ~45 new localization keys cover Connection (Host / Port / Username / Password / Test connection), Sync (Target collection, Enable sync, Sync interval, Sub-collections, Import ratings), Debug (Sync status, Last sync, Clear timestamp, Request log, Raw JSON-RPC). The "Integrations" section header and "Kodi" subtitle on the main Settings screen are also localized. Proper nouns (the word "Kodi", JSON-RPC API examples like `VideoLibrary.GetMovies`) remain in English.

  * lib/features/settings/screens/kodi_screen.dart, settings_screen.dart: Route hardcoded strings through `S.of(context)`.
  * lib/l10n/app_en.arb, app_ru.arb: Add keys.

- **Empty-collection hint localized**

  Two fallback hints below the "No items yet" header (`collectionEmptyAddHint`, `collectionEmptyReadonly`) were still hardcoded English; now translated to Russian.

  * lib/features/collections/widgets/collection_items_view.dart: Replace hardcoded strings with `S.of(context)` lookups.

- **Settings screen reorganized per user feedback**

  Section order is now Profile → Data (Backup / Restore / Import / Storage) → Appearance → Services → About. Data-critical flows (backup, import) surface right after the profile block. The Gamepad Debug entry is removed from the main list (still reachable through the Debug Hub in `kDebugMode` builds). The Error group no longer renders as a separate section. Version is a tile inside About. Discord RPC and Discord RA sync move out of Appearance into Services — they're integrations, not look-and-feel toggles.

  * lib/features/settings/screens/settings_screen.dart: Reorder sections; remove orphan entries.

- **Colored iOS-style leading bubbles on every settings tile**

  Each row gets a 28×28 rounded coloured capsule with a white icon on the left; section headers show a matching small icon before the uppercase title. Status pips and value colours highlight active state: the Kodi row shows a green pip + green "On" when enabled, the API keys value turns green when all three are set.

  * lib/features/settings/widgets/settings_tile.dart (SettingsTile): Add `leadingIcon`, `leadingColor`, `statusDotColor`, `valueColor` params.
  * lib/features/settings/widgets/settings_group.dart (SettingsGroup): Add `titleIcon`, `titleIconColor`.
  * lib/features/settings/screens/settings_screen.dart: Populate icons / colours across tiles.

- **Compact sizing on narrow screens (<600px)**

  Across the Settings screen and the global top-bar search field, font sizes, icon sizes, and vertical padding shrink for mobile using the existing `isCompactScreen` helper. Desktop (≥600px) layout unchanged.

  * lib/features/settings/widgets/settings_tile.dart, settings_group.dart, lib/shared/widgets/app_top_bar.dart: Branch sizing on `isCompactScreen`.

- **Explicit Save button in every settings input field** (UX breaking)

  `InlineTextField` used to auto-save on focus loss, which was implicit and inconsistent with the rest of the UI; SteamGridDB and TMDB key fields additionally wrote to prefs on every keystroke. Every settings field (Author name; IGDB Client ID / Secret; SteamGridDB and TMDB API keys; Kodi Host / Port / Username / Password) now shows an orange "✓ Save" pill flush to the right edge of the field while there are unsaved changes. Tapping outside cancels and reverts. Enter still commits. The Save pill listens to raw `onPointerDown` so clicks commit before the TextField blurs itself on desktop mouse input.

  * lib/features/settings/widgets/inline_text_field.dart (InlineTextField): Remove auto-save-on-blur; add explicit Save pill.

- **Unified StatusDot + sync-icon row on all API key sections**

  IGDB, SteamGridDB, and TMDB blocks end in the same row: a coloured StatusDot (green ✓ connected / red ✕ error / grey ? unknown) on the left, a circular sync (↻) IconButton on the right to rerun validation. Reset button sits between them when a built-in default is available. The old separate "Connection Status" SettingsGroup with StatusDot + "Platforms available: N" row + full-width "Verify Connection" button is folded into the IGDB credentials card. SteamGridDB and TMDB now track their last-validation result locally.

  * lib/features/settings/widgets/credentials_content.dart: Unify three API sections; track last-validation locally for SteamGridDB and TMDB.

- **Kodi settings: Target Collection elevated to the top**

  It's the most consequential choice and the picker works offline; the section now precedes Connection. When the referenced collection has been deleted externally, `targetCollectionId` is cleared automatically on open (a guard flag prevents the post-frame callback from stacking across rebuilds). While no valid target is selected, Enable sync, Sync interval, Sub-collections, and Import ratings all render as disabled. The "Test connection" row is replaced by the same StatusDot + sync-icon pattern used on the API key sections.

  * lib/features/settings/screens/kodi_screen.dart: Reorder sections; add post-frame target-cleanup guard.

### Removed

- **`Platforms available` row and the standalone Connection Status group in IGDB credentials**

  The metric didn't justify its space; the connection status lives inside the IGDB credentials card now.

  * lib/features/settings/widgets/credentials_content.dart: Remove the group; fold StatusDot + sync-icon pattern into the IGDB credentials card.

- **Standalone Gamepad Debug entry in the main Settings screen**

  Still reachable from the Debug Hub in `kDebugMode` builds. Orphan localization key `settingsGamepadDebugSubtitle` deleted from both ARBs.

  * lib/features/settings/screens/settings_screen.dart: Remove entry.
  * lib/l10n/app_en.arb, app_ru.arb: Remove orphan key.

- **"Tier list" entry in a collection's three-dot menu**

  The duplicate shortcut that opened the global tier lists list for the current collection is gone; the "Create tier list from this collection" action remains.

  * lib/features/collections/screens/collection_screen.dart: Remove menu entry.

## [0.27.0] - 2026-04-18

### Changed
- **Tags sorted alphabetically (case-insensitive)** — in Manage Tags dialog and in the item tag picker. Previously DAO ordering (`sort_order ASC, name ASC`) combined with `sort_order=0` for every tag fell back to SQLite binary `name ASC` sort, which mixed case and Cyrillic unexpectedly. Sorting is now applied in `CollectionTagsNotifier` on `build`/`create`/`rename`/`refresh` via lowercase `compareTo` (`collection_tags_provider.dart`)

### Fixed
- **Search field did not react to typing when opened from a collection or wishlist** — the global `AppTopBar` search field is bound to the active tab's query provider (`searchContextFor(activeTab)`), but `SearchScreen` always reads `searchTabQueryProvider`. When pushed from a collection's `+` button or a wishlist item, the active tab stayed `Collections`/`Wishlist`, so keystrokes went into the wrong provider and the screen saw nothing. `SearchScreen` now accepts an `isPushed` flag; callers (`CollectionActions.addItems`, `WishlistScreen`) push via `rootNavigator: true` and pass `isPushed: true`, which makes the screen render its own `Scaffold`/`AppBar` with a `TextField` wired directly to `searchTabQueryProvider`. Controller initializes from the current provider value so reopening the screen restores the last query (`search_screen.dart`, `collection_actions.dart`, `wishlist_screen.dart`)
- **`SharedPreferences.setPrefix` threw `StateError` on in-process restart** — `setPrefix('flutter_dev.')` was called inside `_loadAppState()`, which runs again from `AppRestartScope._restart()` after the first `getInstance()`. The second call violated the library precondition and was swallowed by `runZonedGuarded` as a severe log. Moved to `main()` before the first `_loadAppState()` so it runs exactly once per process (`main.dart`)

### Changed
- **Table view drag-and-drop reorder** — `CollectionTableView` accepts an optional `onReorder` callback; when set, renders a `ReorderableListView` with a drag handle per row and disables column-click sort/filter (manual order takes priority). `CollectionItemsView` wires `onReorder` when `sortMode == manual && canEdit`, reusing the existing `reorderItem()` notifier/DAO pipeline (`collection_table_view.dart`, `collection_items_view.dart`)
- **Table view visual polish** — zebra row striping (alpha 10) replaces the thin divider; thumbnails grow from 32×46 to 36×52 with increased row padding; header labels become UPPERCASE with 0.8 letter-spacing and softer `textTertiary` color; status chip gains a 6px colored dot before its label; empty rating/tag cells render blank instead of an em-dash; hover tint bumped from alpha 12 to 22 (`collection_table_view.dart`)
- **Home status filter defaults to "All"** — previously the Home tab defaulted to showing only `inProgress` items, so new users had to discover the filter to see everything. Now defaults to `null` (All); user choice still persists per profile (`collections_provider.dart`)

## [0.26.0] - 2026-04-16

### Added
- **Time Spent tracking** — per-item time logging in collection. Timer icon with `Xh Ym` value in the item detail header row (next to source badge and media type). Tap to open hours+minutes input dialog — entered value replaces the total. Stored as `time_spent_minutes` column in `collection_items` (DB migration v34). Included in `.xcollx` export when "Include user data" is enabled. Header row changed from `Row` to `Wrap` to prevent overflow with many elements (`add_time_dialog.dart`, `media_detail_view.dart`, `item_detail_screen.dart`, `collection_item.dart`, `collection_dao.dart`, `collections_provider.dart`)
- **Service status badges in top bar** — desktop-only SVG icons for Kodi sync and Discord RPC in the app header, between the search field and settings gear. Brand-colored (Kodi blue, Discord blurple) when connected/running, gray when stopped/disconnected. Kodi icon pulses during active sync cycle. Click to toggle: Kodi start/stop sync timer, Discord connect/disconnect IPC. Tooltip shows current status. Uses polling-based `serviceStatusProvider` (2s interval with `ref.read`) to avoid badge flicker from settings invalidation. `DiscordRpcService.isConnected` / `isEnabled` public getters. SVG assets: `icon_discord.svg`, `icon_kodi.svg` (`service_badges.dart`, `service_status_provider.dart`, `app_top_bar.dart`, `discord_rpc_service.dart`, `app_assets.dart`)
- **Kodi watch sync** — background sync service that periodically polls Kodi VideoLibrary via JSON-RPC, matches movies to TMDB, and syncs watch status/ratings/dates to local collections. First sync cycle auto-populates the target collection with all Kodi movies; subsequent cycles update existing items and add new ones. Sub-collections from Kodi movie sets (e.g. "Harry Potter Collection (kodi)"). Per-profile settings with connection config, sync interval (30s–15min), import ratings toggle. Unified KodiScreen in Settings: connection test, sync controls, debug panel with request log and raw JSON-RPC console. TMDB `/find/{id}` endpoint for IMDB→TMDB resolution. New DAO methods: `findAllCollectionItems()`, `findCollectionByName()`. Models: KodiMovie, KodiTvShow, KodiEpisode, KodiUniqueIds, KodiApplicationInfo, KodiDateParser (`kodi_api.dart`, `kodi_sync_service.dart`, `kodi_settings_provider.dart`, `kodi_screen.dart`, `tmdb_api.dart`, `collection_dao.dart`)
- **Item status logic extracted to pure functions** — `computeDatesForStatus()`, `computeStatusForDates()`, `computeStatusFromProgress()`, `mergeExternalStatus()` centralize all status/date transition rules. Used by collections provider, episode tracker, and all external sync services (RA, Steam, Trakt, Kodi). 617 lines of pure unit tests with full branch coverage (`item_status_logic.dart`, `collections_provider.dart`, `episode_tracker_provider.dart`, `ra_sync_helpers.dart`, `steam_import_service.dart`, `trakt_zip_import_service.dart`)
- **Anime (AniList) as new media type** — `MediaType.anime` for Japanese anime with full AniList metadata: episodes, duration, format (TV/OVA/Movie/ONA/Special), source material (Original/Manga/Light Novel), studios, season, banner image for backdrop. New `anime_cache` table (DB migration v33), `AnimeDao`, `ImageType.animeCover`, `AppColors.animeAccent` (pink). AniList GraphQL queries extended with `duration`, `source`, `bannerImage`, `nextAiringEpisode`. Full integration: search (browse + filters), add to collection, detail card with chips, canvas, export/import, backup. `AniListAnimeSource` activated in search sources. Anime filter chip added to collection filter bar and Home/All Items screen. 5 localization keys EN+RU (`anime_dao.dart`, `migration_v33.dart`, `anime_progress_section.dart`, `anilist_anime_source.dart`, + ~35 files updated)
- **Anime episode progress tracker** — `AnimeProgressSection` with progress bar, "+1 episode" button, manual edit dialog, "Mark as completed" button, and next airing episode info for ongoing anime. Auto-status: +1 from zero → inProgress, mark completed → completed, reset to 0 → notStarted, dropped untouched. Uses existing `currentEpisode` field (no migration needed) (`anime_progress_section.dart`, `collections_provider.dart`)
- **CopyableText shared widget** — extracted from `ScreenAppBar._CopyableTitle` into reusable `CopyableText` widget. Accepts any child widget + text to copy. Now used in both `ScreenAppBar` and `ItemDetailsSheet` title. Tap to copy, hover shows copy/check icon (`copyable_text.dart`, `screen_app_bar.dart`, `item_details_sheet.dart`)
- **MediaProgressRow shared widget** — extracted progress row (label + value + progress bar + increment button) from `MangaProgressSection` into reusable `MediaProgressRow`. Now shared between manga and anime progress sections, eliminating code duplication (`media_progress_row.dart`, `manga_progress_section.dart`, `anime_progress_section.dart`)
- **Discord Rich Presence** — shows currently viewed collection item in Discord status (desktop only). Displays activity verb (Playing/Watching/Reading) + item name, platform/progress/year, elapsed timer. RetroAchievements-linked games show RA icon with achievement progress (earned/total) and award status (Beaten/Mastered). Toggle in Settings > Appearance. Auto-connects on app launch if enabled, lazy reconnect if Discord starts later. Uses `dart_discord_presence` package via IPC pipe (`discord_rpc_service.dart`, `settings_provider.dart`, `settings_screen.dart`, `item_detail_screen.dart`, `platform_features.dart`). 2 localization keys EN+RU
- **Discord RetroAchievements sync** — optional mode that polls RA profile every 30 seconds and streams live emulator activity to Discord. Shows game title + platform (fetched via `getGameSummary`), in-game Rich Presence string from emulator, and achievement progress. Game info cached per session to minimize API calls. When RA sync is active, collection card presence is suppressed. Toggle appears in Settings when Discord RPC is on and RA credentials are configured. `RaUserProfile.lastGameId` field added, `RaApi.getGameSummary()` lightweight endpoint. 2 localization keys EN+RU (`discord_rpc_service.dart`, `settings_provider.dart`, `settings_screen.dart`, `ra_api.dart`, `ra_user_profile.dart`)
- **Gyroscope parallax effect (Android)** — backdrop images in item detail card and search detail sheet subtly shift based on device tilt, creating a depth illusion behind the content overlay. Uses `sensors_plus` for gyroscope data with smooth lerp interpolation. Desktop renders statically (`gyroscope_parallax_image.dart`, `media_detail_view.dart`, `item_details_sheet.dart`)
- **Discord RetroAchievements sync** — optional mode that polls RA profile every 30 seconds and streams live emulator activity to Discord. Shows game title + platform (fetched via `getGameSummary`), in-game Rich Presence string from emulator, and achievement progress. Game info cached per session to minimize API calls. When RA sync is active, collection card presence is suppressed. Toggle appears in Settings when Discord RPC is on and RA credentials are configured. `RaUserProfile.lastGameId` field added, `RaApi.getGameSummary()` lightweight endpoint. 2 localization keys EN+RU (`discord_rpc_service.dart`, `settings_provider.dart`, `settings_screen.dart`, `ra_api.dart`, `ra_user_profile.dart`)

### Changed
- **Notes auto-save** — user notes and author comments now auto-save with 1-second debounce while typing. Also saves on dispose (leaving the screen). No more losing notes by forgetting to press the check button. Check button still works — it saves immediately and exits edit mode (`media_detail_view.dart`)
- **App shell redesign (liquid sidebar + adaptive bottom bar)** — navigation replaced: desktop gets a 72px rail with liquid-morphing selection indicator (`LiquidIndicator`), mobile gets a matching 64px bottom bar. Deleted the old `navigation_shell.dart` (~625 lines) and its 371-line test suite. New files: `app_shell.dart`, `app_sidebar.dart`, `app_bottom_bar.dart`, `liquid_indicator.dart`, `nav_icon_button.dart`, `nav_destinations.dart`, `nav_tab.dart` (`lib/shared/navigation/`)
- **Global app top bar with contextual search** — persistent `AppTopBar` replaces per-screen search fields. Hosts centered search field that is wired to the active tab's query provider, a settings gear with update badge, and an F1 shortcut hint. Per-tab query state lives in `search_providers.dart` (`collectionsSearchQueryProvider`, `allItemsSearchQueryProvider`, plus existing per-feature providers). Typing anywhere on a screen with no focused editable routes characters into the top-bar field (`app_top_bar.dart`, `search_providers.dart`, `app_shell.dart`)
- **DraggableFab replaces per-screen AppBar actions** — screen actions (create, import, toggle view, sort direction, extra menu, export, rename, delete…) are now exposed via a repositionable Fan menu attached to a single circular FAB. Primary actions fan horizontally; secondary actions fan vertically with dividers. Drag to relocate, tap to open (`draggable_fab.dart`, applied across Home, Collection, Wishlist, Tier Lists, Settings sub-screens)
- **Chevron filter bar with segmented media-type selector** — new `ChevronSegment` and `StatusDropdownSegment` primitives form a full-width row of connected chevrons. Active segment tints with media accent (`MediaTypeTheme.colorFor`), inactive segments tint faintly. Compact mode (<700px) collapses labels to icons. Used by `CollectionFilterBar` (`lib/shared/widgets/chevron_filter_bar.dart`) and by the redesigned search `FilterBar` (`lib/features/search/widgets/filter_bar.dart`)
- **Bottom-sheet filters on narrow screens** — collection and search filters collapse to a `DraggableScrollableSheet` with a drag handle, radial accent glow, and per-row sort/filter controls. Opened via a tune-icon chevron button in the filter bar. Applied to `CollectionFilterSheet` and the new `FilterSheet` (`collection_filter_sheet.dart`, `filter_sheet.dart`)
- **Unified SubScreenTitleBar on all sub-screens** — 44px title bar with back button (auto-hidden when nothing to pop) and bottom border, replacing `ScreenAppBar` in settings, debug, profile-picker, tier-list-detail, wishlist, and collection screens (`sub_screen_title_bar.dart`)
- **Search filter bar consolidated into chevrons** — `FilterBar` (browse mode) now builds the same chevron row that `CollectionFilterBar` uses: first chevron is source picker (accent-tinted per group), followed by source-specific filter chevrons and a sort chevron; TMDB sources show a compact Customize chevron. On narrow screens collapses to `[Source][🎚 Filters (N)][Customize?]` with a sheet. Clear button appears only when filters are active. Deleted: in-bar `SourceDropdown`/`FilterDropdown`/`SortDropdown` fixed-height-36 variants (`filter_bar.dart`)
- **All Items filters redesigned** — `AllItemsScreen` filter row uses the same chevron segments as collection view with media-type counts inline. Platform dropdown extracted into sheet on narrow screens (`all_items_screen.dart`)
- **Wishlist and Tier Lists adapted to new shell** — removed custom `ScreenAppBar` wiring, actions moved to `DraggableFab`, list and grid styles unchanged (`wishlist_screen.dart`, `tier_lists_screen.dart`, `tier_list_detail_screen.dart`)
- **Settings sub-screens use standard AppBar** — `credentials_screen`, `cache_screen`, `debug_hub_screen`, `credits_screen`, `database_screen`, `profiles_screen`, `steam_import_screen`, `ra_import_screen`, `trakt_import_screen`, `browse_collections_screen`, `gamepad_debug_screen`, `steamgriddb_debug_screen`, `import_result_screen` now use `SubScreenTitleBar` or platform `AppBar` and integrate with global top bar search (~13 screens updated)
- **Search chevron filter sentinel unified** — `filter_dropdown.dart`, `filter_bar.dart`, and `filter_sheet.dart` share one `kFilterResetSentinel` so the "All" option in the searchable dialog clears the filter regardless of entry point. Shared `filterAccentForGroup` utility extracted to `lib/features/search/utils/filter_ui.dart`, replacing the duplicate `_accentForGroup` helper in `filter_bar.dart` and `filter_sheet.dart` (`filter_ui.dart`)
- **Platform list extraction is now cached** — `CollectionFilterBar._extractPlatforms()` caches its result by item-list identity instead of recomputing every rebuild (`collection_filter_bar.dart`)
- **Discover Customize visibility** — TMDB "Customize feed" chevron stays visible when filters are selected (Customize IS the filter/sort configuration of the feed); it only hides when an actual text search is active, at which point the feed becomes search results (`filter_bar.dart`)
- **ItemDetailsSheet narrow-screen polish** — search/discover detail sheet adapts to narrow windows and phones: below 500px width the header switches to a stacked layout (hero poster centered on top, info column full-width below so genres/tags get the whole sheet width instead of a ~220px strip beside the cover). The `+` add button moved from its own drag-handle row to a `Positioned` overlay in the top-right, reclaiming ~50px of header height; info column reserves 48px right padding in row mode so the button never covers the title. Backdrop gained two improvements: falls back to the poster with strong blur (`ImageFilter.blur` sigma=40, denser gradient) as an ambient background when no dedicated backdrop is available, and switches from `BoxFit.cover`/`center` to `BoxFit.fitWidth`/`topCenter` for real backdrops so landscape images show their full width at the top instead of being cropped to a center slice (`item_details_sheet.dart`)

## [0.25.1] - 2026-04-10

### Added
- **Copy title from AppBar** — clicking the title in `ScreenAppBar` copies it to clipboard. Hover shows copy icon, turns to checkmark on success. Works on all screens with titles (`screen_app_bar.dart`)
- **Wishlist context menu** — right-click (desktop) and long press (mobile) on wishlist items opens context menu with Search, Edit, Resolve/Unresolve, and Delete actions. Replaced trailing `PopupMenuButton` with `showMenu` at cursor/touch position (`wishlist_screen.dart`)
- **Unified ItemDetailsSheet** — merged 4 separate detail bottom sheets (`GameDetailsSheet`, `MediaDetailsSheet`, `MangaDetailsSheet`, `VnDetailsSheet`) into single modular `ItemDetailsSheet` with factory constructors (`.movie()`, `.tvShow()`, `.game()`, `.manga()`, `.visualNovel()`). Redesigned UI: rounded sheet with elevation and tiled background pattern, full-bleed backdrop image with gradient fade, translucent content card, circular floating "+" add button. 3 deleted files (~900 lines), 1 new file (~600 lines) (`item_details_sheet.dart`, `search_screen.dart`, `discover_feed.dart`, `recommendations_section.dart`)
- **Backdrop in item detail card** — full-bleed backdrop with vertical gradient fade (matching search sheet style), content wrapped in frosted-glass container. Games use IGDB artwork (`artwork_url`), manga uses AniList banner (`banner_url`). DB migration v32. All backdrop URLs persisted to DB (`media_detail_view.dart`)
- **Detailed API error info with copy button** — all 7 API clients now capture full debug info on errors: API name, request URL+method, HTTP status, DioException type, underlying cause, and response body excerpt. Error display shows user-friendly message with "Copy error details" button. New files: `api_error_detail.dart`, `api_error_extract.dart`, `api_error_display.dart`. 2 localization keys EN+RU
- **API connection timeouts** — all 7 API clients now have 5-second `connectTimeout` and `receiveTimeout` (was unlimited). Prevents UI from hanging indefinitely on network issues

### Changed
- **RA platform mapping expanded and fixed** — `consolePlatformMap` changed from `Map<int, int>` to `Map<int, List<int>>` to support IGDB aliases (Super Famicom, Family Computer, Neo Geo Pocket Color, WonderSwan Color, etc.). Fixed 7 incorrect mappings (Game Gear→Nintendo DS, Atari Jaguar→Atari 7800, Nintendo DS→Xbox One, Virtual Boy→ColecoVision, ColecoVision→Vectrex, Atari 7800→Atari Jaguar, Game & Watch→Game Gear). Added 22 new platforms (Amstrad CPC, Apple II, Intellivision, Vectrex, PC-8800, Atari 5200, Fairchild Channel F, Arduboy, Arcadia 2001, etc.). New `primaryIgdbPlatformId()` helper for forward lookup. Total: 56 RA→IGDB mappings (was 34) (`ra_to_igdb_mapper.dart`, `ra_import_service.dart`)
- **Star rating bar reduced** — default star size decreased from 28px to 24px to prevent overflow in narrower layouts (`star_rating_bar.dart`)
- **Search sources preserve typed exceptions** — VNDB, AniList anime, and AniList manga search sources now `rethrow` instead of wrapping in `Exception(e.message)`, preserving error detail for the UI

## [0.25.0] - 2026-04-08

### Added
- **RetroAchievements tracker system** — universal tracker infrastructure with 3 new database tables (`tracker_profiles`, `tracker_game_data`, `tracker_achievements`). RA achievements section in game detail card: stats block (total/unlocked/points/HC), beaten progress panel (progression + win condition bars), achievement list with badge icons, type indicators (missable/progression/win condition), filter chips, award badges (RA-style colored circles: gold=Mastered, silver=Beaten, outline=Softcore). Data loads lazily when opening a game card. Tracker data included in xcollx export (with "Include user data") and full backups. RA credentials saved on Verify Connection (no import required). DB migration v31. 30+ localization keys EN+RU
- **Link/Unlink RetroAchievements** — RA logo badge in game detail header row (next to IGDB/platform badges). Linked: full-color logo, click opens RA game page. Unlinked: pulsing semi-transparent logo, click opens search dialog to link. "Unlink" button in RA section header with confirmation. Search dialog loads game list from RA API by console, local filtering with exact/prefix/contains ranking. `RaApi.getGameList()` + `RaGameListEntry` model. `TrackerDao.deleteGameData()` with cascading achievement cleanup. Reverse platform mapping `igdbToRaConsoleIds()`. 12 localization keys EN+RU (`ra_link_dialog.dart`, `ra_api.dart`, `ra_to_igdb_mapper.dart`, `tracker_provider.dart`, `tracker_dao.dart`, `item_detail_screen.dart`)
- **RA date and status sync** — opening a game card with RA data syncs `startedAt` (first earned achievement), `lastActivityAt` (most recent earned), `completedAt` (award date), and `status` to `collection_items`. Status rules: beaten/mastered → completed, >0 achievements + >90 days inactive → dropped (blocked for notStarted/planned items), >0 achievements → inProgress, 0 achievements → no change. Shared `syncRaDataToCollectionItem()` helper used by both import and per-game refresh. `GetGameInfoAndUserProgress` now uses `a=1` param for award data. Optimistic UI updates without full list reload (`ra_sync_helpers.dart`, `tracker_provider.dart`, `tracker_sync_service.dart`, `collections_provider.dart`, `ra_game_progress.dart`, `ra_import_service.dart`)
- **Unified ItemDetailsSheet** — merged 4 separate detail bottom sheets (`GameDetailsSheet`, `MediaDetailsSheet`, `MangaDetailsSheet`, `VnDetailsSheet`) into single modular `ItemDetailsSheet` with factory constructors (`.movie()`, `.tvShow()`, `.game()`, `.manga()`, `.visualNovel()`). Redesigned UI: rounded sheet with elevation and tiled background pattern, full-bleed backdrop image with gradient fade (visible at top, dissolving to dark at bottom), translucent content card, circular floating "+" add button in header with hover scale effect, `SourceBadge` with external link, year inline with title, compact genre chips. Modular parameters: `subtitle`, `infoChips`, `extraInfoIcon`, `maxGenres`, `coverHeight`. 3 deleted files (~900 lines), 1 new file (~600 lines). `_RecPosterCard` and `_DiscoverPosterCard` replaced with unified `MediaPosterCard` — consistent hover effects, rating badges, and "in collection" indicators across search, discover, and recommendations (`item_details_sheet.dart`, `search_screen.dart`, `discover_feed.dart`, `recommendations_section.dart`)
- **Adaptive card variant** — poster cards automatically use `CardVariant.compact` on mobile (<600px) and `CardVariant.grid` on desktop across all screens: Main (all items), collection grid, search results, discover feed, recommendations
- **Table view horizontal scroll** — collection table view scrolls horizontally on narrow screens (<600px) with minimum width 600px, keeping all columns visible instead of overflowing
- **Backdrop in item detail card** — movies, TV shows, games, and manga display backdrop image as background in the detail card (gradient fade, 40% screen height). Movies/TV use TMDB backdrop, games use IGDB artwork (`artwork_url` in `games`), manga uses AniList banner (`banner_url` in `manga_cache`). DB migration v32. All backdrop URLs persisted to DB, included in export/import. Visible through content with diagonal + vertical transparency
- **Update warning dialog** — tapping "Update available" in Settings now shows a warning dialog reminding users to create a backup before updating. Explains that the app is in active development and database migrations may change data format. 3 localization keys EN+RU
- **App version in backup filename** — backup ZIP now named `tonkatsu-backup-v{version}-{date}.zip` and manifest includes `app_version` field
- **Browse Online Collections** — new screen in Settings > Import to browse and download pre-built collections from the `tonkatsu-collections` GitHub repository. Features searchable dropdown filters for platform (32 platforms) and category, text search, download with progress indicator, and automatic import via existing `ImportService`. Supports `.xcoll`, `.xcollx`, and `.zip` files. 16 localization keys EN+RU (`collection_browser_service.dart`, `collections_index.dart`, `collection_browser_provider.dart`, `browse_collections_screen.dart`, `browse_collections_content.dart`, `settings_screen.dart`)
- **Table view inline editing** — click Rating cell to set 1–10 stars via popup (with hover highlight and clear button), click Status chip to change status via dropdown (5 options with colored icons, auto-sets `startedAt`/`completedAt`), click Tag cell to assign/remove tag via popup. All editable only when collection is not locked (`collection_table_view.dart`, `collection_items_view.dart`)
- **Tag column in table view** — new `TableColumn.tag` between Status and Rating. Colored chip for assigned tag, em-dash when untagged. Supports cyclic header filter and alphabetical sorting (`collection_table_view.dart`)
- **Platform cyclic filter** — clicking Platform column header now cycles through platform values (like Status/Type/Rating) instead of toggling sort direction. Header shows current filter value (`collection_table_view.dart`)
- **Tag sidebar** — vertical bookmark-style panel on the right side of collection view (desktop only). Appears when 1+ tags exist. Multi-select: click tags to toggle. "Group" button at top toggles tag grouping mode — sorts items by tag and adds animated color-coded border (rotating highlight) around each tagged poster. Stale tag IDs auto-cleaned from filter on tag deletion (`tag_sidebar.dart`, `collection_screen.dart`, `collection_items_view.dart`, `media_poster_card.dart`)
- **Tag name search** — text search in collection (search bar + type-to-filter) and All Items screen now matches item name OR tag name. `TagDao.getAll()` and `allTagsMapProvider` for cross-collection tag lookup (`collection_screen.dart`, `all_items_screen.dart`, `all_items_provider.dart`, `tag_dao.dart`)
- **Tag display on All Items** — poster cards on the Home/All Items screen now show tag name and color badge, same as in collection view (`all_items_screen.dart`)
- **Tag grouping on mobile** — "Group" chip with icon in mobile filter bottom sheet toggles tag grouping mode (same as desktop sidebar button) (`collection_filter_bar.dart`, `collection_screen.dart`)
- **HSL color picker for tags** — tag management dialog now includes a palette of 18 preset colors plus HSL sliders (Hue/Saturation/Lightness) with gradient tracks, live preview, and hex code display. Color dot on each tag row opens the picker. "No color" button to reset (`tag_management_dialog.dart`)
- **Overlay toggle settings** — two switches in Settings > Appearance to independently enable/disable platform overlays on game posters (PS5, Switch, etc.) and Blu-ray overlays on movie/TV show posters. Animation posters have no Blu-ray overlay. When disabled, plain cover images are shown. Applied across collection grid, detail screen, tier lists, all items screen, and tier list PNG export. `SettingsState.resolveOverlayFor()` helper for consistent overlay resolution (`settings_provider.dart`, `settings_screen.dart`, `collection_items_view.dart`, `item_detail_screen.dart`, `all_items_screen.dart`, `tier_item_card.dart`, `tier_list_view.dart`, `tier_row.dart`, `tier_list_export_view.dart`, `tier_list_detail_screen.dart`)
- 15 localization keys EN+RU: `tagSidebarAll`, `colorPickerTitle`, `colorPickerNoColor`, `colorPickerApply`, `settingsShowPlatformOverlay`, `settingsShowPlatformOverlaySubtitle`, `settingsShowBlurayOverlay`, `settingsShowBlurayOverlaySubtitle`, `collectionFilterSearchHint`, `collectionFilterSort`, `collectionFilterAscending`, `collectionFilterDescending`, `collectionFilterFilters`, `collectionFilterClearAll`, `collectionFilterPlatform`

### Changed
- **RA achievements section redesigned** — removed dark container background and custom border, unified with app theme: `AppTypography.h3` header, `AppTypography.caption` stats, `AppColors.surfaceBorder` dividers. Expand/collapse button moved above achievement list (always visible); collapse button also shown at bottom when expanded. 50/50 side-by-side layout with notes on wide screens, stacked on mobile (`ra_achievements_section.dart`, `media_detail_view.dart`)
- **Steam import: batch lookup by Steam App ID** — replaced per-game IGDB name search (65 HTTP requests) with batch lookup via `external_games` endpoint (2 requests). Exact matching by Steam `appid` instead of fuzzy name search. Collection is created lazily — only after successful Steam library fetch, preventing empty collections on API errors. `rtime_last_played` now stored as `lastActivityAt` (was incorrectly stored as `startedAt`) (`igdb_api.dart`, `steam_import_service.dart`, `steam_import_content.dart`)
- **RA import: batch IGDB search via multiquery** — replaced per-game IGDB search (N requests with 300ms delay) with batched multiquery (10 games per request, ~10x fewer HTTP calls). Removed separate `getUserAwardDates` API call — `HighestAwardDate` is now parsed directly from `GetUserCompletionProgress` response. `MostRecentAwardedDate` stored as `lastActivityAt` only (was incorrectly stored as `startedAt`). Lazy collection creation on error. Progress updates during IGDB batch search. `RaToIgdbMapper.bestMatch()` extracted as public static for reuse (`ra_import_service.dart`, `ra_to_igdb_mapper.dart`, `ra_import_content.dart`, `ra_game_progress.dart`)
- **Default collection sort: Last Activity** — new `CollectionSortMode.lastActivity` sorts items by `lastActivityAt` (most recent first, items without activity at the bottom). Set as default sort mode for new collections. 3 localization keys EN+RU (`collection_sort_mode.dart`, `sort_utils.dart`, `collections_provider.dart`)
- **Welcome wizard updated** — added Tier Lists tab to "How it Works" step (step 5), added rate limit warning for built-in API keys at the top of API Keys step (step 4), separated open/copy actions in API link cards (open_in_new opens URL, content_copy copies to clipboard). Fixed step number comments (2→4, 3→5, 4→6). Localized snackbar message. 2 localization keys EN+RU: `welcomeHowTierListsDesc`, `welcomeApiRateLimitHint` (`welcome_step_api_keys.dart`, `welcome_step_how_it_works.dart`, `welcome_step_ready.dart`)
- **Empty states unified** — all main tabs (Home, Collections, Tier Lists, Wishlist) now use consistent empty state style: 64px muted icon, `h2` title in `textTertiary`, `body` hint in `textSecondary` with `textAlign: center`. Tier Lists gained icon and "Tap +" hint. Home hint now shows step-by-step guidance. Collections hint updated from "gaming journey" to "media library". 2 localization keys EN+RU: `tierListEmptyHint`, updated `allItemsAddViaCollections`, `collectionsNoCollectionsHint` (`tier_lists_screen.dart`, `all_items_screen.dart`, `home_screen.dart`, `wishlist_screen.dart`)
- **Canvas toolbar reordered** — lock button moved before the list/board switch for better visual flow (`collection_screen.dart`)
- **Poster images use BoxFit.cover** — `MediaPosterCard` and `CollectionCard` changed from `BoxFit.contain` to `BoxFit.cover` for consistent image rendering across all screens, eliminating letterbox bars (`media_poster_card.dart`, `collection_card.dart`)
- **Open in collection dialog improved** — when a game exists in the same collection on multiple platforms, dialog now shows platform name and colored dot alongside collection name, making entries distinguishable (`search_screen.dart`)
- **Collection filter bar redesigned** — media type dropdown replaced with horizontal `ChoiceChip` row supporting multi-select. Platform and tag filters moved into a collapsible panel (desktop: expand arrow with `AnimatedCrossFade`; mobile: bottom sheet with `ChoiceChip` groups). Search field and sort button remain in the main row. View toggle (Grid/Table) moved to AppBar. Clear button resets all active filters. `CollectionFilterBar` converted from `ConsumerWidget` to `ConsumerStatefulWidget` (`collection_filter_bar.dart`, `collection_screen.dart`)
- **Tag grouping redesigned** — replaced section dividers with flat sorted grid. When grouping is active (via sidebar "Group" button or mobile filter chip), items are sorted by tag with animated color-coded borders on tagged poster cards. Layout unchanged — same grid columns, no dividers. Desktop tag chips removed from filter bar expand panel (managed by TagSidebar) (`collection_items_view.dart`, `collection_filter_bar.dart`, `media_poster_card.dart`)
- **View toggle simplified** — collection view mode cycles Grid → Table → Grid (List view temporarily hidden). Toggle button moved from filter bar to AppBar (`collection_screen.dart`)

### Removed
- **Breadcrumbs navigation** — removed entire breadcrumb system (`BreadcrumbScope`, `BreadcrumbAppBar`, `AutoBreadcrumbAppBar`) and all BreadcrumbScope wrappers from 25 screens. Replaced with `ScreenAppBar` — compact 44px AppBar with subtle gradient border, localized titles on all screens, and automatic back button on mobile. Deleted `breadcrumb_scope.dart`, `breadcrumb_app_bar.dart`, `auto_breadcrumb_app_bar.dart` and their tests (~2300 lines removed). Added `screen_app_bar.dart` (~100 lines)
- **Media type legend** — removed `MediaTypeLegend` widget from Home screen. Color-coded filter chips already convey the same information (`media_type_legend.dart` deleted, `all_items_screen.dart`)

### Fixed
- **Tag group button clears selection** — pressing "Group" button in tag sidebar or mobile filter now clears all selected tag filters, resetting the view to show all items (`collection_screen.dart`)
- **Color picker dialog overflow** — HSL color picker dialog content wrapped in `SingleChildScrollView` to prevent 257px bottom overflow on small screens (`tag_management_dialog.dart`)
- **Cover image distortion on detail screen** — removed `memCacheHeight` from detail view cover decoding. Specifying both `cacheWidth` and `cacheHeight` forced Flutter to decode into a fixed aspect ratio, distorting non-standard images (`media_detail_view.dart`)
- **Tag assignment flickers all images** — assigning a tag to a single collection item no longer causes all poster images to reload. Replaced `ref.invalidate()` / `refresh()` (which set `AsyncLoading` and reloaded all items from DB) with optimistic `updateItemTag()` that updates only the affected item in-place via `copyWith` (`collections_provider.dart`, `item_tags_section.dart`, `collection_items_view.dart`)

## [0.24.0] - 2026-03-31

### Added
- **Multi-platform items** — allow the same game on different platforms within one collection. Migration v30: conditional unique indexes (`idx_ci_coll_game` with `platform_id` for games, `idx_ci_coll_other` without for other media types; same split for uncategorized). Canvas sync updated to handle duplicate `external_id` items (count-based orphan removal instead of set-based). Export includes `platform_id` in tier list entries. Import mapping key includes `platform_id` for games (backward compatible — falls back to key without platform). Platform selection dialog shows already-added platforms with checkmark icon. Collection picker no longer blocks collections that already contain the game (same game on a different platform is allowed). `CollectedItemInfo.platformId` field added for per-platform tracking (`migration_v30.dart`, `schema.dart`, `database_service.dart`, `export_service.dart`, `import_service.dart`, `canvas_provider.dart`, `search_screen.dart`, `collection_dao.dart`, `collection_repository.dart`, `collected_item_info.dart`)
- **Platform overlay templates on poster cards** — 92 platform overlay PNG images (600×900) from SteamGridDB covering Sony, Nintendo, Microsoft, Sega, Atari, Neo Geo, NEC, and retro consoles. `Platform.overlayAsset` getter maps 75 IGDB platform IDs to overlay files. Overlay rendered on top of poster in `MediaPosterCard` (collection, home, tier list — not search), `TierItemCard`, and `MediaDetailView` cover image. Cards with overlay use square corners; cards without overlay keep rounded corners. Rating badge moves from poster to subtitle row as gold `★8 / 7.5` text for overlay cards. Text platform badge remains as fallback for unmapped platforms. Genre subtitle removed from all poster cards for cleaner layout (`platform.dart`, `media_poster_card.dart`, `tier_item_card.dart`, `media_detail_view.dart`, `item_detail_screen.dart`, `collection_items_view.dart`, `all_items_screen.dart`, `browse_grid.dart`, `pubspec.yaml`, `assets/images/platform_overlays/`)
- **Collection tags (sections)** — group items within a collection by custom tags/sections. `CollectionTag` model with `fromDb`/`fromExport`/`toDb`/`toExport`/`copyWith`. `TagDao` for CRUD and `setItemTag()`. DB migration v29 (create `collection_tags` table, add `tag_id` column to `collection_items` with `ON DELETE SET NULL`). `CollectionTagsNotifier` provider for async tag management. `TagManagementDialog` for creating, renaming, and deleting tags (accessible from collection menu). Items grouped by tag with section dividers in grid and list views (like AllItemsScreen grouping pattern). Tag badge on poster cards (bottom-right, colored) with tap-to-change popup menu. Tag selector chip in item detail header (next to source and type). Export includes `tags` array and `tag_name` per item; import restores tags and assignments by name. Orphaned tagIds gracefully fall back to "untagged" group. 14 localization keys EN+RU (`collection_tag.dart`, `tag_dao.dart`, `migration_v29.dart`, `collection_tags_provider.dart`, `tag_management_dialog.dart`, `item_tags_section.dart`, `collection_items_view.dart`, `media_poster_card.dart`, `media_detail_view.dart`, `collection_screen.dart`, `item_detail_screen.dart`, `export_service.dart`, `import_service.dart`, `xcoll_file.dart`, `schema.dart`)
- **Custom items** — manually create collection entries with custom title, cover (from file or URL), year, genres, platform, description, and rating. `CustomMedia` model with `fromDb`/`toDb`/`copyWith`/`toExport`. `CustomMediaDao` for CRUD. `CreateCustomItemDialog` with searchable multi-select genre picker (merged IGDB+TMDB genres), cover source dialog with 2:3 aspect ratio hint, star rating. Custom items support `displayType` — styled as game/movie/tv/etc with matching colors and icons on canvas, collection list, and detail screen. Local cover files cached via `ImageCacheService` with `local://cover` marker in DB. DB migrations v27 (create `custom_items` table) and v28 (add `display_type` column). Export/import support for custom items in `.xcoll`/`.xcollx` files. `MediaType.custom` added with theme colors. `AllItemsScreen`, `WishlistScreen`, `SearchScreen` updated for custom type. 30+ localization keys EN+RU (`custom_media.dart`, `custom_media_dao.dart`, `create_custom_item_dialog.dart`, `collections_provider.dart`, `canvas_provider.dart`, `collection_dao.dart`, `canvas_repository.dart`, `collection_repository.dart`, `schema.dart`, `migration_v27.dart`, `migration_v28.dart`)
- **Export with personal data** — optional "Include personal data" checkbox in export format dialog. When enabled, `.xcoll`/`.xcollx` files include user status, dates (started, completed, last activity), personal notes (user_comment), episode progress (current_season, current_episode), sort order, and added_at. New `user_data: true` flag in file header. Import auto-restores all user data when present; old files without the flag import as before (backward compatible). `CollectionItem.toExport({includeUserData})`, `XcollFile.includesUserData`, `ImportService._restoreUserData()`. 2 localization keys EN+RU. 14 new tests (`collection_item.dart`, `xcoll_file.dart`, `export_service.dart`, `import_service.dart`, `collection_actions.dart`, `app_en.arb`, `app_ru.arb`)
- **Full backup & restore** — one-button backup of all collections (full export with user data, canvas, images, tier lists), wishlist, and app settings into a single `.zip` archive. Restore from backup with confirmation dialog showing manifest preview (collection/item/wishlist counts), checkboxes for wishlist and settings restoration. Collections always created as new (no merge). Wishlist deduplicated by text. `BackupService` with `createBackup()`, `readManifest()`, `restoreFromBackup()`. `BackupManifest` model for ZIP metadata. Settings → Backup section with "Backup All Data" and "Restore from Backup" tiles. 15 localization keys EN+RU (`backup_service.dart`, `settings_screen.dart`, `app_en.arb`, `app_ru.arb`)

### Changed
- **Canvas provider refactored into 5 files** — split 1387-line `canvas_provider.dart` into `canvas_state.dart` (CanvasState + BaseCanvasController), `canvas_timer_mixin.dart` (debounce logic), `canvas_operations_mixin.dart` (15 shared CRUD methods), `canvas_provider.dart` (CanvasNotifier + barrel exports), `game_canvas_provider.dart` (GameCanvasNotifier). Eliminated ~200 lines of duplication between CanvasNotifier and GameCanvasNotifier via `CanvasOperationsMixin`. All existing imports unchanged via barrel exports
- **Tier list UX improvements** — added right-click context menu (rename/delete) on tier list cards for desktop (long press remains for Android). Added "+" button in tier list detail AppBar for adding new tiers. Removed "Add tier" option from tier row bottom sheet (now only accessible via AppBar button and Ctrl+Enter shortcut)
- **Trakt import: Trakt v3 export format support** — auto-detect flat ZIP structure (`trakt-export-*.zip`) from Trakt v3 alongside legacy nested format (`username/watched/*.json`). Username extracted from `user-profile.json` for new format. Both formats fully backward compatible (`trakt_zip_import_service.dart`)
- **Trakt import: own TMDB API key required** — import button disabled with warning banner when using built-in TMDB key. Directs user to add own key in Settings → Credentials (`trakt_import_content.dart`, 1 localization key EN+RU)

### Fixed
- **Imported games disappear after app restart** — `clearStaleGames()` on splash screen deleted games from cache when their `cached_at` timestamp (from the exported file) was older than 30 days. Removed all `clearStale*` methods (`clearStaleGames`, `clearStaleMovies`, `clearStaleTvShows`, `clearStaleEpisodes`) from splash screen startup, DAOs, DatabaseService, and GameRepository. Cache tables are lightweight and don't need periodic cleanup (`splash_screen.dart`, `game_dao.dart`, `movie_dao.dart`, `tv_show_dao.dart`, `database_service.dart`, `game_repository.dart`, `import_service.dart`)
- **Profile stats screen crashes app** — `ProfilesScreen._loadStats()` opened a second readonly SQLite connection to the same database file via `databaseFactory.openDatabase()`, then called `db.close()` which closed the singleton connection used by the entire app. All subsequent DB queries returned empty results. Fixed by passing the already-open `DatabaseService` for the current profile instead of opening a new connection (`profile_service.dart`, `profiles_screen.dart`)
- **Canvas image flicker** — fixed imported images (base64) flickering on every canvas interaction (pan, zoom, drag). `CanvasImageItem` converted from `ConsumerWidget` to `ConsumerStatefulWidget` to cache decoded bytes across rebuilds, with `gaplessPlayback: true` preventing blank frames (`canvas_image_item.dart`)
- **Table view column filtering** — clicking Status/Type/Rating headers now cycles through values present in the collection instead of just toggling asc/desc sort. Only values that exist in the current collection are shown. Filter resets when items change externally. `ItemStatus.genericLabel()` added for media-type-agnostic labels (`collection_table_view.dart`, `item_status.dart`)
- **Tier list drag flicker** — added `ValueKey` to tier rows, tier items, and unranked pool items to preserve widget identity across state rebuilds. Fixes all cards flickering when moving a single item between tiers (`tier_list_view.dart`, `tier_row.dart`)

## [0.23.0] - 2026-03-25

### Added
- **Search source grouping** — `SearchSource` now declares `groupId`, `groupName`, `groupIcon` for visual grouping in the source picker popup. `SourceDropdown` displays grouped items with section headers (TMDB, IGDB, AniList, VNDB) and dividers. `groupedSearchSources` helper in `search_sources.dart` auto-groups sources by `groupId`. No new providers — `browseProvider` remains the single source of truth. Adding a new source only requires implementing `SearchSource` and appending to the registry (`search_source.dart`, `source_dropdown.dart`, `search_sources.dart`, all 6 source files)
- **AniList Anime source (dormant)** — `Anime` model with `fromJson`/`fromDb`/`toDb`/`copyWith`, `AniListApi.browseAnime()`/`getAnimeById()`/`getAnimeByIds()` with GraphQL queries, `AniListAnimeSource` with genre and status filters. Source is not yet registered in `searchSources` — pending DB table, DAO, DetailsSheet, and browse_grid/search_screen integration (see `dev/unwork/anime_metadata.md`). 7 localization keys EN+RU (`anime.dart`, `anilist_api.dart`, `anilist_anime_source.dart`, `anilist_anime_genre_filter.dart`, `anilist_anime_status_filter.dart`)
- **"Trending" sort option** — `BrowseSortOption.label()` now maps `'trending'` to localized "Trending" / "В тренде" (`search_source.dart`, `app_en.arb`, `app_ru.arb`)
- **Status filter on All Items screen** — dropdown chip in the media type chips row filters items by status (In Progress, Planned, Not Started, Completed, Dropped). Default: In Progress. Selection persisted in SharedPreferences via `homeStatusFilterProvider`. Replaces the previous Rating sort chip. Status icons and colors match item detail cards. `CollectionDao.getCollectionIdsWithStatus()` added for future collection-level filtering (`all_items_screen.dart`, `collections_provider.dart`, `collection_dao.dart`, `app_en.arb`, `app_ru.arb`)
- **User profiles** — multi-profile system with isolated databases and image caches per profile. `Profile` model (`id`, `name`, `color`, `createdAt`) stored in `profiles.json`. `ProfileService` handles CRUD, migration from legacy single-DB layout, profile stats (readonly DB query). `ProfilesScreen` in Settings for managing profiles (create/edit/delete with color picker, switch with app restart confirmation, per-profile collection/item stats). `ProfilePickerScreen` at startup when multiple profiles exist ("Who's playing today?") with "Don't ask again" option. Profile indicator (colored circle with initial) in NavigationRail and BottomBar. Profile-aware database and image cache paths (`database_service.dart`, `image_cache_service.dart`). `AppRestartScope` widget in `main.dart` for seamless profile switching on Android (recreates `ProviderScope` with fresh providers via key change); desktop uses process restart. Sealed `EditProfileResult` for type-safe dialog returns. 18 predefined profile colors. `Profile.hexToColor()` static utility. 30+ localization keys EN+RU (`profile.dart`, `profile_service.dart`, `profile_provider.dart`, `profiles_screen.dart`, `profile_picker_screen.dart`, `create_profile_dialog.dart`, `edit_profile_dialog.dart`, `main.dart`, `navigation_shell.dart`, `settings_screen.dart`, `splash_screen.dart`)
- **Cross-platform gamepad support** — refactored gamepad system from Windows-only to cross-platform (Windows, Linux, Android). `GamepadMapping` abstraction with `WindowsGamepadMapping` (JOYINFOEX), `LinuxGamepadMapping` (/dev/input/js*), `AndroidGamepadMapping`. Normalized stick keys (`stick-left-x/y`, `stick-right-x/y`), trigger key (`trigger`). New `kGamepadSupported` flag enables gamepad on Android handhelds (Odin 2, Steam Deck). Button mapping: LB/RB = main tabs, LT/RT = filters/sub-tabs, D-pad = content navigation, A = confirm, B = back (Esc), Y = context menu (RMB analog). `FocusTraversalGroup` prevents focus from escaping window. Auto-focus on first content item when switching tabs. `CollectionCard` refactored to `InkWell` for native focus support. `onLongPress` added to `CollectionItemTile`, collection grid/list views, and `WishlistTile` for Y button context menu. 35 new tests for mappings (`gamepad_mappings.dart`, `gamepad_service.dart`, `gamepad_listener.dart`, `gamepad_action.dart`, `gamepad_provider.dart`, `platform_features.dart`, `navigation_shell.dart`, `collection_card.dart`, `collection_item_tile.dart`, `collection_items_view.dart`, `wishlist_screen.dart`)
- **Right-click context menus** — desktop right-click (onSecondaryTapUp) shows popup context menu on collection items in all view modes (grid, list, table, reorderable) with Move/Copy/Remove actions, and on collection cards on the home screen (grid + list) with Open/Rename/Delete actions. Mobile long-press behavior unchanged (`collection_items_view.dart`, `collection_item_tile.dart`, `collection_table_view.dart`, `media_poster_card.dart`, `collection_card.dart`, `collection_list_tile.dart`, `home_screen.dart`)
- **Sort control in collection picker dialog** — interactive sort toggle button in the picker dialog header (A→Z / Z→A / date ascending / date descending) with localized labels. Initial sort inherited from home screen settings. Cyclic toggle on click (`collection_picker_dialog.dart`)
- **Copy as Text** — template-based text export of collections to clipboard. Quick "Copy as List" menu item with default template `{name} ({year})`. "Copy as Text…" dialog with editable template, clickable token chips (`{name}`, `{year}`, `{rating}`, `{myRating}`, `{platform}`, `{status}`, `{genres}`, `{notes}`, `{type}`, `{#}`), sort options, and live preview. Smart cleanup removes empty tokens with surrounding delimiters/brackets. Template persisted in SharedPreferences. `TextExportService` with 10 tokens, `CopyAsTextDialog`, 14 localization keys EN+RU (`text_export_service.dart`, `copy_as_text_dialog.dart`, `collection_actions.dart`, `collection_screen.dart`)
- **Keyboard shortcuts for desktop** — full keyboard navigation and hotkeys across all screens. Global shortcuts in `NavigationShell` via `CallbackShortcuts`: Ctrl+1..6 (tab switch), Ctrl+Tab/Shift+Tab (cycle tabs), Escape/Alt+Left (back), Ctrl+F (search), F5 (refresh), F1 (contextual help dialog). Screen-level shortcuts: HomeScreen (Ctrl+N create, Ctrl+I import, Ctrl+Shift+V toggle view, Delete/F2 on focused card), CollectionScreen (Ctrl+N/E/I, Ctrl+Shift+V, Ctrl+B board toggle, Delete/Ctrl+M/Ctrl+Delete/F2), ItemDetailScreen (Ctrl+B/L board/lock toggle, Ctrl+M move, Alt+0..5 rating), TierListsScreen (Ctrl+N create, Delete/F2 on focused card), TierListDetailScreen (Ctrl+E export, Ctrl+Enter add tier, Ctrl+Shift+D clear all), WishlistScreen (Ctrl+N add, Ctrl+H toggle resolved, Ctrl+Shift+D clear resolved), SearchScreen (shortcutGroup for F1). Keyboard focus tracking on `CollectionCard`, `MediaPosterCard`, `_TierListCard` with `onFocusChanged` callbacks. F1 dialog (`KeyboardShortcutsDialog`) shows global + current screen shortcuts with styled key badges. Tooltip hints with shortcut keys on all action buttons (desktop only). New utility module `shortcut_helper.dart` with `wrapWithScreenShortcuts()` and `tooltipWithShortcut()`. Mobile-safe: all shortcuts gated behind `kIsMobile` check (`lib/shared/keyboard/keyboard_shortcuts.dart`, `keyboard_shortcuts_dialog.dart`, `shortcut_helper.dart`, `navigation_shell.dart`, `home_screen.dart`, `collection_screen.dart`, `item_detail_screen.dart`, `tier_lists_screen.dart`, `tier_list_detail_screen.dart`, `wishlist_screen.dart`, `search_screen.dart`, `collection_card.dart`, `collection_items_view.dart`, `media_poster_card.dart`)

## [0.22.0] - 2026-03-19

### Added
- **Separate debug/release database** — debug and profile builds use `tonkatsu_box_dev/` folder, release builds use `tonkatsu_box/` to prevent test data from polluting user collections. Database path and build mode logged at startup (`database_service.dart`)
- **Per-tab Discover sections** — Discover feed now shows only relevant sections per search tab: Movies (Top Rated Movies, Upcoming), TV (Popular TV Shows, Top Rated TV Shows), Anime (Anime). Trending available on all tabs but disabled by default — users enable it via Customize sheet. `discoverSectionsPerSource` mapping, `DiscoverFeed.sourceId`, `DiscoverCustomizeSheet.sourceId` filter sections dynamically (`discover_provider.dart`, `discover_feed.dart`, `discover_customize_sheet.dart`, `search_screen.dart`)
- **Table view for collections** — third view mode alongside grid and list. `CollectionTableView` widget with sortable columns (Name, Type, Platform, Status, Rating, Year) — click headers to toggle ascending/descending sort. Compact rows with poster thumbnails, media type icons, status chips, and star ratings. Hover highlight on desktop, separator lines between rows, styled sticky header with sort indicators. 3-way view toggle button in `CollectionFilterBar`: grid → list → table → grid (icon cycles accordingly). View mode persisted per-collection. 7 new localization keys (EN + RU): `collectionListViewTable`, `collectionTableName`, `collectionTableType`, `collectionTablePlatform`, `collectionTableStatus`, `collectionTableRating`, `collectionTableYear` (`collection_table_view.dart`, `collection_items_view.dart`, `collection_filter_bar.dart`, `collection_screen.dart`, `app_en.arb`, `app_ru.arb`)
- **RetroAchievements import** — new `RaApi` client (`ra_api.dart`) fetches user profile and game completion progress via RetroAchievements Web API (username + API key auth, paginated, rate-limited 1 req/sec). `RaImportService` (`ra_import_service.dart`) orchestrates full import pipeline: fetch RA library + award dates in parallel → match each game to IGDB via `RaToIgdbMapper` → add to collection with platform mapping (RA ConsoleID → IGDB PlatformID, 30+ consoles) → update existing items (status upgrade only, never downgrade) → add unmatched games to Wishlist. Achievement progress saved as user comment (`RA: 12/30 achievements (40%) • beaten-hardcore`). Activity dates (completedAt from awards, lastActivityAt from last played). `RaImportResult` with `toUniversal()` extension for unified `ImportResultScreen`. `RaImportScreen` + `RaImportContent` with credentials input (saved to SharedPreferences), profile preview card (avatar, points, member since, rich presence), collection selector (create new / use existing), IGDB connection warning, live progress with per-game status, navigation to `ImportResultScreen`. Models: `RaGameProgress` (fromJson, completionRate, itemStatus mapping), `RaUserProfile` (fromJson, userPicUrl). Accessible from Settings → Import section. 26 new localization keys (EN + RU) (`ra_api.dart`, `ra_import_service.dart`, `ra_to_igdb_mapper.dart`, `ra_import_screen.dart`, `ra_import_content.dart`, `ra_game_progress.dart`, `ra_user_profile.dart`, `settings_screen.dart`, `settings_provider.dart`, `api_key_initializer.dart`, `app_en.arb`, `app_ru.arb`)
- **IGDB token auto-refresh** — `IgdbApi._igdbPost()` wrapper intercepts HTTP 401, refreshes OAuth token via `getAccessToken(clientId, clientSecret)`, retries request once. `clientSecret` propagated through `ApiKeys` → `IgdbApi.setCredentials()`. `onTokenRefreshed` callback saves new token + expiry to SharedPreferences. On startup, `connectionStatus` set to `connected` when valid token exists (no manual "Verify Connection" needed) (`igdb_api.dart`, `api_key_initializer.dart`, `settings_provider.dart`)

### Changed
- **Update notification moved to navigation** — replaced `UpdateBanner` (content-area banner) with a pulsing badge on the Settings tab icon in both NavigationRail (desktop) and BottomNavigationBar (mobile). Settings screen shows "Update available: vX.Y.Z" tile with link to GitHub releases when update is detected. `UpdateBanner` widget removed (`navigation_shell.dart`, `settings_screen.dart`, `settings_tile.dart`)
- **ApiKeys extended with RA credentials** — `ApiKeys` class now includes `raUsername`, `raApiKey`, `igdbClientSecret` fields. `fromPrefs()` loads RA credentials from SharedPreferences. `clearSettings()` removes RA keys alongside other API credentials (`api_key_initializer.dart`, `settings_provider.dart`)
- **Media type labels on poster cards** — colored media type name (e.g. "Game", "Movie") in card subtitle using `Text.rich` with `MediaTypeTheme.colorFor()`. Order: platform · year · Type (colored) · genre. Visible on all grid/compact `MediaPosterCard` variants across AllItemsScreen, CollectionItemsView, and BrowseGrid (`media_poster_card.dart`)
- **Media type legend** — `MediaTypeLegend` widget with horizontal row of colored dots + localized labels for each `MediaType`. Dismissible via close icon. Shown on AllItemsScreen between filter chips and grid (`media_type_legend.dart`, `all_items_screen.dart`)
- **Spacing and typography constants** — `AppSpacing.gridGap` (16px), `AppSpacing.screenPadding` (20px), `AppTypography.cardTitle` (13px/w600), `AppTypography.cardSubtitle` (11px/w400). Applied to grid padding in AllItemsScreen and CollectionItemsView (`app_spacing.dart`, `app_typography.dart`)
- **Universal import result system** — `UniversalImportResult` model (`universal_import_result.dart`) with per-MediaType breakdown maps (importedByType, wishlistedByType, updatedByType), untyped totals for sources without breakdown, computed getters (totalImported, totalWishlisted, totalUpdated, hasWishlistItems, effectiveCollectionId). `ImportResultScreen` (`import_result_screen.dart`) with celebration header, `_ResultCard` widgets showing per-type breakdown with `MediaTypeTheme` icons/colors, wishlist hint, skipped count, "Open Collection" / "Done" buttons. `toUniversal()` extensions on `SteamImportResult` and `TraktImportResult`. Steam and Trakt importers navigate to `ImportResultScreen` after completion instead of inline result / snackbar. 9 new localization keys (EN + RU). 35 tests (model, extensions, widget)
- **Trakt per-MediaType import tracking** — `TraktImportResult` extended with `importedByType`, `wishlistedByType`, `updatedByType` maps. All import sections (watched movies/shows, ratings, watchlist→collection) now track per-type counts. Result screen shows breakdown by Movie/TV Show/Animation (`trakt_zip_import_service.dart`)
- **Trakt wishlist fallback for watched items** — watched movies and TV shows that fail TMDB fetch (data unavailable) are now added to Wishlist with media type hint instead of being silently skipped. Deduplication via `findUnresolved()` (`trakt_zip_import_service.dart`)
- **Copy item to another collection** — full clone of collection items (status, ratings, comments, progress, activity dates) via "Copy to collection" in context menu on list tiles and detail screens. Canvas and tier-list entries are not copied. Uncategorized hidden from clone target picker. Schema-resilient DAO implementation (`collection_dao.dart`, `collection_repository.dart`, `collections_provider.dart`, `collection_actions.dart`, `collection_item_tile.dart`, `item_detail_screen.dart`)
- **Collection list sorting** — sort collections by date created or alphabetically (A→Z / Z→A) with direction toggle. Sort mode persisted in SharedPreferences. Sort popup button in HomeScreen AppBar with visual indicator when non-default. `CollectionListSortMode` enum, `CollectionListSortNotifier`, `CollectionListSortDescNotifier` (`collection_list_sort_mode.dart`, `collections_provider.dart`, `home_screen.dart`)
- **Collection list grid/list view toggle** — switch between grid (iOS-style folder cards) and list (simple text tiles) view. Preference persisted in SharedPreferences. `CollectionListTile`, `UncategorizedListTile` widgets, `CollectionListViewModeNotifier` (`collection_list_tile.dart`, `collections_provider.dart`, `home_screen.dart`)
- **"Open in collection" button on search cards** — when an item is already in a collection, the check badge on search result cards becomes a clickable button that navigates to `ItemDetailScreen`. If the item is in multiple collections, a picker dialog is shown. Works for all 6 media types (`media_poster_card.dart`, `browse_grid.dart`, `search_screen.dart`)
- **Card shadows instead of borders** — `CardThemeData` updated: `elevation: 0` → `2`, added `shadowColor: Colors.black26`, removed `BorderSide(color: surfaceBorder)`. Cards now use subtle shadow instead of flat border (`app_theme.dart`)

### Fixed
- **API key race condition on first launch** — API requests failed with "API key not set" on first app launch because `SettingsNotifier.build()` set API keys after UI had already started making requests. Added `ApiKeys` class (`api_key_initializer.dart`) that loads keys from SharedPreferences synchronously in `main()` before `runApp()`. API providers (`tmdbApiProvider`, `igdbApiProvider`, `steamGridDbApiProvider`) now read keys from `apiKeysProvider` at creation time. `SettingsNotifier._loadFromPrefs()` no longer sets API keys (they are already set); `_syncApiClients()` added for `importConfig()` re-sync (`api_key_initializer.dart`, `main.dart`, `tmdb_api.dart`, `igdb_api.dart`, `steamgriddb_api.dart`, `settings_provider.dart`)

## [0.21.0] - 2026-03-16

### Added
- **Steam Library import** — new `SteamApi` client (`steam_api.dart`) fetches user's owned games via Steam Web API. `SteamImportService` (`steam_import_service.dart`) orchestrates the full import pipeline: fetch library → filter DLC/soundtracks/demos → match each game to IGDB → add to collection (PC platform, status based on playtime) → add unfound games to wishlist with media type hint. Target collection selector: create new ("Steam Library") or pick existing (Radio + Dropdown, same pattern as Trakt). Duplicates are updated instead of skipped: playtime comment refreshed, `startedAt` date updated, status upgraded only `notStarted` → `inProgress` (never downgrades). Wishlist deduplication: checks for existing unresolved item by name before adding (`WishlistDao.findUnresolvedByText()`). Playtime saved as user comment (`Steam: 2.1h`), last played date as `startedAt`. Rate limiting (4 req/sec) for IGDB. Progress callback with stage/current/total/stats. Invalidates collectionStats, collectionCovers, collectionItems, canvas, allItems, wishlist providers after import (`steam_api.dart`, `steam_import_service.dart`, `steam_import_content.dart`, `wishlist_dao.dart`, `database_service.dart`)
- **File import into existing collection** — `.xcoll/.xcollx` import now supports importing into an existing collection via a target selection dialog ("Create new" / "Add to existing"). Duplicates are updated (authorComment, userRating) instead of silently skipped. Canvas, tier lists, and per-item canvas are skipped when importing into an existing collection to avoid duplication. "Import" menu item added inside collection screen (PopupMenu) for quick import with pre-filled collectionId. `ImportProgressDialog` extracted into shared widget. 7 new localization keys (EN + RU) (`import_service.dart`, `home_screen.dart`, `collection_screen.dart`, `import_progress_dialog.dart`)
- **Steam import UI** — `SteamImportScreen` + `SteamImportContent` with 3 states: input (API key + Steam ID + collection selector with clickable helper links), progress (linear indicator + live stats for imported/wishlisted/updated), result (final counts + "Open collection" button navigating to the target collection). IGDB connection warning when not configured. Accessible from Settings > Import section. 30 localization keys (EN + RU) (`steam_import_screen.dart`, `steam_import_content.dart`, `settings_screen.dart`, `app_en.arb`, `app_ru.arb`)
- **Platform names on game cards in search** — `BrowseGrid` now passes `platformMap` to `MediaPosterCard.platformLabel` for game results. Shows up to 3 platform abbreviations with "+N" overflow (e.g. "PC, PS4, XONE +1"). Platform data loaded from `SearchScreen._platformMap` (`browse_grid.dart`, `search_screen.dart`)
- **Platform names on tier list game cards** — `TierItemCard` shows platform abbreviation below the item name for games with an assigned platform. Displayed in both the interactive tier list view and PNG export (`tier_item_card.dart`)
- **Commit convention guide** — `docs/COMMITS.md` with Conventional Commits format, type table, scope examples, branch naming rules. `CONTRIBUTING.md` updated with link to the new guide (`COMMITS.md`, `CONTRIBUTING.md`)
- **Steam test infrastructure** — `MockSteamApi`, `MockSteamImportService` in `mocks.dart`, `createTestSteamOwnedGame` builder in `builders.dart`. 25 tests for `SteamApi` (parsing, errors, shouldSkip), 21 tests for `SteamImportService` (import flow, statuses, duplicate update, wishlist dedup, progress, exact match)

### Changed
- **Platform filter shows abbreviations** — platform names in search filter now display as "Name (ABBR)" (e.g. "Nintendo Entertainment System (NES)"). Search matches both full name and abbreviation. Applies to both the filter sheet and filter dropdown (`platform_filter_sheet.dart`, `igdb_platform_filter.dart`)
- **`BrowseNotifier.setSearchQuery()`** — new method to update `searchQuery` in state without triggering `_fetch()`. Used by `FilterBar.onBeforeFilterChange` callback to sync pending search text before filter application (`browse_provider.dart`)
- **`FilterBar.onBeforeFilterChange`** — new optional `VoidCallback` parameter, invoked before `setFilter()`. `SearchScreen` passes `_syncSearchText` to preserve typed-but-unsubmitted search text when user changes a filter (`filter_bar.dart`, `search_screen.dart`)

### Fixed
- **Activity dates missing year** — date chips on detail screens and episode watched dates showed "Jan 15" without year. Now displays "Jan 15, 2025" (`media_detail_view.dart`, `episode_tracker_section.dart`)
- **Trakt import stale data after import** — re-importing from Trakt created duplicate wishlist entries and collection items/canvas/stats did not refresh until app restart. Now checks `findUnresolved()` before adding to wishlist. Full provider invalidation: `collectionStatsProvider`, `collectionCoversProvider`, `collectionItemsNotifierProvider`, `canvasNotifierProvider`, `wishlistProvider` refresh after import. Radio button ListTiles respond to text tap (`trakt_import_content.dart`, `trakt_zip_import_service.dart`, `wishlist_repository.dart`)
- **Search text lost when changing filters** — when user typed a search query without pressing Enter and then changed a filter (e.g. platform), the search text was only in the `TextEditingController` but not in `BrowseState.searchQuery`, so `_fetch()` ran without the query. Now `FilterBar` syncs the controller text into the provider before applying the filter (`browse_provider.dart`, `filter_bar.dart`, `search_screen.dart`)

## [0.20.0] - 2026-03-12

### Added
- **Tier list item labels** — `TierItemCard` now shows a black label bar under each cover with the full item name (white text, no truncation). Dynamic height via `IntrinsicHeight` in `TierRow` and `_ExportTierRow`. Export PNG also includes labels (`tier_item_card.dart`, `tier_row.dart`, `tier_list_export_view.dart`)
- **Create tier list dialog validation** — empty name and unselected collection now show inline error messages. Added `tierListErrorEmptyName` and `tierListErrorNoCollection` localization keys (EN + RU) (`create_tier_list_dialog.dart`, `app_en.arb`, `app_ru.arb`)
- **Tier list type-to-filter** — `TypeToFilterOverlay` on tier list detail screen filters Unranked pool by item name (desktop keyboard input). `TierListView` accepts `filterQuery` parameter with case-insensitive matching (`tier_list_detail_screen.dart`, `tier_list_view.dart`)
- **Gamepad Debug available in all environments** — `GamepadDebugScreen` accessible from Settings in release builds (not just debug mode). Added "Export log to file" button that saves raw + service events to a `.txt` file via FilePicker (desktop) or Documents directory (Android). Responsive layout: vertical stacking on narrow screens (<600px) (`gamepad_debug_screen.dart`, `settings_screen.dart`)
- **Tier list cleanup on item removal/move** — `TierListDao.removeItemFromCollectionTierLists()` and `getTierListIdsForItem()` methods. `CollectionsNotifier.removeItem()` and `moveItem()` now invalidate affected tier list detail providers (`tier_list_dao.dart`, `collections_provider.dart`)
- **Collection picker duplicate detection** — `showCollectionPickerDialog` now accepts `alreadyInCollectionIds` parameter. Collections where the item already exists are shown as disabled with a "✓ Added" badge, sorted to the bottom. Footer displays "Already in N collection(s)" counter. Uncategorized follows the same rules — disabled when `null` is in the set. All 7 `_add*ToAnyCollection` methods in `SearchScreen`, 2 recommendation methods in `ItemDetailScreen` compute and pass `alreadyInCollectionIds` (`collection_picker_dialog.dart`, `search_screen.dart`, `item_detail_screen.dart`)
- **Cross-type duplicate detection** — `_addMovieToAnyCollection` and `_addTvShowToAnyCollection` now check both their own provider and `collectedAnimationIdsProvider`. Likewise, animation methods check movie/tvShow providers. Ensures the picker highlights collections regardless of the media type the item was added as (`search_screen.dart`, `item_detail_screen.dart`)
- **Collection picker search filter** — text filter field shown when there are ≥5 collections, with clear button. Client-side name matching (`collection_picker_dialog.dart`)
- **Collection picker visual redesign** — replaced `AlertDialog` with `Dialog` + `_CollectionPickerContent` StatefulWidget. Colored icon squares (brand/tertiary), constrained size (400×500), divider footer with counter and Cancel (`collection_picker_dialog.dart`)
- **New localization keys** — `collectionPickerFilter`, `collectionPickerAlreadyAdded`, `collectionPickerAlreadyInCount` in EN and RU with ICU plurals (`app_en.arb`, `app_ru.arb`)

### Changed
- **Tier list card size increase** — cover dimensions 60×82 → 90×120, label width 60 → 70 in tier row and export row (`tier_item_card.dart`, `tier_row.dart`, `tier_list_export_view.dart`)
- **Create tier list dialog desktop UX** — wider dialog (520px on ≥800px screens), larger padding, bigger font, radio buttons selectable by text label tap, Create button is now `FilledButton` (`create_tier_list_dialog.dart`)
- **Priority rating sort** — `CollectionSortMode.rating` now uses `userRating` first, falls back to `apiRating`; items with no rating pushed to end/beginning based on direction (`sort_utils.dart`)
- **`_CanvasTimerMixin` refactoring** — extracted `moveItem()`, `updateViewport()`, `resetViewport()` and timer fields from `CanvasNotifier` and `GameCanvasNotifier` into a shared `_CanvasTimerMixin`. Each notifier implements `_persistViewport()` and `_viewportId`. Eliminates ~90 lines of duplicated code (`canvas_provider.dart`)

### Fixed
- **NavigationRail overflow** — wrapped rail in `LayoutBuilder`; switches to `labelType: selected` when height < 480px to prevent 11px bottom overflow (`navigation_shell.dart`)
- **Tier list ghost items** — items deleted from or moved between collections no longer remain on the old collection's tier list. Entries cleaned up via `removeItemFromCollectionTierLists()` and provider invalidation (`collections_provider.dart`, `tier_list_dao.dart`)
- **Markdown toolbar link dialog overflow** — wrapped `Column` content in `SingleChildScrollView` to prevent RenderFlex overflow on small screens (`markdown_toolbar.dart`)
- **Searchable filter dialogs** — `SearchFilter.searchable` property enables a search dialog (with text filter field) instead of plain `PopupMenuButton` for filters with many options. Enabled for `IgdbGenreFilter` and `IgdbPlatformFilter` (`filter_dropdown.dart`, `search_source.dart`)
- **Multi-select platform filter** — `SearchFilter.multiSelect` property enables checkbox-based multi-selection. `IgdbPlatformFilter` supports selecting multiple platforms simultaneously. Dialog shows checkboxes, "Apply (N)" / "Reset" buttons, selected items pinned to top (`filter_dropdown.dart`, `igdb_platform_filter.dart`)
- **`_SearchableFilterDialog` widget** — reusable dialog with text search field, single-select (tap to choose) and multi-select (checkboxes + confirm) modes. Selected items sorted to top on open (`filter_dropdown.dart`)
- **Global error handlers** — `AppLogger.setupErrorHandlers()` captures `FlutterError.onError` and `PlatformDispatcher.onError`. `main()` wrapped in `runZonedGuarded` for unhandled zone errors. All exceptions logged with full stack traces via `dart:developer` (`app_logger.dart`, `main.dart`)
- **TTL eviction for movie/tvShow/episode caches** — `MovieDao.clearStaleMovies()`, `TvShowDao.clearStaleTvShows()`, `TvShowDao.clearStaleEpisodes()` delete entries older than 30 days not linked to a collection. Runs automatically at startup in `SplashScreen` via `Future.wait` (`movie_dao.dart`, `tv_show_dao.dart`, `splash_screen.dart`)

### Fixed
- **Collection card mosaic** — cover images no longer stretched/cropped. Changed `BoxFit.cover` → `BoxFit.contain` to preserve original aspect ratio, removed `memCacheHeight` (was forcing square decode), added black border outline around each cover. Grid layout changed to 3+3 (was 3+2) with 6 covers (`collection_card.dart`, `collection_covers_provider.dart`)

### Changed
- **`CollectionDao._loadJoinedData()`** — 6 sequential `await` calls replaced with `Future.wait()` for parallel execution. All queries are independent (different tables), `_resolveGenresIfNeeded` still runs after (`collection_dao.dart`)
- **Collection default view mode** — changed from list to grid (card view) for new collections (`collection_screen.dart`)

### Removed
- **`ItemStatus.displayLabel()`** — dead code removed. Only `localizedLabel()` (l10n-aware) remains (`item_status.dart`)

### Changed
- **`IgdbApi.browseGames()`** — parameter `platformId: int?` changed to `platformIds: List<int>?` for multi-platform filtering (`igdb_api.dart`)
- **`IgdbGamesSource.fetch()`** — platform filter value parsing supports both `List<Object>` (multi-select) and `int` (single) via pattern matching (`igdb_games_source.dart`)
- **`BrowseState.hasFilters`** — now correctly treats empty `List<Object>` as inactive filter (`browse_provider.dart`)
- **`BottomNavigationBar`** — hidden labels on mobile (`showSelectedLabels: false`, `showUnselectedLabels: false`) to prevent overflow with 6 tabs (`navigation_shell.dart`)

### Added
- **Tier Lists feature** — full-featured tier list system for ranking collection items. Create global tier lists (all items) or scoped to a specific collection. Drag-and-drop items between tiers (S/A/B/C + custom). Customizable tier labels and colors via color picker (12 presets). Export tier list as PNG image (RepaintBoundary capture with "made by Tonkatsu Box" branding). New navigation tab with `Icons.leaderboard`
- **Tier Lists models** — `TierList` (id, name, collectionId, isGlobal), `TierDefinition` (tierKey, label, color, sortOrder with static S/A/B/C defaults), `TierListEntry` (collectionItemId, tierKey, sortOrder). All models with `fromDb`/`toDb`/`copyWith`/`toExport`/`fromExport`
- **Tier Lists database** — 3 new SQLite tables (`tier_lists`, `tier_definitions`, `tier_list_entries`) via migration v26. `TierListDao` with full CRUD, reorder, and batch operations
- **Tier Lists providers** — `TierListsNotifier` (AsyncNotifier for list management with optimistic updates) and `TierListDetailNotifier` (FamilyNotifier for single tier list state: definitions, entries, items, drag-and-drop operations)
- **Tier Lists .xcollx export/import** — tier lists included in full export with `itemIdMapping` pattern (`media_type:external_id` → new item ID) for cross-collection entry resolution on import
- **Tier Lists from collection screen** — `IconButton(Icons.leaderboard)` in collection AppBar opens filtered tier lists for that collection. Popup menu action to create a scoped tier list with auto-navigation to detail screen
- **Collection tier lists provider** — `collectionTierListsProvider` (FamilyAsyncNotifier) loads tier lists filtered by `collectionId` via `TierListDao.getTierListsByCollection()`. Create/rename/delete invalidate global `tierListsProvider`
- **Tier Lists localization** — 21 new keys in EN and RU (navTierLists, tierListCreate, tierListUnranked, tierListExportImage, etc.)
- **Tier Lists tests** — 99 new tests: models (29), DAO (17), providers (79), widgets (20)

### Changed
- **Default tier definitions** — reduced from 6 (S/A/B/C/D/F) to 4 (S/A/B/C). Users can still add custom tiers via the "+" button
- **TierListsScreen** — added optional `collectionId` parameter. When set, shows only tier lists for that collection and creates new ones scoped to it
- **CreateTierListDialog** — `_submit` validates that a collection is selected when scope is "From collection". Uses `collectionTierListsProvider` for collection-scoped creation
- **Landing page (docs/index.html)** — added Tier Lists feature card, meta keywords (`tier list maker, tier list generator`), updated hero subtitle and JSON-LD description

## [0.19.0] - 2026-03-10

### Added
- **MiniMarkdownText widget** — inline rich text renderer supporting bold (`**`), italic (`*`), links (`[text](url)`), and bare URLs. Tappable links open in system browser via `url_launcher`. Used in detail screen comments and wishlist notes
- **MarkdownToolbar widget** — reusable toolbar with Bold/Italic/Link buttons for markdown editing. Static `wrapSelection()` wraps selected text in markers, `insertLink()` opens a dialog for `[text](url)` insertion. Used in `MediaDetailView` (comments/reviews) and `AddWishlistDialog` (notes)
- **Wishlist markdown support** — note field in Add/Edit Wishlist dialog now has `MarkdownToolbar` and renders notes via `MiniMarkdownText` on the wishlist screen

### Changed
- **MediaPosterCard grid layout** — fixed-height text block (`SizedBox` 52px / 38px compact) ensures uniform card height across the grid. Title now shows up to 2 lines (was 1). Subtitle always rendered (empty string preserves space). `Tooltip` wraps text block for full title on hover/long press
- **MediaPosterCard hover dimming** — idle posters are dimmed ~25% (`Color.fromARGB(0x40, 0, 0, 0)`), dimming smoothly fades to transparent on hover via `AnimatedBuilder` linked to `_hoverController`. Scale 1.04x on hover preserved
- **MiniMarkdownText link regex** — removed `https?://` requirement from `[text](url)` pattern, allowing arbitrary URLs like `[guide](topper)`
- **MediaDetailView** — extracted inline markdown toolbar code into shared `MarkdownToolbar` widget (−100 lines)

## [0.18.1] - 2026-03-06

### Added
- **Built-in IGDB Key** — IGDB now supports built-in API keys via `--dart-define` (same pattern as TMDB and SteamGridDB). Users can search games immediately after install without registering a Twitch developer app. Auto-verifies OAuth token on startup when credentials are available. Credentials UI shows "Using built-in key" status with Reset button. Welcome Wizard displays "BUILT-IN KEY" badge for all APIs that have embedded keys. Release workflow updated with `IGDB_CLIENT_ID` and `IGDB_CLIENT_SECRET` dart-defines for all 3 platforms. 13 new tests

## [0.18.0] - 2026-03-06

### Changed
- **Settings UX — Subtitles & Reorder** — added optional `subtitle` parameter to `SettingsGroup` (shown below uppercase title) and `SettingsTile` (shown below main text). Reordered settings sections: Profile moved from 5th to 1st position. Added 12 new localization keys (EN + RU) for section and tile subtitles, updated 3 existing subtitle values for clarity. 5 new tests for subtitle rendering

### Added
- **Completion Time Display** — shows time taken to complete collection items when both started and completed dates are set. Added `CollectionItem.completionTime` getter that returns `Duration?` from date difference (null for missing dates or negative durations). `ActivityDatesSection` displays completion time with localized formatting ("2 weeks", "3 months", "1.1 years"). `MediaDetailView` includes completion time in horizontal dates row. Shared `lib/shared/utils/duration_formatter.dart` utility with `formatDuration()` and `formatCompletionTime()` functions, supporting 6 time ranges with smart rounding. 7 localization keys (EN + RU): `activityDatesCompletionTime`, `durationLessThanDay`, `durationOneDay`, `durationDays`, `durationWeeks`, `durationMonths`, `durationYears`. 26 new tests: 5 for `CollectionItem.completionTime` logic, 18 for `ActivityDatesSection` widget, 3 for `MediaDetailView` integration
- **Welcome Wizard — Name & Language steps** — expanded Welcome Wizard from 4 to 6 steps. New step 2 (`WelcomeStepName`) lets the user set their author name via a `TextField` backed by `SettingsNotifier.setDefaultAuthor()`. New step 3 (`WelcomeStepLanguage`) offers English/Russian selection via animated cards backed by `SettingsNotifier.setAppLanguage()`. 8 new localization keys (EN + RU). 18 new tests for both widgets, plus updated `welcome_screen_test.dart` for 6-step flow
- **AniList Manga Integration** — manga as 6th media type via AniList GraphQL API. `AniListApi` client (`anilist_api.dart`) with search, browse (genre/format filters, 4 sort modes), batch `getMangaByIds()` with pagination (50 per batch). `Manga` model with 22 fields, computed properties (`rating10`, `formatLabel`, `statusLabel`, `progressString`), `fromJson`/`fromDb`/`toDb`/`toExport`/`copyWith`. `AniListMangaSource` — pluggable search source with `AniListGenreFilter` (20 genres) and `MangaFormatFilter` (6 formats). `MangaDetailsSheet` — bottom sheet with cover, metadata, genres, description, "Add to Collection" button. `MangaProgressSection` — reading progress widget with chapter/volume progress bars, +1 increment buttons, edit dialog, "Mark as completed". Auto-status transitions for manga reading progress (`_autoUpdateMangaStatus`): notStarted/planned→inProgress on first chapter/volume, →completed when chapters reach total, →notStarted on full reset, completed→inProgress on decrease; `dropped` status is never overwritten. DB migration v25 (`manga_cache` table), `MangaDao` for CRUD operations. Full propagation across `MediaType.manga`, `CanvasItemType.manga`, `CollectionItem.manga`, canvas repository, collection covers, export/import, all_items filter chip, collection filter bar, browse grid with in-collection markers, wishlist→search navigation. 18 localization keys (EN + RU). 53 new tests
- **AniList Attribution** — AniList card added to Credits screen (`_TextLogoProviderCard` with brand blue `#3DB4F2`), `creditsAniListAttribution` localization key (EN + RU), README updated in 7 places (description, features, API setup, credits, tech stack)
- **DAO layer** — extracted 7 domain-specific DAO classes from `DatabaseService` into `lib/core/database/dao/`: `GameDao`, `MovieDao`, `TvShowDao`, `VisualNovelDao`, `CollectionDao`, `CanvasDao`, `WishlistDao`. Each DAO receives a database accessor function and encapsulates all SQL operations for its domain
- `CanvasDao.insertCanvasItemsBatch()` and `deleteCanvasItemsBatch()` — batch INSERT/DELETE using `Transaction` + `Batch` for canvas items. Eliminates N individual DB calls when opening/syncing large canvases
- `CanvasRepository.createItemsBatch()` and `deleteItemsBatch()` — repository-level batch operations wrapping DAO batch methods
- Tests for all 7 DAOs (166 tests): `game_dao_test.dart`, `movie_dao_test.dart`, `tv_show_dao_test.dart`, `visual_novel_dao_test.dart`, `collection_dao_test.dart`, `canvas_dao_test.dart`, `wishlist_dao_test.dart`
- `TransactionMockDatabase` in `test/helpers/mocks.dart` — solves mocktail limitation with generic `Database.transaction<T>()` method stubbing

### Changed
- **Create Collection Dialog** — removed author field from `CreateCollectionDialog`, author is now taken automatically from Settings (`authorName`). Deleted `CreateCollectionResult` class. Dialog returns `String?` (name only). Removed 3 orphan localization keys (`createCollectionAuthor`, `createCollectionAuthorHint`, `createCollectionEnterAuthor`)
- **Settings Unified Layout** — removed desktop sidebar layout (`SettingsSidebar`), all platforms now use a single iOS-style grouped-list with `SettingsGroup`/`SettingsTile`. Deleted 4 legacy widgets: `SettingsSidebar`, `SettingsSection`, `SettingsRow`, `SettingsNavRow` (−334 lines). All 7 screen wrappers unified: `Align(topCenter)` + `ConstrainedBox(600)` + consistent `EdgeInsets.symmetric` padding
- **Credits Screen** — replaced SVG logo cards (`_ProviderCard`, `_TextLogoProviderCard`, `_OpenSourceCard`) with plain-text `SettingsGroup` entries. Removed `flutter_svg` and `source_badge` dependencies from credits
- **Trakt Import Screen** — merged separate instructions and file picker sections into a single `SettingsGroup`
- **Debug Hub Screen** — migrated from `SettingsSection`/`SettingsNavRow` to `SettingsGroup`/`SettingsTile`
- `SearchScreen` — added `initialSourceId` parameter replacing legacy `initialTabIndex` for precise source pre-selection from Wishlist
- Recommendations section on detail screens — changed from blacklist to whitelist (only movies, TV shows, animation)
- `DataSource.anilist` color set to AniList brand blue `Color(0xFF3DB4F2)`
- `CollectionDao.getCollectionCovers()` — added `LEFT JOIN manga_cache` for manga cover thumbnails
- `DatabaseService` refactored from ~2700 lines to ~850 lines — now delegates all operations to DAO instances via `late final` fields, preserving the existing public API
- `CanvasRepository.initializeCanvas()` — replaced N individual `createItem()` calls with single `createItemsBatch()` transaction
- `CanvasNotifier._syncCanvasWithItems()` — replaced individual `deleteItem()`/`createItem()` loops with `deleteItemsBatch()`/`createItemsBatch()` batch calls. Fixes "database has been locked for 10s" warnings on large collections
- `CollectionDao.reorderItems()` — replaced N sequential `txn.update()` calls with `Batch.update()` in a single transaction
- `CollectionItemsNotifier` — replaced `ref.read()` in action methods with instance fields set during `build()` to fix Riverpod assertion error when watched dependencies change asynchronously
- `docs/CODESTYLE.md` — fixed builder names to match actual functions, updated migration procedure example

### Fixed
- Fixed search text field clear button not appearing/disappearing reactively — added `TextEditingController.addListener` for immediate rebuild
- Fixed search text auto-deleting on input — replaced `!hasSearchQuery` sync in `build()` with source-change-only clear via `_lastSourceId` tracking
- Fixed wishlist→search navigation opening wrong source for all non-game types
- Fixed detail sheet cover images not loading on Windows desktop — replaced `CachedNetworkImage` (unreliable `flutter_cache_manager` HTTP cache) with project's `CachedImage` widget (file-based `ImageCacheService`) in `GameDetailsSheet`, `MangaDetailsSheet`, `VnDetailsSheet`, `MediaDetailsSheet`, and `DiscoverRow`. Added `cacheImageType`/`cacheImageId` optional params to `MediaDetailsSheet` for correct per-media-type caching. Updated callers in `SearchScreen` and `DiscoverFeed`
- Fixed manga card tap not opening details or adding to collection
- Fixed collection covers not showing for manga items
- Fixed "database has been locked for 10s" warnings when opening canvas for collections with many items — batch DB operations reduce N individual INSERT/DELETE calls to single transactions
- Fixed Riverpod `_didChangeDependency` assertion crash in `CollectionItemsNotifier.refresh()` when sort providers update asynchronously from SharedPreferences
- Fixed RenderFlex overflow in Welcome Wizard on small screens — added adaptive layout with `LayoutBuilder` to `WelcomeStepName`, `WelcomeStepLanguage`, and `WelcomeStepReady`. Applied `SingleChildScrollView` with responsive sizing for icons, text, spacing, and buttons based on screen height constraints. Prevents 73px/113px overflow on constrained displays

## [0.17.0] - 2026-03-03

### Added
- **[Experimental]** Type-to-Filter overlay (desktop only) — typing on physical keyboard shows a floating search bar that filters loaded items by title in real-time. Works on 5 screens: AllItems, HomeScreen, CollectionScreen, SearchScreen, WishlistScreen. Widget `TypeToFilterOverlay` (`type_to_filter_overlay.dart`), keys: printable characters — show/filter, Escape — hide, Backspace — delete character, close button. Zero overhead on mobile
- `sortDisabledTooltip` localization key (EN + RU) — tooltip for disabled sort dropdown during text search
- Tests: `type_to_filter_overlay_test.dart` (12 tests), `filter_dropdown_test.dart` (3 tests), updated `browse_provider_test.dart`, `search_source_test.dart`
- Database migration v24 (`migration_v24.dart`) — seed genres, tags, and platforms as static reference data. TMDB genres (EN + RU for movie + tv), 23 IGDB genres, 100 VNDB tags, 220 IGDB platforms embedded directly in migration. Eliminates runtime API calls for reference data
- `tmdb_genres` table extended with `lang` column (composite PK: id, type, lang) — supports bilingual genre names without runtime API calls
- `credentialsPlatformsAvailable` localization key (EN + RU) — replaces sync-related labels
- Tests: `genre_provider_test.dart` (17 tests), `igdb_genre_provider_test.dart` (5 tests), `vndb_tag_provider_test.dart` (5 tests)
- `AppLogger` utility (`lib/core/logging/app_logger.dart`) — centralized logging via `package:logging` and `dart:developer`. Initialized once in `main()` before `runApp()`, logs visible in Flutter DevTools Logging tab
- `static final Logger _log` field in 11 core classes: `IgdbApi`, `TmdbApi`, `SteamGridDbApi`, `VndbApi`, `DatabaseService`, `ImageCacheService`, `ImportService`, `ExportService`, `TraktZipImportService`, `ConfigService`, `UpdateService`
- Logging in `DatabaseService._onCreate()` and `_onUpgrade()` — schema creation and migration progress messages
- `dart-tonkatsu` coding standards skill (`.claude/skills/dart-tonkatsu/SKILL.md`) — project-wide Dart/Flutter conventions including logging rules, catch-block policy, import ordering, model structure
- iOS folder-style `CollectionCard` widget (`collection_card.dart`) — 3+3 mosaic grid (3 posters top row, 2 posters + "+N" counter bottom row), hover dimming effect with `AnimationController`, rounded corners (16px outer, 8px cells), internal padding 14px
- `UncategorizedCard` widget for uncategorized items with inbox icon
- `CoverInfo` model (`cover_info.dart`) — lightweight cover data (externalId, mediaType, platformId, thumbnailUrl) for collection card mosaics
- `collectionCoversProvider` (`collection_covers_provider.dart`) — `FutureProvider.family` that fetches first 5 cover thumbnails via optimized SQL JOIN query
- `DatabaseService.getCollectionCovers()` — single SQL query joining `collection_items` with all 5 media cache tables (games, movies, tv_shows, visual_novels), prioritized by completion status
- `CollectionFilterBar` widget (`collection_filter_bar.dart`) — compact filter row with media type dropdown, search field, sort dropdown, grid/list toggle, and platform chips for games
- `CollectionItemTile` widget (`collection_item_tile.dart`) — list item tile for collection items
- `CollectionItemsView` widget (`collection_items_view.dart`) — grid/list view for collection items with filtering and sorting
- `CollectionCanvasLayout` widget (`collection_canvas_layout.dart`) — canvas/board layout extracted from collection screen
- `CollectionActions` helper (`collection_actions.dart`) — extracted collection action methods (add, remove, move, export) from collection screen
- Tests: `collection_card_test.dart` (22 tests), `collection_covers_provider_test.dart` (4 tests), `collection_filter_bar_test.dart`, `collection_item_tile_test.dart`, `collection_items_view_test.dart`, `collection_canvas_layout_test.dart`, `collection_actions_test.dart`, `cover_info_test.dart`

### Changed
- Unified Search — replaced separate `browse()` and `search()` methods in `SearchSource` with single `fetch(query?, filterValues, sortBy, page)`. Text search and filters now work simultaneously on all 5 tabs. `BrowseState` removed `isSearchMode`, added `hasSearchQuery`/`hasActiveQuery`. SearchScreen shows FilterBar + SearchField simultaneously (no AnimatedSwitcher toggle)
- IGDB `searchGames` now supports `genreId`, `year`, `decade` filter parameters during text search
- TMDB `searchMoviesPaged`/`searchTvShowsPaged` now support `year` parameter during text search
- VNDB `browseVn` now accepts `query` for native search+tag combination
- Sort dropdown (`FilterDropdown`) disabled with tooltip hint when text search is active on sources that don't support custom sort (TMDB, IGDB). VNDB supports sort during search and remains enabled. Controlled via `SearchSource.supportsSortDuringSearch`
- `BrowseGrid` accepts optional `clientFilter` parameter for Type-to-Filter client-side filtering by title
- Genre/tag/platform providers now read static data from SQLite (seeded by migration v24) instead of fetching from APIs at runtime. Affected: `genre_provider.dart`, `igdb_genre_provider.dart`, `vndb_tag_provider.dart`
- `genre_provider.dart` — `movieGenresProvider`/`tvGenresProvider` derive from `movieGenreMapProvider`/`tvGenreMapProvider` (no duplicate DB queries). Language-aware: reads `lang` column based on TMDB language setting
- `Platform` model simplified — removed `logoImageId`, `syncedAt`, `logoUrl` fields
- `DatabaseService.getTmdbGenreMap()` — added `lang` parameter for bilingual genre lookup
- `DatabaseService._onCreate()` — calls `MigrationV24().migrate(db)` for fresh install seeding
- `DatabaseService.clearAllData()` — no longer deletes static reference tables (platforms, tmdb_genres, igdb_genres, vndb_tags)
- `SettingsNotifier` — removed `syncPlatforms()`, `_preloadTmdbGenres()`, `lastSync` from state. `setTmdbLanguage()` no longer clears/reloads genre cache
- `CredentialsContent` — removed platform sync button, logo download logic, last sync display. Changed label from "Platforms synced" to "Platforms available"
- IGDB API queries — removed `platform_logo.image_id` from `fetchPlatforms` and `fetchPlatformsByIds`
- Replaced 5 silent `catch (_)` blocks with `catch (e)` + `_log.warning(...)` in `TmdbApi` (genre map loading), `ImageCacheService` (save bytes, download), `ImportService` (base64 restore), `ExportService` (export failure)
- Replaced `debugPrint()` with `_log.warning()` in `ImportService` (VNDB fetch error)
- Replaced `print()` with `_log.fine()` in `GamepadDebugScreen` (raw gamepad events)
- Replaced `import 'package:flutter/foundation.dart'` with `import 'dart:typed_data'` in `ImportService` (only `Uint8List` was needed)
- `HomeScreen` — replaced category-grouped layout with single `GridView.builder` using `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 273, childAspectRatio: 1)`. All collections rendered as `CollectionCard` widgets
- `CollectionScreen` — major refactoring: extracted filter bar, items view, canvas layout, and action helpers into separate widgets. Reduced from ~1800 lines to ~500 lines

### Fixed
- `collectionCoversProvider` now invalidated in all 6 mutation points in `CollectionItemsNotifier` (`refresh`, `delete`, `moveItem`, `updateItemStatus`, `updateActivityDates`) — cover mosaics on HomeScreen update when items are added, removed, or moved
- `DatabaseService.getCollectionCovers()` SQL — wrapped in subquery to avoid referencing column alias `thumbnail_url` in WHERE clause (not reliably supported across SQLite versions)
- `BrowseGrid` viewport fill auto-load — on tall/wide screens where initial results (20 items) fit entirely without scrollbar, `loadMore()` was never called. Added `_scheduleViewportFillCheck()` with `addPostFrameCallback` and `ref.listen` to auto-load more pages until viewport is filled or results exhausted

### Removed
- `DatabaseService.cacheIgdbGenres()`, `cacheTmdbGenres()`, `clearTmdbGenres()`, `cacheVndbTags()`, `clearPlatforms()` — replaced by static seeding in migration v24
- `SettingsNotifier.syncPlatforms()`, `_preloadTmdbGenres()` — no longer needed with static data
- `SettingsState.lastSync` field — sync timestamp removed from state
- `ImageType.platformLogo` — platform logos no longer cached (removed from `image_cache_service.dart`)
- `Platform.logoImageId`, `Platform.syncedAt`, `Platform.logoUrl` — platform logo fields removed
- `_buildPlatformLogo()` methods in `search_screen.dart` and `platform_filter_sheet.dart` — replaced with static icons
- `_formatTimestamp()` and `_downloadLogosIfEnabled()` in `credentials_content.dart`
- `CollectionTile` widget (`collection_tile.dart`) and its tests — replaced by `CollectionCard`
- `HeroCollectionCard` widget (`hero_collection_card.dart`) and its tests — replaced by `CollectionCard`

## [0.16.0] - 2026-02-28

### Added
- Visual Novel support via VNDB API — 5th media type (`MediaType.visualNovel`). New model `VisualNovel` (`visual_novel.dart`) with `fromJson`/`fromDb`/`toDb`/`toExport`/`copyWith`, computed getters (rating10, numericId, releaseYear, lengthLabel, platformsString). `VndbTag` for genre tags
- VNDB API client (`vndb_api.dart`) — public API (no auth, ~200 req/min). Methods: `searchVn()`, `browseVn()`, `getVnById()`, `getVnByIds()`, `fetchTags()`. Custom `VndbApiException` with rate limit handling
- `VndbSource` search source (`vndb_source.dart`) — pluggable source for Browse/Search with tag-based genre filter and 3 sort options (rating, released, votecount)
- `VndbTagFilter` (`vndb_tag_filter.dart`) — async tag loading from VNDB API via `vndbTagsProvider` with DB cache
- `VnDetailsSheet` (`vn_details_sheet.dart`) — bottom sheet with VN cover, alt title, rating, release year, length label, developers, platforms, tags, description, and "Add to Collection" button
- `DataSource.vndb` — VNDB source badge (blue #2A5FC1) in `data_source.dart`
- `ImageType.vnCover` — VN cover image caching in `image_cache_service.dart`
- Database migration v22→v23 — `visual_novels_cache` and `vndb_tags` tables with CRUD methods
- Visual Novel export/import — `visual_novels` array in `.xcollx` media section, VNDB API fetch on light import
- VNDB attribution card in Credits screen (`credits_content.dart`)
- `collectedVisualNovelIdsProvider` — tracks VN IDs across collections for in-collection markers
- Localization: 7 new keys (EN + RU) — `mediaTypeVisualNovel`, `visualNovelNotFound`, `searchSourceVisualNovels`, `searchHintVisualNovels`, `browseSortMostVoted`, `collectionFilterVisualNovels`, `creditsVndbAttribution`
- Tests: `visual_novel_test.dart` (42 tests), `vndb_api_test.dart` (20 tests). Updated existing tests for 5th media type

### Changed
- `MediaType` enum extended with `visualNovel` value — all exhaustive switches updated (`collection_screen`, `item_detail_screen`, `all_items_screen`, `canvas_item`, `hero_collection_card`)
- `CollectionItem` extended with `VisualNovel? visualNovel` field and `_resolvedMedia` case for visual novels
- `CollectionStats` extended with `visualNovelCount` field
- `browse_grid.dart` — `_collectedIdsProvider` includes VN IDs
- `search_sources.dart` — registered `VndbSource()` as 5th search source
- `import_service.dart` — added `VndbApi` dependency and visual novel fetch/restore logic
- `export_service.dart` — visual novels embedded in media section
- `app_colors.dart` — added `vnAccent` color
- `media_type_theme.dart` — added VN icon (Icons.menu_book) and color

- Search refactoring — pluggable source architecture with `SearchSource` / `SearchFilter` abstractions (`search_source.dart`). Four sources: `TmdbMoviesSource`, `TmdbTvSource`, `TmdbAnimeSource`, `IgdbGamesSource` (`lib/features/search/sources/`). Five filter types: `TmdbGenreFilter`, `IgdbGenreFilter`, `YearFilter`, `IgdbPlatformFilter`, `AnimeTypeFilter` (`lib/features/search/filters/`)
- Browse/Search mode — unified `BrowseNotifier` (`browse_provider.dart`) manages source switching, filter state, pagination, and search vs browse mode. Source dropdown + filter bar + sort dropdown in horizontal `FilterBar` (`filter_bar.dart`). Grid results in `BrowseGrid` (`browse_grid.dart`)
- `IgdbApi.browseGames()` — discover games with genre/platform filters and sort options (`igdb_api.dart`)
- `IgdbApi.getGenres()` — fetch all IGDB genres; `igdbGenresProvider` caches genre list (`igdb_genre_provider.dart`)
- `TmdbApi` decade-based year filtering — `discoverMoviesFiltered()` and `discoverTvShowsFiltered()` accept `yearDecadeStart`/`yearDecadeEnd` for grouped year ranges (`tmdb_api.dart`)
- `SearchFilter.cacheKey` — disambiguates filters with the same `key` but different option sets. `TmdbGenreFilter` → `genre_movie`/`genre_tv`, `IgdbGenreFilter` → `genre_igdb` (`search_source.dart`, `tmdb_genre_filter.dart`, `igdb_genre_filter.dart`)
- "In collection" markers in Browse grid — `_collectedIdsProvider` aggregates collected TMDB/IGDB IDs across all collections, `BrowseGrid._buildCard()` passes `isInCollection: true` to `MediaPosterCard` for green checkmark badge (`browse_grid.dart`)
- `SourceDropdown` widget — dropdown to switch between search sources with icons and labels (`source_dropdown.dart`)
- `FilterDropdown` widget — generic popup menu dropdown for search filters with async option loading and generation-based cancellation (`filter_dropdown.dart`)
- `GameDetailsSheet` widget — bottom sheet with game details, cover art, and "Add to Collection" button (`game_details_sheet.dart`)
- Localization: 20 new keys for Browse/Search UI — source labels, filter placeholders, sort options, empty states (EN + RU)
- Tests: 50+ new tests for search sources, filters (cacheKey coverage), browse_provider, browse_grid (isInCollection, grid delegate variants), filter_bar, filter_dropdown, source_dropdown

### Changed
- `SearchScreen` rewritten from 4-tab TabBarView to unified Browse/Search architecture — single source dropdown replaces TabBar, filters replace bottom sheets, BrowseGrid replaces per-tab grids (`search_screen.dart`)
- `BrowseGrid` grid delegate now matches `CollectionScreen` — desktop (≥800px): `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, childAspectRatio: 0.55)`, mobile/tablet: `SliverGridDelegateWithFixedCrossAxisCount(childAspectRatio: 0.55)` (`browse_grid.dart`)
- `FilterDropdown.didUpdateWidget()` now compares `filter.cacheKey` instead of `filter.key` to correctly reload options when switching between movie/tv/game genre filters (`filter_dropdown.dart`)
- `FilterBar` now applies `ValueKey('${source.id}_${filter.cacheKey}')` to each `FilterDropdown` — forces Flutter to recreate the widget when source changes (`filter_bar.dart`)
- `DiscoverProvider` extracted discover section IDs and settings into standalone providers for reuse across Browse/Search modes (`discover_provider.dart`)
- `DatabaseService.upsertGame()` improved null-safe merge logic for existing game records (`database_service.dart`)

### Fixed
- Games added via Browse/Search now persist data before collection insert — added `upsertGame()` call in `_addGameToCollection()` and `_addGameToAnyCollection()`, preventing "Unknown Game" entries in collections (`search_screen.dart`)

### Removed
- Removed `GameSearchNotifier`, `MediaSearchNotifier`, `SortSelector`, `PlatformFilterSheet`, `MediaFilterSheet` — replaced by `BrowseNotifier` and pluggable source/filter architecture

- "External Rating" sort mode (`CollectionSortMode.externalRating`) — sorts collection items by IGDB/TMDB API rating (`apiRating`, normalized 0–10), highest first, unrated items at the end. Localized in EN and RU (`collection_sort_mode.dart`, `sort_utils.dart`, `app_en.arb`, `app_ru.arb`)
- Tests: `externalRating` coverage in `collection_sort_mode_test.dart` (6 new tests) and `sort_utils_test.dart` (6 new tests)
- `externalUrl` field on `Game`, `Movie`, `TvShow` models — stores the IGDB/TMDB page URL. `Game.fromJson()` reads `url` from IGDB API; `Movie.fromJson()` / `TvShow.fromJson()` construct `https://www.themoviedb.org/{movie|tv}/{id}`. Included in `toDb()`, `fromDb()`, `copyWith()`, `toJson()` (Game). Persisted in SQLite (`external_url TEXT` column), exported in `.xcollx` (`game.dart`, `movie.dart`, `tv_show.dart`)
- Clickable `SourceBadge` — when `onTap` is provided, the badge shows an `open_in_new` icon and wraps in `InkWell`. Tapping opens the external URL in the system browser (`source_badge.dart`)
- `externalUrl` parameter on `MediaDetailView` — passes URL to `SourceBadge.onTap` via `_launchExternalUrl()` using `url_launcher` (`media_detail_view.dart`)
- `externalUrl` field on `_MediaConfig` in `ItemDetailScreen` — extracted from `game.externalUrl` / `movie.externalUrl` / `tvShow.externalUrl` and forwarded to `MediaDetailView` (`item_detail_screen.dart`)
- Database migration v20 → v21 — `ALTER TABLE games/movies_cache/tv_shows_cache ADD COLUMN external_url TEXT` (`database_service.dart`)
- `url` added to IGDB `_gameFields` query — fetched for all game endpoints (`igdb_api.dart`)
- CLI scripts: `external_url` field added to `_gameToDb()`, `_movieToDb()`, `_tvShowToDb()` in `generate_demo_collections.dart` and `generate_all_snes.dart`
- Demo Collections Generator — CLI scripts (`tool/generate_demo_collections.dart`, `tool/generate_all_snes.dart`) for generating `.xcollx` demo files from IGDB/TMDB APIs, with `tool/README.md` documentation
- `DemoCollectionsScreen` — debug screen accessible from Developer Tools for generating demo collections with various platforms and media types (`demo_collections_screen.dart`)
- `IgdbApi.getTopGamesByPlatform()` — fetches top-rated games for a specific platform from IGDB (`igdb_api.dart`)
- Tests: `externalUrl` coverage in `game_test.dart`, `movie_test.dart`, `tv_show_test.dart`, `source_badge_test.dart` (onTap group), `media_detail_view_test.dart` (External URL group)
- Settings redesign — two responsive layouts: mobile (< 800px) flat iOS-style list with `SettingsGroup`/`SettingsTile` and push-navigation, desktop (≥ 800px) sidebar + content panel with instant section switching (`settings_screen.dart`)
- `SettingsGroup` widget — flat group with optional uppercase title, `surfaceLight` container, dividers between children (`settings_group.dart`)
- `SettingsTile` widget — thin settings row (~44px) with title, optional value, trailing widget, and chevron icon (`settings_tile.dart`)
- `SettingsSidebar` widget — desktop sidebar (200px) with selectable items, separator support, brand-color highlight (`settings_sidebar.dart`)
- Content widgets extracted from Screen files for reuse in both mobile push-nav and desktop inline panel: `CredentialsContent`, `CacheContent`, `DatabaseContent`, `CreditsContent`, `TraktImportContent` (`lib/features/settings/content/`)
- Localization: `settingsConnections`, `settingsApiKeys`, `settingsApiKeysValue`, `settingsData`, `settingsCacheValue` keys (EN + RU)
- Tests: `settings_group_test.dart`, `settings_tile_test.dart`, `settings_sidebar_test.dart` — widget tests for new settings components

### Changed
- `SettingsScreen` rewritten with dual-layout architecture — mobile layout uses `SettingsGroup`/`SettingsTile` instead of `SettingsSection`/`SettingsNavRow`, desktop layout uses `SettingsSidebar` + content panel (`settings_screen.dart`)
- `CredentialsScreen`, `CacheScreen`, `DatabaseScreen`, `CreditsScreen`, `TraktImportScreen` converted to thin wrappers delegating body to extracted Content widgets
- `settings_screen_test.dart` rewritten for new widget structure (SettingsGroup/SettingsTile/SettingsSidebar), mobile/desktop layout tests
- `navigation_shell_test.dart` updated — "Credentials" → "API Keys" label, `ListTile` → direct text finder for settings navigation tests
- Auto-load platforms from IGDB when searching games and opening collections — eliminates "Unknown Platform" chips without manual "Sync Platforms". `IgdbApi.fetchPlatformsByIds()` fetches only needed platforms, `GameRepository.ensurePlatformsCached()` checks DB cache first and fetches missing ones, `CollectionItemsNotifier._loadItems()` triggers lazy load on first open (`igdb_api.dart`, `game_repository.dart`, `collections_provider.dart`)
- Platforms included in full export/import (.xcollx) — `_collectMediaData()` collects platform IDs from game items and exports `Platform.toDb()` into `media['platforms']`, `_restoreEmbeddedMedia()` restores them via `Platform.fromDb()` → `upsertPlatforms()` for offline import (`export_service.dart`, `import_service.dart`)
- `DatabaseService.getPlatformsByIds()` public method — parameterized `SELECT ... WHERE id IN (?)` query, replaces inline SQL in `_loadJoinedData()` (`database_service.dart`)
- Unified media accessors on `CollectionItem` — `releaseYear`, `runtime`, `totalSeasons`, `totalEpisodes`, `genresString`, `genres`, `mediaStatus`, `formattedRating`, `dataSource`, `imageType`, `placeholderIcon` getters that resolve media-type-specific data (game/movie/tvShow/animation) through a single `_resolvedMedia` record. Eliminates switch-on-mediaType boilerplate in UI code (`collection_item.dart`)
- Unified media accessors on `CanvasItem` — `mediaTitle`, `mediaThumbnailUrl`, `mediaImageType`, `mediaCacheId`, `mediaPlaceholderIcon` getters for canvas media elements (`canvas_item.dart`)
- `DataSource` enum extracted to standalone model (`data_source.dart`), re-exported from `source_badge.dart` for backward compatibility
- Uncategorized info banner on item detail screen — informs user that Board and episode tracking require a collection, with "Add to Collection" action button (`item_detail_screen.dart`)
- Seasons/episodes summary text for uncategorized TV shows and animated series — displays "X seasons • Y ep" as a simple text row instead of the full episode tracker (`item_detail_screen.dart`)
- Localization: `uncategorizedBanner`, `uncategorizedBannerAction` keys (EN + RU)
- Tests: 10 new widget tests for uncategorized banner and seasons info (`item_detail_screen_test.dart`)

### Changed
- `CollectionScreen` grid cards now use `CollectionItem` unified accessors (`item.imageType`, `item.releaseYear`, `item.genresString`) instead of local `_imageTypeFor()`, `_yearFor()`, `_subtitleFor()` helper methods — removed ~55 lines of switch boilerplate (`collection_screen.dart`)
- `CanvasView` media card rendering now uses `CanvasItem` unified accessors instead of inline switch statements (`canvas_view.dart`)
- `ExportService` now uses `CollectionItem.dataSource` accessor instead of switch-on-mediaType (`export_service.dart`)

### Removed
- Removed SignPath code signing policy section from `README.md` (certificate info, team roles, privacy policy)
- Removed SignPath code signing policy block, CSS styles, and i18n translations (EN + RU) from landing page (`docs/index.html`)

## [0.15.0] - 2026-02-25

### Added
- Discover feed on Search screen — shown when search field is empty. Horizontal poster rows for Trending, Top Rated Movies, Popular TV Shows, Upcoming, Anime, Top Rated TV Shows. Customizable via bottom sheet (toggle sections, hide owned items). Customize button in AppBar (`discover_feed.dart`, `discover_row.dart`, `discover_customize_sheet.dart`, `discover_provider.dart`)
- Recommendations section on item detail screen — "Similar Movies" / "Similar TV Shows" from TMDB `/similar` endpoint, displayed as horizontal poster row below Activity & Progress. Tap to view details with "Add to Collection" button (`recommendations_section.dart`)
- Reviews section on item detail screen — TMDB user reviews displayed as expandable cards with author, rating, date, and content (`reviews_section.dart`, `tmdb_review.dart`)
- Show/hide recommendations toggle in Settings — `showRecommendations` boolean in SettingsState, SwitchListTile in Settings screen (`settings_provider.dart`, `settings_screen.dart`)
- `ScrollableRowWithArrows` widget — overlay left/right arrow buttons for horizontal lists on desktop (width >= 600px), with gradient backgrounds and smooth scroll animation (`scrollable_row_with_arrows.dart`)
- `HorizontalMouseScroll` widget — converts vertical mouse wheel events to horizontal scroll for horizontal lists (`horizontal_mouse_scroll.dart`)
- `TmdbReview` model — TMDB review data with author, content, rating, URL, date (`tmdb_review.dart`)
- TMDB API: `getMovieRecommendations()`, `getTvShowRecommendations()`, `getMovieReviews()`, `getTvShowReviews()`, `discoverMovies()`, `discoverTvShows()`, Discover list providers (trending, top rated, popular, upcoming, anime) (`tmdb_api.dart`, `discover_provider.dart`)
- TMDB API: lazy-cached genre map resolution — `genre_ids` (numbers) resolved to `genres` (names) across all list endpoints (search, discover, recommendations, trending, popular, multiSearch) via `_ensureMovieGenreMap()` / `_ensureTvGenreMap()` / `_resolveGenreIds()`. Cache invalidated on language change and API key clear (`tmdb_api.dart`)
- `MediaDetailsSheet`: added `genres` parameter — displays genre chips in the detail bottom sheet (`media_details_sheet.dart`)
- `MediaDetailView`: added `recommendationSections` parameter — renders recommendation/review widgets outside the ExpansionTile, always visible (`media_detail_view.dart`)
- Localization: 30+ new ARB keys for Discover, recommendations, reviews UI (EN + RU)
- Tests: `discover_provider_test.dart`, `discover_row_test.dart`, `media_details_sheet_test.dart`, `tmdb_review_test.dart`, `horizontal_mouse_scroll_test.dart`, `scrollable_row_with_arrows_test.dart`, `settings_provider_show_recommendations_test.dart`

### Changed
- Eager preload of seasons AND episodes when adding a TV show or animated series — `_preloadSeasonsAsync()` now fetches episodes for each season (cache → API → save), awaited before showing snackbar instead of fire-and-forget, guaranteeing offline access to episode tracker data (`search_screen.dart`)
- All add-to-collection methods now call `upsertMovie()` / `upsertTvShow()` before `addItem()` — ensures media model is cached in DB for offline access. Previously only `_addMovieToAnyCollection` and `_addTvShowToAnyCollection` did this; now all 8 methods (movie, TV show, animation movie, animation TV show × direct/picker) are consistent (`search_screen.dart`)
- TMDB poster URL size reduced from `w500` to `w342` in `Movie.fromJson()`, `TvShow.fromJson()`, `TvSeason.fromJson()` — ~40% smaller downloads, sufficient for all poster display sizes (100–130px logical) (`movie.dart`, `tv_show.dart`, `tv_season.dart`)
- `posterThumbUrl` getter now uses `RegExp(r'/w\d+')` instead of hardcoded `'/w500'` — works correctly with both new `w342` URLs and legacy `w500` URLs stored in database (`movie.dart`, `tv_show.dart`)
- Rewrote episode tracker auto-status logic (`_checkAutoComplete` → `_updateAutoStatus`) — now handles all transitions: notStarted ↔ inProgress ↔ completed, supports `MediaType.animation`, fetches TV details from TMDB API when cache is missing `totalEpisodes`/`totalSeasons` (`episode_tracker_provider.dart`)
- Added `clearStartedAt` / `clearCompletedAt` flags to `CollectionItem.copyWith()` — allows resetting nullable date fields to null (`collection_item.dart`)
- `DatabaseService.updateItemStatus()` now clears/sets dates based on status: `notStarted` clears both dates, `inProgress` clears `completedAt` and sets `startedAt` if missing (`database_service.dart`)
- `CollectionItemsNotifier.updateStatus()` mirrors DB date logic in local state for instant UI updates (`collections_provider.dart`)
- Owned badge (check_circle icon) now shown on Recommendations section, matching Discover feed behavior (`recommendations_section.dart`)
- Mouse drag-to-scroll enabled in horizontal rows via `ScrollConfiguration` with `PointerDeviceKind.mouse`, scrollbar hidden (`scrollable_row_with_arrows.dart`)
- Swapped navigation icons — Collections uses `shelves` icon, Wishlist uses `bookmark`/`bookmark_border` (across navigation, empty states, welcome screen, dialogs) (`navigation_shell.dart`, `home_screen.dart`, `collection_screen.dart`, `wishlist_screen.dart`, `add_wishlist_dialog.dart`, `welcome_step_how_it_works.dart`, `trakt_import_screen.dart`)
- Removed all `debugPrint` diagnostic logging from episode tracker (`episode_tracker_provider.dart`, `episode_tracker_section.dart`)

### Fixed
- Fixed `EpisodeTrackerSection` being rendered for uncategorized items (where `collectionId` is null) — episode tracking requires a real `collection_id` in the `watched_episodes` DB table, so the section is now hidden when `collectionId` is null (`item_detail_screen.dart`)
- Fixed poster image cache miss when opening detail sheet from Discover feed and Recommendations — was using `posterThumbUrl` (w154) while poster cards used `posterUrl` (w500), causing re-download. Now both use `posterUrl` for consistent caching (`discover_feed.dart`, `recommendations_section.dart`)
- Fixed genres displaying as numeric IDs (e.g., "18, 53") instead of names (e.g., "Drama, Thriller") in Discover feed and Recommendations — TMDB list endpoints return `genre_ids` which were passed as-is to `Movie.fromJson()` (`tmdb_api.dart`)
- Fixed `completedAt` date not being set when marking all episodes as watched — TMDB search/list APIs don't return `number_of_episodes`/`number_of_seasons`, so cached TvShow had null values; now `_updateAutoStatus` fetches full TV details from `/tv/{id}` endpoint on first use and caches result (`episode_tracker_provider.dart`)
- Fixed `started_at` not being set when first episode is marked as watched — auto-transition to `inProgress` now triggers `started_at` in both DB and local state (`episode_tracker_provider.dart`, `collections_provider.dart`, `database_service.dart`)
- Fixed no reverse transition when unchecking all episodes — status now resets to `notStarted` with cleared dates; unchecking from `completed` transitions back to `inProgress` (`episode_tracker_provider.dart`)
- Fixed episode tracker only searching for `MediaType.tvShow`, missing `MediaType.animation` items (`episode_tracker_provider.dart`)
- Fixed Discover and genre caches not invalidating on TMDB language change — added `ref.watch(settingsNotifierProvider.select(...tmdbLanguage))` to all Discover providers and genre providers (`discover_provider.dart`, `genre_provider.dart`)

## [0.14.0] - 2026-02-24

### Changed
- Redesigned `StatusChipRow` from Wrap of chip-buttons to "piano-style" segmented bar — full-width `Row` of `Expanded` segments, flat color fill, icon-only (no text, no borders, no rounded corners), tooltip with localized label (`status_chip_row.dart`)
- Replaced emoji status icons with Material icons across the app — `ItemStatus.icon` (emoji String) replaced by `materialIcon` (IconData): `radio_button_unchecked` (notStarted), `play_arrow_rounded` (inProgress), `check_circle` (completed), `pause_circle_filled` (dropped), `bookmark` (planned) (`item_status.dart`)
- Updated `StatusRibbon` to show Material icon instead of emoji + text — icon-only diagonal ribbon on collection cards (`status_ribbon.dart`)
- Updated `MediaPosterCard` status badge to use Material `Icon` instead of emoji `Text` (`media_poster_card.dart`)
- Swapped navigation icons — Collections uses `bookmark_border`/`bookmark`, Wishlist uses `collections_bookmark_outlined`/`collections_bookmark` (`navigation_shell.dart`, `home_screen.dart`, `collection_screen.dart`, `wishlist_screen.dart`, `add_wishlist_dialog.dart`, `welcome_step_how_it_works.dart`, `trakt_import_screen.dart`)
- Changed edit buttons in Author's Review and My Notes from `TextButton.icon` to `IconButton` — icon-only pencil, no "Edit" text (`media_detail_view.dart`)
- Moved Activity Dates from collapsed `ExpansionTile` to always-visible compact horizontal `Wrap` under My Rating — editable Started/Completed with `DatePicker`, readonly Added/Last Activity (`media_detail_view.dart`, `item_detail_screen.dart`)
- Removed `ItemStatus.onHold` status — simplified from 6 to 5 statuses (notStarted, inProgress, completed, dropped, planned). DB migration v20 converts existing `on_hold` items to `not_started`. Removed `onHold` from `CollectionStats`, `StatusChipRow` filtering, `AppColors.statusOnHold`, Trakt import priority mapping, and `statusOnHold` ARB keys (`item_status.dart`, `database_service.dart`, `collection_repository.dart`, `status_chip_row.dart`, `app_colors.dart`, `trakt_zip_import_service.dart`)
- Unified 4 detail screens (`GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen`, `AnimeDetailScreen`) into single `ItemDetailScreen` — media type determined from `CollectionItem.mediaType`, UI configured via `_MediaConfig` class (`item_detail_screen.dart`)
- Replaced TabBar (Details/Board tabs) with Board toggle IconButton in AppBar — `Icons.dashboard` (active) / `Icons.dashboard_outlined` (inactive), no more `SingleTickerProviderStateMixin` or `TabController`
- Extracted episode tracker into shared `EpisodeTrackerSection` widget with `accentColor` parameter — reused for TV Show and Animation (tvShow source) (`episode_tracker_section.dart`)
- Simplified navigation in `collection_screen.dart` and `all_items_screen.dart` — replaced 4-case media type switch with single `ItemDetailScreen` call
- Unified 4 detail screen test files into single `item_detail_screen_test.dart`
- Replaced hardcoded `'Season N'` fallback with localized `seasonName` ARB key, replaced `'min'` with `runtimeMinutes` in episode tracker (`episode_tracker_section.dart`)

### Fixed
- Fixed RenderFlex overflow in Author's Review and My Notes section headers on narrow screens — wrapped inner `Row` with `Expanded` + `Flexible` + `TextOverflow.ellipsis` (`media_detail_view.dart`)

### Removed
- `GameDetailScreen` (`game_detail_screen.dart`, 601 lines), `MovieDetailScreen` (`movie_detail_screen.dart`, 638 lines), `TvShowDetailScreen` (`tv_show_detail_screen.dart`, 1082 lines), `AnimeDetailScreen` (`anime_detail_screen.dart`, 1185 lines) — replaced by unified `ItemDetailScreen`
- `detailsTab` ARB key — no longer needed after TabBar removal
- 4 old detail screen test files (`game_detail_screen_test.dart`, `movie_detail_screen_test.dart`, `tv_show_detail_screen_test.dart`, `anime_detail_screen_test.dart`)
- `ItemStatus.icon` emoji getter, `displayText()` and `localizedText()` methods — replaced by `materialIcon` getter (`item_status.dart`)
- Private `_statusIcon()` function from `status_chip_row.dart` — icon mapping moved to `ItemStatus.materialIcon`

### Added
- Full i18n localization (English / Russian) — Flutter `gen_l10n` infrastructure with 521 ARB keys, ICU MessageFormat plurals for Russian (`=0`, `=1`, `few`, `other`), output class `S` with `nullable-getter: false` (`l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_ru.arb`)
- App Language setting — `SettingsNotifier.setAppLanguage()` with `SegmentedButton` (English / Русский) in Settings, persisted via SharedPreferences, applied to `MaterialApp.locale` in `app.dart` (`settings_provider.dart`, `settings_screen.dart`, `app.dart`)
- Localized extension methods on enums — `ItemStatus.localizedLabel(S, MediaType)`, `MediaType.localizedLabel(S)`, `CollectionSortMode.localizedDisplayLabel(S)` / `localizedShortLabel(S)` / `localizedDescription(S)`, `SearchSortField.localizedShortLabel(S)` / `localizedDisplayLabel(S)` (`item_status.dart`, `media_type.dart`, `collection_sort_mode.dart`, `search_sort.dart`)
- `flutter_localizations` and `intl` dependencies (`pubspec.yaml`)
- Localization delegates added to all ~64 test files for `MaterialApp` compatibility

### Changed
- Replaced all hardcoded English UI strings (~50 files) with `S.of(context).key` calls — navigation labels, screen titles, buttons, dialogs, tooltips, error messages, empty states, form hints
- `StatusChipRow` and `StatusRibbon` now use `localizedLabel(S.of(context), mediaType)` instead of `displayLabel(mediaType)` (`status_chip_row.dart`, `status_ribbon.dart`)
- Cached Navigator widget instances in `NavigationShell._navigatorWidgets` to prevent route history loss during locale-triggered rebuilds (`navigation_shell.dart`)

### Removed
- `AppStrings` constants class — all values inlined or replaced by l10n keys (`app_strings.dart`, `app_strings_test.dart`)

### Added
- Credits screen with API provider attribution — TMDB (mandatory), IGDB, SteamGridDB logos + disclaimer text + external links, Open Source section with MIT license info and `showLicensePage()` button (`credits_screen.dart`)
- "About" section in Settings — app version from `PackageInfo` and "Credits & Licenses" navigation row (`settings_screen.dart`)
- `flutter_svg` dependency for rendering SVG logos in Credits screen (`pubspec.yaml`)
- SVG logos for TMDB, IGDB, SteamGridDB in `assets/credits/` (app) and `docs/assets/` (landing page)
- Footer attribution on landing page — "Data by" with TMDB, IGDB, SteamGridDB logo links, localized for EN/RU (`docs/index.html`)
- Credits section in README with TMDB disclaimer, IGDB, SteamGridDB attribution (`README.md`)
- 19 widget tests for `CreditsScreen`: attribution texts, provider links, Open Source section, compact layout, licenses button (`credits_screen_test.dart`)
- 7 new tests for `SettingsScreen` About section: section visibility, Version/Credits nav rows, icons, tappability, version placeholder (`settings_screen_test.dart`)
- Trakt.tv ZIP import — offline import from Trakt data export: watched movies/shows → collection items, ratings → userRating, watchlist → planned/wishlist, watched episodes → episode tracker. Animation detection via TMDB genres. Conflict resolution (status hierarchy, ratings only if null, episodes merge). `TraktZipImportService` with `validateZip()` and `importFromZip()` methods, progress reporting via `ImportProgress` (`trakt_zip_import_service.dart`)
- Trakt Import screen — file picker, ZIP validation preview (username, counts), import options (watched/ratings/watchlist checkboxes), target collection selector (new or existing), progress dialog with `ValueNotifier` + `LinearProgressIndicator` (`trakt_import_screen.dart`)
- "Trakt Import" navigation row in Settings screen (`settings_screen.dart`)
- `archive` dependency (^4.0.2) for cross-platform ZIP extraction (`pubspec.yaml`)
- `DatabaseService.findCollectionItem()` — lookup by (collectionId, mediaType, externalId) for import conflict resolution (`database_service.dart`)
- `CollectionRepository.findItem()` — wrapper over `findCollectionItem` (`collection_repository.dart`)
- 69 unit tests for `TraktZipImportService`: models, ZIP validation, full import cycle with conflict resolution, animation detection, ratings, watchlist, episodes, progress callbacks (`trakt_zip_import_service_test.dart`)
- 12 widget tests for `TraktImportScreen`: UI structure, breadcrumbs, compact layout, button types, no preview/options before file selection (`trakt_import_screen_test.dart`)
- 2 new tests for `SettingsScreen`: Trakt Import nav row visibility and tappability (`settings_screen_test.dart`)

## [0.13.0] - 2026-02-23

### Added
- Linux desktop build support — GTK runner (`linux/`), `build-linux` CI job with `ninja-build` + `libgtk-3-dev`, `.tar.gz` artifact in GitHub Releases (`release.yml`)
- `--dart-define=TMDB_API_KEY` and `--dart-define=STEAMGRIDDB_API_KEY` in CI release workflow for Linux build (`release.yml`)
- Platform safety guards for VgMapsPanel — `Platform.isWindows` check in `initState()` and `build()` prevents WebView initialization on non-Windows platforms (`vgmaps_panel.dart`)
- `kVgMapsEnabled` gate around VgMapsPanel Consumer in all 5 detail screens — prevents unnecessary provider watching on non-Windows platforms (`game_detail_screen.dart`, `movie_detail_screen.dart`, `tv_show_detail_screen.dart`, `anime_detail_screen.dart`, `collection_screen.dart`)
- 8 new tests for `platform_features.dart`: `kCanvasEnabled`, `kVgMapsEnabled`, `kScreenshotEnabled`, `kIsMobile`, `isLandscapeMobile` (`platform_features_test.dart`)
- Built-in API tokens for TMDB and SteamGridDB via `--dart-define` — `ApiDefaults` class with `String.fromEnvironment` for compile-time key injection (`api_defaults.dart`)
- Three-tier API key fallback in `SettingsNotifier._loadFromPrefs()` — user key (SharedPreferences) → built-in key (dart-define) → null (`settings_provider.dart`)
- `isTmdbKeyBuiltIn` / `isSteamGridDbKeyBuiltIn` getters on `SettingsState` for detecting active built-in keys
- `resetTmdbApiKeyToDefault()` / `resetSteamGridDbApiKeyToDefault()` methods on `SettingsNotifier` to revert to built-in keys
- "Using built-in key" status indicator and "Reset" button in credentials screen when built-in key is active (`credentials_screen.dart`)
- Hint recommending own API keys for better rate limits, shown when built-in key is active
- `--dart-define=TMDB_API_KEY` and `--dart-define=STEAMGRIDDB_API_KEY` in CI release workflow for Windows and Android builds (`release.yml`)
- `.env` / `.env.local` added to `.gitignore` for local development keys
- 13 new tests: `ApiDefaults` constants, built-in key fallback logic, `isTmdbKeyBuiltIn`/`isSteamGridDbKeyBuiltIn`, `resetTmdbApiKeyToDefault`/`resetSteamGridDbApiKeyToDefault`

### Changed
- Linux runner window title set to "Tonkatsu Box", binary name to `tonkatsu_box`, application ID to `com.hacan359.tonkatsubox` (`linux/CMakeLists.txt`, `linux/runner/my_application.cc`)

## [0.12.0] - 2026-02-22

### Added
- Unified SnackBar notification system — `SnackType` enum (success/error/info), `context.showSnack()` extension with auto-hide, typed icons and colored borders, `loading` parameter for progress indication, `context.hideSnack()` for manual dismissal (`snackbar_extension.dart`)
- Added 17 new tests for `SnackBarExtension`: all 3 types with icons/colors/borders, loading mode, auto-hide, action, duration, text style, SnackBar properties, `hideSnack()` (`snackbar_extension_test.dart`)
- Auto-sync platforms on IGDB verify — `_verifyConnection()` now automatically calls `syncPlatforms()` and `_downloadLogosIfEnabled()` after successful connection (`credentials_screen.dart`)
- API key validation — `SteamGridDbApi.validateApiKey()` method for testing SteamGridDB API keys; `SettingsNotifier.validateTmdbKey()` and `validateSteamGridDbKey()` methods (`steamgriddb_api.dart`, `settings_provider.dart`)
- "Test" button in credentials screen — `_buildSaveRow()` now accepts optional `onValidate` callback; Test buttons shown for SteamGridDB and TMDB when API key is saved (`credentials_screen.dart`)
- Per-tab API key checks in search — Games tab checks IGDB credentials, Movies/TV/Animation tabs check TMDB key; missing key shows `_buildMissingApiKeyState()` with "Go to Settings" button (`search_screen.dart`)
- Smart error handling in search — `_isNetworkError()` detects connection/timeout/socket errors and shows "No internet connection" with `wifi_off` icon; API errors show error text with Retry button (`search_screen.dart`)
- Added 16 new tests: `validateApiKey` (5), `validateTmdbKey`/`validateSteamGridDbKey` (7), Test button visibility (4)
- Auto-delete empty collection prompt — after moving the last item out, a dialog asks whether to delete the now-empty collection (`game_detail_screen.dart`, `movie_detail_screen.dart`, `tv_show_detail_screen.dart`, `anime_detail_screen.dart`, `collection_screen.dart`)
- Board connection edge anchoring — connections now attach to the nearest edge center (top/bottom/left/right) instead of the item center (`CanvasConnectionPainter._getEdgePoint()`)
- Multi-page TMDB search — initial search loads 3 pages in parallel (~60 results) for movies and TV shows (`MediaSearchNotifier._fetchMoviePages()`, `_fetchTvShowPages()`)
- Added 6 new tests: canvas sync by (type, refId), orphan deletion without collectionItemId, non-media item preservation, edge point directions, drag offset edge points, diagonal edge selection

### Changed
- Migrated all 85 SnackBar calls across 13 files to unified `context.showSnack()` extension — removed all direct `ScaffoldMessenger.of(context).showSnackBar()` calls, `messenger` variables, and `_showSnackBar()` helpers (`home_screen.dart`, `collection_screen.dart`, `search_screen.dart`, `credentials_screen.dart`, `database_screen.dart`, `cache_screen.dart`, `welcome_step_api_keys.dart`, 4 detail screens, 2 debug screens)
- Simplified `snackBarTheme` in `AppTheme` — removed redundant backgroundColor, contentTextStyle, shape (now controlled by extension)
- Search screen no longer blocks all tabs when IGDB keys are missing — each tab independently checks its required API key (`search_screen.dart`)
- Simplified import — imported collections are now created as `CollectionType.own` (fully editable) instead of `CollectionType.imported` (`import_service.dart`)
- Removed fork system — deleted `fork()`, `revertToOriginal()` from `CollectionRepository` and `CollectionsNotifier`; removed "Create Copy" and "Revert to Original" UI actions; all collections now use unified folder icon and gameAccent color
- Home screen shows a flat list of all collections instead of grouping by type (own/forked/imported)
- `Collection.isEditable` now always returns `true`; removed `isFork` and `isImported` getters
- `moveItem()` returns `({bool success, bool sourceEmpty})` record type instead of `bool`
- Board connections rendered on top of items with `IgnorePointer` (previously rendered underneath)
- Increased max board element size from 2000 to 5000 (`_DraggableCanvasItemState._maxItemSize`)
- Increased IGDB search page size from 20 to 50 (`GameSearchNotifier._gamePageSize`, `GameRepository` default limit)
- Canvas sync now matches items by `(itemType, itemRefId)` pair instead of `collectionItemId`, fixing a bug where newly synced items were invisible due to `getCanvasItems` filtering by `collection_item_id IS NULL`

### Fixed
- Fixed canvas not displaying items added to collection — `_syncCanvasWithItems()` was setting `collectionItemId` on created items, but `getCanvasItems()` SQL query filters by `collection_item_id IS NULL`, making them invisible. Items are now created without `collectionItemId`, consistent with `initializeCanvas()`

### Removed
- Removed `_showSnackBar()` private helper method from `SteamGridDbDebugScreen`
- Removed all direct `ScaffoldMessenger` usage from feature screens (13 files) — replaced by `snackbar_extension.dart`
- Removed `CollectionRepository.fork()` and `revertToOriginal()` methods
- Removed `CollectionsNotifier.fork()` and `revertToOriginal()` methods
- Removed `importedCollectionsProvider` and `forkedCollectionsProvider`
- Removed "Revert to Original" menu option from `CollectionScreen`
- Removed "Create Copy" option from `HomeScreen` collection context menu
- Removed Imported/Forked section headers from `HomeScreen`

## [0.11.0] - 2026-02-21

### Added
- Added update checker — queries GitHub Releases API on app launch and shows a dismissible banner when a newer version is available (`lib/core/services/update_service.dart`, `lib/shared/widgets/update_banner.dart`)
  - `UpdateService` with semver comparison, 24-hour throttle via SharedPreferences, and silent error handling
  - `UpdateBanner` widget embedded in `NavigationShell` (both desktop and mobile layouts)
  - "Update" button opens the release page via `url_launcher`; dismiss button hides the banner until next launch
- Added `package_info_plus` dependency for reading current app version
- Added 27 tests: `update_service_test.dart` (19 tests — semver, throttle, cache, errors), `update_banner_test.dart` (8 tests — show/hide/dismiss/loading/error states)

### Changed
- Replaced debug signing with release keystore for Android APK (`android/app/build.gradle.kts`)
  - Signing config reads from environment variables (CI) with fallback to `key.properties` (local)
  - All future APK updates install over previous versions without uninstalling
- Changed `applicationId` and `namespace` from `com.example.xerabora` to `com.hacan359.tonkatsubox`
- Moved `MainActivity.kt` to `com.hacan359.tonkatsubox` package
- Updated `release.yml` CI workflow to decode keystore from GitHub Secrets and pass signing env variables

## [0.10.0] - 2026-02-20

### Added
- **Welcome Wizard** — 4-step onboarding shown on first launch (`lib/features/welcome/`)
  - Step 1 «Welcome»: app capabilities, media types, works-without-keys section
  - Step 2 «API Keys»: IGDB (required), TMDB (recommended), SteamGridDB (optional) instructions with external links
  - Step 3 «How it works»: app structure (5 tabs), Quick Start (5 steps), sharing formats (.xcoll/.xcollx)
  - Step 4 «Ready!»: CTA buttons — «Go to Settings» (→ NavigationShell with Settings tab) or «Skip» (→ Home)
  - PageView with swipe, step indicators, progress bar, Skip link, Back/Next navigation, dot indicators
  - `kWelcomeCompletedKey` flag saved in SharedPreferences
  - Re-openable from Settings → Help → «Welcome Guide» (with `fromSettings: true` → pop on finish)
- Added `initialTab` parameter to `NavigationShell` — allows opening app on a specific tab (used by Welcome Wizard → Settings)
- Added «Help» section in `SettingsScreen` with «Welcome Guide» navigation row (icon: `Icons.school`)
- Added `docs/guides/` — source-of-truth markdown for wizard content: `WELCOME.md`, `API_KEYS.md`, `HOW_IT_WORKS.md`
- Added 173 tests for Welcome Wizard: `welcome_screen_test.dart` (32 tests), `step_indicator_test.dart` (16 tests), `welcome_step_intro_test.dart` (14 tests), `welcome_step_api_keys_test.dart` (20 tests), `welcome_step_how_it_works_test.dart` (16 tests), `welcome_step_ready_test.dart` (13 tests), plus updates to `settings_screen_test.dart`, `navigation_shell_test.dart`, `app_test.dart`

### Changed
- Modified `SplashScreen._tryNavigate()` to check `welcome_completed` flag — routes to `WelcomeScreen` on first launch, `NavigationShell` on subsequent launches
- Replaced `AddWishlistSheet` (bottom sheet) with `AddWishlistForm` — full-page form screen with `AutoBreadcrumbAppBar`, breadcrumb navigation ("Add" / "Edit"), and TextButton action in AppBar
- Added title validation (minimum 2 characters) with inline `errorText` that clears on input in `AddWishlistForm`
- Added `showCheckmark: false` to media type `ChoiceChip`s — fixes checkmark overlapping the avatar icon
- Added `runSpacing` to media type chips `Wrap` for better multi-line layout

### Added
- Added 5 reusable settings widgets (`lib/features/settings/widgets/`): `SettingsSection` (Card with header, icon, trailing), `SettingsRow` (ListTile wrapper), `SettingsNavRow` (navigation row with chevron), `StatusDot` (icon + label indicator), `InlineTextField` (tap-to-edit with blur/Enter commit, visibility toggle, gamepad D-pad support)
- Added compact mode (width < 600) across all 5 settings screens — responsive padding, icon sizes, gap spacing
- Added `AppColors.brand` (#EF7B44), `brandLight`, `brandPale` as the dedicated app accent palette, separate from media-type accents
- Added `theme-color` meta tag (#EF7B44) to landing page (`docs/index.html`)
- Added TMDB content language setting (Russian / English) in Settings via SegmentedButton
- Added `BreadcrumbScope` InheritedWidget (`lib/shared/widgets/breadcrumb_scope.dart`) — accumulates breadcrumb labels up the widget tree via `visitAncestorElements`
- Added `AutoBreadcrumbAppBar` (`lib/shared/widgets/auto_breadcrumb_app_bar.dart`) — reads `BreadcrumbScope` chain and generates clickable breadcrumb navigation automatically
- Added tab root `BreadcrumbScope` in `NavigationShell._buildTabNavigator()` — provides root label ('Main', 'Collections', 'Wishlist', 'Search', 'Settings') to all routes
- Added tests for `BreadcrumbScope` (6 tests) and `AutoBreadcrumbAppBar` (8 tests)

### Fixed
- Fixed missing `mounted` check after async operations in `CacheScreen` (3 `setState` calls after `await`)
- Fixed SnackBar leak in `CredentialsScreen._downloadLogosIfEnabled()` — added try/catch around download to properly hide progress SnackBar on exception
- Fixed route transition overlap: transparent Scaffold backgrounds caused content of both pages to show through each other during navigation. Added `_OpaquePageTransitionsBuilder` in `PageTransitionsTheme` — each route now gets its own opaque `DecoratedBox` with tiled background, preventing bleed-through
- Added `cacheWidth`/`cacheHeight` to `Image.file()` in `CachedImage` and `memCacheWidth: 300` to `MediaPosterCard` — reduces decoded image memory for poster cards

### Changed
- Refactored 5 settings screens (`settings_screen`, `credentials_screen`, `cache_screen`, `database_screen`, `debug_hub_screen`) to use shared `SettingsSection`, `SettingsNavRow`, `SettingsRow`, `StatusDot`, `InlineTextField` widgets — net reduction ~200 lines, eliminated manual `Card > Padding > Column > Row` patterns
- Replaced AlertDialog for author name editing with inline `InlineTextField` on `SettingsScreen`
- Replaced 4 `TextEditingController` + 2 `FocusNode` + 3 obscure booleans in `CredentialsScreen` with 4 local String variables — `InlineTextField` manages its own state
- Recolored app palette: introduced `AppColors.brand` (#EF7B44) as the primary UI accent, replacing `gameAccent` in 15 screens/widgets (theme, navigation, snackbar, focus indicator, chips, progress bars, settings headers)
- Updated media accent colors: games #707DD2 (indigo), movies #EF7B44 (orange), TV shows #B1E140 (lime), animation #A86ED4 (purple)
- Unified `MediaTypeTheme` to delegate to `AppColors` constants — was hardcoded Material colors (#2196F3, #F44336, #4CAF50, #9C27B0)
- Recolored landing page (`docs/index.html`): new CSS variables (`--brand`, `--brand-light`, `--brand-pale`), updated media accent colors, CTA buttons, glow effects, showcase shadows, media-tag borders, section labels
- Updated Wishlist appbar icon colors to `AppColors.textSecondary` (was default white)
- Refactored `CollectionItem` media resolution: replaced 5 identical `switch(mediaType)` blocks with a single `_resolvedMedia` getter using Dart records
- Redesigned `BreadcrumbAppBar` visual style: height 40→44px, font 12→13px, `›` separator → `Icons.chevron_right` (14px, 50% opacity), last crumb w600/textPrimary, hover pill effect (surfaceLight background, borderRadius 6), mobile collapse (>2 crumbs → first…last), mobile back button (← instead of logo), text overflow ellipsis (maxWidth 300 current / 180 intermediate), `accentColor` parameter for accent border-bottom, gamepad support (`Actions > Focus` with `FocusNode` dispose)
- Migrated all 20 screens from manual breadcrumb assembly to `BreadcrumbScope` + `AutoBreadcrumbAppBar`: Settings (8 screens), Collections (6 screens), Home, Search, Wishlist tabs
- Removed `collectionName` parameter from detail screens (`GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen`, `AnimeDetailScreen`) — breadcrumb labels now come from scope chain
- Updated 12 test files to wrap screens in `BreadcrumbScope` and adapt to new separator icon

### Removed
- Removed decorative logo watermark from Collections screen (`home_screen.dart`) — Stack with 300×300 logo at 4% opacity
- Removed `BreadcrumbAppBar.collectionFallback()` factory constructor — replaced by `AutoBreadcrumbAppBar` with `BreadcrumbScope`
- Removed `_buildFallbackAppBar()` methods from all 4 detail screens
- Removed `DecoratedBox` from `MaterialApp.builder` in `app.dart` — tiled background now applied per-route via `PageTransitionsTheme`

## [0.9.0] - 2026-02-19

### Added
- Добавлена фича «Wishlist» — заметки для отложенного поиска контента (5-й таб навигации)
  - Модель `WishlistItem` (`lib/shared/models/wishlist_item.dart`) с `fromDb()`, `toDb()`, `copyWith()`
  - Таблица `wishlist` в SQLite, миграция v18→v19, 8 CRUD методов в `DatabaseService`
  - `WishlistRepository` (`lib/data/repositories/wishlist_repository.dart`) — тонкая обёртка над БД
  - `WishlistNotifier` (`wishlistProvider`) — AsyncNotifier с оптимистичным обновлением state
  - `activeWishlistCountProvider` — счётчик активных (не resolved) элементов для badge
  - `WishlistScreen` — ListView с FAB, popup menu (Search/Edit/Resolve/Delete), фильтр resolved, clear resolved
  - `AddWishlistDialog` — создание/редактирование заметки с опциональным типом медиа (ChoiceChip: Game/Movie/TV/Animation)
  - 5-й таб «Wishlist» в `NavigationShell` с Badge (количество активных заметок)
  - Тап на заметку → переход в `SearchScreen` с предзаполненным запросом
  - Resolved заметки: зачёркнутый текст, opacity 0.5, в конце списка
  - Добавлены тесты: wishlist_item_test (10), database_service_test (+13 Wishlist CRUD), wishlist_repository_test (8), wishlist_provider_test (11), wishlist_screen_test (12), add_wishlist_dialog_test (10), navigation_shell_test (обновлены для 5 табов)
- Добавлен параметр `initialQuery` в `SearchScreen` — предзаполнение поля поиска и автоматический запуск поиска при открытии из Wishlist
- Добавлена настройка «Author name» в Settings — имя автора по умолчанию для новых и форкнутых коллекций
  - Поле `defaultAuthor` в `SettingsKeys`, `SettingsState`, `SettingsNotifier`
  - Карточка с диалогом редактирования на экране Settings
  - Замена хардкода `'User'` в `home_screen.dart` на `settings.authorName`
  - Экспорт/импорт ключа через `ConfigService`
- Добавлен файл `LICENSE` (MIT, 2025, hacan359)
- Добавлен `toString()` в `CollectedItemInfo` для удобства отладки

### Changed
- Рефакторинг `CollectionItem.fromDb()` — делегирует в `fromDbWithJoins()`, убрано ~30 строк дублирования

### Added
- Добавлен тайловый фон на всех экранах — `background_tile.png` (паттерн геймпада) зациклен через `ImageRepeat.repeat` с `opacity: 0.03` и `scale: 0.667` в `MaterialApp.builder`
  - Путь к ассету в `AppAssets.backgroundTile`
  - `scaffoldBackgroundColor` в теме изменён на `Colors.transparent` для прозрачности Scaffold-ов
  - Удалён явный `backgroundColor: AppColors.background` с 16 экранов (28 Scaffold-ов)
- Обновлены иконки приложения (Android + Windows) через `flutter_launcher_icons`

### Fixed
- Исправлен crash `Null check operator used on a null value` в `CanvasNotifier.removeByCollectionItemId()` и `removeMediaItem()` — добавлен null-guard для `_collectionId`

### Added
- Добавлена поддержка мультиплатформенных игр — одна и та же игра может быть добавлена в коллекцию с разными платформами (SNES, GBA и т.д.) с независимым прогрессом, рейтингом и заметками
  - Миграция БД v17→v18: UNIQUE индексы `collection_items` расширены на `COALESCE(platform_id, -1)` для различения записей по платформе
  - Метод `DatabaseService.getUniquePlatformIds()` — получение уникальных ID платформ из игровых элементов (опционально по коллекции)
  - Метод `DatabaseService.deleteCanvasItemByCollectionItemId()` — удаление канвас-элемента по ID элемента коллекции
  - Метод `CanvasRepository.deleteByCollectionItemId()` — обёртка для удаления канвас-элементов
  - Провайдер `allItemsPlatformsProvider` (`all_items_provider.dart`) — FutureProvider уникальных платформ из игровых элементов
- Добавлен фильтр платформ на экранах Home (AllItemsScreen) и Collection (CollectionScreen)
  - При выборе типа "Games" появляется второй ряд ChoiceChip с платформами (All + список платформ из текущих элементов)
  - Фильтрация работает совместно с фильтром типа медиа
  - Смена типа медиа автоматически сбрасывает выбранную платформу
- Добавлен бейдж платформы на постер-карточках игр — параметр `platformLabel` в `MediaPosterCard`, отображается как subtitle
- Добавлены тесты: `database_service_test.dart` (+11 тестов: multi-platform UNIQUE index, getUniquePlatformIds), `all_items_provider_test.dart` (+5 тестов: allItemsPlatformsProvider), `all_items_screen_test.dart` (+4 теста: платформенный фильтр), `canvas_repository_test.dart` (+2 теста: deleteByCollectionItemId)

### Changed
- Рефакторинг синхронизации канваса (`canvas_provider.dart`) — ключи элементов изменены с `"mediaType:externalId"` на `collectionItemId` (уникальный PK), что позволяет корректно различать одну игру на разных платформах
- Обновлена `_syncCanvasWithItems()` и `removeByCollectionItemId()` в `CanvasNotifier` для работы с `collectionItemId`

### Added
- Добавлена фича «Move to Collection» — перемещение элементов между коллекциями и в/из uncategorized
  - Метод `DatabaseService.updateItemCollectionId()` — обновление `collection_id` и `sort_order` элемента
  - Метод `CollectionRepository.moveItemToCollection()` — перемещение с обработкой UNIQUE constraint
  - Метод `CollectionItemsNotifier.moveItem()` — перемещение с инвалидацией всех связанных провайдеров
  - Shared диалог `collection_picker_dialog.dart` — выбор коллекции с sealed class `CollectionChoice` (`ChosenCollection` / `WithoutCollection`), параметры `excludeCollectionId`, `showUncategorized`
  - `PopupMenuButton` на экранах деталей (Game, Movie, TV Show, Anime) — пункты «Move to Collection» и «Remove» (заменяет одиночную кнопку Remove)
  - `PopupMenuButton` на тайлах `_CollectionItemTile` в `CollectionScreen` — «Move» и «Remove» (заменяет одиночный `IconButton` Remove)
- Добавлены тесты: `anime_detail_screen_test.dart` (31 тест), `collection_picker_dialog_test.dart` (12 тестов), `database_service_test.dart` (тесты updateItemCollectionId), дополнены `collection_repository_test.dart` (moveItemToCollection: success, duplicate, not found)

### Changed
- Рефакторинг `SearchScreen` — sealed class `CollectionChoice` и метод `_showCollectionSelectionDialog()` вынесены в shared `collection_picker_dialog.dart`, удалено ~80 строк дублирующего кода
- Скрыта вкладка Board на экранах деталей для uncategorized-элементов (`collectionId == null`) — геттер `_hasCanvas` на 4 detail screens, `TabController(length: _hasCanvas ? 2 : 1)`
- Инвалидация `uncategorizedItemCountProvider` при добавлении/удалении элементов в `CollectionItemsNotifier.addItem()` и `removeItem()`
- Улучшен сброс базы данных (`DatabaseScreen._resetDatabase`) — добавлена инвалидация 7 провайдеров (`collectionsProvider`, `uncategorizedItemCountProvider`, `allItemsNotifierProvider`, `collectedGameIdsProvider`, `collectedMovieIdsProvider`, `collectedTvShowIdsProvider`, `collectedAnimationIdsProvider`) + навигация `pushReplacement(NavigationShell)` для полного сброса стеков всех табов
- Обновлены провайдеры канваса, SteamGridDB панели, VGMaps панели и трекера эпизодов для поддержки nullable `collectionId`

### Fixed
- Исправлен crash `FileImage._loadAsync: Bad state: File is empty` — добавлен sync guard в `CachedImage` перед `Image.file()`: проверка `existsSync()` и `lengthSync() > 0` с fallback на сетевое изображение
- Исправлена валидация кэша: `ImageCacheService.isImageCached()` теперь проверяет целостность файла через magic bytes (`_isValidImageFile`), а не только существование
- Исправлено сохранение пустых файлов в кэш: `ImageCacheService.saveImageBytes()` отклоняет пустые данные (`bytes.isEmpty`)
- Исправлен сброс БД не обновляющий UI — элементы оставались на экранах до перезапуска приложения

### Added
- Добавлен виджет `BreadcrumbAppBar` (`lib/shared/widgets/breadcrumb_app_bar.dart`) — навигационные хлебные крошки: логотип 20x20 + разделители `›` + кликабельные крошки. Поддержка `bottom` (TabBar), `actions`, горизонтальный скролл. Последняя крошка — жирная (w600), остальные кликабельные (w400)
- Добавлен экран-хаб `SettingsScreen` — 4 карточки навигации: Credentials, Cache, Database, Debug (только kDebugMode). Заменяет монолитный экран настроек (~1118 строк)
- Добавлены подэкраны настроек: `CredentialsScreen` (IGDB/SteamGridDB/TMDB API ключи), `CacheScreen` (кэш изображений), `DatabaseScreen` (export/import/reset), `DebugHubScreen` (3 debug-инструмента)
- Добавлен параметр `collectionName` в экраны деталей (`GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen`, `AnimeDetailScreen`) для отображения в хлебных крошках
- Добавлены тесты: `breadcrumb_app_bar_test.dart` (21 тест), `settings_screen_test.dart` (15 тестов, переписан), `credentials_screen_test.dart` (43 теста), `database_screen_test.dart` (11 тестов), `cache_screen_test.dart` (8 тестов), `debug_hub_screen_test.dart` (10 тестов)

### Changed
- Все экраны переведены на `BreadcrumbAppBar` вместо стандартного AppBar: AllItemsScreen, HomeScreen, CollectionScreen, SearchScreen, все detail screens, все debug screens
- Логотип вынесен выше NavigationRail в `NavigationShell` (desktop) — `Column(logo, Expanded(Rail))` вместо `Rail.leading`
- Реструктуризация Settings: монолитный экран (~1118 строк) разбит на хаб + 4 подэкрана с навигацией через `Navigator.push`
- Debug screens (IGDB Media, SteamGridDB, Gamepad) используют `BreadcrumbAppBar` с крошками Settings › Debug › {name}

### Removed
- Удалён монолитный код SettingsScreen (секции credentials, cache, database, danger zone — перенесены в отдельные экраны)
- Удалён `settings_screen_config_test.dart` — покрытие перенесено в `database_screen_test.dart`

### Added
- Добавлен экран All Items (Home tab) — отображает все элементы из всех коллекций в grid-виде с PosterCard, именем коллекции как subtitle. Чипсы фильтрации по типу медиа (All/Games/Movies/TV Shows/Animation) и ActionChip сортировки по рейтингу (toggle asc/desc). Loading, empty, error states. RefreshIndicator
- Добавлена 4-табная навигация: Home (все элементы), Collections, Search, Settings. Ранее было 3 таба: Home (коллекции), Search, Settings
- Добавлены провайдеры `allItemsSortProvider`, `allItemsSortDescProvider`, `allItemsNotifierProvider`, `collectionNamesProvider` (`lib/features/home/providers/all_items_provider.dart`)
- Добавлены методы `DatabaseService.getAllCollectionItems()` и `getAllCollectionItemsWithData()` — загрузка элементов из всех коллекций (с опциональной фильтрацией по типу медиа)
- Добавлен метод `CollectionRepository.getAllItemsWithData()`
- Добавлена утилита `applySortMode()` (`lib/features/collections/providers/sort_utils.dart`) — вынесена общая логика сортировки из `CollectionItemsNotifier`

### Changed
- Изменена навигация `NavigationShell`: `NavTab` enum расширен до 4 значений (home, collections, search, settings), `_tabCount = 4`, `AllItemsScreen` загружается eager, остальные tabs lazy
- Рефакторинг `CollectionItemsNotifier._applySortMode()` → вызывает shared `applySortMode()` из `sort_utils.dart`
- Добавлена инвалидация `allItemsNotifierProvider` при добавлении/удалении элементов в `CollectionItemsNotifier`
- Исправлен баг `_loadFromPrefs()` в sort-нотифайерах: добавлен `await Future<void>.value()` чтобы state не перезаписывался return в build()

### Changed
- Оптимизирован запуск на Android — ленивая инициализация табов в `NavigationShell`: SearchScreen и SettingsScreen строятся только при первом переключении на таб (убирает 4 тяжёлых DB-запроса и загрузку платформ при старте)
- Добавлена платформенная проверка в `GamepadService` — на мобильных (Android/iOS) сервис не запускается и не подписывается на `Gamepads.events`, что снижает нагрузку при старте
- Оптимизирован `SplashScreen` — pre-warming базы данных выполняется параллельно с 2-секундной анимацией логотипа. Навигация происходит только когда И анимация завершена, И DB открыта — это разводит DB-инициализацию и route transition по времени, предотвращая ANR на слабых устройствах
- Уменьшена длительность FadeTransition при переходе с splash на главный экран на мобильных: 200ms вместо 500ms

### Added
- Добавлен виджет `DualRatingBadge` (`lib/shared/widgets/dual_rating_badge.dart`) — двойной рейтинг `★ 8 / 7.5` (пользовательский + API). Режимы: badge (затемнённый фон на постере), compact (уменьшенный), inline (без фона, для list-карточек). Геттеры `hasRating`, `formattedRating`
- Добавлен виджет `MediaPosterCard` (`lib/shared/widgets/media_poster_card.dart`) — единая вертикальная постерная карточка с enum `CardVariant` (grid/compact/canvas). Grid/compact: hover-анимация, DualRatingBadge, отметка коллекции, статус-бейдж, title+subtitle. Canvas: Card с цветной рамкой по типу медиа, без hover/рейтинга
- Добавлены геттеры `CollectionItem.apiRating` (нормализованный 0–10: IGDB/10, TMDB as-is) и `CollectionItem.itemDescription` (game.summary / movie.overview / tvShow.overview) в `lib/shared/models/collection_item.dart`
- Добавлены тесты: `dual_rating_badge_test.dart` (25 тестов), `media_poster_card_test.dart` (46 тестов), дополнены `collection_item_test.dart` (+20 тестов apiRating/itemDescription)

### Changed
- Изменён `collection_screen.dart` — `PosterCard` заменён на `MediaPosterCard(variant: grid/compact)` с двойным рейтингом. `_CollectionItemTile` обогащён: DualRatingBadge inline, описание (1 строка), заметки пользователя (иконка `note_outlined`). Удалён метод `_normalizedRating()`
- Изменён `search_screen.dart` — `PosterCard` заменён на `MediaPosterCard(variant: grid/compact)` с API рейтингом
- Изменён `canvas_view.dart` — `CanvasGameCard`/`CanvasMediaCard` заменены на `MediaPosterCard(variant: canvas)` через единый helper `_buildMediaCard(CanvasItem)`

### Removed
- Удалён `PosterCard` (`lib/shared/widgets/poster_card.dart`) — заменён на `MediaPosterCard(variant: grid/compact)` (~340 строк)
- Удалён `MediaCard` (`lib/shared/widgets/media_card.dart`) — мёртвый код после редизайна SearchScreen (~323 строки)
- Удалены `GameCard`, `MovieCard`, `TvShowCard` (`lib/features/search/widgets/`) — мёртвый код (~361 строка)
- Удалены `CanvasGameCard`, `CanvasMediaCard` (`lib/features/collections/widgets/`) — заменены на `MediaPosterCard(variant: canvas)` (~282 строки)
- Удалены тесты удалённых виджетов: 7 файлов (~2792 строки). Итого: -3604 строки кода

### Added
- Добавлен пользовательский рейтинг (1-10) — новое поле `userRating` в `CollectionItem`, миграция БД v14→v15 (`ALTER TABLE collection_items ADD COLUMN user_rating INTEGER`), метод `DatabaseService.updateItemUserRating()`
- Добавлен виджет `StarRatingBar` (`lib/shared/widgets/star_rating_bar.dart`) — 10 кликабельных звёзд с InkWell (focusable для геймпада), повторный клик на текущий рейтинг сбрасывает оценку
- Добавлена секция "My Rating" на экранах деталей (Game, Movie, TV Show, Anime) — между Status и My Notes, отображает `StarRatingBar` с текущим значением и label "X/10"
- Добавлен режим сортировки `CollectionSortMode.rating` — сортировка по пользовательскому рейтингу (высшие первыми, без оценки — в конце)

### Changed
- Переименована секция "Author's Comment" → "Author's Review" на экранах деталей — добавлена подпись "Visible to others when shared. Your review of this title." для пояснения назначения
- Изменён порядок секций на экранах деталей: Header → Status → My Rating → **My Notes** → **Author's Review** → Activity & Progress (ранее Author's Comment шёл перед My Notes)
- Изменён `CollectionItem.copyWith()` — добавлены sentinel-флаги `clearAuthorComment` и `clearUserComment` для возможности очистки комментариев (установки в `null`)
- Изменён `CollectionItemsNotifier` — методы `updateAuthorComment` и `updateUserComment` используют sentinel-флаги при передаче `null`, добавлен метод `updateUserRating` с валидацией диапазона 1-10
- Дополнительные секции (Activity Dates, Episode Progress) обёрнуты в `ExpansionTile` "Activity & Progress" (свёрнуто по умолчанию)

### Fixed
- Исправлена невозможность очистить комментарий автора и личные заметки — `copyWith` использовал `??` для nullable String-полей, что не позволяло установить `null`

### Added
- Добавлена визуальная доска (Board) на Android — `kCanvasEnabled` теперь возвращает `true` на всех платформах, Board доступен в коллекциях и на экранах деталей (игры, фильмы, сериалы, анимация)
- Добавлено контекстное меню по long press на мобильных устройствах — long press на пустом месте доски открывает меню добавления элементов (текст/изображение/ссылка), long press на элементе — меню редактирования (Edit/Delete/Connect и т.д.)
- Увеличен размер resize handle на мобильных устройствах (24px вместо 14px) для удобства тач-ввода
- Добавлен zoom-to-fit при открытии Board — на мобильных контент автоматически масштабируется, чтобы все элементы помещались в viewport с отступами

### Changed
- Переименован «Canvas» → «Board» во всех пользовательских текстах (28 вхождений): вкладка «Board» в коллекции и на экранах деталей, tooltip замка «Lock/Unlock board», SnackBar «Image/Map added to board», кнопка «Add to Board» в VGMaps, описание формата экспорта, сообщения импорта, описание сброса БД в настройках, пустые состояния доски
- Скрыта кнопка VGMaps Browser и пункт меню «Browse maps...» на не-Windows платформах — VGMaps требует `webview_windows`, доступен только на Windows через `kVgMapsEnabled`
- Упрощена подсказка режима создания связей: «Tap an element to create a connection.» вместо «Click on an element to create a connection. Press Escape to cancel.»

### Added
- Добавлен экспорт canvas-изображений в полный экспорт `.xcollx` — изображения с канваса (`CanvasItemType.image`) теперь включаются в секцию `images` с ключом `canvas_images/{hash}`
- Добавлен полный офлайн-экспорт: секция `media` в `.xcollx` содержит данные Game/Movie/TvShow (через `toDb()` без `cached_at`). При импорте данные восстанавливаются из файла через `fromDb()` — API-вызовы не требуются
- Добавлен этап `ImportStage.restoringMedia` для отслеживания прогресса восстановления медиа-данных
- Добавлено поле `media` в `XcollFile` с поддержкой сериализации/десериализации
- Добавлен метод `ExportService._collectMediaData()` — сбор Game/Movie/TvShow из joined полей элементов с дедупликацией по ID
- Добавлены методы `ImportService._restoreEmbeddedMedia()` и `_fetchMediaFromApi()` — условный импорт: офлайн из файла или онлайн из API
- Добавлена предзагрузка сезонов сериалов при добавлении tvShow/animation-сериала в коллекцию — `_preloadSeasons()` в `SearchScreen` (fire-and-forget, не блокирует UI). Сезоны кэшируются в `tv_seasons_cache` для офлайн-доступа
- Добавлены `tv_seasons` в полный экспорт `.xcollx` — сезоны сериалов собираются из кэша БД и включаются в секцию `media.tv_seasons`. `ExportService._collectMediaData()` стал async, принимает `DatabaseService`
- Добавлено восстановление `tv_seasons` при импорте `.xcollx` — `ImportService._restoreEmbeddedMedia()` парсит `media.tv_seasons` и восстанавливает через `TvSeason.fromDb()` с отслеживанием прогресса
- Добавлены счётчики элементов на filter chips коллекции — каждый чип показывает количество: All (N), Games (N), Movies (N), TV Shows (N), Animation (N)
- Добавлены `tv_episodes` в полный экспорт `.xcollx` — эпизоды всех сезонов сериалов собираются из кэша БД и включаются в секцию `media.tv_episodes`. Метод `DatabaseService.getEpisodesByShowId()` возвращает все эпизоды сериала. Запросы сезонов и эпизодов выполняются параллельно через `Future.wait`
- Добавлено восстановление `tv_episodes` при импорте `.xcollx` — `ImportService._restoreEmbeddedMedia()` парсит `media.tv_episodes` и восстанавливает через `TvEpisode.fromDb()` / `upsertEpisodes()` с отслеживанием прогресса

### Fixed
- Исправлен маппинг `ImageType` для анимации: `_imageTypeFor()` в `CollectionScreen`, `HeroCollectionCard` и `CanvasMediaCard` теперь учитывает `platformId` — анимационные сериалы (`AnimationSource.tvShow`) отображают обложки из `tv_show_posters` вместо `movie_posters`
- Исправлена обработка повреждённых кэшированных изображений: `CachedImage` теперь при ошибке декодирования (`Codec failed to produce an image`) удаляет битый файл из кэша, показывает изображение из сети (fallback) и перекачивает файл в фоне. Добавлен метод `ImageCacheService.deleteImage()`. Флаг `_corruptHandled` предотвращает повторные вызовы при rebuild
- Исправлен диалог экспорта: выбор формата (Light/Full) теперь показывается всегда, а не только при наличии canvas данных

### Changed
- Изменён `_AppRouter` — приложение больше не блокируется без API ключей, только поиск недоступен
- Изменён `SearchScreen` — при отсутствии API ключей показывает заглушку вместо интерфейса поиска
- Увеличена ширина кнопок Save в настройках: 80px → 100px (текст не обрезается на узких экранах)
- Уменьшены размеры шрифтов на 2px для лучшего отображения на Android (h1: 26, h2: 18, h3: 14, body: 12, bodySmall: 11, caption: 10)

### Fixed
- Исправлена валидация API ключей: при пустом поле показывается ошибка вместо ложного успеха

### Removed
- Удалены персональные данные прогресса из экспорта коллекции: `status`, `current_season`, `current_episode` больше не включаются в `.xcoll`/`.xcollx` файлы. При импорте старых файлов с этими полями — обратная совместимость сохранена
- Удалён класс `CollectionGame` и enum `GameStatus` (`lib/shared/models/collection_game.dart`) — полностью заменены на `CollectionItem` и `ItemStatus`
- Удалён `CollectionGamesNotifier` и провайдеры `collectionGamesProvider`, `collectionGamesNotifierProvider` из `collections_provider.dart` (~180 строк)
- Удалён legacy-маппинг статуса `'playing'` — статус `inProgress` теперь единообразен для всех типов медиа. Миграция БД v13→v14 обновляет существующие записи
- Удалён метод `ItemStatus.dbValue(MediaType)` — везде используется `ItemStatus.value`
- Удалён формат v1 (.rcoll): класс `RcollGame`, константа `xcollLegacyVersion`, методы `_parseV1()`, `createXcollFile()`, `exportToLegacyJson()`, `_importV1()`. Файлы v1 при попытке импорта выбрасывают `FormatException`
- Удалены этапы импорта `ImportStage.cachingGames` и `ImportStage.addingGames` (использовались только v1)
- Удалены геттеры `XcollFile.isV1`, `XcollFile.isV2`, `XcollFile.gameIds`, поле `XcollFile.legacyGames`
- Удалены legacy-методы из `DatabaseService`: `getCollectionGames()`, `getCollectionGamesWithData()`, `getCollectionGameById()`, `addGameToCollection()`, `removeGameFromCollection()`, `updateGameStatus()`, `getCollectionGameCount()`, `getCompletedGameCount()`, `getCollectionStats()`, `clearCollectionGames()` и др.
- Удалены legacy-методы из `CollectionRepository`: `getGames()`, `getGamesWithData()`, `addGame()`, `removeGame()`, `updateGameStatus()` и др.
- Удалено поле `CollectionStats.playing` — заменено на `inProgress`
- Удалён файл `test/shared/models/collection_game_test.dart`

### Changed
- Изменён `GameDetailScreen` — рефакторинг с `CollectionGame`/`collectionGamesNotifierProvider` на `CollectionItem`/`collectionItemsNotifierProvider`, параметр `gameId` → `itemId`
- Изменён `SearchScreen` — `addGame()` заменён на `addItem(mediaType: MediaType.game, ...)` через `collectionItemsNotifierProvider`
- Изменён формат fork snapshot — ключ `'games'` заменён на `'items'` с полями `media_type`/`external_id`/`platform_id`
- Изменена версия БД: 13 → 14

### Added
- Добавлена вкладка Animation в универсальном поиске — 4-й таб, объединяющий анимационные фильмы и анимационные сериалы из TMDB (жанр Animation, genre_id=16). Анимация фильтруется клиентски из результатов Movies и TV Shows
- Добавлен `MediaType.animation` в enum `MediaType` с `displayLabel: 'Animation'`, `fromString('animation')`
- Добавлен `AnimationSource` — abstract final class с константами `movie = 0`, `tvShow = 1` для дискриминации источника анимации через `collection_items.platform_id`
- Добавлен `CanvasItemType.animation` с `fromMediaType(MediaType.animation)`, `isMediaItem` возвращает true
- Добавлен экран `AnimeDetailScreen` (`lib/features/collections/screens/anime_detail_screen.dart`) — адаптивный: movie-like layout (runtime, без episode tracker) для `AnimationSource.movie`, tvShow-like layout (episode tracker, seasons) для `AnimationSource.tvShow`. Accent color: `AppColors.animationAccent`
- Добавлен виджет `AnimationCard` (`lib/features/search/widgets/animation_card.dart`) — карточка анимации в поиске с бейджем "Movie"/"Series" для различения типа источника
- Добавлен filter chip `Animation` в `CollectionScreen` для фильтрации элементов коллекции по типу
- Добавлен цвет `animationColor = Color(0xFF9C27B0)` (фиолетовый) в `MediaTypeTheme` и `animationAccent = Color(0xFFCE93D8)` в `AppColors`
- Добавлен провайдер `collectedAnimationIdsProvider` в `collections_provider.dart`
- Добавлены тесты: `animation_source_test.dart`, обновлены `media_type_test.dart`, `canvas_item_test.dart`, `media_type_theme_test.dart`, `collection_item_test.dart`, `media_search_provider_test.dart`

### Changed
- Изменён `MediaSearchNotifier` — добавлен `MediaSearchTab.animation`, фильтрация по genre_id=16: Animation tab показывает только анимацию, Movies/TV Shows табы исключают анимацию
- Изменён `SearchScreen` — `TabController(length: 4)`, 4-й таб Animation с объединённым списком animated movies + TV shows
- Изменён `CollectionScreen` — обновлены все switch expressions (8 штук) для `MediaType.animation`: рейтинг, год, субтитры, imageType, навигация на `AnimeDetailScreen`, иконка `Icons.animation`
- Изменён `CanvasMediaCard` — обновлены все switch expressions (6 штук) для `CanvasItemType.animation`: imageType, imageId, borderColor (фиолетовый), posterUrl, title, placeholderIcon
- Изменён `CanvasView` — обновлены switch expressions (5 штук) для `CanvasItemType.animation`
- Изменён `CanvasRepository._enrichItemsWithMediaData()` — animation items ищутся параллельно в movies и tvShows по refId
- Изменён `DatabaseService._loadJoinedData()` — case `MediaType.animation` по `platformId` добавляет ID в `movieIds` или `tvShowIds`
- Изменён `CollectionStats` — добавлено поле `animationCount`
- Изменён `CollectionItem` — `itemName`, `coverUrl`, `thumbnailUrl` учитывают `MediaType.animation` с проверкой `platformId` для movie/tvShow
- Изменён `HeroCollectionCard` — animation → `ImageType.moviePoster`
- Изменён `ExportService` / `ImportService` — поддержка animation при экспорте/импорте

- Добавлен замок канваса (View Mode Lock) — кнопка-замок в AppBar для блокировки канваса в режим просмотра. Доступен только для собственных/fork коллекций. При блокировке боковые панели (SteamGridDB, VGMaps) закрываются автоматически. Реализован на `CollectionScreen`, `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen`
- Добавлено сохранение режима отображения коллекции (grid/list) в SharedPreferences — при переключении выбор запоминается per-collection и восстанавливается при следующем открытии. Ключ `SettingsKeys.collectionViewModePrefix` в `settings_provider.dart`

### Added
- Добавлен виджет `StatusChipRow` — горизонтальный ряд chip-кнопок для выбора статуса на detail-экранах (все статусы видны сразу, тап = выбор, AnimatedContainer для плавных переходов)
- Добавлен виджет `StatusRibbon` — диагональная ленточка статуса в верхнем левом углу list-карточек (display only, цвет из `ItemStatus.color`, emoji + метка)
- Добавлен геттер `ItemStatus.color` — единый маппинг статус→цвет, устранено дублирование `_getStatusColor()`
- Добавлен статус-бейдж (цветной кружок с эмодзи) на `PosterCard` в grid-режиме коллекции — новый параметр `ItemStatus? status`
- Добавлен шрифт Inter (Regular, Medium, SemiBold, Bold) в `assets/fonts/`
- Добавлен `AppTheme` (`lib/shared/theme/app_theme.dart`) — централизованная тёмная тема через `AppColors`, стилизация всех Material-компонентов
- Добавлены стили `posterTitle` и `posterSubtitle` в `AppTypography`
- Добавлены константы `radiusLg`, `radiusXl`, `posterAspectRatio`, `gridColumnsDesktop/Tablet/Mobile` в `AppSpacing`
- Добавлен виджет `RatingBadge` (`lib/shared/widgets/rating_badge.dart`) — цветной бейдж рейтинга (зелёный ≥8, жёлтый ≥6, красный <6)
- Добавлены виджеты shimmer-загрузки (`lib/shared/widgets/shimmer_loading.dart`) — `ShimmerBox`, `ShimmerPosterCard`, `ShimmerListTile` с анимированным градиентом
- Добавлен виджет `PosterCard` (`lib/shared/widgets/poster_card.dart`) — вертикальная карточка 2:3 с постером, RatingBadge, hover-анимацией и отметкой коллекции
- Добавлен виджет `HeroCollectionCard` (`lib/shared/widgets/hero_collection_card.dart`) — большая карточка коллекции с градиентным фоном, прогресс-баром и статистикой
- Добавлена адаптивная навигация в `NavigationShell` — `BottomNavigationBar` при ширине <800px, `NavigationRail` при ≥800px
- Добавлен режим сетки в `CollectionScreen` — переключение list/grid, `PosterCard` в `GridView.builder`
- Добавлены фильтры в `CollectionScreen` — фильтр по типу медиа (All/Games/Movies/TV Shows) через `ChoiceChip`, поиск по имени

### Changed
- Заменён `PopupMenuButton` dropdown на `StatusChipRow` (ряд чипов) на detail-экранах (game, movie, tv_show)
- Заменён compact dropdown на `StatusRibbon` (диагональная ленточка) на list-карточках `_CollectionItemTile` — статус теперь display only, смена только на detail-экране
- Перенесена кнопка "New Collection" из FAB в AppBar (IconButton "+") на `HomeScreen`
- Перенесена кнопка "Add Items" из FAB в AppBar (IconButton "+") на `CollectionScreen`
- Мигрирован `game_detail_screen.dart` с legacy `StatusDropdown` (GameStatus) на `StatusChipRow` (ItemStatus) с конвертацией через `toItemStatus()`/`_toGameStatus()`
- Углублена тёмная палитра `AppColors`: background `#121212`→`#0A0A0A`, surface `#1E1E1E`→`#141414`, surfaceLight `#2A2A2A`→`#1E1E1E`, surfaceBorder `#3A3A3A`→`#2A2A2A`, textPrimary `#E0E0E0`→`#FFFFFF`
- Добавлены цвета рейтинга в `AppColors`: `ratingHigh` (#22C55E), `ratingMedium` (#FBBF24), `ratingLow` (#EF4444)
- Добавлен цвет статуса `statusPlanned` (#8B5CF6) в `AppColors`
- Установлен минимальный размер окна 800×600 (`windows/runner/win32_window.cpp`, `WM_GETMINMAXINFO`)
- Изменён `AppTypography` — шрифт Inter (`fontFamily: 'Inter'`), `letterSpacing: -0.5` для h1, `-0.2` для h2
- Изменён `app.dart` — принудительно тёмная тема (`ThemeMode.dark`), удалены `_lightTheme`/`_darkTheme`/`_buildTheme()`, подключён `AppTheme.darkTheme`
- Изменён `HomeScreen` — `CustomScrollView` со Slivers, первые коллекции как `HeroCollectionCard`, shimmer-загрузка
- Изменён `SearchScreen` — результаты поиска в виде сетки `PosterCard` вместо горизонтальных карточек, затемнение постеров
- Изменён `MediaDetailView` — все цвета через `AppColors`/`AppTypography`, постер увеличен 80×120→100×150, добавлен параметр `accentColor` для per-media окрашивания
- Изменены detail screens (Game, Movie, TvShow) — fallback AppBars стилизованы через `AppColors`, добавлены per-media `accentColor` (movieAccent, tvShowAccent)
- Изменён `SettingsScreen` — кнопки Export/Import адаптивные (Row при ≥400px, Column при <400px), `Theme.of(context).colorScheme.error` заменён на `AppColors.error`
- Изменён `MediaCard` — постер увеличен 60×80→64×96
- Изменён `ImageCacheService` — eager-кэширование обложки при добавлении элемента в коллекцию из поиска, валидация magic bytes (JPEG/PNG/WebP) вместо проверки размера, безопасное удаление файлов при блокировке Windows

### Fixed
- Исправлен overflow заголовков секций в `SettingsScreen` — текст в `Row` обёрнут в `Flexible` с `TextOverflow.ellipsis` (7 секций)
- Исправлен overflow `ListTile` с кнопкой очистки кэша в `SettingsScreen` — `TextButton.icon` заменён на `IconButton`
- Исправлен vertical overflow в `SearchScreen` empty/error states — `Column` заменён на `SingleChildScrollView` + `MainAxisSize.min`
- Исправлен crash `PathAccessException` на Windows при удалении занятого файла в `ImageCacheService` (errno 32)
- Исправлена ошибка `Invalid image data` при загрузке битых кэшированных файлов — валидация magic bytes
- Исправлено отображение чужой обложки на карточке в сетке поиска — добавлен `ValueKey` на `PosterCard` в `GridView`
- Исправлен критический баг миграции БД: колонка `collection_item_id` отсутствовала в `CREATE TABLE` для `canvas_items` и `canvas_connections` при свежей установке (Android). Запросы с `WHERE collection_item_id IS NULL` падали с ошибкой `no such column`
- Исправлен overflow 47/128px в `CreateCollectionDialog` при открытии клавиатуры на Android — `Column` обёрнут в `SingleChildScrollView`
- Исправлен overflow 1.6px в `_CollectionItemTile` на Android (text scale > 1.0) — обложка увеличена с 48×64 до 48×72
- Исправлен overflow 38px справа в `HeroCollectionCard` на узком экране — добавлен `maxLines: 1` и `overflow: TextOverflow.ellipsis` к тексту статистики, уменьшена мозаика с 80 до 64px
- Исправлена работа `FilePicker` на Android: `FileType.custom` заменён на `FileType.any` с ручной проверкой расширения (в `ImportService`, `ExportService`, `ConfigService`)
- Исправлена производительность старта на Android (308 пропущенных кадров) — `_preloadTmdbGenres()` и `_loadPlatformCount()` отложены через `Future.microtask()`
- Исправлен overflow 128px в `_buildEmptyState()` и `_buildErrorState()` на Android при открытой клавиатуре — `Padding` заменён на `SingleChildScrollView`

---

### Added
- Добавлена дизайн-система для тёмной темы: `AppColors`, `AppSpacing`, `AppTypography` (`lib/shared/theme/`)
- Добавлен `NavigationShell` с `NavigationRail` — боковая навигация (Home, Search, Settings)
- Добавлены виджеты: `SectionHeader` (заголовок секции с кнопкой действия)

### Removed
- Удалён виджет `ItemStatusDropdown` и `ItemStatusChip` (`item_status_dropdown.dart`) — заменены на `StatusChipRow` и `StatusRibbon`
- Удалён legacy виджет `StatusDropdown` и `StatusChip` (`status_dropdown.dart`) — заменены на `StatusChipRow`
- Удалены FAB-кнопки "New Collection" и "Add Items" — перенесены в AppBar
- Удалена цветная полоска статуса (3px) на `_CollectionItemTile` — заменена на `StatusRibbon`
- Удалён неиспользуемый виджет `RatingBadge` (`lib/shared/widgets/rating_badge.dart`) и его тесты
- Удалён неиспользуемый виджет `PosterCard` (`lib/shared/widgets/poster_card.dart`) и его тесты
- Удалена неиспользуемая константа `AppColors.statusBacklog`
- Удалена неиспользуемая константа `AppSpacing.radiusLg`
- Удалена зависимость `cupertino_icons` (не используется в Windows-приложении)
- Удалены dev-зависимости `mockito` и `build_runner` (проект использует mocktail, генерируемых файлов нет)

### Changed
- Исправлена типизация `_handleWebMessage(dynamic)` → `_handleWebMessage(Object?)` в VGMaps панели
- Обновлён doc-комментарий в `CollectedItemInfo` — убрана ссылка на legacy-таблицу `collection_games`
- Добавлена таблица `tmdb_genres` в БД (миграция v12→v13) — кэш жанров TMDB (id, type, name)
- Добавлены методы `cacheTmdbGenres()` и `getTmdbGenreMap()` в `DatabaseService`
- Добавлены провайдеры `movieGenreMapProvider` и `tvGenreMapProvider` для быстрого маппинга ID→имя жанров
- Добавлена предзагрузка жанров TMDB при старте приложения (`_preloadTmdbGenres()` в `SettingsNotifier`)
- Добавлен авторезолвинг числовых genre_ids при загрузке элементов коллекции из БД (`_resolveGenresIfNeeded<T>()`)
- Добавлены изображения (постеры/обложки) в bottom sheets деталей фильмов и сериалов в поиске

### Changed
- Изменён `HomeScreen` — применена тёмная тема с `AppColors`, `SectionHeader`, `PosterCard` вместо `CollectionTile`
- Изменён `CollectionScreen` — применена тёмная тема: AppBar → SliverAppBar, статистика в виде цветных чипов, `PosterCard` grid для элементов
- Изменён `SearchScreen` — применена тёмная тема: AppBar, TabBar, SearchField, карточки результатов
- Изменены detail screens (Game, Movie, TvShow) — применена тёмная тема: SliverAppBar, секции, чипы
- Изменён `SettingsScreen` — применена тёмная тема: секции с бордерами, кнопки, диалоги
- Изменён `MediaCard` — переработан с `Card` на `Material` + `Container` + `InkWell` с `AppColors`/`AppTypography`
- Изменён `CollectionTile` — стилизация через `AppColors`
- Изменён `CreateCollectionDialog` — стилизация через `AppColors`
- Изменён `CachedImage` — стилизация placeholder/error через `AppColors`
- Изменены search widgets (`GameCard`, `MovieCard`, `TvShowCard`) — стилизация через `AppColors`
- Изменены filter/sort widgets (`PlatformFilterSheet`, `MediaFilterSheet`, `SortSelector`) — тёмная тема
- Изменён `genre_provider.dart` — DB-first стратегия загрузки жанров (БД → API → сохранение в БД)
- Изменён `media_search_provider.dart` — жанры резолвятся в имена ПЕРЕД сохранением в БД
- Изменён `app.dart` — корневой виджет оборачивает в `NavigationShell`
- Изменена версия БД: 12 → 13

### Fixed
- Исправлено отображение числовых ID вместо имён жанров в карточках фильмов и сериалов (TMDB Search API возвращает genre_ids)
- Исправлен потенциальный `FormatException` в `genre_provider.dart` — замена `int.parse` на `int.tryParse` с фильтрацией
- Исправлено мерцание canvas-изображений при перетаскивании (canvas_view.dart)

---

### Added
- Добавлена система дат активности элементов коллекции: `started_at`, `completed_at`, `last_activity_at` — для отслеживания прогресса и истории взаимодействия с играми, фильмами и сериалами
- Добавлена миграция БД v11→v12: три новых колонки в `collection_items`, инициализация `last_activity_at` из `added_at` для существующих записей
- Добавлен виджет `ActivityDatesSection` (`lib/features/collections/widgets/activity_dates_section.dart`) — секция с 4 строками: Added (readonly), Started (editable), Completed (editable), Last Activity (readonly). DatePicker для ручного редактирования дат
- Добавлен метод `updateItemActivityDates` в `DatabaseService` и `CollectionRepository` — ручное обновление дат через DatePicker
- Добавлены методы `updateActivityDates` в `CollectionGamesNotifier` и `CollectionItemsNotifier` — оптимистичное обновление дат в UI
- Добавлена автоматическая установка дат при смене статуса: `last_activity_at` обновляется всегда, `started_at` устанавливается при переходе в inProgress/Playing (если null), `completed_at` устанавливается при переходе в Completed
- Добавлено отображение даты просмотра (`watched_at`) в каждом эпизоде трекера сериалов

### Changed
- Изменён `updateItemStatus` в `DatabaseService` — теперь автоматически устанавливает даты активности при смене статуса (SELECT + UPDATE в одном вызове)
- Изменены модели `CollectionItem` и `CollectionGame` — добавлены поля `startedAt`, `completedAt`, `lastActivityAt`, обновлены `fromDb`, `toDb`, `copyWith`, `fromCollectionItem`, `toCollectionItem`
- Изменён `EpisodeTrackerState` — `watchedEpisodes` изменён с `Set<(int, int)>` на `Map<(int, int), DateTime?>` для хранения дат просмотра
- Изменены `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` — добавлена секция `ActivityDatesSection` в `extraSections`
- Изменён `_EpisodeTile` в `TvShowDetailScreen` — отображает дату просмотра эпизода в subtitle

### Fixed
- Исправлена рассинхронизация статусов при возврате из `GameDetailScreen` в список коллекции: `CollectionGamesNotifier` теперь инвалидирует `collectionItemsNotifierProvider` при обновлении статуса, дат, комментариев — обеспечивая синхронизацию между двумя провайдерами

---

### Added
- Добавлена поддержка Android (Lite версия без Canvas)
- Добавлена Android конфигурация: `build.gradle.kts`, `AndroidManifest.xml`, `MainActivity.kt`, иконки, стили
- Добавлен файл платформенных флагов `platform_features.dart` (`kCanvasEnabled`, `kVgMapsEnabled`, `kScreenshotEnabled`) — условное отключение Canvas, VGMaps, Screenshot на мобильных платформах
- Добавлена зависимость `sqflite: ^2.4.0` для нативной работы SQLite на Android

### Changed
- Изменён `database_service.dart` — `databaseFactoryFfi.openDatabase()` заменён на `databaseFactory.openDatabase()` для кроссплатформенной работы (FFI на desktop, нативный плагин на Android)
- Изменены `CollectionScreen`, `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` — переключатель List/Canvas и вкладка Canvas скрыты на Android через `kCanvasEnabled`
- Обновлён `file_picker` с 6.2.1 до 10.3.10 — исправлена несовместимость v1 Android embedding с новыми версиями Flutter
- Обновлены транзитивные зависимости: `build_runner` 2.11.0, `hooks` 1.0.1, `objective_c` 9.3.0, `source_span` 1.10.2, `url_launcher_ios` 6.4.0

---

### Added
- Добавлен режим сортировки коллекции (`CollectionSortMode`): Date Added (по умолчанию), Status (активные первыми), Name (A-Z), Manual (ручной порядок). Режим сохраняется в SharedPreferences per collection
- Добавлен `CollectionSortNotifier` — провайдер режима сортировки с персистентным хранением в SharedPreferences
- Добавлен getter `statusSortPriority` в `ItemStatus` — приоритет для сортировки: inProgress(0) → planned(1) → notStarted(2) → onHold(3) → completed(4) → dropped(5)
- Добавлен UI-селектор сортировки (`_buildSortSelector`) между статистикой и списком элементов коллекции — компактный `PopupMenuButton` с иконкой, текущим режимом и dropdown меню
- Добавлено поле `sort_order` в таблицу `collection_items` (миграция БД v10→v11) для ручной сортировки drag-and-drop
- Добавлен `ReorderableListView` с drag handle в режиме Manual sort — элементы коллекции можно перетаскивать вверх/вниз
- Добавлены методы `getNextSortOrder()` и `reorderItems()` в `DatabaseService` для управления порядком элементов
- Добавлен метод `reorderItem()` в `CollectionItemsNotifier` — оптимистичное обновление UI + batch update sort_order в БД

### Changed
- Изменён `_CollectionItemTile` — маленький цветной бейдж типа медиа убран из обложки, вместо него добавлена наклонённая полупрозрачная фоновая иконка (200px, -0.3 rad, opacity 0.06) по центру карточки через `Stack` + `Positioned.fill` + `Transform.rotate`. Иконка обрезается `Clip.antiAlias` — виден только фрагмент как водяной знак. Cover упрощён с `Stack` до тернарного оператора
- Изменён `CollectionItemsNotifier` — добавлена реактивная сортировка через `ref.watch(collectionSortProvider)`, метод `_applySortMode()` применяет выбранный режим при загрузке и обновлении элементов
- Изменён `CollectionItem` — добавлено поле `sortOrder` (default 0), обновлены `fromDb`, `toDb`, `copyWith`, `internalDbFields`
- Изменён `_buildItemsList` — при Manual sort mode используется `ReorderableListView.builder` с кастомным drag handle вместо `ListView.builder`

### Added
- Добавлен формат экспорта v2: `.xcoll` (лёгкий — метаданные + ID элементов) и `.xcollx` (полный — + canvas + base64 обложки). Старый `.rcoll` поддерживается как legacy v1 (только импорт)
- Добавлен миксин `Exportable` (`lib/shared/models/exportable.dart`) — контракт `toExport()`, `internalDbFields`, `dbToExportKeyMapping`. Применён к `CanvasItem`, `CanvasConnection`, `CanvasViewport`, `Collection`, `CollectionItem`
- Добавлена модель `XcollFile` (`lib/core/services/xcoll_file.dart`) — контейнер файла экспорта/импорта с поддержкой v1 (games) и v2 (items, canvas, images). Вспомогательные классы: `ExportFormat`, `ExportCanvas`, `RcollGame`
- Добавлены методы `readImageBytes()` и `saveImageBytes()` в `ImageCacheService` — прямой доступ к байтам для экспорта/импорта обложек
- Добавлено встраивание кэшированных обложек в full export (`.xcollx`): `ExportService._collectCachedImages()` собирает base64-обложки всех элементов, `ImportService._restoreImages()` восстанавливает обложки в локальный кэш при импорте
- Добавлена стадия `ImportStage.importingImages` в enum для отслеживания прогресса восстановления обложек
- Добавлен `ImageType.canvasImage('canvas_images')` в enum `ImageType` — кэширование URL-изображений с канваса
- Добавлены тесты: `xcoll_file_test.dart`, обновлены `export_service_test.dart` (+24 тестов v2 + images), `import_service_test.dart` (+56 тестов v2 + per-item canvas + images), `canvas_image_item_test.dart` (+10 тестов)

### Changed
- Изменён `ExportService` — полная переработка: добавлены `createLightExport()`, `createFullExport()`, `exportToFile()` с диалогом сохранения. Зависимости: `CanvasRepository`, `ImageCacheService`. Сбор canvas-данных и per-item canvas при full export
- Изменён `ImportService` — полная переработка: добавлен `_importV2()` с поддержкой items, canvas (viewport + items + connections), per-item canvas, восстановление обложек. `_importV1()` для legacy .rcoll
- Изменён `CanvasImageItem` — переведён с `StatelessWidget` на `ConsumerWidget`, URL-изображения используют `CachedImage` с `ImageType.canvasImage` вместо `CachedNetworkImage` для диск-кэширования. Добавлена функция `urlToImageId()` (FNV-1a хэш для стабильных cache-ключей)
- Изменены модели: `Collection`, `CollectionItem`, `CanvasItem`, `CanvasConnection`, `CanvasViewport` — добавлены методы `toExport()` через миксин `Exportable`
- Изменён `HomeScreen` — import использует `.xcoll`, `.xcollx`, `.rcoll` расширения

- Добавлено локальное кэширование изображений (Task #13): обложки игр, постеры фильмов и сериалов скачиваются в локальное хранилище для оффлайн-работы
- Добавлены значения `moviePoster` и `tvShowPoster` в enum `ImageType` (`image_cache_service.dart`) для кэширования постеров фильмов и сериалов
- Добавлены параметры `memCacheWidth`, `memCacheHeight`, `autoDownload` в виджет `CachedImage` — pass-through для `CachedNetworkImage`, автоматическое скачивание в кэш при отсутствии локального файла
- Добавлены параметры `cacheImageType` и `cacheImageId` в `MediaCard` и `MediaDetailView` — при наличии используется `CachedImage` вместо `CachedNetworkImage`
- Добавлен метод `_getImageTypeForCache()` в `CollectionScreen._CollectionItemTile` — маппинг `MediaType` → `ImageType`

### Changed
- Изменён `CachedImage` — полностью переработана логика: при cache enabled + файл отсутствует показывается изображение из сети (fallback на remoteUrl) вместо иконки ошибки, с фоновой загрузкой в кэш через `addPostFrameCallback`
- Изменён `getImageUri` (`ImageCacheService`) — при cache enabled + файл отсутствует возвращает `ImageResult(uri: remoteUrl, isLocal: false, isMissing: true)` вместо `ImageResult(uri: null, isMissing: true)`
- Изменены `CanvasGameCard` и `CanvasMediaCard` — переведены с `StatelessWidget` на `ConsumerWidget`, используют `CachedImage` вместо `CachedNetworkImage`
- Изменён `CollectionScreen` — thumbnails коллекции используют `CachedImage` вместо `CachedNetworkImage`
- Изменены `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` — передают `cacheImageType`/`cacheImageId` в `MediaDetailView`
- Изменён `SettingsScreen` — `FutureBuilder<List<dynamic>>` заменён на типизированный `FutureBuilder<(int, int)>` с Dart record для статистики кэша
- Обновлены тесты: `cached_image_test.dart` (13), `canvas_game_card_test.dart`, `canvas_media_card_test.dart` — добавлены ProviderScope, MockImageCacheService, тесты новых ImageType

---

### Added
- Добавлен `ConfigService` (`lib/core/services/config_service.dart`) — сервис экспорта/импорта конфигурации. Класс `ConfigResult` (success/failure/cancelled). Экспорт 7 ключей SharedPreferences в JSON через FilePicker, импорт с валидацией версии и типов
- Добавлен метод `DatabaseService.clearAllData()` — очистка всех 14 таблиц SQLite в одной транзакции с соблюдением порядка FK
- Добавлены методы `SettingsNotifier`: `exportConfig()`, `importConfig()`, `flushDatabase()` — делегирование ConfigService и DatabaseService с обновлением state
- Добавлена секция Configuration в `SettingsScreen` — кнопки Export Config и Import Config для выгрузки/загрузки API ключей
- Добавлена секция Danger Zone в `SettingsScreen` — кнопка Reset Database с диалогом подтверждения, очистка всех данных с сохранением настроек
- Добавлены тесты: `config_service_test.dart` (27), `settings_provider_flush_test.dart` (11), `settings_screen_config_test.dart` (15)

- Добавлена модель `TvEpisode` (`lib/shared/models/tv_episode.dart`) — эпизод сериала из TMDB с полями: tmdbShowId, seasonNumber, episodeNumber, name, overview, airDate, stillUrl, runtime. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()`. Equality по (tmdbShowId, seasonNumber, episodeNumber)
- Добавлена миграция БД v9→v10: таблицы `tv_episodes_cache` (кэш эпизодов TMDB) и `watched_episodes` (трекинг просмотренных эпизодов по коллекциям, FK CASCADE на collections)
- Добавлены методы в `DatabaseService`: `getEpisodesByShowAndSeason`, `upsertEpisodes`, `clearEpisodesByShow`, `getWatchedEpisodes`, `markEpisodeWatched`, `markEpisodeUnwatched`, `getWatchedEpisodeCount`, `markSeasonWatched`, `unmarkSeasonWatched`
- Добавлен метод `TmdbApi.getSeasonEpisodes(int tmdbShowId, int seasonNumber)` — загрузка списка эпизодов сезона из TMDB API (`GET /tv/{id}/season/{number}`)
- Добавлен провайдер `EpisodeTrackerNotifier` (`lib/features/collections/providers/episode_tracker_provider.dart`) — NotifierProvider.family по ключу `({collectionId, showId})`. State: episodesBySeason, watchedEpisodes (Set<(int,int)>), loadingSeasons, error. Cache-first стратегия: БД → API → кэш. Автоматический статус Completed при просмотре всех эпизодов (сравнение с tvShow.totalEpisodes из метаданных)
- Добавлена секция Episode Progress в `TvShowDetailScreen`: LinearProgressIndicator с общим прогрессом, ExpansionTile для каждого сезона с ленивой загрузкой эпизодов, CheckboxListTile для отметки просмотра, кнопка Mark all / Unmark all для сезонов
- Добавлена кнопка Refresh в секции сезонов — принудительное обновление данных из TMDB API (новые сезоны/эпизоды добавляются, метаданные обновляются, watched-статусы сохраняются)
- Добавлен метод `EpisodeTrackerNotifier.refreshSeason()` — принудительная загрузка эпизодов сезона из API, минуя кэш
- Добавлен fallback при загрузке сезонов: если кэш БД пуст — автоматическая загрузка из TMDB API с кэшированием
- Добавлены тесты: `tv_episode_test.dart` (46), `episode_tracker_provider_test.dart` (36), обновлены `tmdb_api_test.dart` (+6 тестов getSeasonEpisodes), обновлены `tv_show_detail_screen_test.dart` (MockDatabaseService, MockTmdbApi, новые тесты Episode Progress)

### Changed
- Изменён `TvShowDetailScreen` — секция прогресса заменена с простых +/- кнопок (currentSeason/currentEpisode) на полноценный трекер эпизодов с ExpansionTile по сезонам, чекбоксами и автоматическим статусом Completed. Добавлены виджеты `_SeasonsListWidget`, `_SeasonExpansionTile`, `_EpisodeTile`

---

### Added
- Добавлен персональный Canvas для каждого элемента коллекции (per-item canvas): каждая игра, фильм или сериал имеет собственный холст, доступный через вкладку Canvas на экране деталей
- Добавлен `GameCanvasNotifier` (`lib/features/collections/providers/canvas_provider.dart`) — NotifierProvider.family по ключу `({collectionId, collectionItemId})`. Автоинициализация одним медиа-элементом, поддержка всех типов canvas-элементов (game/movie/tvShow/text/image/link)
- Добавлена миграция БД v8→v9: колонка `collection_item_id` в таблицах `canvas_items` и `canvas_connections`, индексы, таблица `game_canvas_viewport`
- Добавлены методы в `DatabaseService`: `getGameCanvasItems`, `getGameCanvasItemCount`, `getGameCanvasConnections`, `getGameCanvasViewport`, `upsertGameCanvasViewport`, `deleteGameCanvasItems`, `deleteGameCanvasConnections`, `deleteGameCanvasViewport`
- Добавлены методы в `CanvasRepository`: `getGameCanvasItems`, `getGameCanvasItemsWithData`, `hasGameCanvasItems`, `getGameCanvasViewport`, `saveGameCanvasViewport`, `getGameCanvasConnections`
- Добавлено поле `collectionItemId: int?` в модели `CanvasItem` и `CanvasConnection` (null для коллекционного canvas, значение для per-item)
- Добавлена сортировка результатов поиска: `SearchSort` с полями relevance/date/rating и направлением asc/desc. Виджет `SortSelector` с визуальным индикатором направления
- Добавлена фильтрация поиска TMDB: фильтр по году выпуска и жанрам. Виджет `MediaFilterSheet` (BottomSheet с DraggableScrollableSheet, FilterChip для жанров)
- Добавлены провайдеры жанров: `movieGenresProvider`, `tvGenresProvider` — кэширование списков жанров из TMDB API
- Добавлены параметры `year` и `firstAirDateYear` в методы `TmdbApi.searchMovies()` и `TmdbApi.searchTvShows()`
- Добавлены боковые панели SteamGridDB и VGMaps в экраны деталей (`GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen`) — теперь панели доступны на per-item canvas, а не только на основном canvas коллекции
- Добавлены тесты: `search_sort_test.dart`, `sort_selector_test.dart`, `media_filter_sheet_test.dart`, `genre_provider_test.dart`, обновлены `game_search_provider_test.dart`, `media_search_provider_test.dart`, `tmdb_api_test.dart`, `canvas_item_test.dart`, `canvas_connection_test.dart`, `canvas_repository_test.dart`, `game_detail_screen_test.dart`, `movie_detail_screen_test.dart`, `tv_show_detail_screen_test.dart`

### Changed
- Изменены `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` — добавлен `TabBar` с вкладками Details и Canvas. Вкладка Details использует `MediaDetailView(embedded: true)`, вкладка Canvas содержит `CanvasView` с боковыми панелями SteamGridDB (320px) и VGMaps (500px)
- Изменён `MediaDetailView` — добавлен параметр `embedded: bool` (true = только контент без Scaffold, false = полный экран)
- Изменён `CanvasView` — принимает необязательный `collectionItemId` для работы с per-item canvas
- Изменён `SearchScreen` — добавлены `SortSelector` и `MediaFilterSheet` для сортировки и фильтрации результатов поиска
- Изменён `GameSearchNotifier` — добавлены методы `setSort()`, `_applySort()` с сортировкой по релевантности (exact match/startsWith/contains), дате и рейтингу
- Изменён `MediaSearchNotifier` — добавлены методы `setSort()`, `setYearFilter()`, `setGenreFilter()` с локальной фильтрацией по жанрам и серверной фильтрацией по году
- Изменён `CanvasRepository` — выделен приватный метод `_enrichItemsWithMediaData()` для переиспользования при обогащении данными Game/Movie/TvShow

### Fixed
- Исправлена утечка данных между per-item canvas и основным canvas коллекции: добавлен фильтр `AND collection_item_id IS NULL` в 6 SQL-методов `DatabaseService` (`getCanvasItems`, `deleteCanvasItemByRef`, `deleteCanvasItemsByCollection`, `getCanvasItemCount`, `getCanvasConnections`, `deleteCanvasConnectionsByCollection`)
- Исправлена проблема: боковые панели SteamGridDB и VGMaps не открывались на per-item canvas (виджеты панелей отсутствовали в widget tree detail-экранов)

---

### Added
- Добавлен виджет `SourceBadge` (`lib/shared/widgets/source_badge.dart`) — бейдж источника данных (IGDB, TMDB, SteamGridDB, VGMaps) с цветовой маркировкой и текстовой меткой. Размеры: small, medium, large
- Добавлен виджет `MediaCard` (`lib/shared/widgets/media_card.dart`) — базовый виджет карточки результата поиска: постер 60x80, название, subtitle, metadata, trailing-виджет. GameCard, MovieCard, TvShowCard переписаны как тонкие обёртки
- Добавлен виджет `MediaDetailView` (`lib/shared/widgets/media_detail_view.dart`) — базовый виджет экрана деталей медиа: постер 80x120, SourceBadge, info chips, описание, секция статуса, комментарии, заметки, диалог редактирования. GameDetailScreen, MovieDetailScreen, TvShowDetailScreen переписаны как тонкие обёртки
- Добавлена модель `MediaDetailChip` — чип с иконкой и текстом для отображения метаинформации (год, рейтинг, жанры и т.д.)
- Добавлен виджет `MediaTypeBadge` (`lib/shared/widgets/media_type_badge.dart`) — бейдж типа медиа с цветной иконкой (игра — синий, фильм — красный, сериал — зелёный)
- Добавлены константы `MediaTypeTheme` (`lib/shared/constants/media_type_theme.dart`) — цвета и иконки для визуального разделения типов медиа
- Добавлены тесты: `source_badge_test.dart`, `media_card_test.dart`, `media_detail_view_test.dart`, `media_type_badge_test.dart`, `media_type_theme_test.dart`
- Добавлено отображение фильмов и сериалов в коллекциях, деталях и канвасе (Stage 18)
- Добавлен виджет `ItemStatusDropdown` (`lib/features/collections/widgets/item_status_dropdown.dart`) — универсальный dropdown статуса с контекстными лейблами: "Playing"/"Watching" в зависимости от `MediaType`. Включает `ItemStatusChip` для read-only отображения. Полный и компактный режимы. Для сериалов включает статус `onHold`
- Добавлен виджет `CanvasMediaCard` (`lib/features/collections/widgets/canvas_media_card.dart`) — карточка фильма/сериала на канвасе по паттерну `CanvasGameCard`: постер, название, placeholder icon
- Добавлен экран `MovieDetailScreen` (`lib/features/collections/screens/movie_detail_screen.dart`) — тонкая обёртка над `MediaDetailView`: маппинг CollectionItem+Movie на параметры виджета, info chips (год, runtime, жанры, рейтинг), статус через `ItemStatusDropdown`
- Добавлен экран `TvShowDetailScreen` (`lib/features/collections/screens/tv_show_detail_screen.dart`) — тонкая обёртка над `MediaDetailView`: маппинг CollectionItem+TvShow на параметры виджета, info chips (год, сезоны, эпизоды, жанры, рейтинг, статус шоу), секция прогресса через `extraSections`
- Добавлены значения `movie` и `tvShow` в enum `CanvasItemType`, joined поля `Movie? movie` и `TvShow? tvShow` в модели `CanvasItem`, статический метод `CanvasItemType.fromMediaType()`, геттер `isMediaItem`
- Добавлен метод `deleteMediaItem(collectionId, CanvasItemType, refId)` в `CanvasRepository` для generic удаления по типу медиа
- Добавлен метод `removeMediaItem(MediaType, externalId)` в `CanvasNotifier` для generic удаления медиа из канваса
- Добавлены тесты: `item_status_dropdown_test.dart` (95), `canvas_media_card_test.dart` (19), `movie_detail_screen_test.dart` (38), `tv_show_detail_screen_test.dart` (39) — всего 191 новый тест Stage 18

### Changed
- Рефакторинг карточек поиска: `GameCard`, `MovieCard`, `TvShowCard` переписаны как тонкие обёртки над базовым `MediaCard` — удалено ~700 строк дублированного UI кода
- Рефакторинг экранов деталей: `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` переписаны как тонкие обёртки над базовым `MediaDetailView` — удалено ~1300 строк дублированного UI кода. Единый layout: постер 80x120 + SourceBadge + info chips + описание inline + статус + комментарии
- Добавлены бейджи `SourceBadge` в карточки поиска и экраны деталей для отображения источника данных (IGDB/TMDB)
- Добавлены цветные бордеры `MediaTypeBadge` на канвас-карточки (`CanvasGameCard`, `CanvasMediaCard`) для визуального разделения типов медиа
- Добавлены логотипы источников данных (IGDB, TMDB, SteamGridDB) на экран настроек рядом с полями API ключей
- Изменён `CollectionScreen` — полный переход с `CollectionGame`/`collectionGamesNotifierProvider` на `CollectionItem`/`collectionItemsNotifierProvider`: универсальная плитка `_CollectionItemTile` с иконкой типа медиа, контекстные подзаголовки (платформа/год+runtime/год+сезоны), навигация к `MovieDetailScreen`/`TvShowDetailScreen` по типу, `ItemStatusDropdown` вместо `StatusDropdown`
- Изменён `CanvasView` — добавлены switch cases для `CanvasItemType.movie` и `CanvasItemType.tvShow` с рендерингом `CanvasMediaCard`, типоспецифичные размеры (160x240 для movie/tvShow)
- Изменён `CanvasContextMenu` — флаг `showEdit` использует `!itemType.isMediaItem` для скрытия Edit у movie/tvShow (как у game)
- Изменён `CanvasRepository.getItemsWithData()` — загрузка и join Movie/TvShow данных из кэша помимо Game
- Изменён `CanvasRepository.initializeCanvas()` — определение `CanvasItemType` из `CollectionItem.mediaType` для всех типов медиа
- Изменён `CanvasNotifier._initializeFromItems()` — убран фильтр game-only, передаются все элементы коллекции
- Изменён `CanvasNotifier._syncCanvasWithItems()` — синхронизация всех типов медиа с маппингом `MediaType` → `CanvasItemType`
- Изменён `DatabaseService.deleteCanvasItemByRef()` — принимает параметр `itemType` вместо хардкода `'game'`

---

### Added
- Добавлен универсальный поиск с табами Games / Movies / TV Shows (Stage 17)
- Добавлен провайдер `MediaSearchNotifier` (`lib/features/search/providers/media_search_provider.dart`) — поиск фильмов и сериалов через TMDB API с debounce 400ms, переключение табов, кэширование результатов в БД
- Добавлен enum `MediaSearchTab` (movies, tvShows) и state `MediaSearchState` с copyWith, equality
- Добавлен виджет `MovieCard` (`lib/features/search/widgets/movie_card.dart`) — горизонтальная карточка фильма: постер 60x80, название, год, рейтинг, runtime, жанры
- Добавлен виджет `TvShowCard` (`lib/features/search/widgets/tv_show_card.dart`) — горизонтальная карточка сериала: постер 60x80, название, год, рейтинг, жанры, количество сезонов/эпизодов, статус
- Добавлены тесты: `media_search_provider_test.dart`, `movie_card_test.dart`, `tv_show_card_test.dart`

### Changed
- Изменён `SearchScreen` — добавлены TabBar/TabBarView с 3 табами (Games / Movies / TV Shows), общее поле поиска, фильтр платформ только для Games, bottom sheet деталей для фильмов/сериалов, добавление фильмов/сериалов в коллекцию через `collectionItemsNotifierProvider.addItem()` с кэшированием через `upsertMovies()`/`upsertTvShows()`
- Изменён `CollectionScreen` — "Add Game" → "Add Items", "No Games Yet" → "No Items Yet", "Add games to start..." → "Add items to start..." для соответствия универсальным коллекциям
- Изменён `CanvasView` — "Add games to the collection first" → "Add items to the collection first"

### Fixed
- Исправлен баг: подсказка в поле поиска не обновлялась при переключении табов (добавлен `setState` в `_onTabChanged()`)

---

### Added
- Добавлены универсальные коллекции с поддержкой фильмов и сериалов (Stage 16)
- Добавлена модель `CollectionItem` (`lib/shared/models/collection_item.dart`) — универсальный элемент коллекции с MediaType, ItemStatus, заменяет привязку к играм
- Добавлен enum `MediaType` (`lib/shared/models/media_type.dart`) — game, movie, tvShow с отображаемыми названиями
- Добавлен enum `ItemStatus` (`lib/shared/models/item_status.dart`) — notStarted, inProgress, completed, dropped, planned с label, emoji и цветом
- Добавлен `CollectionItemsNotifier` в `collections_provider.dart` — CRUD для универсальных элементов коллекции
- Добавлена миграция БД v7→v8: таблица `collection_items` с FK CASCADE, индексы по collection_id и media_type
- Добавлены методы в `DatabaseService`: `getCollectionItems`, `insertCollectionItem`, `updateCollectionItem`, `deleteCollectionItem`, `getCollectionItemCount`, `getCollectionItemsByType`
- Добавлены методы в `CollectionRepository`: `getItems`, `addItem`, `updateItemStatus`, `deleteItem`, `getItemCount`
- Добавлена обратная совместимость: `CollectionGame.fromCollectionItem()` адаптер, `canvasNotifierProvider` работает с обоими провайдерами
- Добавлены тесты: `collection_item_test.dart`, `media_type_test.dart`, `item_status_test.dart`, `collection_game_test.dart` (обновлён)

### Changed
- Изменён `CanvasNotifier` — слушает `collectionItemsNotifierProvider` для синхронизации канваса с универсальными коллекциями
- Изменён `CollectionGamesNotifier.refresh()` — инвалидирует `collectionItemsNotifierProvider` для двусторонней синхронизации
- Изменён `ExportService` / `ImportService` — поддержка универсальных элементов при экспорте/импорте

---

### Added
- Добавлена интеграция TMDB API для фильмов и сериалов (Stage 15)
- Добавлен API клиент `TmdbApi` (`lib/core/api/tmdb_api.dart`) — поиск фильмов/сериалов, детали, популярные, мультипоиск, списки жанров. OAuth через API key (Bearer token)
- Добавлена модель `Movie` (`lib/shared/models/movie.dart`) — фильм с полями: id, title, overview, posterPath, releaseDate, rating, genres, runtime и др. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()`
- Добавлена модель `TvShow` (`lib/shared/models/tv_show.dart`) — сериал с полями: id, title, overview, posterPath, firstAirDate, rating, genres, seasons, episodes, status. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()`
- Добавлена модель `TvSeason` (`lib/shared/models/tv_season.dart`) — сезон сериала. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()`
- Добавлена миграция БД до версии 7: таблицы `movies_cache`, `tv_shows_cache`, `tv_seasons_cache`
- Добавлена секция TMDB API Key в экран настроек для ввода и сохранения ключа
- Добавлено поле `tmdbApiKey` в `SettingsState` и метод `setTmdbApiKey()` в `SettingsNotifier`
- Добавлены тесты: `movie_test.dart` (105), `tv_show_test.dart`, `tv_season_test.dart`, `tmdb_api_test.dart` (81), обновлены `settings_provider_test.dart`, `settings_state_test.dart`

### Changed
- Изменён `DatabaseService` — версия БД увеличена до 7, добавлены 3 таблицы кэша
- Изменён `SettingsNotifier.build()` — инициализация TMDB API клиента
- Изменён `settings_screen.dart` — добавлена секция TMDB API key

---

### Added
- Добавлена боковая панель VGMaps Browser для канваса (Stage 12): встроенный WebView-браузер vgmaps.com для поиска и добавления карт уровней на канвас
- Добавлен провайдер `VgMapsPanelNotifier` (`lib/features/collections/providers/vgmaps_panel_provider.dart`) — NotifierProvider.family по collectionId. State: isOpen, currentUrl, canGoBack, canGoForward, isLoading, capturedImageUrl/Width/Height, error
- Добавлен виджет `VgMapsPanel` (`lib/features/collections/widgets/vgmaps_panel.dart`) — боковая панель 500px: заголовок, навигация (back/forward/home/reload), поиск по имени игры, WebView2 через `webview_windows`, JS injection для перехвата ПКМ на изображениях, bottom bar с превью и кнопкой "Add to Canvas"
- Добавлена кнопка FAB "VGMaps Browser" на тулбар канваса (иконка map, только в режиме редактирования)
- Добавлен пункт "Browse maps..." в контекстное меню пустого места канваса
- Добавлена зависимость `webview_windows: ^0.4.0` — нативный Edge WebView2 для Windows
- Добавлено взаимоисключение панелей: открытие VGMaps закрывает SteamGridDB и наоборот
- Добавлены тесты: `vgmaps_panel_provider_test.dart` (24), `vgmaps_panel_test.dart` (23), обновлены `canvas_view_test.dart` (+2), `canvas_context_menu_test.dart` (+3) — всего 52 теста Stage 12

### Changed
- Изменён `CollectionScreen` — добавлена вторая боковая панель VGMaps с AnimatedContainer (500px). Метод `_addVgMapsImage()` масштабирует карту до max 400px по ширине
- Изменён `CanvasView` — добавлена кнопка FAB VGMaps Browser, взаимоисключение панелей при toggle, `onBrowseMaps` callback в контекстное меню
- Изменён `CanvasContextMenu.showCanvasMenu()` — добавлен необязательный параметр `onBrowseMaps` и пункт "Browse maps..." с Icons.map

---

### Added
- Добавлена боковая панель SteamGridDB для канваса (Stage 10): поиск игр и добавление изображений (grids, heroes, logos, icons) прямо на канвас
- Добавлен провайдер `SteamGridDbPanelNotifier` (`lib/features/collections/providers/steamgriddb_panel_provider.dart`) — NotifierProvider.family по collectionId. Управление поиском игр, выбором типа изображений, in-memory кэш результатов API по ключу `gameId:imageType`
- Добавлен enum `SteamGridDbImageType` (grids/heroes/logos/icons) с отображаемыми лейблами
- Добавлен виджет `SteamGridDbPanel` (`lib/features/collections/widgets/steamgriddb_panel.dart`) — боковая панель 320px: заголовок, поле поиска (автозаполнение из названия коллекции), предупреждение об отсутствии API ключа, результаты поиска (ListView.builder с verified иконкой), SegmentedButton выбора типа, сетка thumbnail-ов (GridView.builder + CachedNetworkImage). Клик на изображение добавляет его на канвас
- Добавлена кнопка FAB "SteamGridDB Images" на тулбар канваса (иконка image_search, только в режиме редактирования)
- Добавлен пункт "Find images..." в контекстное меню пустого места канваса (с разделителем, только в режиме редактирования)
- Добавлены тесты: `steamgriddb_panel_provider_test.dart` (29), `steamgriddb_panel_test.dart` (28), обновлены `canvas_view_test.dart` (+4), `canvas_context_menu_test.dart` (+3) — всего 64 теста Stage 10

### Changed
- Изменён `CollectionScreen` — канвас обёрнут в Row с AnimatedContainer (200ms, easeInOut) для анимированного открытия/закрытия панели, `.select((s) => s.isOpen)` для минимизации rebuild. Метод `_addSteamGridDbImage()` масштабирует изображение до max 300px по ширине с сохранением пропорций
- Изменён `CanvasView` — добавлена кнопка FAB SteamGridDB перед существующими Center view и Reset positions, передаётся `onFindImages` callback в контекстное меню
- Изменён `CanvasContextMenu.showCanvasMenu()` — добавлен необязательный параметр `onFindImages` и пункт "Find images..." с PopupMenuDivider

---

### Added
- Добавлены связи Canvas (Stage 9): визуальные линии между элементами канваса с тремя стилями (solid, dashed, arrow), настраиваемым цветом и лейблами
- Добавлена модель `CanvasConnection` (`lib/shared/models/canvas_connection.dart`) — связь между двумя элементами канваса с полями: id, collectionId, fromItemId, toItemId, label, color (hex), style, createdAt
- Добавлен enum `ConnectionStyle` (solid/dashed/arrow) с `fromString()` конвертером
- Добавлен `CanvasConnectionPainter` (`lib/features/collections/widgets/canvas_connection_painter.dart`) — CustomPainter для рендеринга связей: solid (drawLine), dashed (PathMetrics), arrow (solid + треугольник). Hit-test на линии для контекстного меню
- Добавлен `EditConnectionDialog` (`lib/features/collections/widgets/dialogs/edit_connection_dialog.dart`) — диалог редактирования связи: TextField для label, 8 цветных кнопок, SegmentedButton для стиля (Solid/Dashed/Arrow)
- Добавлена миграция БД до версии 6: таблица `canvas_connections` с FK CASCADE на canvas_items (автоудаление при удалении элемента)
- Добавлены CRUD методы в `DatabaseService`: `getCanvasConnections`, `insertCanvasConnection`, `updateCanvasConnection`, `deleteCanvasConnection`, `deleteCanvasConnectionsByCollection`
- Добавлены методы в `CanvasRepository`: `getConnections`, `createConnection`, `updateConnection`, `deleteConnection`
- Добавлены методы в `CanvasNotifier`: `startConnection`, `completeConnection`, `cancelConnection`, `deleteConnection`, `updateConnection`
- Добавлен пункт "Connect" в контекстное меню элемента канваса — запускает режим создания связи
- Добавлено контекстное меню связей (ПКМ на линии) — Edit / Delete
- Добавлены тесты: `canvas_connection_test.dart` (25), `canvas_repository_connections_test.dart`, `canvas_provider_connections_test.dart`, `canvas_connection_painter_test.dart` (18), `edit_connection_dialog_test.dart`, `canvas_context_menu_connect_test.dart` (7)

### Changed
- Изменён `CanvasView` — добавлен слой CustomPaint для отрисовки связей под элементами, режим создания связи (курсор cell, временная пунктирная линия к курсору, баннер-индикатор, Escape для отмены), hit-test на линии для контекстного меню
- Изменён `CanvasNotifier` — поля `connections` и `connectingFromId` в `CanvasState`, параллельная загрузка connections через `Future.wait`, фильтрация connections при удалении элемента
- Изменён `CanvasContextMenu` — добавлен пункт Connect и метод `showConnectionMenu` для Edit/Delete связей
- Изменён `CanvasRepository` — добавлены 4 метода для CRUD связей
- Изменена `DatabaseService` — версия БД увеличена до 6, добавлена таблица canvas_connections с индексом

---

### Added
- Добавлены элементы Canvas (Stage 8): текстовые блоки, изображения, ссылки, контекстное меню, resize
- Добавлен `CanvasContextMenu` (`lib/features/collections/widgets/canvas_context_menu.dart`) — контекстное меню ПКМ: Add Text/Image/Link на пустом месте; Edit/Delete/Bring to Front/Send to Back на элементе
- Добавлен `CanvasTextItem` (`lib/features/collections/widgets/canvas_text_item.dart`) — текстовый блок с настраиваемым размером шрифта (Small 12/Medium 16/Large 24/Title 32)
- Добавлен `CanvasImageItem` (`lib/features/collections/widgets/canvas_image_item.dart`) — изображение по URL (CachedNetworkImage) или из файла (base64)
- Добавлен `CanvasLinkItem` (`lib/features/collections/widgets/canvas_link_item.dart`) — ссылка с иконкой, double-click открывает в браузере через url_launcher
- Добавлен `AddTextDialog` (`lib/features/collections/widgets/dialogs/add_text_dialog.dart`) — диалог создания/редактирования текста
- Добавлен `AddImageDialog` (`lib/features/collections/widgets/dialogs/add_image_dialog.dart`) — диалог добавления изображения (URL/файл)
- Добавлен `AddLinkDialog` (`lib/features/collections/widgets/dialogs/add_link_dialog.dart`) — диалог добавления/редактирования ссылки
- Добавлен resize handle для всех элементов канваса (14x14, правый нижний угол, мин. 50x50, макс. 2000x2000)
- Добавлены методы `addTextItem`, `addImageItem`, `addLinkItem`, `updateItemData`, `updateItemSize` в `CanvasNotifier`
- Добавлен метод `updateItemData` в `CanvasRepository` для обновления JSON data элемента
- Добавлена зависимость `url_launcher: ^6.2.0`
- Добавлены тесты: `canvas_context_menu_test.dart` (10), `canvas_text_item_test.dart` (8), `canvas_image_item_test.dart` (8), `canvas_link_item_test.dart` (9), `add_text_dialog_test.dart` (9), `add_link_dialog_test.dart` (11), `add_image_dialog_test.dart` (14), + 16 тестов для новых методов canvas_provider + 2 теста updateItemData в canvas_repository — всего 87 тестов Stage 8

### Changed
- Изменён `CanvasView` — добавлено контекстное меню (ПКМ), resize handle, рендеринг text/image/link элементов вместо SizedBox.shrink()
- Изменён `CanvasNotifier` — добавлены 5 методов для управления текстом, изображениями, ссылками и размерами
- Изменён `CanvasRepository` — добавлен метод `updateItemData` для обновления JSON-данных элемента

### Fixed
- Исправлен баг визуальной обратной связи при перетаскивании: элементы теперь двигаются в реальном времени вместо прыжка при отпускании мыши (замена `ValueNotifier + Transform.translate` на `setState + Positioned`)
- Исправлен баг визуальной обратной связи при ресайзе: размер элемента обновляется в реальном времени при перетаскивании handle
- Текстовые блоки на канвасе отображаются без фона — убран Container с цветом и бордером
- Добавлены типоспецифичные размеры по умолчанию: text 200x100, image 200x200, link 200x48 (ранее все типы использовали 150x200)
- Виджеты `CanvasImageItem`, `CanvasLinkItem` заменили фиксированные SizedBox на `SizedBox.expand()` для корректного ресайза

---

- Добавлен базовый Canvas — визуальный холст для свободного размещения элементов коллекции (Stage 7)
- Добавлена миграция БД до версии 5: таблицы `canvas_items` и `canvas_viewport` с FK CASCADE и индексами
- Добавлена модель `CanvasItem` (`lib/shared/models/canvas_item.dart`) с enum `CanvasItemType` (game/text/image/link)
- Добавлена модель `CanvasViewport` (`lib/shared/models/canvas_viewport.dart`) — хранение зума и позиции камеры
- Добавлен `CanvasRepository` (`lib/data/repositories/canvas_repository.dart`) — CRUD для canvas_items и viewport, инициализация сеткой
- Добавлен `CanvasNotifier` (`lib/features/collections/providers/canvas_provider.dart`) — state management канваса с debounced save (300ms position, 500ms viewport), двусторонняя синхронизация с коллекцией (реактивная через `ref.listen`)
- Добавлен `CanvasView` (`lib/features/collections/widgets/canvas_view.dart`) — InteractiveViewer с зумом 0.3–3.0x, drag-and-drop с абсолютным отслеживанием позиции, фоновая сетка, автоцентрирование
- Добавлен `CanvasGameCard` (`lib/features/collections/widgets/canvas_game_card.dart`) — компактная карточка игры с обложкой и названием
- Добавлен переключатель List/Canvas в `CollectionScreen` через `SegmentedButton`
- Добавлены CRUD методы в `DatabaseService`: `getCanvasItems`, `insertCanvasItem`, `updateCanvasItem`, `deleteCanvasItem`, `deleteCanvasItemByRef`, `deleteCanvasItemsByCollection`, `getCanvasItemCount`, `getCanvasViewport`, `upsertCanvasViewport`
- Добавлены тесты: `canvas_item_test.dart` (24), `canvas_viewport_test.dart` (17), `canvas_repository_test.dart` (27), `canvas_provider_test.dart` (45), `canvas_game_card_test.dart` (6), `canvas_view_test.dart` (30) — всего 149 тестов для Stage 7

### Changed
- Изменён `DatabaseService` — версия БД увеличена до 5, добавлены таблицы canvas_items и canvas_viewport
- Изменён `CollectionScreen` — добавлен SegmentedButton для переключения между List и Canvas режимами, синхронизация удаления игр с канвасом
- Оптимизирован `CanvasView` — кеширование `Theme.of(context)`, параллельная загрузка items и viewport

### Fixed
- Исправлен баг drag-and-drop: карточки двигались быстрее курсора из-за конфликта жестов InteractiveViewer и GestureDetector (переход на абсолютное отслеживание через `globalPosition`, блокировка `panEnabled` при drag)

---

- Добавлен API клиент SteamGridDB (`lib/core/api/steamgriddb_api.dart`): поиск игр, загрузка grids, heroes, logos, icons с Bearer token авторизацией
- Добавлена модель `SteamGridDbGame` (`lib/shared/models/steamgriddb_game.dart`) — результат поиска игры в SteamGridDB
- Добавлена модель `SteamGridDbImage` (`lib/shared/models/steamgriddb_image.dart`) — изображение из SteamGridDB (grids, heroes, logos, icons)
- Добавлен debug-экран SteamGridDB (`lib/features/settings/screens/steamgriddb_debug_screen.dart`) с 5 табами: Search, Grids, Heroes, Logos, Icons
- Добавлена секция SteamGridDB API Key в экран настроек для ввода и сохранения ключа
- Добавлена секция Developer Tools в настройках с навигацией на debug-экран (скрыта в release сборке через `kDebugMode`)
- Добавлен скилл `changelog-docs` для документирования изменений и актуализации docs
- Добавлен `steamGridDbApiProvider` — Riverpod провайдер для SteamGridDB API клиента
- Добавлено поле `steamGridDbApiKey` в `SettingsState` и метод `setSteamGridDbApiKey()` в `SettingsNotifier`
- Добавлены тесты: `steamgriddb_game_test.dart`, `steamgriddb_image_test.dart`, `steamgriddb_api_test.dart`

### Changed
- Изменён `SettingsKeys` — добавлен ключ `steamGridDbApiKey`
- Изменён `SettingsNotifier.build()` — теперь также инициализирует SteamGridDB API клиент
- Изменён `SettingsNotifier.clearSettings()` — очищает также SteamGridDB API ключ
- Изменён `settings_screen.dart` — добавлены секции SteamGridDB API и Developer Tools
- Обновлены тесты `settings_state_test.dart` и `settings_screen_test.dart` для покрытия новых полей
