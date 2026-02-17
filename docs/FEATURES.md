# Features

## Dark Theme

The app uses a forced dark theme (ThemeMode.dark) with a cinematic design system:
- **AppColors** — deep dark palette (#0A0A0A background), rating colors (green/yellow/red), accent colors per media type
- **AppTypography** — Inter font with 8 text styles (h1–caption, posterTitle, posterSubtitle), negative letter-spacing on headings
- **AppSpacing** — standardized spacing (4–32px), border radii (4–20px), poster aspect ratio (2:3), grid column counts
- **AppTheme** — centralized ThemeData with styled AppBar, Card, Input, Dialog, BottomSheet, Chip, Button, NavigationRail, TabBar
- **Adaptive navigation** — NavigationRail sidebar on desktop (≥800px), BottomNavigationBar on mobile (<800px), 4 tabs: Home, Collections, Search, Settings
- **MediaPosterCard** — unified vertical 2:3 poster card with 3 variants: grid (hover animation, dual rating badge, collection checkmark, status emoji), compact (smaller sizes for landscape), canvas (colored border by media type, no hover)
- **DualRatingBadge** — dual rating display `★ 8 / 7.5` (user rating + API rating) on poster cards and list items. Modes: badge (dark overlay on poster), compact (smaller), inline (no background, for list tiles)
- **HeroCollectionCard** — large gradient collection card with progress bar and stats
- **ShimmerLoading** — animated shimmer placeholders (ShimmerBox, ShimmerPosterCard, ShimmerListTile)

## Platforms

- **Windows** — full version with Board, VGMaps Browser, SteamGridDB panel, all features
- **Android** — full version: collections, search, details, episode tracker, Board (visual board), export/import. VGMaps Browser is not available (requires `webview_windows`). SteamGridDB panel works on all platforms
- Board is available on all platforms (long press opens context menu on mobile instead of right-click)

## Home (All Items)

The Home tab shows all items from all collections in a single grid view:
- **Unified view** — browse all collection items (games, movies, TV shows, animation) in one place
- **Media type filter** — horizontal ChoiceChip row: All, Games, Movies, TV Shows, Animation
- **Rating sort** — toggle chip to sort by user rating (ascending/descending)
- **Default sort** — by date added (newest first); Manual sort mode is not available (falls back to Date Added)
- **Collection name** — each card shows which collection the item belongs to
- **Tap to navigate** — opens the item's detail screen (game/movie/TV show/anime)
- **Pull to refresh** — RefreshIndicator to reload all items
- **Loading/empty/error states** — shimmer loading, "No items yet" message, retry on error

## Collections

Create unlimited collections organized however you want:
- By platform (SNES, PlayStation, PC...)
- By genre (RPGs, Platformers...)
- By theme (Couch co-op, Hidden gems...)
- Personal lists (Backlog, Completed, Favorites...)
- Mix games, movies and TV shows in a single collection
- **Grid mode** — toggle between list and poster grid view; choice is saved per-collection and restored on next open. Grid cards show dual rating badge (`★ 8 / 7.5`), collection checkmark, and status emoji
- **Type filter** — filter items by type (All/Games/Movies/TV Shows/Animation) with item count badges on each chip
- **Search** — filter items by name within a collection

## Universal Search

Search across multiple media types via tabbed interface:

### Games (IGDB)
- 200,000+ games from Atari to PS5
- Covers, genres, descriptions
- Release dates and ratings
- Platform filter for targeted search

### Movies (TMDB)
- Posters, genres, runtime
- Release dates and ratings
- Filter by release year and genres
- Add to any collection with one tap

### TV Shows (TMDB)
- Posters, genres, seasons/episodes
- Show status (Returning, Ended, Cancelled)
- Release dates and ratings
- Filter by first air year and genres
- Add to any collection with one tap
- Animated TV shows (genre Animation) are excluded — see Animation tab

### Animation (TMDB)
- Combined tab for animated movies and animated TV shows from TMDB
- Filters by Animation genre (ID=16) — only animated content appears here
- Movies and TV Shows tabs exclude animated content automatically
- Badge "Movie" or "Series" on each card to distinguish source type
- Add to any collection with one tap (stored with `MediaType.animation` and `AnimationSource` discriminator)
- Adaptive detail screen: movie-like layout for animated films, TV show-like layout (with episode tracker) for animated series

### Sorting
- Sort results by relevance, date, or rating
- Toggle ascending/descending order
- Relevance scoring: exact match > starts with > contains

### Filtering (Movies & TV Shows)
- Filter by release year (1900–2100)
- Filter by genres (multi-select from TMDB genre list)
- Active filter chips displayed below the search bar
- "Clear All" to reset filters

## Visual Identity

### Source Badges
Each item shows its data source via a colored badge:
- **IGDB** — purple badge on game cards and detail screens
- **TMDB** — teal badge on movie/TV show cards and detail screens
- Source logos displayed next to API key fields in Settings

### Media Type Colors
Color-coded visual distinction between media types:
- Games — blue accent
- Movies — red accent
- TV Shows — green accent
- Animation — purple accent
- Applied to board card borders and collection item card backgrounds
- Large tilted semi-transparent background icon (200px, 6% opacity, rotated -17°) on each collection item card as a watermark for quick visual identification

## Progress Tracking

Track status for each item in your collection with context-aware labels:

| Status | Games | Movies/TV Shows |
|--------|-------|-----------------|
| ⬜ Not Started | Not Started | Not Started |
| 🎮/📺 In Progress | In Progress | In Progress |
| ✅ Completed | Completed | Completed |
| ⏸️ On Hold | — | On Hold (TV shows only) |
| ❌ Dropped | Dropped | Dropped |
| 📋 Planned | Planned | Planned |

Status is displayed differently depending on context:
- **Detail screens** — horizontal chip row (`StatusChipRow`) with all available statuses visible; tap to change
- **List view cards** — diagonal ribbon (`StatusRibbon`) in the top-left corner; display only (change status from detail screen)
- **Grid view cards** — emoji badge; display only

View statistics per collection — see your completion rate at a glance.

### Activity Dates

Track when you started, finished, and last interacted with each item:
- **Added** — auto-set when item is added to collection (read-only)
- **Started** — auto-set when status changes to In Progress/Playing/Watching (if not already set); editable via DatePicker
- **Completed** — auto-set when status changes to Completed; editable via DatePicker
- **Last Activity** — auto-updated on any status change (read-only)

Displayed in the `ActivityDatesSection` widget on all detail screens (game, movie, TV show). Dates persist in SQLite and survive export/import.

## Collection Sorting

Sort items within a collection using different modes:
- **Date Added** (default) — newest items first
- **Status** — active items first: In Progress → Planned → Not Started → On Hold → Completed → Dropped
- **Name** — alphabetical A to Z
- **Manual** — custom drag-and-drop order with drag handle icon

Sort mode is saved per collection and persists between sessions. A compact sort selector is displayed between the collection stats and the item list. In Manual mode, a drag handle appears on each item card for reordering via drag-and-drop.

### Episode Tracker (TV Shows & Animated Series)

Track your viewing progress for TV shows and animated series at the episode level:
- **Episode Progress bar** — shows overall watched/total count with a LinearProgressIndicator
- **Season sections** — ExpansionTile for each season with watched count badge
- **Season preloading** — when adding a TV show or animated series to a collection, all seasons are automatically fetched and cached in SQLite (fire-and-forget, non-blocking)
- **Lazy episode loading** — episodes are fetched from TMDB API only when a season is expanded (cached in SQLite for offline access)
- **Per-episode checkboxes** — mark individual episodes as watched/unwatched with CheckboxListTile; watched date displayed in subtitle
- **Bulk actions** — "Mark all" / "Unmark all" button per season to toggle all episodes at once
- **Auto-complete** — when all episodes are watched, the show's status is automatically set to Completed (compares against total episode count from show metadata)

## Detail Screens

Tap any item in a collection to see its full details. All detail screens have two tabs:

**Details tab** — unified layout via `MediaDetailView`:
- Poster (100x150) with source badge (IGDB/TMDB) and per-media accent color
- Type icon and label
- Info chips (year, rating, genres, etc.)
- Inline description (max 4 lines)
- Status chip row (horizontal chips for all available statuses)
- My Rating (10 clickable stars, 1-10 scale, tap again to clear)
- My Notes (private), Author's Review (visible to others when shared)
- Activity & Progress (collapsed ExpansionTile with dates, episode tracker)

**Board tab** — personal board for the item with full board functionality (see Per-Item Board above)

### Game Details
- Source: IGDB
- Info chips: release year, rating, genres
- Status chip row with game-specific labels ("Playing")

### Movie Details
- Source: TMDB
- Info chips: release year, runtime (formatted as "2h 10m"), rating, genres
- Status chip row with "Watching" label

### TV Show Details
- Source: TMDB
- Info chips: first air date, seasons/episodes count, rating, show status (Returning/Ended/Canceled), genres
- Episode tracker section: progress bar, expandable seasons with per-episode checkboxes, bulk mark/unmark, auto-complete
- Status chip row (includes "On Hold" chip)

### Animation Details
- Source: TMDB (animated movies and animated TV shows)
- Adaptive layout based on animation source (`AnimationSource.movie` or `AnimationSource.tvShow`):
  - **Animated movie** — movie-like layout: runtime, rating, genres (no episode tracker)
  - **Animated series** — TV show-like layout: seasons, episodes, episode tracker with per-episode checkboxes
- Purple accent color (`AppColors.animationAccent`)
- Board tab with SteamGridDB panel (all platforms) and VGMaps panel (Windows only)

## User Rating

Rate any item in your collection from 1 to 10 using clickable stars (`StarRatingBar` widget). Tap a star to set the rating, tap the same star again to clear it. Rating is displayed as "X/10" next to the section header. Collections can be sorted by rating (highest first, unrated items at the end).

## Comments & Reviews

Add personal notes and reviews to any item:
- **Author's Review** — Your review of the title. Visible to everyone who imports your collection. Included in export files
- **My Notes** — Private notes only you can see. Not included in export

## Sharing

Export collections in three formats:

### Light Export (`.xcoll`)
- Metadata + element IDs for all media types (games, movies, TV shows)
- Tiny file size, fast export
- Recipients fetch full data from APIs on import

### Full Export (`.xcollx`)
- Everything from light export, plus:
- Board data (viewport, items, connections) including per-item boards
- Base64-encoded cover images (game covers, movie/TV show posters)
- Base64-encoded board images (images added to visual boards)
- Embedded media data (Game/Movie/TvShow/TvSeason/TvEpisode) for fully offline import — no IGDB/TMDB API calls needed
- TV show seasons are preloaded into cache when adding a TV show or animated series to a collection, ensuring they're available for export
- All episodes for each season are included in the export for complete offline access
- Self-contained — recipients can import without internet (all data, covers, board images, seasons, and episodes included)

## Forking

Found a collection you like? Fork it:
- Create your own editable copy
- Add or remove games
- Revert to original anytime

## Board (Visual Board)

Visualize your collection on a free-form board, or create a personal board for each item. Board is available on all platforms (Windows, Android).

> **Note:** In the UI the feature is called "Board". In the codebase, file names and class names still use "canvas" (e.g. `CanvasView`, `canvas_view.dart`, `CanvasItem`).

- **Infinite board** with zoom (0.3x – 3.0x) and pan
- **Drag-and-drop** all elements with real-time visual feedback
- **Dot grid background** for visual alignment
- **Auto-layout** — new board initializes all items (games, movies, TV shows) in a 5-column grid
- **Auto-sync** — adding or removing items in the collection automatically updates the board
- **Media cards** — games, movies and TV shows display as `MediaPosterCard(canvas)` with poster/cover, title, and colored border by media type
- **Persistent viewport** — zoom level and position are saved and restored
- **Center view** and **Reset positions** controls
- **List/Board toggle** — switch between traditional list and visual board via SegmentedButton
- **Board lock** — lock button in AppBar to freeze the board in view-only mode (only for own/fork collections). When locked, all editing is disabled and side panels (SteamGridDB, VGMaps) are closed. Available on collection board and per-item board (detail screens, Board tab only)
- **Context menu** — right-click (desktop) or long press (mobile) to open context menu. On empty space: Add Text/Image/Link. On elements: Edit/Delete/Bring to Front/Send to Back/Connect
- **Text blocks** — add custom text with configurable font size (Small 12/Medium 16/Large 24/Title 32), transparent background
- **Images** — add images from URL or local file (base64 encoded)
- **Links** — add clickable links with custom labels (double-click to open in browser)
- **Resize** — drag the bottom-right handle to resize any element with real-time preview (min 50x50, max 2000x2000). Resize handle is larger on mobile (24px vs 14px) for easier touch input
- **Z-index management** — Bring to Front / Send to Back via context menu
- **Connections** — draw visual lines between any two board elements
  - Three line styles: solid, dashed, arrow
  - 8 color choices (gray, red, orange, yellow, green, blue, purple, black)
  - Optional text labels displayed at the midpoint of the line
  - Create via right-click/long press → Connect, then tap the target element
  - Edit/Delete connections via right-click/long press on the line
  - Connections auto-delete when a connected element is removed
  - Temporary dashed preview line while creating a connection
- **SteamGridDB Image Panel** — side panel for browsing and adding SteamGridDB images to board (available on all platforms)
  - Search games by name (auto-fills from collection name)
  - Browse 4 image types: Grids (box art), Heroes (banners), Logos, Icons
  - Click any thumbnail to add it to the board center (scaled to max 300px width)
  - In-memory cache for API results (no re-fetching on tab switch)
  - Toggle via toolbar button or right-click/long press "Find images..."
  - Warning when SteamGridDB API key is not configured
- **VGMaps Browser Panel** — side panel with embedded WebView2 browser for vgmaps.de (**Windows only** — requires `webview_windows`, hidden on other platforms via `kVgMapsEnabled`)
  - Navigate vgmaps.de directly inside the app (back/forward/home/reload)
  - Search games by name via built-in search field
  - Right-click any image on vgmaps.de to capture it
  - Preview captured image with dimensions in the bottom bar
  - Click "Add to Board" to place the map image on the board (scaled to max 400px width)
  - Toggle via toolbar button or right-click "Browse maps..."
  - Mutually exclusive with SteamGridDB panel (opening one closes the other)

### Per-Item Board
Each game, movie, or TV show in a collection has its own personal board:
- Access via the **Board** tab on any detail screen (game/movie/TV show)
- Auto-initialized with the item's media card (game cover, movie poster, etc.)
- Full board functionality: text, images, links, connections, SteamGridDB panel (all platforms) and VGMaps panel (Windows only)
- Completely isolated from the collection board — items don't leak between boards
- Separate viewport (zoom/position) saved per item

## TMDB Integration

Access movie and TV show data from The Movie Database:
- Search movies and TV shows by name
- View details: poster, genres, rating, runtime/seasons
- Cache results locally in SQLite for offline access
- Add movies and TV shows to any collection
- **Genre caching** — TMDB genre lists are cached in `tmdb_genres` table (DB-first strategy: load from DB, fallback to API). Genres are preloaded on app start when TMDB API key is configured. Numeric genre IDs in search results are resolved to human-readable names before saving to DB. Old cached items with numeric IDs are auto-resolved when loaded from collections

## SteamGridDB Integration

Access high-quality game artwork from SteamGridDB:
- Search games by name
- Browse grid images (box art)
- Browse hero images (banners)
- Browse logos and icons
- Add images directly to board from the side panel
- Debug panel for testing API endpoints (dev builds only)

## Configuration Management

### Export / Import Config
Export your API keys and settings to a JSON file and import them on another machine:
- **Export Config** — saves all 7 settings keys (IGDB, SteamGridDB, TMDB) to a `.json` file via file dialog
- **Import Config** — loads settings from a `.json` file, validates format and version, updates API clients immediately
- Config file includes a version marker for forward compatibility

### Reset Database
Clear all application data while preserving your API keys and settings:
- **Reset Database** button in the Danger Zone section of Settings
- Confirmation dialog prevents accidental data loss
- Clears all 14 SQLite tables (collections, games, movies, TV shows, board, episodes) in a single transaction
- SharedPreferences (API keys, tokens) are preserved

## Offline Mode

After initial setup, most features work offline:
- Browse your collections
- Update play status
- Add comments

Only searching for new games requires internet.

### Image Caching

When enabled in Settings, media images (game covers, movie posters, TV show posters, board URL images) are downloaded locally for offline access:
- **Toggle** — enable/disable image caching in Settings → Image Cache
- **Auto-download** — images are automatically saved to local storage when viewed with caching enabled
- **Eager caching** — cover images are downloaded immediately when adding items to collections from search
- **Validation** — downloaded files are validated by JPEG/PNG/WebP magic bytes; invalid files are deleted
- **Fallback** — if cache is cleared or a file is missing, images load from the network and re-download in the background
- **Board images** — URL images added to boards are also cached to disk (using FNV-1a hash of URL as cache key)
- **Custom folder** — choose where cached images are stored via file picker
- **Cache stats** — view file count and total size in Settings
- **Clear cache** — delete all locally saved images with one tap
- Covers collection thumbnails, detail screens, board cards, and board URL images
