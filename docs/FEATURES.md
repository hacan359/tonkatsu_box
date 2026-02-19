[← Back to README](../README.md)

# Features

## 🎨 Dark Theme & Design System

The app uses a forced dark theme (ThemeMode.dark) with a cinematic design system:

- **AppColors** — deep dark palette (#0A0A0A background), rating colors (green/yellow/red), accent colors per media type
- **AppTypography** — Inter font with 8 text styles (h1–caption, posterTitle, posterSubtitle), negative letter-spacing on headings
- **AppSpacing** — standardized spacing (4–32px), border radii (4–20px), poster aspect ratio (2:3), grid column counts
- **AppTheme** — centralized ThemeData with styled AppBar, Card, Input, Dialog, BottomSheet, Chip, Button, NavigationRail, TabBar
- **Adaptive navigation** — NavigationRail sidebar on desktop (≥800px), BottomNavigationBar on mobile (<800px), 5 tabs: Home, Collections, Wishlist, Search, Settings. Logo 48×48 above NavigationRail (desktop)
- **BreadcrumbAppBar** — unified navigation breadcrumbs on all screens: logo 20×20 + `›` separators + clickable crumbs. Last crumb is bold (w600), non-last crumbs are clickable and navigate back. Supports TabBar (bottom) and action buttons

<details>
<summary><b>UI Components</b></summary>

- **MediaPosterCard** — unified vertical 2:3 poster card with 3 variants: grid (hover animation, dual rating badge, collection checkmark, status emoji, platform label for games), compact (smaller sizes for landscape), canvas (colored border by media type, no hover)
- **DualRatingBadge** — dual rating display `★ 8 / 7.5` (user rating + API rating) on poster cards and list items. Modes: badge (dark overlay on poster), compact (smaller), inline (no background, for list tiles)
- **HeroCollectionCard** — large gradient collection card with progress bar and stats
- **ShimmerLoading** — animated shimmer placeholders (ShimmerBox, ShimmerPosterCard, ShimmerListTile)

</details>

## 📱 Platforms

| Platform | Features |
|----------|----------|
| **Windows** | Full version: Board, VGMaps Browser, SteamGridDB panel, all features |
| **Android** | Full version: collections, search, details, episode tracker, Board, export/import |

> [!NOTE]
> VGMaps Browser requires `webview_windows` and is only available on Windows. SteamGridDB panel works on all platforms. Board uses long press for context menu on mobile instead of right-click.

## 🏠 Home (All Items)

The Home tab shows all items from all collections in a single grid view:

- **Unified view** — browse all collection items (games, movies, TV shows, animation) in one place
- **Media type filter** — horizontal ChoiceChip row: All, Games, Movies, TV Shows, Animation
- **Platform filter** — when "Games" is selected, a second row of ChoiceChips shows available platforms (All + SNES, GBA, etc.). Resets on media type change
- **Rating sort** — toggle chip to sort by user rating (ascending/descending)
- **Default sort** — by date added (newest first)
- **Collection name** — each card shows which collection the item belongs to
- **Tap to navigate** — opens the item's detail screen
- **Pull to refresh** — RefreshIndicator to reload all items
- **Loading/empty/error states** — shimmer loading, "No items yet" message, retry on error

## 📦 Collections

Create unlimited collections organized however you want:

- By platform (SNES, PlayStation, PC...), genre (RPGs, Platformers...), theme (Couch co-op, Hidden gems...), or personal lists (Backlog, Completed, Favorites...)
- Mix games, movies and TV shows in a single collection
- **Multi-platform games** — add the same game with different platforms (e.g. Castlevania for SNES and GBA) with independent progress, rating, and notes. Platform badge shown on poster cards
- **Grid mode** — toggle between list and poster grid view; choice is saved per-collection. Grid cards show dual rating badge (`★ 8 / 7.5`), collection checkmark, and status emoji
- **Type filter** — filter items by type (All/Games/Movies/TV Shows/Animation) with item count badges
- **Platform filter** — when "Games" is selected, a second row of ChoiceChips shows platforms from current collection items. Resets when switching media types
- **Search** — filter items by name within a collection
- **Move to Collection** — move items between collections or to/from uncategorized via PopupMenuButton on detail screens and collection tiles

### Collection Sorting

Sort items within a collection:
- **Date Added** (default) — newest items first
- **Status** — active items first: In Progress → Planned → Not Started → On Hold → Completed → Dropped
- **Name** — alphabetical A to Z
- **Rating** — highest user rating first, unrated at the end
- **Manual** — custom drag-and-drop order with drag handle icon

Sort mode is saved per collection and persists between sessions.

## 🔍 Universal Search

Search across multiple media types via tabbed interface:

| Tab | Source | Features |
|-----|--------|----------|
| **Games** | IGDB | 200k+ titles, covers, genres, platform filter |
| **Movies** | TMDB | Posters, genres, runtime, year/genre filter |
| **TV Shows** | TMDB | Seasons/episodes, show status, year/genre filter |
| **Animation** | TMDB | Combined animated movies + series, "Movie"/"Series" badge |

> [!TIP]
> The Animation tab automatically filters by genre Animation (ID=16). Movies and TV Shows tabs exclude animated content, so there's no overlap.

- **Sorting** — by relevance, date, or rating (toggle ascending/descending)
- **Filtering** — by release year (1900–2100), genres (multi-select), active filter chips

## 📊 Progress Tracking

Track status for each item in your collection:

| Status | Emoji | Description |
|--------|-------|-------------|
| Not Started | ⬜ | Default status |
| In Progress | 🎮 / 📺 | Currently playing/watching |
| Completed | ✅ | Finished |
| On Hold | ⏸️ | Paused (TV shows only) |
| Dropped | ❌ | Abandoned |
| Planned | 📋 | Want to play/watch |

Status display varies by context: horizontal chip row on detail screens, diagonal ribbon on list cards, emoji badge on grid cards.

### Episode Tracker (TV Shows & Animated Series)

Track viewing progress at the episode level:
- Episode progress bar with watched/total count
- Expandable seasons with per-episode checkboxes
- Season preloading on add, lazy episode loading on expand
- Bulk "Mark all" / "Unmark all" per season
- Auto-complete when all episodes are watched

### Activity Dates

- **Added** — auto-set when item is added (read-only)
- **Started** — auto-set on status change to In Progress; editable via DatePicker
- **Completed** — auto-set on status change to Completed; editable via DatePicker
- **Last Activity** — auto-updated on any status change (read-only)

### User Rating

Rate any item 1–10 with clickable stars. Tap again to clear. Collections can be sorted by rating.

### Comments & Reviews

- **Author's Review** — visible to everyone who imports your collection
- **My Notes** — private, not included in export

## 📋 Detail Screens

Tap any item to see full details. Screens have one or two tabs:

**Details tab** — poster with source badge, info chips, description, status chips, star rating, notes/review, activity dates

**Board tab** — personal board for the item (hidden for uncategorized items)

**Actions menu** (PopupMenuButton): "Move to Collection" and "Remove"

<details>
<summary><b>Detail screen variants</b></summary>

- **Game Details** — IGDB source, release year, rating, genres
- **Movie Details** — TMDB source, runtime ("2h 10m"), rating, genres
- **TV Show Details** — TMDB source, seasons/episodes count, show status, episode tracker
- **Animation Details** — adaptive: movie-like for animated films, TV show-like (with episodes) for animated series. Purple accent

</details>

## 🎨 Visual Identity

### Source Badges
- **IGDB** — purple badge on game cards/details
- **TMDB** — teal badge on movie/TV show cards/details

### Media Type Colors
| Type | Color | Accent |
|------|-------|--------|
| Games | Blue | `#64B5F6` |
| Movies | Red | `#EF5350` |
| TV Shows | Green | `#66BB6A` |
| Animation | Purple | `#CE93D8` |

Applied to board card borders, collection item backgrounds, and tilted watermark icons (200px, 6% opacity, rotated -17°).

### Tiled Background
A subtle gamepad pattern (`background_tile.png`) is repeated across the entire app via `MaterialApp.builder`. The tile is rendered at 3% opacity and 1.5x scale over the dark background, giving all screens a consistent textured look without per-screen configuration.

## 📝 Wishlist

Quick notes for content to find later when internet is available:

- **Text notes** — save game/movie/TV show names for later search
- **Optional media type hint** — tag notes as Game, Movie, TV Show, or Animation (ChoiceChip selector)
- **Optional note** — additional context (platform, year, source of recommendation)
- **Tap to search** — opens SearchScreen with pre-filled query and correct media tab
- **Resolve/Unresolve** — mark items as found; resolved items show strikethrough text at 50% opacity, sorted to bottom
- **Filter toggle** — show/hide resolved items
- **Clear resolved** — bulk delete all resolved items with confirmation dialog
- **Badge** — navigation icon shows count of active (unresolved) items
- **Popup menu** — Search, Edit, Mark resolved/Unresolve, Delete per item
- **FAB** — quick add via floating action button

## 📤 Sharing

### Light Export (`.xcoll`)
Metadata + element IDs. Tiny file size. Recipients fetch data from APIs on import.

### Full Export (`.xcollx`)
Everything: board data, base64 covers, embedded media data (Game/Movie/TvShow/TvSeason/TvEpisode), all episodes. Fully self-contained — import without internet.

### Forking
Create your own editable copy of any imported collection. Add or remove items. Revert to original anytime.

## 🎨 Board (Visual Board)

Visualize your collection on a free-form board, or create a personal board for each item.

> [!TIP]
> In the UI the feature is called "Board". In the codebase, file names and class names still use "canvas" (e.g. `CanvasView`, `canvas_view.dart`, `CanvasItem`).

<details>
<summary><b>Board features</b></summary>

- **Infinite board** with zoom (0.3x – 3.0x) and pan
- **Drag-and-drop** all elements with real-time visual feedback
- **Dot grid background** for visual alignment
- **Auto-layout** — 5-column grid for new boards
- **Auto-sync** — adding/removing collection items updates the board
- **Persistent viewport** — zoom and position saved/restored
- **Board lock** — freeze in view-only mode, closes side panels
- **Context menu** — right-click (desktop) or long press (mobile)

</details>

<details>
<summary><b>Board elements</b></summary>

- **Media cards** — poster/cover with title, colored border by media type
- **Text blocks** — configurable font size (Small 12 / Medium 16 / Large 24 / Title 32)
- **Images** — from URL or local file (base64 encoded)
- **Links** — clickable with custom labels (double-click to open)
- **Resize** — drag bottom-right handle (min 50×50, max 2000×2000)
- **Z-index** — Bring to Front / Send to Back

</details>

<details>
<summary><b>Connections</b></summary>

Draw visual lines between any two board elements:
- Three styles: solid, dashed, arrow
- 8 colors (gray, red, orange, yellow, green, blue, purple, black)
- Optional text labels at midpoint
- Create via context menu → Connect → tap target
- Auto-delete when connected element is removed

</details>

<details>
<summary><b>Side panels</b></summary>

**SteamGridDB Image Panel** — search games, browse grids/heroes/logos/icons, click to add to board. In-memory cache.

**VGMaps Browser Panel** — embedded WebView2 for vgmaps.de. Navigate, search, right-click to capture images, add to board. Mutually exclusive with SteamGridDB panel.

> [!NOTE]
> VGMaps Browser is **Windows only** (requires `webview_windows`). SteamGridDB panel works on all platforms.

</details>

### Per-Item Board

Each item in a collection has its own personal board:
- Access via the **Board** tab on any detail screen
- Auto-initialized with the item's media card
- Full board functionality with SteamGridDB and VGMaps panels
- Completely isolated from the collection board
- Separate viewport saved per item

## 🔌 API Integrations

### IGDB (Games)
- 200k+ games from Atari to PS5 via Twitch OAuth
- Covers, genres, descriptions, platforms, ratings

### TMDB (Movies & TV Shows)
- Movies, TV shows, animation from The Movie Database
- Genre caching in SQLite (DB-first strategy)
- Season/episode data with lazy loading

### SteamGridDB (Artwork)
- High-quality game artwork: grids, heroes, logos, icons
- Side panel for adding images to boards
- Debug panel for testing (dev builds only)

## ⚙️ Settings

Settings is organized as a hub with 4 sub-screens:

| Screen | Description |
|--------|-------------|
| **Credentials** | IGDB, TMDB, SteamGridDB API keys |
| **Cache** | Image caching toggle, folder, stats, clear |
| **Database** | Config export/import (.json), Reset Database |
| **Debug** | IGDB Media, SteamGridDB, Gamepad (dev only) |

> [!WARNING]
> **Reset Database** clears all collections, items, and board data. API keys and settings are preserved. This action cannot be undone.

## 📴 Offline Mode

After initial setup, most features work offline: browse collections, update status, add comments. Only search requires internet.

### Image Caching

When enabled, media images are downloaded locally for offline access:
- **Auto-download** on view, **eager caching** on add from search
- **Validation** — JPEG/PNG/WebP magic bytes; empty/corrupt files rejected
- **Fallback** — three layers: service validation → sync guard → `errorBuilder`
- **Board images** cached via FNV-1a hash of URL
- **Custom folder**, cache stats, and clear in Settings
