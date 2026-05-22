<p align="center">
  <img src="assets/images/logo.png" width="120" alt="Tonkatsu Box">
</p>

<h1 align="center">Tonkatsu Box</h1>

<p align="center">
  <b>Your personal collection manager for games, movies, TV shows, anime, visual novels, and manga</b>
</p>

<p align="center">
  <a href="https://github.com/hacan359/tonkatsu_box/releases/latest"><img src="https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Windows"></a>
  <a href="https://github.com/hacan359/tonkatsu_box/releases/latest"><img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux"></a>
  <a href="https://github.com/hacan359/tonkatsu_box/releases/latest"><img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android"></a>
</p>

<p align="center">
  <a href="https://github.com/hacan359/tonkatsu_box/actions/workflows/test.yml"><img src="https://github.com/hacan359/tonkatsu_box/actions/workflows/test.yml/badge.svg" alt="Tests"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter&logoColor=white" alt="Flutter 3.38+"></a>
  <a href="https://discord.gg/JZVNPF7cS2"><img src="https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white" alt="Discord"></a>
</p>

---

> [!WARNING]
> **This app is in active development.** Updates may include database migrations that change data format. Please **create a backup** before updating (Settings → Backup → Create Backup). Alternatively, you can manually copy the app data folder:
> - **Windows:** `%APPDATA%\Roaming\Tonkatsu Box\Tonkatsu Box`
> - **Linux:** `~/.local/share/tonkatsu_box` (or `$XDG_DATA_HOME/tonkatsu_box`)
> - **Android:** use the built-in backup feature (Settings → Backup)

---

Tonkatsu Box is a free, open-source app to organize your media collections. Search millions of titles from IGDB, TMDB, VNDB, and AniList. Track your progress, rate everything, create visual boards and mood grids, and import your library from Steam, Trakt.tv, RetroAchievements, MyAnimeList, or AniList.

<p align="center">
  <img src="docs/screenshots/mockup_main_all.jpg" width="800" alt="Main screen">
</p>

## Screenshots

| Collections | Collection Grid |
|---|---|
| <img src="docs/screenshots/mockup_collections.jpg" alt="Collections"> | <img src="docs/screenshots/mockup_collection_view.jpg" alt="Collection Grid"> |

| Bulk Selection | Item Details |
|---|---|
| <img src="docs/screenshots/mockup_bulk_selection.jpg" alt="Bulk selection"> | <img src="docs/screenshots/mockup_item_details.jpg" alt="Item Details"> |

| Game Search | Add to Collection |
|---|---|
| <img src="docs/screenshots/mockup_game_search.jpg" alt="Game Search"> | <img src="docs/screenshots/mockup_add_game.jpg" alt="Add to collection"> |

| Settings | Search Sources |
|---|---|
| <img src="docs/screenshots/mockup_settings.jpg" alt="Settings"> | <img src="docs/screenshots/mockup_search_sources.jpg" alt="Search Sources"> |

| Tier List | Mood Grid |
|---|---|
| <img src="docs/screenshots/mockup_tier_list.jpg" alt="Tier List"> | <img src="docs/screenshots/mockup_mood_grid.jpg" alt="Mood grid"> |

## Features

| | |
|---|---|
| **Collections** | Organize by platform, genre, or any way you like. Grid, list, and table views |
| **Wishlist** | Dedicated top-level list for what you want to play, watch, or read next |
| **Search** | IGDB (games), TMDB (movies/TV), AniList (anime & manga), VNDB (visual novels) |
| **Progress Tracking** | Status, ratings 1-10, episode tracking for TV shows and anime |
| **Discord Rich Presence** | Show what you're playing/watching/reading in Discord (desktop) |
| **Visual Boards** | Drag-and-drop canvas with posters, notes, and connections |
| **Tier Lists & Mood Grids** | Rank items into S/A/B/C tiers, or arrange them on a visual N×M board with labels — export either as PNG |
| **Import** | Steam library, Trakt.tv history, RetroAchievements progress, MyAnimeList XML, AniList by username |
| **Kodi Sync** | Push movies, TV shows, and anime to a Kodi media server over JSON-RPC |
| **Export & Share** | .xcoll / .xcollx files with full offline support |
| **Gamepad** | Navigate with Xbox controller (desktop and Android handhelds) |
| **Languages** | English & Russian |

## Download

| Platform | Link |
|----------|------|
| Windows | [**Download .exe**](https://github.com/hacan359/tonkatsu_box/releases/latest) |
| Linux | [**Download .AppImage**](https://github.com/hacan359/tonkatsu_box/releases/latest) |
| Android | [**Download .apk**](https://github.com/hacan359/tonkatsu_box/releases/latest) |

> Linux support is experimental.

## Quick Start

1. **Download and install** from the links above
2. **Launch the app** — Welcome Wizard guides you through setup
3. **Start adding items** from Search, or import ready-made collections

The app works offline after setup. API keys are built-in.

> [Full guide on Wiki](https://github.com/hacan359/tonkatsu_box/wiki/Getting-Started)

## Ready-made Collections

**[Tonkatsu Collections](https://github.com/hacan359/tonkatsu-collections)** — 25,000+ games across 23 platforms, top movies, TV shows & anime. Download `.xcollx` → Import → Done.

## Import Your Data

Already tracking elsewhere? Bring your data:

| | Source | What's imported |
|:-:|--------|-----------------|
| <img src="assets/images/icon_steam_color.png" width="28" alt="Steam"> | **Steam** | Owned games, playtime, last played date |
| <img src="assets/images/icon_trakt_color.png" width="28" alt="Trakt.tv"> | **Trakt.tv** | Watch history, ratings, watchlist, episode progress |
| <img src="assets/images/ra_logo.png" width="28" alt="RetroAchievements"> | **RetroAchievements** | Retro game library, achievement progress, awards |
| <img src="assets/images/icon_myanimelist_color.png" width="28" alt="MyAnimeList"> | **MyAnimeList** | Anime and manga lists with scores, status and progress from an XML export |
| <img src="assets/images/icon_anilist_color.png" width="28" alt="AniList"> | **AniList** | Anime and manga directly by a public username — no API key required |
| 📦 | **.xcollx files** | Collections shared by others |

> [Import guides on Wiki](https://github.com/hacan359/tonkatsu_box/wiki)

## Data Sources

| | Type | Source | API Key |
|:-:|------|--------|---------|
| <img src="assets/images/icon_igdb_color.png" width="28" alt="IGDB"> | Games | [IGDB](https://www.igdb.com/) | Built-in |
| <img src="assets/images/icon_tmdb_color.png" width="28" alt="TMDB"> | Movies & TV | [TMDB](https://www.themoviedb.org/) | Built-in |
| <img src="assets/images/icon_vndb_color.png" width="28" alt="VNDB"> | Visual Novels | [VNDB](https://vndb.org/) | Not required |
| <img src="assets/images/icon_anilist_color.png" width="28" alt="AniList"> | Anime & Manga | [AniList](https://anilist.co/) | Not required |
| <img src="assets/images/icon_steamgriddb_color.png" width="28" alt="SteamGridDB"> | Artwork | [SteamGridDB](https://www.steamgriddb.com/) | Built-in |
| <img src="assets/images/icon_scrapper_color.png" width="28" alt="ScreenScraper"> | Retro media gallery | [ScreenScraper](https://www.screenscraper.fr/) | Required (user account) |
| <img src="assets/images/ra_logo.png" width="28" alt="RetroAchievements"> | Achievements | [RetroAchievements](https://retroachievements.org/) | Required |

> [API Keys Setup](https://github.com/hacan359/tonkatsu_box/wiki/API-Keys-Setup)

## Platform Support

| Feature | Windows | Linux | Android |
|---------|:-------:|:-----:|:-------:|
| Collections & search | ✅ | ✅ | ✅ |
| Progress tracking | ✅ | ✅ | ✅ |
| Visual boards | ✅ | ✅ | ✅ |
| Tier lists | ✅ | ✅ | ✅ |
| Import (Steam/Trakt/RA) | ✅ | ✅ | ✅ |
| Kodi sync | ✅ | ✅ | ✅ |
| VGMaps browser | ✅ | — | — |
| Gamepad | ✅ | ✅ | ✅ |
| Discord Rich Presence | ✅ | ✅ | — |

## Documentation

- [**Wiki**](https://github.com/hacan359/tonkatsu_box/wiki) — user guides & FAQ
- [**Changelog**](CHANGELOG.md) — version history

## Building from Source

```bash
git clone https://github.com/hacan359/tonkatsu_box.git
cd tonkatsu_box
flutter pub get
flutter run -d windows  # or linux / android
```

Requires Flutter 3.38+. See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details.

## Community

- [Discord](https://discord.gg/JZVNPF7cS2) — chat & support
- [Issues](https://github.com/hacan359/tonkatsu_box/issues) — bug reports

## Contributing

Contributions welcome! See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for build instructions, code style, and PR guidelines.

## Credits

Data: [IGDB](https://www.igdb.com/) · [TMDB](https://www.themoviedb.org/) · [VNDB](https://vndb.org/) · [AniList](https://anilist.co/) · [MyAnimeList](https://myanimelist.net/) · [RetroAchievements](https://retroachievements.org/) · [SteamGridDB](https://www.steamgriddb.com/) · [ScreenScraper](https://www.screenscraper.fr/)

*This product uses the TMDB API but is not endorsed or certified by TMDB.*

## License

[MIT](LICENSE)
