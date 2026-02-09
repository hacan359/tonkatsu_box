# Roadmap

## Current Version (v1.0)

- [x] Project setup
- [x] IGDB integration
- [x] Collection management
- [x] Progress tracking
- [x] Import/Export (.rcoll)
- [x] Forking collections
- [x] Comments system
- [x] SteamGridDB integration (API client, debug panel)
- [x] Offline image caching
- [x] Platform logos

## Canvas Development

- [x] Stage 7: Basic Canvas — visual canvas with zoom, pan, drag-and-drop, grid layout, List/Canvas toggle, bidirectional collection sync
- [x] Stage 8: Canvas Elements — context menu, text blocks, images, links, resize, z-index
- [x] Stage 9: Connections — visual connections (solid/dashed/arrow) between canvas elements with labels, colors, edit/delete, auto-cleanup
- [x] Stage 10: SteamGridDB Widget — side panel for adding SteamGridDB images to canvas
- [x] Stage 12: VGMaps Browser — side panel with embedded WebView2 for browsing and adding vgmaps.com level maps to canvas
- [x] Stage 15: TMDB Integration — API client for movies/TV shows, models (Movie, TvShow, TvSeason), DB cache tables, settings UI
- [x] Stage 16: Universal Collections — CollectionItem model with MediaType (game/movie/tvShow), ItemStatus, DB migration, backward-compatible adapters
- [x] Stage 17: Universal Search — tabbed search (Games/Movies/TV Shows), MediaSearchProvider, MovieCard, TvShowCard, add movies/TV shows to collections
- [x] Stage 18: Media Display — movie/TV show detail screens, ItemStatusDropdown, CanvasMediaCard, CollectionScreen switched to CollectionItem, canvas support for all media types
- [x] UI Cards: Source badges (IGDB/TMDB), unified MediaCard for search, unified MediaDetailView for detail screens, media type color coding, canvas card type borders
- [x] Search Sorting: Sort results by relevance, date, or rating with toggleable direction
- [x] TMDB Filters: Filter movies/TV shows by release year and genres
- [x] Per-Item Canvas: Personal canvas for each game/movie/TV show with TabBar detail screens, SteamGridDB and VGMaps panels, data isolation
- [ ] Stage 13: Export Full — extended .rcoll-full format with canvas layout and images

## Future Plans

### RetroAchievements Integration
Connect your ROM library with RetroAchievements:
- Link games by ROM hash
- View available achievements
- Track your unlocked achievements

### Online Features
- Cloud sync between devices
- Public collection marketplace
- Follow other collectors
- Collection ratings and reviews

### Additional Platforms
- macOS support
- Linux support

## Contributing

This project is in active development. Feature requests and contributions are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
