# Collection File Formats

xeRAbora supports two file formats for sharing collections.

## Formats Overview

| Extension | Version | Description |
|-----------|---------|-------------|
| `.xcoll` | v2 | Light export — metadata + element IDs |
| `.xcollx` | v2 | Full export — + canvas + base64 images |

> **Note:** The legacy `.rcoll` (v1) format is no longer supported. Files in v1 format will be rejected with a `FormatException`.

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
      { "id": 1234, "name": "Game Name", "summary": "...", "cover_url": "//images.igdb.com/...", "genres": "Action|RPG", "rating": 85.5, ... }
    ],
    "movies": [
      { "tmdb_id": 550, "title": "Movie Title", "overview": "...", "poster_url": "/poster.jpg", "genres": "[\"Action\",\"Drama\"]", "runtime": 139, ... }
    ],
    "tv_shows": [
      { "tmdb_id": 1399, "title": "TV Show", "total_seasons": 8, "total_episodes": 73, "genres": "[\"Drama\"]", ... }
    ]
  }
}
```

### v2 Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| version | number | yes | Always `2` |
| format | string | yes | `"light"` or `"full"` |
| name | string | yes | Collection name |
| author | string | yes | Creator name |
| created | string | yes | ISO 8601 date |
| description | string | no | Collection description |
| items | array | yes | List of collection items |
| canvas | object | no | Collection-level canvas (full only) |
| images | object | no | Base64 cover images (full only) |
| media | object | no | Embedded Game/Movie/TvShow data for offline import (full only) |

### Item Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| media_type | string | yes | `"game"`, `"movie"`, `"tv_show"`, or `"animation"` |
| external_id | number | yes | IGDB ID (games) or TMDB ID (movies/TV) |
| platform_id | number | no | IGDB platform ID (games) or AnimationSource (animation: 0=movie, 1=tvShow) |
| comment | string | no | Author's comment |
| _canvas | object | no | Per-item canvas data (full only) |

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

**Canvas images** — `imageId` is FNV-1a 32-bit hash of the image URL:
- `canvas_images/a1b2c3d4` — image added to the canvas board

Values are base64-encoded PNG image data.

### Media Object

Contains full Game/Movie/TvShow data for offline import. Each entry uses the same format as the corresponding model's `toDb()` output (without `cached_at`).

| Field | Type | Description |
|-------|------|-------------|
| games | array | Game objects from IGDB (id, name, summary, cover_url, genres, rating, ...) |
| movies | array | Movie objects from TMDB (tmdb_id, title, overview, poster_url, genres, runtime, ...) |
| tv_shows | array | TvShow objects from TMDB (tmdb_id, title, total_seasons, total_episodes, genres, ...) |

All three arrays are optional — only non-empty categories are included. Animation items are stored in `movies` (animated films) or `tv_shows` (animated series) based on their `AnimationSource`.

When `media` is present during import, data is restored directly from the file via `fromDb()` — no API calls to IGDB/TMDB are needed. When `media` is absent (light export or older full exports), the app fetches data from APIs as before.

---

## How Import Works

### v2 Light (`.xcoll`)
1. App reads the file and creates a collection
2. Inserts items with their metadata (comments)
3. Fetches full game/movie/TV data from IGDB/TMDB using IDs

### v2 Full (`.xcollx`)
1. If `media` section is present — restores Game/Movie/TvShow data from embedded data (offline)
2. If `media` section is absent — fetches data from IGDB/TMDB APIs (online, same as light import)
3. Creates collection and inserts items with metadata
4. Restores collection-level canvas (viewport, items, connections)
5. Restores per-item canvases (embedded in `_canvas` field of each item)
6. Restores cover images and canvas images from base64 to local disk cache
