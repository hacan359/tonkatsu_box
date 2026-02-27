# Tool Scripts

Standalone Dart CLI scripts for generating `.xcollx` demo collection files.
No Flutter dependencies — only `dart:io` and `dart:convert`.

## Prerequisites

- Dart SDK (comes with Flutter)
- IGDB API credentials (Twitch Client ID + Client Secret)
- TMDB API key (v3)

## Scripts

### generate_demo_collections.dart

Generates 10 curated `.xcollx` collections (6 game + 4 media) with embedded cover art.

**Game collections (IGDB):** Top 50 by rating for SNES, PS1, NES, Sega Genesis, N64, Game Boy.

**Media collections (TMDB):** Top Rated Movies, Top Rated TV Shows, Best Anime Series, Best Anime Movies.

```bash
dart tool/generate_demo_collections.dart \
  --igdb-client-id=<id> \
  --igdb-client-secret=<secret> \
  --tmdb-key=<api_key_v3> \
  --output=<dir>
```

Or via environment variables: `IGDB_CLIENT_ID`, `IGDB_CLIENT_SECRET`, `TMDB_KEY`, `OUTPUT_DIR`.

### generate_all_snes.dart

Fetches **all** games for a given IGDB platform into a single `.xcollx` file with covers and IGDB URLs as author comments.

```bash
dart tool/generate_all_snes.dart \
  --igdb-client-id=<id> \
  --igdb-client-secret=<secret> \
  --output=<dir> \
  --platform=19
```

Or via environment variables: `IGDB_CLIENT_ID`, `IGDB_CLIENT_SECRET`, `OUTPUT_DIR`.

**Platform IDs:** SNES=19, PS1=7, NES=18, Genesis=29, N64=4, GameBoy=33.

**Example output:** `all_platform_19_games.xcollx` — 1972 SNES games, 1827 covers, ~10 MB.

## Notes

- IGDB covers use `t_cover_small` (90x128) to keep file size reasonable
- Images are downloaded 5 in parallel with 15s timeout
- IGDB requests are rate-limited (300ms between paginated calls)
- TMDB requires VPN in some regions
- Output files are JSON with base64-encoded images (`.xcollx` format v2)
