# Features

## Dark Theme

The app uses a forced dark theme (ThemeMode.dark) with a cinematic design system:
- **AppColors** — deep dark palette (#0A0A0A background), rating colors (green/yellow/red), accent colors per media type
- **AppTypography** — Inter font with 8 text styles (h1–caption, posterTitle, posterSubtitle), negative letter-spacing on headings
- **AppSpacing** — standardized spacing (4–32px), border radii (4–20px), poster aspect ratio (2:3), grid column counts
- **AppTheme** — centralized ThemeData with styled AppBar, Card, Input, Dialog, BottomSheet, Chip, Button, NavigationRail, TabBar
- **Adaptive navigation** — NavigationRail sidebar on desktop (≥800px), BottomNavigationBar on mobile (<800px)
- **PosterCard** — vertical 2:3 poster card with hover animation, RatingBadge overlay, collection checkmark
- **HeroCollectionCard** — large gradient collection card with progress bar and stats
- **RatingBadge** — color-coded rating badge (green ≥8, yellow ≥6, red <6)
- **ShimmerLoading** — animated shimmer placeholders (ShimmerBox, ShimmerPosterCard, ShimmerListTile)

## Platforms

- **Windows** — full version with Canvas, VGMaps Browser, all features
- **Android** — Lite version: collections, search, details, episode tracker, export/import (no Canvas)

## Collections

Create unlimited collections organized however you want:
- By platform (SNES, PlayStation, PC...)
- By genre (RPGs, Platformers...)
- By theme (Couch co-op, Hidden gems...)
- Personal lists (Backlog, Completed, Favorites...)
- Mix games, movies and TV shows in a single collection
- **Grid mode** — toggle between list and poster grid view; choice is saved per-collection and restored on next open
- **Type filter** — filter items by type (All/Games/Movies/TV Shows/Animation)
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
- Applied to canvas card borders and collection item card backgrounds
- Large tilted semi-transparent background icon (200px, 6% opacity, rotated -17°) on each collection item card as a watermark for quick visual identification

## Progress Tracking

Track status for each item in your collection with context-aware labels:

| Status | Games | Movies/TV Shows |
|--------|-------|-----------------|
| ⬜ Not Started | Not Started | Not Started |
| 🎮/📺 In Progress | Playing | Watching |
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
- **Lazy loading** — episodes are fetched from TMDB API only when a season is expanded (cached in SQLite for offline access)
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
- Status chip row (horizontal chips for all available statuses), author comment, personal notes

**Canvas tab** — personal canvas for the item with full canvas functionality (see Per-Item Canvas above)

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
- Canvas tab with SteamGridDB and VGMaps panels (desktop only)

## Comments

Add personal notes to any item:
- **Author comments** — Visible to everyone who imports your collection
- **Personal comments** — Private notes only you can see

## Sharing

Export collections in three formats:

### Light Export (`.xcoll`)
- Metadata + element IDs for all media types (games, movies, TV shows)
- Tiny file size, fast export
- Recipients fetch full data from APIs on import

### Full Export (`.xcollx`)
- Everything from light export, plus:
- Canvas data (viewport, items, connections) including per-item canvases
- Base64-encoded cover images for offline import
- Self-contained — recipients don't need internet for covers

### Legacy Export (`.rcoll`)
- v1 format with game IDs only
- Supported for import (backward compatibility)
- Share via Discord, Telegram, Reddit, email

## Forking

Found a collection you like? Fork it:
- Create your own editable copy
- Add or remove games
- Revert to original anytime

## Canvas View

Visualize your collection on a free-form canvas, or create a personal canvas for each item:
- **Infinite canvas** with zoom (0.3x – 3.0x) and pan
- **Drag-and-drop** all elements with real-time visual feedback
- **Dot grid background** for visual alignment
- **Auto-layout** — new canvas initializes all items (games, movies, TV shows) in a 5-column grid
- **Auto-sync** — adding or removing items in the collection automatically updates the canvas
- **Media cards** — games, movies and TV shows display as compact cards with poster/cover and title
- **Persistent viewport** — zoom level and position are saved and restored
- **Center view** and **Reset positions** controls
- **List/Canvas toggle** — switch between traditional list and visual canvas via SegmentedButton
- **Canvas lock** — lock button in AppBar to freeze the canvas in view-only mode (only for own/fork collections). When locked, all editing is disabled and side panels (SteamGridDB, VGMaps) are closed. Available on collection canvas and per-item canvas (detail screens, Canvas tab only)
- **Context menu** (right-click) — Add Text/Image/Link on empty space; Edit/Delete/Bring to Front/Send to Back on elements
- **Text blocks** — add custom text with configurable font size (Small 12/Medium 16/Large 24/Title 32), transparent background
- **Images** — add images from URL or local file (base64 encoded)
- **Links** — add clickable links with custom labels (double-click to open in browser)
- **Resize** — drag the bottom-right handle to resize any element with real-time preview (min 50x50, max 2000x2000)
- **Z-index management** — Bring to Front / Send to Back via context menu
- **Connections** — draw visual lines between any two canvas elements
  - Three line styles: solid, dashed, arrow
  - 8 color choices (gray, red, orange, yellow, green, blue, purple, black)
  - Optional text labels displayed at the midpoint of the line
  - Create via right-click → Connect, then click the target element
  - Edit/Delete connections via right-click on the line
  - Connections auto-delete when a connected element is removed
  - Temporary dashed preview line while creating a connection
- **SteamGridDB Image Panel** — side panel for browsing and adding SteamGridDB images to canvas
  - Search games by name (auto-fills from collection name)
  - Browse 4 image types: Grids (box art), Heroes (banners), Logos, Icons
  - Click any thumbnail to add it to the canvas center (scaled to max 300px width)
  - In-memory cache for API results (no re-fetching on tab switch)
  - Toggle via toolbar button or right-click "Find images..."
  - Warning when SteamGridDB API key is not configured
- **VGMaps Browser Panel** — side panel with embedded WebView2 browser for vgmaps.de
  - Navigate vgmaps.de directly inside the app (back/forward/home/reload)
  - Search games by name via built-in search field
  - Right-click any image on vgmaps.de to capture it
  - Preview captured image with dimensions in the bottom bar
  - Click "Add to Canvas" to place the map image on the canvas (scaled to max 400px width)
  - Toggle via toolbar button or right-click "Browse maps..."
  - Mutually exclusive with SteamGridDB panel (opening one closes the other)

### Per-Item Canvas
Each game, movie, or TV show in a collection has its own personal canvas:
- Access via the **Canvas** tab on any detail screen (game/movie/TV show)
- Auto-initialized with the item's media card (game cover, movie poster, etc.)
- Full canvas functionality: text, images, links, connections, SteamGridDB and VGMaps panels
- Completely isolated from the collection canvas — items don't leak between canvases
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
- Add images directly to canvas from the side panel
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
- Clears all 14 SQLite tables (collections, games, movies, TV shows, canvas, episodes) in a single transaction
- SharedPreferences (API keys, tokens) are preserved

## Offline Mode

After initial setup, most features work offline:
- Browse your collections
- Update play status
- Add comments

Only searching for new games requires internet.

### Image Caching

When enabled in Settings, media images (game covers, movie posters, TV show posters, canvas URL images) are downloaded locally for offline access:
- **Toggle** — enable/disable image caching in Settings → Image Cache
- **Auto-download** — images are automatically saved to local storage when viewed with caching enabled
- **Eager caching** — cover images are downloaded immediately when adding items to collections from search
- **Validation** — downloaded files are validated by JPEG/PNG/WebP magic bytes; invalid files are deleted
- **Fallback** — if cache is cleared or a file is missing, images load from the network and re-download in the background
- **Canvas images** — URL images added to canvases are also cached to disk (using FNV-1a hash of URL as cache key)
- **Custom folder** — choose where cached images are stored via file picker
- **Cache stats** — view file count and total size in Settings
- **Clear cache** — delete all locally saved images with one tap
- Covers collection thumbnails, detail screens, canvas cards, and canvas URL images
