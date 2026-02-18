[← Back to README](../README.md)

# 🗺️ Roadmap

![Progress](https://img.shields.io/badge/overall_progress-~85%25-brightgreen?style=for-the-badge)

> Approximate completion: **~85%** — Core features, canvas system, media integrations, Android Lite, and UI redesign are done. A few restoration tasks and future plans remain.

---

## ✅ Current Version (v1.0)

- [x] Project setup
- [x] IGDB integration
- [x] Collection management
- [x] Progress tracking
- [x] Import/Export (.xcoll/.xcollx)
- [x] Forking collections
- [x] Comments system
- [x] SteamGridDB integration (API client, debug panel)
- [x] Offline image caching
- [x] Platform logos

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
- [x] Animation Tab — 4th search tab combining animated movies and TV shows from TMDB (genre Animation, ID=16). MediaType.animation enum, AnimationSource discriminator (movie=0, tvShow=1), adaptive AnimeDetailScreen, purple accent color, filter chip in collections, canvas support
- [x] Legacy Removal — removed CollectionGame/GameStatus, collectionGamesNotifierProvider, v1 .rcoll format, 'playing' status mapping. DB migration v14. Unified on CollectionItem/ItemStatus only
- [x] User Rating — userRating field (1-10) on CollectionItem, DB migration v15, StarRatingBar widget (10 clickable stars), My Rating section on detail screens, sort by rating. Author's Comment renamed to Author's Review with description subtitle
- [x] Unified MediaPosterCard — single vertical poster card with 3 variants (grid/compact/canvas). DualRatingBadge (`★ 8 / 7.5`), enhanced list tiles (description, inline rating, user notes). Replaced 7 card widgets, deleted ~3600 lines of dead code
- [x] Breadcrumb Navigation — BreadcrumbAppBar on all screens (logo + `›` separators + clickable crumbs). Logo above NavigationRail on desktop. collectionName parameter on detail screens for full path display
- [x] Settings Restructuring — monolithic SettingsScreen (~1118 lines) split into hub + 4 sub-screens: CredentialsScreen, CacheScreen, DatabaseScreen, DebugHubScreen. Debug screens use breadcrumb navigation
- [x] Move to Collection — move items between collections or to/from uncategorized. DB `updateItemCollectionId`, shared `CollectionPickerDialog`, PopupMenuButton on detail screens and collection tiles. Board tab hidden for uncategorized items

---

## ✅ UI Redesign (completed)

- [x] Design system — AppColors (deep dark palette), AppSpacing, AppTypography (Inter font), AppTheme (centralized dark theme)
- [x] NavigationShell — adaptive: NavigationRail (≥800px) / BottomNavigationBar (<800px)
- [x] Dark theme — forced dark theme applied to all screens via AppTheme
- [x] Reusable widgets — SectionHeader, RatingBadge, ShimmerLoading, MediaPosterCard (replaced PosterCard), DualRatingBadge, HeroCollectionCard
- [x] TMDB Genre caching — tmdb_genres DB table, DB-first loading, auto-resolve numeric IDs
- [x] HomeScreen — HeroCollectionCard for featured collections, shimmer loading
- [x] CollectionScreen — grid mode with MediaPosterCard (dual rating), type filter, name search
- [x] SearchScreen — poster grid with MediaPosterCard, shimmer loading
- [x] MediaDetailView — AppColors/AppTypography, poster 100×150, per-media accent colors
- [x] Detail screens — styled fallback AppBars, per-media accent colors
- [x] Settings — adaptive Export/Import buttons
- [x] MediaCard — poster 64×96
- [x] Image caching — eager download on add, magic bytes validation, Windows file lock fix
- [x] StatusChipRow + StatusRibbon — modern chip-based status selection on detail screens, diagonal ribbon on list cards

### 📋 UI Restoration (remaining)

- [ ] Canvas mode restoration — Grid/Canvas toggle, CanvasView + SteamGridDB/VGMaps panels
- [ ] Episode Tracker restoration — full episode tracker in TV Show detail screen
- [ ] Activity Dates restoration — editable ActivityDatesSection in detail screens
- [ ] Search filters restoration — Platform Filter, Media Filter, Sort Selector

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
- [ ] Linux support

---

## Contributing

This project is in active development. Feature requests and contributions are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
