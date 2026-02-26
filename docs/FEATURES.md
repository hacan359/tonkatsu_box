[← Back to README](../README.md)

# Features

## 🎨 Dark Theme & Design System

The app uses a forced dark theme (ThemeMode.dark) with a cinematic design system:

- **AppColors** — deep dark palette (#0A0A0A background), brand accent (#EF7B44 orange) for UI elements, distinct accent per media type (indigo games, orange movies, lime TV shows, purple animation), rating colors (green/yellow/red)
- **AppTypography** — Inter font with 8 text styles (h1–caption, posterTitle, posterSubtitle), negative letter-spacing on headings
- **AppSpacing** — standardized spacing (4–32px), border radii (4–20px), poster aspect ratio (2:3), grid column counts
- **AppTheme** — centralized ThemeData with styled AppBar, Card, Input, Dialog, BottomSheet, Chip, Button, NavigationRail, TabBar
- **Adaptive navigation** — NavigationRail sidebar on desktop (≥800px), BottomNavigationBar on mobile (<800px), 5 tabs: Home, Collections, Wishlist, Search, Settings. Logo 48×48 above NavigationRail (desktop)
- **Breadcrumb Navigation** — automatic breadcrumb trail via `BreadcrumbScope` InheritedWidget + `AutoBreadcrumbAppBar`. Height 44px, chevron_right separators (14px, 50% alpha), hover pill effect, last crumb w600/textPrimary, overflow ellipsis (300/180px), mobile collapse (>2 crumbs → first…last), mobile back button, gamepad support, optional `accentColor` border-bottom. Tab root scope from NavigationShell, screen/push scopes from each screen

<details>
<summary><b>UI Components</b></summary>

- **MediaPosterCard** — unified vertical 2:3 poster card with 3 variants: grid (hover animation, dual rating badge, collection checkmark, status Material icon badge, platform label for games), compact (smaller sizes for landscape), canvas (colored border by media type, no hover)
- **DualRatingBadge** — dual rating display `★ 8 / 7.5` (user rating + API rating) on poster cards and list items. Modes: badge (dark overlay on poster), compact (smaller), inline (no background, for list tiles)
- **HeroCollectionCard** — large gradient collection card with progress bar and stats
- **ShimmerLoading** — animated shimmer placeholders (ShimmerBox, ShimmerPosterCard, ShimmerListTile)

</details>

## 📱 Platforms

| Platform | Features |
|----------|----------|
| **Windows** | Full version: Board, VGMaps Browser, SteamGridDB panel, all features |
| **Linux** | Full version: same as Windows except VGMaps Browser (no WebView) |
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
- **Move to Collection** — move items between collections or to/from uncategorized via PopupMenuButton on detail screens and collection tiles. Prompts to delete the source collection when it becomes empty

### Collection Sorting

Sort items within a collection:
- **Date Added** (default) — newest items first
- **Status** — active items first: In Progress → Planned → Not Started → Completed → Dropped
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
- **Per-tab API key checks** — each tab independently checks its required API key (IGDB for Games, TMDB for Movies/TV/Animation); missing key shows "Go to Settings" button
- **Smart error handling** — network errors (connection/timeout/socket) show "No internet connection" with retry; API errors show the error message with retry

### Discover Feed

When the search field is empty, a curated Discover feed is shown with horizontal poster rows:

- **Trending** — interleaved trending movies and TV shows
- **Top Rated Movies** — highest-rated movies from TMDB
- **Popular TV Shows** — currently popular TV shows
- **Upcoming** — upcoming movie releases
- **Anime** — popular animated TV shows
- **Top Rated TV Shows** — highest-rated TV shows
- **Customize** — bottom sheet to toggle sections on/off and hide items already in collections
- **Desktop scroll arrows** — left/right arrow buttons on hover for horizontal lists (width >= 600px)
- **Mouse wheel scroll** — vertical mouse wheel events converted to horizontal scroll

Tap any poster to view details with genre chips, overview, and "Add to Collection" button.

## 📊 Progress Tracking

Track status for each item in your collection:

| Status | Icon | Description |
|--------|------|-------------|
| Not Started | `radio_button_unchecked` | Default status |
| In Progress | `play_arrow_rounded` | Currently playing/watching |
| Completed | `check_circle` | Finished |
| Dropped | `pause_circle_filled` | Abandoned |
| Planned | `bookmark` | Want to play/watch |

Status display varies by context: "piano-style" segmented bar on detail screens (full-width, icon-only colored segments with tooltips), diagonal icon ribbon on list cards, icon badge on grid poster cards.

### Episode Tracker (TV Shows & Animated Series)

Track viewing progress at the episode level:
- Episode progress bar with watched/total count
- Expandable seasons with per-episode checkboxes
- Eager preloading of seasons and episodes on add (offline-ready)
- Bulk "Mark all" / "Unmark all" per season
- Auto-status transitions: first episode → In Progress, all episodes → Completed, uncheck all → Not Started
- Auto-date tracking: `started_at` set on first watch, `completed_at` set on all watched, dates cleared on reset
- Reverse transitions: unchecking from Completed → In Progress, unchecking all → Not Started
- On-demand TMDB detail fetch when `totalEpisodes`/`totalSeasons` missing from cache

### Activity Dates

Displayed as a compact horizontal `Wrap` row directly under My Rating (always visible, not collapsed):

- **Added** — auto-set when item is added (read-only)
- **Started** — auto-set on status change to In Progress; editable via DatePicker (tap the date chip)
- **Completed** — auto-set on status change to Completed; editable via DatePicker (tap the date chip)
- **Last Activity** — auto-updated on any status change (read-only, hidden when null)

### User Rating

Rate any item 1–10 with clickable stars. Tap again to clear. Collections can be sorted by rating.

### Comments & Reviews

- **Author's Review** — visible to everyone who imports your collection
- **My Notes** — private, not included in export

## 📋 Detail Screens

Tap any item to see full details. Screens have one or two tabs:

**Details tab** — poster with source badge, info chips, description, status bar (piano-style segments), star rating, inline activity dates, notes/review

**Board tab** — personal board for the item (hidden for uncategorized items)

**Uncategorized banner** — when an item has no collection, an info banner appears in the "Activity & Progress" section explaining that Board and episode tracking require a collection, with an "Add to Collection" action button. For TV shows and animated series, a simple "X seasons • Y ep" text line replaces the full episode tracker

**Actions menu** (PopupMenuButton): "Move to Collection" and "Remove"

### Recommendations & Reviews (Movies/TV Shows)

Displayed below Activity & Progress section (always visible, not collapsed):

- **Similar Movies / TV Shows** — horizontal poster row from TMDB `/similar` endpoint. Tap to view details with "Add to Collection" button
- **TMDB Reviews** — expandable review cards with author name, rating badge, date, and content preview (3-line truncated, tap to expand)
- **Toggle** — show/hide recommendations in Settings

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
A subtle gamepad pattern (`background_tile.png`) is repeated across the entire app via `PageTransitionsTheme`. Each route is wrapped in an opaque `DecoratedBox` with the tile at 3% opacity and 1.5x scale over the dark background (`_OpaquePageTransitionsBuilder`). This prevents content bleed-through during route transitions while giving all screens a consistent textured look.

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
- **FAB** — quick add via floating action button, opens full-page form with breadcrumb navigation
- **Full-page form** — add/edit items on a dedicated screen (not popup), with title validation (min 2 chars), media type chips (no checkmark overlap), and optional note field

## 📤 Sharing

### Light Export (`.xcoll`)
Metadata + element IDs. Tiny file size. Recipients fetch data from APIs on import.

### Full Export (`.xcollx`)
Everything: board data, base64 covers, embedded media data (Game/Movie/TvShow/TvSeason/TvEpisode), all episodes. Fully self-contained — import without internet.

### Import
Imported collections are fully editable — they behave the same as your own collections.

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
- **Resize** — drag bottom-right handle (min 50×50, max 5000×5000)
- **Z-index** — Bring to Front / Send to Back

</details>

<details>
<summary><b>Connections</b></summary>

Draw visual lines between any two board elements:
- Three styles: solid, dashed, arrow
- 8 colors (gray, red, orange, yellow, green, blue, purple, black)
- Optional text labels at midpoint
- Edge anchoring — lines attach to the nearest edge center (top/bottom/left/right)
- Rendered on top of items (click-through via IgnorePointer)
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
- Access via the **Board** toggle button in the AppBar on any detail screen
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
- Content language setting (Russian / English) — configurable in Settings
- Genre caching in SQLite (DB-first strategy, auto-cleared on language change)
- Season/episode data with lazy loading

### SteamGridDB (Artwork)
- High-quality game artwork: grids, heroes, logos, icons
- Side panel for adding images to boards
- Debug panel for testing (dev builds only)

## 🌐 Localization

Full English and Russian localization with runtime language switching:

- **App Language** — switchable in Settings via SegmentedButton (English / Русский); persisted across sessions
- **521 localized strings** — all UI text: navigation, screens, dialogs, buttons, tooltips, error messages, empty states
- **ICU plurals** — Russian plural forms (`=0`, `=1`, `few`, `other`) for item counts, episode counts, etc.
- **Context-aware status labels** — "Playing" (games) vs "Watching" (movies/TV) adapts to both language and media type
- **Content Language** — TMDB content language (movie/show metadata) is independent of app UI language

> [!NOTE]
> App Language controls all UI text. Content Language (in Settings → Credentials) controls the language of movie/TV show data fetched from TMDB.

## ⚙️ Settings

Settings is organized as a hub with an inline author name field, 4 sub-screens, and an About section. All screens support **compact mode** (responsive layout for screens < 600px width).

Built with 5 reusable widgets: `SettingsSection`, `SettingsRow`, `SettingsNavRow`, `StatusDot`, `InlineTextField`.

- **App Language** — switch between English and Russian via SegmentedButton
- **Author name** — configurable default author for new collections (editable inline via tap-to-edit field)
- **Inline editing** — API keys and author name use `InlineTextField` (tap to edit, blur/Enter to save, no dialogs)
- **Status indicators** — `StatusDot` shows connection status, API key presence with color-coded icons
- **Gamepad support** — all inline fields support D-pad navigation and A-button activation

| Screen | Description |
|--------|-------------|
| **Credentials** | IGDB, TMDB, SteamGridDB API keys via inline fields; TMDB content language (Russian/English); connection status with StatusDot; Verify/Refresh buttons; "Test" buttons for TMDB and SteamGridDB API key validation; auto-sync platforms on IGDB verify |
| **Cache** | Image caching toggle, folder, stats, clear |
| **Database** | Config export/import (.json), Reset Database with confirmation |
| **Debug** | SteamGridDB, Image Debug, Gamepad (dev only) |
| **Trakt Import** | Offline import from Trakt.tv ZIP data export |
| **Credits** | API provider attribution (TMDB mandatory, IGDB, SteamGridDB) with SVG logos, external links, Open Source section with MIT license info and Flutter `showLicensePage()` |

> [!WARNING]
> **Reset Database** clears all collections, items, and board data. API keys and settings are preserved. This action cannot be undone.

### Trakt.tv ZIP Import

Import your data from a Trakt.tv offline export (ZIP archive) without OAuth or API access:

- **File picker** — select the ZIP file exported from trakt.tv/users/YOU/data
- **ZIP validation** — verifies archive structure, extracts username and content counts
- **Preview** — shows username, watched movies/shows, rated movies/shows, watchlist count before importing
- **Import options** — checkboxes for watched items, ratings, and watchlist (all enabled by default)
- **Target collection** — create a new collection or import into an existing one
- **Watched items** — movies and TV shows added as completed with `completedAt` date from Trakt
- **Ratings** — Trakt ratings (1–10) applied as `userRating` (only if no existing rating)
- **Watchlist** — items added as `planned` status or to Wishlist if no TMDB match
- **Episode tracking** — watched episodes imported into the episode tracker
- **Animation detection** — movies/shows with Animation genre automatically categorized as `MediaType.animation`
- **Conflict resolution** — existing items updated only when Trakt status is "higher" (completed > inProgress > planned); `dropped` status is never overwritten
- **Progress dialog** — real-time progress with stage description, item counter, and linear progress bar
- **TMDB integration** — each Trakt item is fetched from TMDB by `ids.tmdb` for full metadata and caching

## 🔄 Update Checker

On app launch, queries the GitHub Releases API for the latest version. Shows a dismissible banner at the bottom of the screen (below content, above navigation bar on mobile) when a newer version is available.

- **Semver comparison** — compares major.minor.patch
- **24-hour throttle** — caches result in SharedPreferences; skips API call if checked within the last 24 hours
- **Silent errors** — network failures are swallowed; banner simply doesn't appear
- **Dismiss** — close button hides the banner until next app launch
- **Update button** — opens the GitHub release page in the default browser

## 📴 Offline Mode

After initial setup, most features work offline: browse collections, update status, add comments. Only search requires internet.

### Image Caching

When enabled, media images are downloaded locally for offline access:
- **Auto-download** on view, **eager caching** on add from search
- **Validation** — JPEG/PNG/WebP magic bytes; empty/corrupt files rejected
- **Fallback** — three layers: service validation → sync guard → `errorBuilder`
- **Board images** cached via FNV-1a hash of URL
- **Custom folder**, cache stats, and clear in Settings
