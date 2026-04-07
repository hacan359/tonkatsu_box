[← Back to README](../README.md)

# 🗺️ Roadmap

![Progress](https://img.shields.io/badge/overall_progress-~90%25-brightgreen?style=for-the-badge)

> Approximate completion: **~90%** — Core features, canvas system, media integrations, Android Lite, UI redesign, Wishlist, and Search refactoring are done. Future plans remain.

---

## ✅ Current Version (v1.0)

- [x] Project setup
- [x] IGDB integration
- [x] Collection management
- [x] Progress tracking
- [x] Import/Export (.xcoll/.xcollx)
- [x] Comments system
- [x] SteamGridDB integration (API client, debug panel)
- [x] Offline image caching
- [x] Static reference data — genres (TMDB EN+RU, IGDB), tags (VNDB), platforms (220 IGDB) embedded in migration v24. No runtime API calls needed for reference data
- [x] Tier Lists — rank collection items across customizable S/A/B/C tiers with drag-and-drop, color picker, PNG export, .xcollx support
- [x] Custom items — manually create collection entries with custom cover, genres, platform, rating, displayType styling. Export/import support

---

## ✅ Canvas Development

- [x] Stage 7: Basic Canvas — visual canvas with zoom, pan, drag-and-drop, grid layout, List/Canvas toggle, bidirectional collection sync
- [x] Stage 8: Canvas Elements — context menu, text blocks, images, links, resize, z-index
- [x] Stage 9: Connections — visual connections (solid/dashed/arrow) between canvas elements with labels, colors, edit/delete, auto-cleanup
- [x] Stage 10: SteamGridDB Widget — side panel for adding SteamGridDB images to canvas
- [x] Stage 12: VGMaps Browser — side panel with embedded WebView2 for browsing and adding vgmaps.com level maps to canvas
- [x] Stage 15: TMDB Integration — API client for movies/TV shows, models (Movie, TvShow, TvSeason), DB cache tables, settings UI
- [x] Stage 16: Universal Collections — CollectionItem model with MediaType (game/movie/tvShow), ItemStatus, DB migration, backward-compatible adapters
- [x] Stage 17: Universal Search — tabbed search (Games/Movies/TV Shows), MediaSearchProvider, MovieCard, TvShowCard, add movies/TV shows to collections
- [x] Stage 18: Media Display — movie/TV show detail screens, StatusChipRow, CanvasMediaCard, CollectionScreen switched to CollectionItem, canvas support for all media types
- [x] UI Cards: Source badges (IGDB/TMDB), unified MediaCard for search, unified MediaDetailView for detail screens, media type color coding, canvas card type borders
- [x] Search Sorting: Sort results by relevance, date, or rating with toggleable direction
- [x] TMDB Filters: Filter movies/TV shows by release year and genres
- [x] Per-Item Canvas: Personal canvas for each game/movie/TV show with TabBar detail screens, SteamGridDB and VGMaps panels, data isolation
- [x] Task #11: Season Details — TMDB API season episodes, TvEpisode model, SQLite cache (tv_episodes_cache), lazy-loading per season
- [x] Task #12: Episode Tracker — per-episode checkboxes, season bulk toggle, watched_episodes DB table, auto-complete to Completed status
- [x] Task #14: Reset Database — clearAllData() for all 14 SQLite tables, confirmation dialog, settings preserved
- [x] Config Export/Import — ConfigService with JSON export/import of 7 SharedPreferences keys, file picker dialogs
- [x] Task #13: Image Caching — local caching of game covers, movie posters, TV show posters with auto-download, fallback to network, toggle in Settings
- [x] Export v2 — Exportable mixin, XcollFile model (v2 only), .xcoll (light) and .xcollx (full with canvas + images). Embedded cover images as base64 for offline import. Canvas URL image caching via ImageType.canvasImage
- [x] Collection sorting — sort by Date Added, Status, Name, Rating, or Manual (drag-and-drop). Per-collection persistence via SharedPreferences
- [x] Media type watermark — large tilted semi-transparent background icon on each collection item card
- [x] Android Lite — collections, search, details, episode tracker, export/import (no Canvas). Platform feature flags
- [x] Activity Dates — started_at, completed_at, last_activity_at for all collection items. Auto-set on status change. DatePicker for manual editing. Watched dates in episode tracker
- [x] Canvas Lock — view-only mode toggle (lock icon in AppBar) for own/fork collections. Closes side panels when locked. Available on collection and per-item canvas
- [x] View Mode Persistence — grid/table toggle saved per-collection in SharedPreferences. 2-way cycle: grid → table (list view temporarily hidden)
- [x] Animation Tab — 4th search tab combining animated movies and TV shows from TMDB (genre Animation, ID=16). MediaType.animation enum, AnimationSource discriminator (movie=0, tvShow=1), adaptive animation config in unified `ItemDetailScreen`, purple accent color, filter chip in collections, canvas support
- [x] Legacy Removal — removed CollectionGame/GameStatus, collectionGamesNotifierProvider, v1 .rcoll format, 'playing' status mapping. DB migration v14. Unified on CollectionItem/ItemStatus only
- [x] User Rating — userRating field (1-10) on CollectionItem, DB migration v15, StarRatingBar widget (10 clickable stars), My Rating section on detail screens, sort by rating. Author's Comment renamed to Author's Review with description subtitle
- [x] Unified MediaPosterCard — single vertical poster card with 3 variants (grid/compact/canvas). DualRatingBadge (`★ 8 / 7.5`), enhanced list tiles (description, inline rating, user notes). Replaced 7 card widgets, deleted ~3600 lines of dead code
- [x] ~~Breadcrumb Navigation~~ — **Removed** in favor of plain AppBar. NavigationRail/BottomBar provides tab context; back button handles return navigation
- [x] Settings Restructuring — monolithic SettingsScreen (~1118 lines) split into hub + 4 sub-screens: CredentialsScreen, CacheScreen, DatabaseScreen, DebugHubScreen
- [x] Settings Redesign — unified iOS-style grouped-list layout for all platforms. Widgets: SettingsGroup, SettingsTile. Removed desktop sidebar layout (SettingsSidebar, SettingsSection, SettingsRow, SettingsNavRow deleted). Credits rewritten to plain text without SVG logos. All screen wrappers unified: Align(topCenter) + ConstrainedBox(600) + consistent padding
- [x] Move to Collection — move items between collections or to/from uncategorized. DB `updateItemCollectionId`, shared `CollectionPickerDialog`, PopupMenuButton on detail screens and collection tiles. Board tab hidden for uncategorized items
- [x] Multi-platform Games — same game with different platforms (SNES, GBA, etc.) in one collection with independent progress/rating/notes. DB migration v18: UNIQUE index with `COALESCE(platform_id, -1)`. Canvas sync via `collectionItemId`. Platform filter chips on Home and CollectionScreen. Platform badge on poster cards
- [x] Wishlist — quick notes for deferred content search. WishlistItem model, DB migration v19 (wishlist table), WishlistRepository, WishlistNotifier (AsyncNotifierProvider), WishlistScreen with FAB/popup menu/filter/clear resolved, AddWishlistDialog with optional media type hint, 5th navigation tab with badge (active count), tap-to-search integration with SearchScreen(initialQuery)
- [x] Trakt.tv ZIP Import — offline import from Trakt data export (ZIP archive). TraktZipImportService with validateZip/importFromZip, TraktImportScreen with file picker/preview/options/progress dialog. Watched movies/shows → collection items (completed), ratings → userRating (if null), watchlist → planned/wishlist, episodes → episode tracker. Animation detection via TMDB genres. Conflict resolution (status hierarchy, dropped never overwritten). `archive` package for cross-platform ZIP extraction
- [x] i18n Localization (EN/RU) — Flutter `gen_l10n` with 521 ARB keys, ICU plural forms for Russian, runtime language switcher in Settings, localized enum labels (ItemStatus, MediaType, CollectionSortMode, SearchSortField), `AppStrings` removed
- [x] Copy to Collection — clone items between collections (full copy of status, ratings, comments, progress, dates). "Copy to collection" in context menu alongside "Move". Canvas and tier-list entries not copied
- [x] Collection List Sort & View — sort by date created or alphabetically with direction toggle, grid/list view switcher. All preferences persisted in SharedPreferences. `CollectionListSortMode`, `CollectionListTile`
- [x] Open in Collection — search result cards with "in collection" badge become clickable, navigating to `ItemDetailScreen`. Multi-collection picker when item exists in several collections
- [x] Right-click context menus — desktop right-click on collection items (Move/Copy/Remove) in all view modes and on collection cards (Open/Rename/Delete) on home screen. Sort toggle in collection picker dialog
- [x] Copy as Text — template-based text export to clipboard with 10 tokens, smart cleanup, sort options, live preview, and template persistence in SharedPreferences
- [x] Export with Personal Data — optional checkbox in export dialog to include user status, dates, notes, and episode progress in `.xcoll`/`.xcollx` files. Backward-compatible import with `user_data` flag
- [x] Full Backup & Restore — one-button ZIP backup of all collections (full export + user data + canvas + images + tier lists), wishlist, and settings. Restore with manifest preview, wishlist dedup, optional settings restore. `BackupService`, Settings → Backup section
- [x] User Profiles — multi-profile system with isolated databases and image caches per profile. Profile picker at startup, profile management in Settings, colored avatar indicators in navigation. Seamless profile switching on Android (ProviderScope restart) and desktop (process restart)

---

## ✅ UI Redesign (completed)

- [x] Design system — AppColors (deep dark palette), AppSpacing, AppTypography (Inter font), AppTheme (centralized dark theme)
- [x] NavigationShell — adaptive: NavigationRail (≥800px) / BottomNavigationBar (<800px)
- [x] Dark theme — forced dark theme applied to all screens via AppTheme
- [x] Reusable widgets — SectionHeader, RatingBadge, ShimmerLoading, MediaPosterCard (replaced PosterCard), DualRatingBadge, CollectionCard (iOS folder style, replaced HeroCollectionCard)
- [x] TMDB Genre caching — tmdb_genres DB table with bilingual support (EN + RU), static seeding via migration v24, auto-resolve numeric IDs
- [x] HomeScreen — CollectionCard with 3+3 cover mosaic, hover dimming, GridView with MaxCrossAxisExtent
- [x] CollectionScreen — refactored into extracted widgets (CollectionFilterBar, CollectionItemsView, CollectionCanvasLayout, CollectionActions)
- [x] SearchScreen — poster grid with MediaPosterCard, shimmer loading
- [x] MediaDetailView — AppColors/AppTypography, poster 100×150, per-media accent colors
- [x] Detail screens — styled fallback AppBars, per-media accent colors
- [x] Settings — adaptive Export/Import buttons
- [x] MediaCard — poster 64×96
- [x] Image caching — eager download on add, magic bytes validation, Windows file lock fix
- [x] StatusChipRow + StatusRibbon — piano-style segmented status bar (icon-only, flat color, full-width), Material icon ribbon on list cards, Material icon badge on poster cards
- [x] Card shadows — replaced flat borders with elevation shadows (elevation 2, Colors.black26)
- [x] Media type labels — colored type name in poster card subtitle (platform · year · Type · genre), MediaTypeLegend widget on AllItemsScreen
- [x] Spacing constants — gridGap (16px), screenPadding (20px), cardTitle/cardSubtitle typography tokens

### 📋 UI Restoration (completed)

- [x] Canvas mode restoration — Board toggle IconButton in AppBar, CanvasView + SteamGridDB/VGMaps panels in unified `ItemDetailScreen`
- [x] Episode Tracker restoration — shared `EpisodeTrackerSection` widget with `accentColor`, used for TV Show and Animation (tvShow source) in `ItemDetailScreen`
- [x] Activity Dates restoration — inline compact horizontal `Wrap` under My Rating with editable Started/Completed date chips
- [x] Search refactoring — pluggable SearchSource/SearchFilter architecture, Browse/Search mode, source dropdown, filter bar, BrowseGrid, in-collection markers, consistent card sizes
- [x] Unified Search — single `fetch()` method replaces separate browse/search. Text search + filters work simultaneously. Sort disabled during search for APIs that don't support it (TMDB, IGDB)
- [x] **[Experimental]** Type-to-Filter overlay — desktop keyboard-driven client-side filtering on AllItems, Home, Collection, Search, Wishlist screens
- [x] VNDB Integration — Visual novels as 5th media type via VNDB API (public, no auth). VisualNovel model, VndbApi client (search, browse, getById, tags), VndbSource (genre filter by tags, 3 sort modes), VnDetailsSheet, DB migration v23 (visual_novels_cache, vndb_tags tables), export/import support, VNDB attribution in Credits
- [x] AniList Manga Integration — Manga as 6th media type via AniList GraphQL API (public, no auth, 90 req/min). Manga model, AniListApi client (searchManga, browseManga, getMangaById, getMangaByIds with batch pagination), AnilistMangaSource (genre + format filters, 3 sort modes), MangaDetailsSheet, DB migration v25 (manga_cache table), MangaDao, export/import support, AniList attribution in Credits. Full canvas, collection, and All Items support
- [x] Keyboard shortcuts — global (Ctrl+1..6 tabs, Ctrl+Tab cycle, Escape/Alt+Left back, Ctrl+F search, F5 refresh, F1 help) and per-screen shortcuts (Ctrl+N create, Delete/F2 on focused items, Ctrl+E export, Alt+0..5 rating). F1 contextual help dialog, tooltip hints, focus tracking on cards. Desktop-only, mobile-safe
- [x] Cross-platform gamepad — Windows + Linux + Android handheld support. GamepadMapping abstraction, normalized keys, LB/RB tabs, LT/RT filters, D-pad content nav, Y = context menu. FocusTraversalGroup, auto-focus on tab switch
- [x] Search source grouping — `SearchSource.groupId`/`groupName`/`groupIcon` for visual grouping in SourceDropdown. Grouped popup with section headers and dividers. `groupedSearchSources` helper auto-groups from registry order
- [ ] AniList Anime Integration — Anime model + API methods ready (browseAnime, getAnimeById, getAnimeByIds), AniListAnimeSource + filters ready but dormant. Pending: anime_cache DB table, AnimeDao, AnimeDetailsSheet, browse_grid/search_screen integration

---

## 📋 Future Plans

### RetroAchievements Integration

Connect your retro game library with RetroAchievements:
- [x] **Import RA library** — fetch played games with achievement progress, match to IGDB, add to collection with platform mapping (30+ consoles), status from awards (mastered/beaten → completed), unmatched games → Wishlist
- [x] **Achievement tracker system** — universal tracker tables (profiles, game data, achievements), RA achievements section in game detail card with progress bars, award badges, recent unlocks and upcoming achievements with badge icons. Lazy loading per-game from `GetGameInfoAndUserProgress` API
- [ ] Link games by ROM hash
- [ ] Filter/sort collections by RA completion percentage or award status
- [ ] Quick Sync button for incremental RA progress updates
- [ ] RA profile card in Settings with sync controls

### New Data Sources

- [x] **Steam** — import your Steam library with playtime tracking, IGDB matching, and wishlist fallback for unfound games
- [ ] **Fantlab** — Russian book/fiction database for sci-fi, fantasy, and literature
- [ ] **Comic Vine** — comics and graphic novels database
- [ ] **Mustapp** — import watch history and ratings from Mustapp

### Online Features

- [x] Browse Online Collections — download pre-built collections from `tonkatsu-collections` GitHub repository (Settings > Import)
- Cloud sync between devices
- Public collection marketplace
- Follow other collectors
- Collection ratings and reviews

### Additional Platforms

- [x] Android support (Lite — collections, search, details, no Canvas)
- [ ] macOS support
- [x] Linux support

---

## Contributing

This project is in active development. Feature requests and contributions are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
