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
- [x] View Mode Persistence — grid/list toggle saved per-collection in SharedPreferences
- [x] Animation Tab — 4th search tab combining animated movies and TV shows from TMDB (genre Animation, ID=16). MediaType.animation enum, AnimationSource discriminator (movie=0, tvShow=1), adaptive animation config in unified `ItemDetailScreen`, purple accent color, filter chip in collections, canvas support
- [x] Legacy Removal — removed CollectionGame/GameStatus, collectionGamesNotifierProvider, v1 .rcoll format, 'playing' status mapping. DB migration v14. Unified on CollectionItem/ItemStatus only
- [x] User Rating — userRating field (1-10) on CollectionItem, DB migration v15, StarRatingBar widget (10 clickable stars), My Rating section on detail screens, sort by rating. Author's Comment renamed to Author's Review with description subtitle
- [x] Unified MediaPosterCard — single vertical poster card with 3 variants (grid/compact/canvas). DualRatingBadge (`★ 8 / 7.5`), enhanced list tiles (description, inline rating, user notes). Replaced 7 card widgets, deleted ~3600 lines of dead code
- [x] Breadcrumb Navigation — `BreadcrumbScope` InheritedWidget + `AutoBreadcrumbAppBar` on all 17 screens. Visual redesign: height 44px, chevron_right separators, hover pill effect, mobile collapse/back button, overflow ellipsis, gamepad support, `accentColor`. Tab root scope in NavigationShell, eliminated `collectionName` data coupling from detail screens
- [x] Settings Restructuring — monolithic SettingsScreen (~1118 lines) split into hub + 4 sub-screens: CredentialsScreen, CacheScreen, DatabaseScreen, DebugHubScreen. Debug screens use breadcrumb navigation
- [x] Settings Redesign — dual-layout (mobile iOS-style flat list + desktop sidebar+content panel). New widgets: SettingsGroup, SettingsTile, SettingsSidebar. Content widgets extracted from Screen files for reuse across layouts
- [x] Move to Collection — move items between collections or to/from uncategorized. DB `updateItemCollectionId`, shared `CollectionPickerDialog`, PopupMenuButton on detail screens and collection tiles. Board tab hidden for uncategorized items
- [x] Multi-platform Games — same game with different platforms (SNES, GBA, etc.) in one collection with independent progress/rating/notes. DB migration v18: UNIQUE index with `COALESCE(platform_id, -1)`. Canvas sync via `collectionItemId`. Platform filter chips on Home and CollectionScreen. Platform badge on poster cards
- [x] Wishlist — quick notes for deferred content search. WishlistItem model, DB migration v19 (wishlist table), WishlistRepository, WishlistNotifier (AsyncNotifierProvider), WishlistScreen with FAB/popup menu/filter/clear resolved, AddWishlistDialog with optional media type hint, 5th navigation tab with badge (active count), tap-to-search integration with SearchScreen(initialQuery)
- [x] Trakt.tv ZIP Import — offline import from Trakt data export (ZIP archive). TraktZipImportService with validateZip/importFromZip, TraktImportScreen with file picker/preview/options/progress dialog. Watched movies/shows → collection items (completed), ratings → userRating (if null), watchlist → planned/wishlist, episodes → episode tracker. Animation detection via TMDB genres. Conflict resolution (status hierarchy, dropped never overwritten). `archive` package for cross-platform ZIP extraction
- [x] i18n Localization (EN/RU) — Flutter `gen_l10n` with 521 ARB keys, ICU plural forms for Russian, runtime language switcher in Settings, localized enum labels (ItemStatus, MediaType, CollectionSortMode, SearchSortField), `AppStrings` removed

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

### 📋 UI Restoration (completed)

- [x] Canvas mode restoration — Board toggle IconButton in AppBar, CanvasView + SteamGridDB/VGMaps panels in unified `ItemDetailScreen`
- [x] Episode Tracker restoration — shared `EpisodeTrackerSection` widget with `accentColor`, used for TV Show and Animation (tvShow source) in `ItemDetailScreen`
- [x] Activity Dates restoration — inline compact horizontal `Wrap` under My Rating with editable Started/Completed date chips
- [x] Search refactoring — pluggable SearchSource/SearchFilter architecture, Browse/Search mode, source dropdown, filter bar, BrowseGrid, in-collection markers, consistent card sizes
- [x] VNDB Integration — Visual novels as 5th media type via VNDB API (public, no auth). VisualNovel model, VndbApi client (search, browse, getById, tags), VndbSource (genre filter by tags, 3 sort modes), VnDetailsSheet, DB migration v23 (visual_novels_cache, vndb_tags tables), export/import support, VNDB attribution in Credits

---

## 📋 Future Plans

### RetroAchievements Integration

Connect your ROM library with RetroAchievements:
- Link games by ROM hash
- View available achievements
- Track your unlocked achievements

### Online Features

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
