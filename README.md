<p align="center">
  <img src="assets/images/logo.png" width="120" alt="Tonkatsu Box">
</p>

<h1 align="center">Tonkatsu Box</h1>

<p align="center">
  <b>Organize your games, movies, TV shows, and anime — all in one place</b>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Windows"></a>
  <a href="#"><img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android"></a>
</p>

<p align="center">
  <a href="https://github.com/hacan359/tonkatsu_box/actions/workflows/test.yml">
    <img src="https://github.com/hacan359/tonkatsu_box/actions/workflows/test.yml/badge.svg" alt="Tests">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter&logoColor=white" alt="Flutter 3.38+">
  </a>
</p>

---

Tonkatsu Box is a free, open-source collection manager for retro games, movies, TV shows, and anime. Search IGDB and TMDB databases with hundreds of thousands of titles, organize them into custom collections, track your backlog and progress, rate everything from 1 to 10, create visual boards with drag-and-drop, and share collections with friends. Available for Windows and Android.

<p align="center">
  <img src="docs/screenshots/01-main-all.jpg" width="800" alt="Main screen — browse all your games, movies, TV shows and anime">
</p>

## What You Can Do

### 🎮 Build Collections
Create as many collections as you want — by platform (SNES, PlayStation, PC), genre (RPGs, Sci-Fi), or your own lists (Backlog, Favorites, Couch co-op night). Mix games, movies and anime in a single collection. Switch between list and poster grid view.

<p align="center">
  <img src="docs/screenshots/03-collections-list.jpg" width="800" alt="Collections list with thumbnails and progress">
</p>
<p align="center">
  <img src="docs/screenshots/04-collection-grid.jpg" width="800" alt="Collection grid view with ratings and search">
</p>

### 🔍 Search & Discover
Two search tabs — **Games** and **TV** — each with their own filters:

**Games** (powered by IGDB):
- Filter by platform — select one or multiple platforms from a searchable list (NES, SNES, PlayStation, PC, and hundreds more)
- Sort by relevance, release date, or IGDB rating
- Pick the exact platform version when adding a game to your collection

**Movies, TV Shows & Anime** (powered by TMDB):
- Filter by type — All, Movies, TV Shows, or Animation
- Sort by relevance, release date, or rating
- Anime is detected automatically by genre — both animated movies and animated series

Results load as you scroll with automatic pagination. Each card shows the poster, title, year, rating, and top genres at a glance.

<p align="center">
  <img src="docs/screenshots/07-search-movies.jpg" width="800" alt="Search movies and TV shows">
</p>
<p align="center">
  <img src="docs/screenshots/09-search-games.jpg" width="800" alt="Search games across platforms">
</p>

### 📝 Wishlist
No internet right now? Jot down the name of a game or movie to search for later. Tag it with a media type, add a note, and tap it when you're ready — the app opens search with the name pre-filled. Mark items as resolved when you've found them.

<p align="center">
  <img src="docs/screenshots/10-wishlist.jpg" width="800" alt="Wishlist with tagged media types">
</p>

### 📊 Track Your Progress
Mark items as Not Started, In Progress, Completed, On Hold, or Dropped. For TV shows and anime, track individual episodes with per-season checkboxes. Rate everything from 1 to 10 stars. See when you started and finished each item.

<p align="center">
  <img src="docs/screenshots/06-item-details.jpg" width="800" alt="Item details with status, rating and notes">
</p>

### 🎨 Visual Boards
Arrange your collection on a free-form board — drag posters around, add text notes, images, and links. Draw connections between items. Browse high-quality game artwork from SteamGridDB and add it to your boards. Each item can also have its own personal board.

<p align="center">
  <img src="docs/screenshots/05-collection-board.jpg" width="800" alt="Visual board with game posters and connections">
</p>

### 📤 Share with Friends
Export your collections as `.xcoll` (lightweight) or `.xcollx` (full offline copy with all images and data). Friends can import them and fork to create their own version.

## Getting Started

### Step 1: Get your API keys

The app uses free APIs to search for games, movies, and artwork. You'll need to register for API keys (it's free and takes a few minutes).

<details>
<summary><b>🎮 IGDB — for searching games (required)</b></summary>

IGDB is powered by Twitch, so you'll need a Twitch account.

1. Go to **[dev.twitch.tv/console](https://dev.twitch.tv/console)** and log in (or create a free Twitch account)
2. Click **Register Your Application**
3. Fill in the form:
   - **Name:** `Tonkatsu Box` (or anything you like)
   - **OAuth Redirect URLs:** `http://localhost`
   - **Category:** `Application Integration`
4. Click **Create**
5. Open your new application and copy the **Client ID**
6. Click **New Secret** and copy the **Client Secret**

You'll enter both in the app under **Settings → Credentials**.

</details>

<details>
<summary><b>🎬 TMDB — for searching movies, TV shows & anime (recommended)</b></summary>

1. Go to **[themoviedb.org](https://www.themoviedb.org/)** and create a free account
2. Go to your profile → **Settings** → **API**
3. Click **Request an API Key** → choose **Developer**
4. Fill in the form (for personal/non-commercial use)
5. Copy your **API Key (v3 auth)**

Enter it in the app under **Settings → Credentials**.

> [!TIP]
> Without a TMDB key, game search still works — you just won't be able to search for movies, TV shows, or anime.

</details>

<details>
<summary><b>🖼️ SteamGridDB — for game artwork on boards (optional)</b></summary>

1. Go to **[steamgriddb.com](https://www.steamgriddb.com/)** and create a free account
2. Go to **Preferences** → **API**
3. Copy your **API Key**

Enter it in the app under **Settings → Credentials**.

> [!TIP]
> This key is only needed if you want to add high-quality game artwork (covers, heroes, logos) to your visual boards.

</details>

> [!TIP]
> On first launch, the app will walk you through a **Welcome Wizard** that explains everything — you can also revisit it later from **Settings → Welcome Guide**.

### Step 2: Install and run

```bash
git clone https://github.com/hacan359/tonkatsu_box.git
cd xerabora
flutter pub get
flutter run -d windows    # or: flutter run -d android
```

> [!NOTE]
> You'll need [Flutter SDK](https://flutter.dev/docs/get-started/install) installed. Windows builds require the Windows desktop development tools, Android builds require the Android SDK.
>
> Android release builds require a signing keystore. See the [Contributing Guide](docs/CONTRIBUTING.md#android-release-builds) for setup instructions.

### Step 3: Enter your API keys

Open the app → go to **Settings** → **Credentials** and paste your API keys. You're ready to go!

## Sharing Collections

### Exporting

1. Open a collection → tap the **menu** (⋮) → **Export**
2. Choose a format:
   - **Light export** (`.xcoll`) — small file with just the list of items. The recipient will need internet to load images and details.
   - **Full export** (`.xcollx`) — complete package with all images, board layouts, and media data. Works fully offline.
3. Pick where to save the file

### Importing

1. Go to **Settings** → **Database** → **Import Collection**
2. Select a `.xcoll` or `.xcollx` file
3. The collection appears in your list — you can browse it as read-only or **fork** it to make your own editable copy

## Platforms

| | Windows | Android |
|---|:---:|:---:|
| Collections & search | ✅ | ✅ |
| Progress & episode tracking | ✅ | ✅ |
| Visual boards | ✅ | ✅ |
| VGMaps browser (level maps) | ✅ | — |
| Export & import | ✅ | ✅ |

## Documentation

For developers and contributors:

| Document | Description |
|----------|-------------|
| [Features](docs/FEATURES.md) | Detailed feature list |
| [Architecture](docs/ARCHITECTURE.md) | Project structure, models, database |
| [Getting Started](docs/GETTING_STARTED.md) | Developer setup guide |
| [API Keys Guide](docs/guides/API_KEYS.md) | Detailed API key registration instructions |
| [How It Works](docs/guides/HOW_IT_WORKS.md) | App structure, quick start, sharing |
| [Roadmap](docs/ROADMAP.md) | Development progress and future plans |
| [Export Format](docs/RCOLL_FORMAT.md) | `.xcoll` / `.xcollx` file format spec |
| [Gamepad Support](docs/GAMEPAD.md) | Xbox controller / D-pad navigation |
| [Contributing](docs/CONTRIBUTING.md) | Contribution guidelines |
| [Changelog](CHANGELOG.md) | Version history |

## Tech Stack

Flutter 3.38+ / Dart 3.10+ · Riverpod · SQLite · Dio · Material Design 3

## Contributing

Contributions are welcome! See the [Contributing Guide](docs/CONTRIBUTING.md) for details.

## Code Signing Policy

Windows binaries are signed with a certificate provided by [SignPath Foundation](https://signpath.org).

Free code signing provided by [SignPath.io](https://signpath.io), certificate by [SignPath Foundation](https://signpath.org).

**Team roles:**
- Committers and reviewers: [hacan359](https://github.com/hacan359)
- Approvers: [hacan359](https://github.com/hacan359)

**Privacy policy:** This program will not transfer any information to other networked systems unless specifically requested by the user or the person installing or operating it. The application uses third-party APIs (IGDB, TMDB, SteamGridDB) only when the user explicitly initiates a search or data fetch.

## License

MIT
