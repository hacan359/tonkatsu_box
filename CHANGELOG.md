# Changelog

Все значимые изменения проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).

## [Unreleased]

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
