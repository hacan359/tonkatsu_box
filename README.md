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

Tonkatsu Box is a free, open-source app to organize your media collections. Search millions of titles from IGDB, TMDB, VNDB, and AniList. Track your progress, rate everything, create visual boards, and import your library from Steam, Trakt.tv, or RetroAchievements.

<p align="center">
  <img src="docs/screenshots/01-main-all.jpg" width="800" alt="Main screen">
</p>

<div align="center">
  <table>
    <tr>
      <td><img src="docs/screenshots/04-collection-grid.jpg" width="280" alt="Collection grid"></td>
      <td><img src="docs/screenshots/05-collection-board.jpg" width="280" alt="Visual board"></td>
      <td><img src="docs/screenshots/09-search-games.jpg" width="280" alt="Game search"></td>
      <td><img src="docs/screenshots/06-item-details.jpg" width="280" alt="Item details"></td>
      <td><img src="docs/screenshots/12-tier-list.jpg" width="280" alt="Tier list"></td>
      <td><img src="docs/screenshots/07-search-movies.jpg" width="280" alt="Movie search"></td>
      <td><img src="docs/screenshots/11-wishlist.jpg" width="280" alt="Wishlist"></td>
    </tr>
  </table>
</div>

## Features

| | |
|---|---|
| **Collections** | Organize by platform, genre, or any way you like. Grid, list, and table views |
| **Search** | IGDB (games), TMDB (movies/TV), VNDB (visual novels), AniList (manga) |
| **Progress Tracking** | Status, ratings 1-10, episode tracking for TV shows |
| **Visual Boards** | Drag-and-drop canvas with posters, notes, and connections |
| **Tier Lists** | Rank items into S/A/B/C tiers and export as PNG |
| **Import** | Steam library, Trakt.tv history, RetroAchievements progress |
| **Export & Share** | .xcoll / .xcollx files with full offline support |
| **Gamepad** | Navigate with Xbox controller |
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

| Source | What's imported |
|--------|-----------------|
| **Steam** | Owned games, playtime, last played date |
| **Trakt.tv** | Watch history, ratings, watchlist, episode progress |
| **RetroAchievements** | Retro game library, achievement progress, awards |
| **.xcollx files** | Collections shared by others |

> [Import guides on Wiki](https://github.com/hacan359/tonkatsu_box/wiki)

## Data Sources

| Type | Source | API Key |
|------|--------|---------|
| Games | [IGDB](https://www.igdb.com/) | Built-in |
| Movies & TV | [TMDB](https://www.themoviedb.org/) | Built-in |
| Visual Novels | [VNDB](https://vndb.org/) | Not required |
| Manga | [AniList](https://anilist.co/) | Not required |
| Artwork | [SteamGridDB](https://www.steamgriddb.com/) | Built-in |
| Achievements | [RetroAchievements](https://retroachievements.org/) | Required |

> [API Keys Setup](https://github.com/hacan359/tonkatsu_box/wiki/API-Keys-Setup)

## Platform Support

| Feature | Windows | Linux | Android |
|---------|:-------:|:-----:|:-------:|
| Collections & search | ✅ | ✅ | ✅ |
| Progress tracking | ✅ | ✅ | ✅ |
| Visual boards | ✅ | ✅ | ✅ |
| Tier lists | ✅ | ✅ | ✅ |
| Import (Steam/Trakt/RA) | ✅ | ✅ | ✅ |
| VGMaps browser | ✅ | — | — |
| Gamepad | ✅ | ✅ | — |

## Documentation

- [**Wiki**](https://github.com/hacan359/tonkatsu_box/wiki) — user guides & FAQ
- [**Changelog**](CHANGELOG.md) — version history
- [**Roadmap**](docs/ROADMAP.md) — planned features

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

Data: [IGDB](https://www.igdb.com/) · [TMDB](https://www.themoviedb.org/) · [VNDB](https://vndb.org/) · [AniList](https://anilist.co/) · [RetroAchievements](https://retroachievements.org/) · [SteamGridDB](https://www.steamgriddb.com/)

*This product uses the TMDB API but is not endorsed or certified by TMDB.*

## License

[MIT](LICENSE)
