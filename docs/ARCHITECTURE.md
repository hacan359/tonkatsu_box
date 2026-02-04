# Architecture

## Overview

xeRAbora is a Windows desktop application built with Flutter. It uses a local SQLite database for storage and fetches game metadata from the IGDB API.

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter (Material 3) |
| State | Riverpod |
| Database | SQLite |
| API | IGDB (via Twitch) |
| Platform | Windows Desktop |

## Data Flow

```
User searches game
       ↓
IGDB API request
       ↓
Results displayed
       ↓
User adds to collection
       ↓
Cached locally in SQLite
```

## Key Components

- **Collections** — User-created game lists
- **Game Cache** — Local storage of IGDB metadata
- **Import/Export** — Share collections via .rcoll files
- **Progress Tracker** — Track play status per game

## Offline Support

After initial sync, the app works offline using cached data. Only searching for new games requires an internet connection.
