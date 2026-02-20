[← Back to README](../README.md)

# Getting Started

## Requirements

- Windows 10 or 11 (or Android 8+)
- Internet connection (for initial setup and search)
- IGDB API credentials (for game search)
- TMDB API key (optional, for movie/TV show search)

---

## What works without API keys

You can use these features right away — no registration needed:

- **Collections** — create, edit, organize
- **Wishlist** — quick list of items to check out later
- **Import** `.xcoll` / `.xcollx` — share collections with friends
- **Canvas boards** — visual boards with artwork
- **Ratings & notes** — rate and comment on items

> API keys are only needed for **searching** new games, movies & TV shows.

---

## Getting API Keys

Detailed instructions: [docs/guides/API_KEYS.md](guides/API_KEYS.md)

### IGDB (Required — Game search)

> [!IMPORTANT]
> IGDB credentials are **required** for game search to work.

1. Go to [dev.twitch.tv](https://dev.twitch.tv)
2. Log in with Twitch account (create one if needed)
3. Go to **Applications** → **Register Your Application**
4. Fill in:
   - Name: `Tonkatsu Box` (or anything)
   - OAuth Redirect URLs: `http://localhost`
   - Category: `Application Integration`
5. Click **Create**
6. Copy your **Client ID** and generate a **Client Secret**

### TMDB (Recommended — Movies, TV & Anime)

> [!NOTE]
> TMDB is **recommended**. It enables searching for movies, TV shows, and animation.

1. Go to [themoviedb.org](https://www.themoviedb.org)
2. Create an account or log in
3. Go to **Settings** → **API**
4. Request an API key (choose "Developer" type)
5. Copy your **API Key (v3 auth)**

### SteamGridDB (Optional — Game artwork)

> [!NOTE]
> SteamGridDB is **optional**. It provides high-quality game artwork for the canvas board.

1. Go to [steamgriddb.com](https://www.steamgriddb.com)
2. Create an account or log in
3. Go to **Preferences** → **API**
4. Copy your **API Key**

---

## App Structure

| Tab | Description |
|-----|-------------|
| **Main** | All items from all collections. Filter by type, sort by rating. |
| **Collections** | Your collections. Grid or list view per collection. |
| **Wishlist** | Quick list of items to check out later. No API needed. |
| **Search** | Find games, movies & TV shows via API. Add to any collection. |
| **Settings** | API keys, cache, database export/import, debug tools. |

More details: [docs/guides/HOW_IT_WORKS.md](guides/HOW_IT_WORKS.md)

---

## First Launch

On first launch, a **Welcome Wizard** guides you through setup:

1. Overview of what Tonkatsu Box can do
2. How to get API keys
3. App structure and quick start guide
4. Go to Settings to enter your keys

You can revisit the wizard anytime from **Settings → Welcome Guide**.

### Manual setup

1. Start Tonkatsu Box
2. Go to **Settings → Credentials**
3. Enter your IGDB Client ID and Client Secret
4. Click **Verify Connection**
5. Platforms will sync automatically
6. (Optional) Enter your TMDB API Key for movie/TV show search
7. (Optional) Enter your SteamGridDB API Key for game artwork
8. You're ready to create collections!

> [!TIP]
> All API keys can be changed later in **Settings → Credentials**.

---

## Quick Start

### Create a Collection

1. Click **+ New Collection**
2. Enter a name
3. Click **Add Items**
4. Search for a game, movie or TV show
5. Select platform (for games) or tap to add (for movies/TV shows)
6. Done!

### Import a Collection

1. Get a `.xcoll` or `.xcollx` file from someone
2. Click **Import**
3. Select the file
4. Collection appears with all data

> [!TIP]
> `.xcoll` is a light export (metadata only — requires internet to fetch covers and details).
> `.xcollx` is a full export (includes canvas, images, and media data — works offline).

### Share a Collection

1. Open your collection
2. Click **Export**
3. Choose `.xcoll` (light) or `.xcollx` (full)
4. Save the file
5. Share it anywhere!

---

## Guides

- [Welcome — what Tonkatsu Box can do](guides/WELCOME.md)
- [API Keys — detailed setup instructions](guides/API_KEYS.md)
- [How it works — app structure & quick start](guides/HOW_IT_WORKS.md)

---

## Tips

> [!TIP]
> - Use the status tracker to manage your backlog
> - Add comments to remember why you added a game
> - Fork interesting collections and customize them
> - Use the star rating (1-10) to rank your favorites
> - On Android, long-press items for context menus; on Windows, right-click
