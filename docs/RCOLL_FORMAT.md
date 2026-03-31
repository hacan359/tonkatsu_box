[← Back to README](../README.md)

# 📦 Collection File Formats

Tonkatsu Box supports two file formats for sharing collections.

## Formats Overview

| Extension | Version | Description |
|-----------|---------|-------------|
| `.xcoll` | v2 | Light export — metadata + element IDs |
| `.xcollx` | v2 | Full export — + canvas + base64 images |

> [!WARNING]
> **The legacy `.rcoll` (v1) format is deprecated and no longer supported.** Files in v1 format will be rejected with a `FormatException`. All collections should use `.xcoll` or `.xcollx` (v2) going forward.

---

## v2 Format (`.xcoll` / `.xcollx`)

### Light Export (`.xcoll`)

```json
{
  "version": 2,
  "format": "light",
  "name": "My Collection",
  "author": "username",
  "created": "2025-02-02T12:00:00Z",
  "description": "Optional description",
  "items": [
    {
      "media_type": "game",
      "external_id": 1234,
      "platform_id": 19,
      "comment": "All-time favorite"
    },
    {
      "media_type": "movie",
      "external_id": 550
    },
    {
      "media_type": "visual_novel",
      "external_id": 17
    }
  ]
}
```

### Full Export (`.xcollx`)

Includes everything from light export plus `canvas`, `images`, and `media`:

```json
{
  "version": 2,
  "format": "full",
  "name": "My Collection",
  "author": "username",
  "created": "2025-02-02T12:00:00Z",
  "items": [
    {
      "media_type": "game",
      "external_id": 1234,
      "platform_id": 19,
      "_canvas": {
        "viewport": { "scale": 1.0, "offset_x": 0.0, "offset_y": 0.0 },
        "items": [ ... ],
        "connections": [ ... ]
      }
    }
  ],
  "canvas": {
    "viewport": { "scale": 1.5, "offset_x": -200.0, "offset_y": -100.0 },
    "items": [
      {
        "id": 1,
        "type": "game",
        "refId": 1234,
        "x": 0.0,
        "y": 0.0,
        "width": 160.0,
        "height": 220.0,
        "z_index": 0,
        "data": null,
        "created_at": 1706880000
      }
    ],
    "connections": [
      {
        "id": 1,
        "from_item_id": 1,
        "to_item_id": 2,
        "label": "sequel",
        "color": "#0000FF",
        "style": "arrow",
        "created_at": 1706880000
      }
    ]
  },
  "images": {
    "game_covers/1234": "iVBORw0KGgo...",
    "movie_posters/550": "iVBORw0KGgo...",
    "canvas_images/a1b2c3d4": "iVBORw0KGgo..."
  },
  "media": {
    "games": [
      { "id": 1234, "name": "Game Name", "summary": "...", "cover_url": "//images.igdb.com/...", "genres": "Action|RPG", "rating": 85.5, "external_url": "https://www.igdb.com/games/game-name", ... }
    ],
    "movies": [
      { "tmdb_id": 550, "title": "Movie Title", "overview": "...", "poster_url": "/poster.jpg", "genres": "[\"Action\",\"Drama\"]", "runtime": 139, ... }
    ],
    "tv_shows": [
      { "tmdb_id": 1399, "title": "TV Show", "total_seasons": 8, "total_episodes": 73, "genres": "[\"Drama\"]", ... }
    ],
    "visual_novels": [
      { "id": "v17", "numeric_id": 17, "title": "Ever17", "alt_title": "Ever17 -the out of infinity-", "rating": 85.5, "vote_count": 1200, "released": "2002-08-29", "tags": "[\"Sci-fi\",\"Mystery\"]", ... }
    ],
    "mangas": [
      { "id": 30002, "title": "Berserk", "title_english": "Berserk", "title_native": "ベルセルク", "cover_url": "https://...", "genres": "[\"Action\",\"Drama\"]", "average_score": 93, "format": "MANGA", "country_of_origin": "JP", ... }
    ],
    "tv_seasons": [
      { "tmdb_show_id": 1399, "season_number": 1, "name": "Season 1", "episode_count": 10, "poster_url": "https://image.tmdb.org/t/p/w500/...", "air_date": "2011-04-17" }
    ],
    "tv_episodes": [
      { "tmdb_show_id": 1399, "season_number": 1, "episode_number": 1, "name": "Winter Is Coming", "overview": "...", "air_date": "2011-04-17", "still_url": "https://image.tmdb.org/t/p/w300/...", "runtime": 62 }
    ]
  }
}
```

---

### v2 Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| version | number | yes | Always `2` |
| format | string | yes | `"light"` or `"full"` |
| name | string | yes | Collection name |
| author | string | yes | Creator name |
| created | string | yes | ISO 8601 date |
| description | string | no | Collection description |
| user_data | boolean | no | `true` if items include personal data (status, dates, notes). Absent or `false` for catalog-only exports |
| items | array | yes | List of collection items |
| canvas | object | no | Collection-level canvas (full only) |
| images | object | no | Base64 cover images (full only) |
| media | object | no | Embedded Game/Movie/TvShow/VisualNovel/Manga/TvSeason/TvEpisode data for offline import (full only) |
| tags | array | no | Collection tag definitions (full only). Each: `{ name, color?, sort_order }` |

### Item Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| media_type | string | yes | `"game"`, `"movie"`, `"tv_show"`, `"animation"`, `"visual_novel"`, or `"manga"` |
| external_id | number | yes | IGDB ID (games), TMDB ID (movies/TV), VNDB numeric ID (visual novels), or AniList ID (manga) |
| platform_id | number | no | IGDB platform ID (games) or AnimationSource (animation: 0=movie, 1=tvShow) |
| comment | string | no | Author's comment |
| user_rating | number | no | User rating (1-10) |
| _canvas | object | no | Per-item canvas data (full only) |
| tag_name | string | no | Name of the assigned tag/section (full only, resolved to `tag_id` on import) |

**User data fields** (present only when top-level `user_data` is `true`):

| Field | Type | Description |
|-------|------|-------------|
| status | string | `"not_started"`, `"in_progress"`, `"completed"`, `"dropped"`, or `"planned"` |
| user_comment | string | User's personal notes |
| current_season | number | Current season (TV shows) |
| current_episode | number | Current episode (TV shows) |
| added_at | number | Unix timestamp (seconds) when item was added |
| sort_order | number | Manual sort position |
| started_at | number | Unix timestamp (seconds) when started |
| completed_at | number | Unix timestamp (seconds) when completed |
| last_activity_at | number | Unix timestamp (seconds) of last activity |

### Canvas Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| viewport | object | no | Zoom and offset: `{scale, offset_x, offset_y}` |
| items | array | yes | Canvas items |
| connections | array | yes | Canvas connections |

### Images Object

Key format: `{ImageType.folder}/{imageId}`

**Cover images** — `imageId` is the external ID (IGDB/TMDB):
- `game_covers/1234` — game cover for IGDB ID 1234
- `movie_posters/550` — movie poster for TMDB ID 550
- `tv_show_posters/1399` — TV show poster for TMDB ID 1399
- `vn_covers/17` — visual novel cover for VNDB numeric ID 17
- `manga_covers/123` — manga cover for AniList ID 123

**Canvas images** — `imageId` is FNV-1a 32-bit hash of the image URL:
- `canvas_images/a1b2c3d4` — image added to the canvas board

Values are base64-encoded PNG image data.

### Media Object

Contains full Game/Movie/TvShow/TvSeason/TvEpisode data for offline import. Each entry uses the same format as the corresponding model's `toDb()` output (without `cached_at`).

| Field | Type | Description |
|-------|------|-------------|
| games | array | Game objects from IGDB (id, name, summary, cover_url, genres, rating, external_url, ...) |
| movies | array | Movie objects from TMDB (tmdb_id, title, overview, poster_url, genres, runtime, external_url, ...) |
| tv_shows | array | TvShow objects from TMDB (tmdb_id, title, total_seasons, total_episodes, genres, external_url, ...) |
| visual_novels | array | VisualNovel objects from VNDB (id, numeric_id, title, alt_title, description, image_url, rating, vote_count, released, length_minutes, length, tags, developers, platforms, external_url) |
| mangas | array | Manga objects from AniList (id, title, title_english, title_native, cover_url, cover_medium_url, description, genres, average_score, mean_score, popularity, status, start_year, chapters, volumes, format, country_of_origin, staff) |
| tv_seasons | array | TvSeason objects from TMDB (tmdb_show_id, season_number, name, episode_count, poster_url, air_date) |
| tv_episodes | array | TvEpisode objects from TMDB (tmdb_show_id, season_number, episode_number, name, overview, air_date, still_url, runtime) |

All seven arrays are optional — only non-empty categories are included.

### Tier Lists Object

Contains tier list data for the exported collection. Only present when the collection has associated tier lists.

| Field | Type | Description |
|-------|------|-------------|
| id | int | Tier list ID (not preserved on import — new ID assigned) |
| name | string | Tier list name |
| collection_id | int? | Source collection ID (null for global) |
| definitions | array | Tier definitions: `{ tier_key, label, color (0xAARRGGBB int), sort_order }` |
| entries | array | Items placed in tiers: `{ collection_item_id, tier_key, sort_order, external_id, media_type, platform_id? }` |

Entries include `external_id`, `media_type`, and optional `platform_id` fields for cross-collection resolution on import. The import process builds an `itemIdMapping` (`"media_type:external_id[:platform_id]" → newItemId`) and resolves entries via this map rather than raw collection_item_id values. For games, the key includes `platform_id` to distinguish the same game on different platforms; lookup falls back to a key without platform for backward compatibility with older exports. Animation items are stored in `movies` (animated films) or `tv_shows` (animated series) based on their `AnimationSource`. Visual novel items are stored in `visual_novels` with VNDB string IDs (e.g. "v17"). Manga items are stored in `mangas` with AniList integer IDs. Seasons are preloaded when a TV show or animation series is added to a collection. Episodes are included from the local cache for each TV show in the collection.

### Tags Object

Contains tag (section) definitions for the exported collection. Only present in full exports when the collection has tags.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Tag name |
| color | int? | Tag color (0xAARRGGBB int), null for default |
| sort_order | int | Display order |

Item-tag assignments are stored per-item via the `tag_name` field (see Item Object). On import, tags are created first, then items are matched by `tag_name` to assign `tag_id`.

When `media` is present during import, data is restored directly from the file via `fromDb()` — no API calls to IGDB/TMDB/VNDB are needed. TV seasons and episodes are also restored if present. When `media` is absent (light export or older full exports), the app fetches data from APIs as before.

---

## How Import Works

### v2 Light (`.xcoll`)

1. App reads the file and creates a collection
2. Inserts items with their metadata (comments)
3. Fetches full game/movie/TV/VN/manga data from IGDB/TMDB/VNDB/AniList using IDs

### v2 Full (`.xcollx`)

1. If `media` section is present — restores Game/Movie/TvShow/VisualNovel/Manga/TvSeason/TvEpisode data from embedded data (offline)
2. If `media` section is absent — fetches data from IGDB/TMDB/VNDB/AniList APIs (online, same as light import)
3. Creates collection and inserts items with metadata
4. Restores collection-level canvas (viewport, items, connections)
5. Restores per-item canvases (embedded in `_canvas` field of each item)
6. Restores cover images and canvas images from base64 to local disk cache
7. Restores tier lists — creates tier list, saves definitions, resolves entries via `itemIdMapping` (`media_type:external_id` → new item ID)
