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
  <a href="https://www.rustore.ru/catalog/app/com.hacan359.tonkatsubox?utm_source=available_in_rustore&utm_medium=com.hacan359.tonkatsubox&rsm=1&mt_link_id=iios36&mt_sub1=com.hacan359.tonkatsubox"><img src="https://img.shields.io/badge/RuStore-0066FF?style=for-the-badge&logo=rustore&logoColor=white" alt="RuStore"></a>
</p>

<p align="center">
  <a href="https://github.com/hacan359/tonkatsu_box/actions/workflows/test.yml"><img src="https://github.com/hacan359/tonkatsu_box/actions/workflows/test.yml/badge.svg" alt="Tests"></a>
  <a href="https://github.com/hacan359/tonkatsu_box/actions/workflows/test.yml"><img src="https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/hacan359/7ed48e87a6bd59afeb08eaf656fd2adb/raw/tonkatsu-box-coverage.json" alt="Coverage"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white" alt="Flutter 3.44+"></a>
  <a href="https://discord.gg/JZVNPF7cS2"><img src="https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white" alt="Discord"></a>
</p>

---

> [!WARNING]
> **This app is in active development.** Updates may include database migrations that change data format. Please **create a backup** before updating (Settings → Backup → Create Backup). Alternatively, you can manually copy the app data folder:
> - **Windows:** `%APPDATA%\Roaming\Tonkatsu Box\Tonkatsu Box`
> - **Linux:** `~/.local/share/tonkatsu_box` (or `$XDG_DATA_HOME/tonkatsu_box`)
> - **Android:** use the built-in backup feature (Settings → Backup)

---

Tonkatsu Box is a free, open-source app to organize your media collections. Search millions of titles from IGDB, TMDB, VNDB, AniList, MangaBaka, OpenLibrary, Fantlab, ComicVine, and Google Books. Track your progress, rate everything, create visual boards and mood grids, and import your library from Steam, IGDB lists, Trakt.tv, Kinorium, RetroAchievements, MyAnimeList, or AniList.

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
| **Search** | IGDB (games), TMDB (movies/TV), AniList (anime & manga), MangaBaka (manga), VNDB (visual novels), OpenLibrary, Fantlab & Google Books (books), ComicVine (comics) |
| **Progress Tracking** | Status, ratings 1-10, episode tracking for TV shows and anime |
| **Discord Rich Presence** | Show what you're playing/watching/reading in Discord (desktop) |
| **Visual Boards** | Drag-and-drop canvas with posters, notes, and connections |
| **Tier Lists & Mood Grids** | Rank items into S/A/B/C tiers, or arrange them on a visual N×M board with labels — export either as PNG |
| **Import** | Steam library, IGDB list CSV, Trakt.tv history, Kinorium CSV, RetroAchievements progress, MyAnimeList XML, AniList by username |
| **Kodi Sync** | Pull watched status and ratings for your movies from a Kodi media server over JSON-RPC |
| **Export & Share** | .xcoll / .xcollx files with full offline support |
| **Gamepad** | Navigate with Xbox controller (desktop and Android handhelds) |
| **Languages** | English & Russian |

## Download

| Platform | Link |
|----------|------|
| Windows | [**Download .zip**](https://github.com/hacan359/tonkatsu_box/releases/latest) |
| Linux | [**Download .tar.gz**](https://github.com/hacan359/tonkatsu_box/releases/latest) |
| Android | [**Download .apk**](https://github.com/hacan359/tonkatsu_box/releases/latest) or [**RuStore**](https://www.rustore.ru/catalog/app/com.hacan359.tonkatsubox) |

> Linux support is experimental.

> On Android you have three options: grab the APK from Releases, install from [RuStore](https://www.rustore.ru/catalog/app/com.hacan359.tonkatsubox), or set up Obtainium for auto-updates (below). RuStore handles updates for you through its own store.

### Auto-updates on Android (Obtainium)

[Obtainium](https://github.com/ImranR98/Obtainium) checks GitHub Releases and installs new APKs for you, so you don't have to download updates by hand.

1. Install Obtainium.
2. Tap **Add App** and paste this into **App source URL**:
   ```
   https://github.com/hacan359/tonkatsu_box
   ```
3. Tap **Add**.
4. The first time it updates, Android asks you to allow installs from Obtainium. Allow it once.
5. In the app settings, pick how often Obtainium checks for releases and turn on auto-update, or just refresh manually whenever you want.

When a new release ships, Obtainium downloads the APK and shows the system install dialog to confirm. Silent background installs are not possible on Android without root.

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
| <img src="assets/images/icon_igdb_color.png" width="28" alt="IGDB"> | **IGDB** | A game list exported as CSV — matched by IGDB id, with a status you pick for the list |
| <img src="assets/images/icon_trakt_color.png" width="28" alt="Trakt.tv"> | **Trakt.tv** | Watch history, ratings, watchlist, episode progress |
| <img src="assets/images/icon_kinorium_color.png" width="28" alt="Kinorium"> | **Kinorium** | Movies, TV & animation from a CSV export — ratings and watch dates |
| <img src="assets/images/ra_logo.png" width="28" alt="RetroAchievements"> | **RetroAchievements** | Retro game library, achievement progress, awards |
| <img src="assets/images/icon_myanimelist_color.png" width="28" alt="MyAnimeList"> | **MyAnimeList** | Anime and manga lists with scores, status and progress from an XML export |
| <img src="assets/images/icon_anilist_color.png" width="28" alt="AniList"> | **AniList** | Anime and manga directly by a public username — no API key required |
| 📦 | **.xcollx files** | Collections shared by others |

> [Import guides on Wiki](https://github.com/hacan359/tonkatsu_box/wiki)

## Device-to-Device Sync

Move your whole collection from one device to another over your home network. No cloud, no account: the two devices talk to each other directly.

How it works:

1. Open **Settings → Database → Device-to-device sync** on both devices. While the screen is open, each device announces itself on the local network and finds the other one.
2. On the device that should **receive** the data, tap the other device in the list.
3. Confirm on both sides: the receiving device shows what it is about to download (device name, date, collection and item counts), and the sending device asks you to allow the transfer.
4. The full database is copied over and **replaces** everything on the receiving device. Restart the app when asked.

This is a full replace, not a merge. Changes made on the receiving device that the sender doesn't have are gone after the transfer.

Before replacing anything, the app keeps the previous database as a backup. **Settings → Database → Backup → Restore** swaps the current database with that backup, and restoring again swaps them back.

> [!CAUTION]
> **This feature can destroy data. Read this before using it.**
> - Receiving a snapshot **overwrites your entire local database**. Anything you added on this device and nowhere else is lost.
> - There is only **one backup slot**. Receiving a second snapshot overwrites the backup made before the first one — after that, the original data is gone for good.
> - The transfer is **not encrypted** and there is no pairing between devices. Use it only on a network you trust (your home Wi-Fi), never on public or shared networks.
> - If the app is killed or the device loses power in the middle of a transfer or restore, the database can end up corrupted. Keep a regular backup (Settings → Backup) before syncing.

### Custom Data Folder

By default the database lives in the app's private folder. **Settings → Database → Storage location** lets you move it to any folder you pick — for example an SD card or a folder synced by a cloud client.

When you pick an empty folder, the app copies your current data there. When you pick a folder that already holds Tonkatsu Box data, the app switches to that data instead. Either way a restart is required. If the custom folder is missing on startup (unplugged drive, dead network share), the app falls back to the default location instead of failing — Settings shows a warning when that happens.

> [!CAUTION]
> - Pointing two devices or a cloud client at the **same live folder** is not supported and can corrupt the database. Sync clients copy files while they are being written; SQLite does not survive that.
> - When the custom folder is unavailable, the app silently runs on the default (possibly empty) data. Your collection is not lost — plug the drive back in and restart — but anything you add meanwhile lands in the default folder, not the custom one.
> - On Android this feature needs the "All files access" permission, which the app requests only when you actually pick a folder.

## Data Sources

| | Type | Source | API Key |
|:-:|------|--------|---------|
| <img src="assets/images/icon_igdb_color.png" width="28" alt="IGDB"> | Games | [IGDB](https://www.igdb.com/) | Built-in |
| <img src="assets/images/icon_tmdb_color.png" width="28" alt="TMDB"> | Movies & TV | [TMDB](https://www.themoviedb.org/) | Built-in |
| <img src="assets/images/icon_vndb_color.png" width="28" alt="VNDB"> | Visual Novels | [VNDB](https://vndb.org/) | Not required |
| <img src="assets/images/icon_anilist_color.png" width="28" alt="AniList"> | Anime & Manga | [AniList](https://anilist.co/) | Not required |
| <img src="assets/images/icon_mangabaka_color.png" width="28" alt="MangaBaka"> | Manga | [MangaBaka](https://mangabaka.org/) | Not required |
| <img src="assets/images/open_library_color.png" width="28" alt="OpenLibrary"> | Books | [OpenLibrary](https://openlibrary.org/) | Not required |
| <img src="assets/images/icon_fantlab_color.png" width="28" alt="Fantlab"> | Books | [Fantlab](https://fantlab.ru/) | Not required |
| <img src="assets/images/icon_google_book_color.png" width="28" alt="Google Books"> | Books | [Google Books](https://books.google.com/) | Optional (free key) |
| <img src="assets/images/comic_vine_color.png" width="28" alt="ComicVine"> | Comics | [ComicVine](https://comicvine.gamespot.com/) | Required (free key) |
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

Requires Flutter 3.44+. See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details.

## Community

- [Discord](https://discord.gg/JZVNPF7cS2) — chat & support
- [Issues](https://github.com/hacan359/tonkatsu_box/issues) — bug reports

## Contributing

Contributions welcome! See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for build instructions, code style, and PR guidelines.

## Credits

Data: [IGDB](https://www.igdb.com/) · [TMDB](https://www.themoviedb.org/) · [VNDB](https://vndb.org/) · [AniList](https://anilist.co/) · [MangaBaka](https://mangabaka.org/) · [OpenLibrary](https://openlibrary.org/) · [Fantlab](https://fantlab.ru/) · [Google Books](https://books.google.com/) · [ComicVine](https://comicvine.gamespot.com/) · [MyAnimeList](https://myanimelist.net/) · [RetroAchievements](https://retroachievements.org/) · [SteamGridDB](https://www.steamgriddb.com/) · [ScreenScraper](https://www.screenscraper.fr/)

*This product uses the TMDB API but is not endorsed or certified by TMDB.*

## License

[MIT](LICENSE)
