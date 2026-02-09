# Features

## Collections

Create unlimited collections organized however you want:
- By platform (SNES, PlayStation, PC...)
- By genre (RPGs, Platformers...)
- By theme (Couch co-op, Hidden gems...)
- Personal lists (Backlog, Completed, Favorites...)
- Mix games, movies and TV shows in a single collection

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
- Add to any collection with one tap

### TV Shows (TMDB)
- Posters, genres, seasons/episodes
- Show status (Returning, Ended, Cancelled)
- Release dates and ratings
- Add to any collection with one tap

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
- Applied to canvas card borders and type badges

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

View statistics per collection — see your completion rate at a glance.

### TV Show Progress

Track your viewing progress for TV shows:
- Current season / total seasons
- Current episode / total episodes
- Increment/decrement with +/- buttons
- Format: "S2/5 • E15/50"

## Detail Screens

Tap any item in a collection to see its full details. All detail screens share a unified layout via `MediaDetailView`:
- Compact poster (80x120) with source badge (IGDB/TMDB)
- Type icon and label
- Info chips (year, rating, genres, etc.)
- Inline description (max 4 lines)
- Status dropdown, author comment, personal notes

### Game Details
- Source: IGDB
- Info chips: release year, rating, genres
- Status dropdown with game-specific labels

### Movie Details
- Source: TMDB
- Info chips: release year, runtime (formatted as "2h 10m"), rating, genres
- Status dropdown with "Watching" label

### TV Show Details
- Source: TMDB
- Info chips: first air date, seasons/episodes count, rating, show status (Returning/Ended/Canceled), genres
- Viewing progress section (current season and episode with +/- controls)
- Status dropdown (includes "On Hold")

## Comments

Add personal notes to any item:
- **Author comments** — Visible to everyone who imports your collection
- **Personal comments** — Private notes only you can see

## Sharing

Export any collection as a `.rcoll` file:
- Tiny file size (~500 bytes per 100 games)
- Share via Discord, Telegram, Reddit, email
- Recipients import and get the full collection with covers

## Forking

Found a collection you like? Fork it:
- Create your own editable copy
- Add or remove games
- Revert to original anytime

## Canvas View

Visualize your collection on a free-form canvas:
- **Infinite canvas** with zoom (0.3x – 3.0x) and pan
- **Drag-and-drop** all elements with real-time visual feedback
- **Dot grid background** for visual alignment
- **Auto-layout** — new canvas initializes all items (games, movies, TV shows) in a 5-column grid
- **Auto-sync** — adding or removing items in the collection automatically updates the canvas
- **Media cards** — games, movies and TV shows display as compact cards with poster/cover and title
- **Persistent viewport** — zoom level and position are saved and restored
- **Center view** and **Reset positions** controls
- **List/Canvas toggle** — switch between traditional list and visual canvas via SegmentedButton
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
  - Toggle via FAB button or right-click "Find images..."
  - Warning when SteamGridDB API key is not configured
- **VGMaps Browser Panel** — side panel with embedded WebView2 browser for vgmaps.com
  - Navigate vgmaps.com directly inside the app (back/forward/home/reload)
  - Search games by name via built-in search field
  - Right-click any image on vgmaps.com to capture it
  - Preview captured image with dimensions in the bottom bar
  - Click "Add to Canvas" to place the map image on the canvas (scaled to max 400px width)
  - Toggle via FAB button or right-click "Browse maps..."
  - Mutually exclusive with SteamGridDB panel (opening one closes the other)

## TMDB Integration

Access movie and TV show data from The Movie Database:
- Search movies and TV shows by name
- View details: poster, genres, rating, runtime/seasons
- Cache results locally in SQLite for offline access
- Add movies and TV shows to any collection

## SteamGridDB Integration

Access high-quality game artwork from SteamGridDB:
- Search games by name
- Browse grid images (box art)
- Browse hero images (banners)
- Browse logos and icons
- Add images directly to canvas from the side panel
- Debug panel for testing API endpoints (dev builds only)

## Offline Mode

After initial setup, most features work offline:
- Browse your collections
- Update play status
- Add comments

Only searching for new games requires internet.
