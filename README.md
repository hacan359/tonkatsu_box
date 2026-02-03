# xeRAbora

[![Tests](https://github.com/hacan359/xerabora/actions/workflows/test.yml/badge.svg)](https://github.com/hacan359/xerabora/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/hacan359/xerabora/graph/badge.svg)](https://codecov.io/gh/hacan359/xerabora)

Local game collections manager with sharing capabilities.

## About

Create personal game collections, track your progress, and share libraries with others via lightweight `.rcoll` files. All game metadata is fetched from IGDB.

## Features

- 🎮 Search and add games from IGDB (200k+ titles)
- 📊 Track play status: not started → playing → completed
- 💬 Add comments to games
- 📤 Export collections as `.rcoll` files
- 📥 Import shared collections — metadata loads automatically
- 🔀 Fork collections and create your own versions

## Current Version (v1.0)

- [x] Project setup
- [ ] IGDB integration
- [ ] Collection management
- [ ] Progress tracking
- [ ] Import/Export (.rcoll)
- [ ] Forking collections
- [ ] Comments system

## Requirements

- Windows 10/11
- Flutter SDK >=3.2.0
- IGDB API credentials (free at [api.igdb.com](https://api.igdb.com))

## Installation

```bash
git clone https://github.com/hacan359/xerabora.git
cd xerabora
flutter pub get
flutter run -d windows
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Database Schema](docs/DATABASE.md)
- [IGDB API](docs/IGDB_API.md)
- [.rcoll Format](docs/RCOLL_FORMAT.md)
- [Development Stages](docs/STAGES.md)

## License

MIT