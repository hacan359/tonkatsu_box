# Collection File Formats

xeRAbora supports three file formats for sharing collections.

## Formats Overview

| Extension | Version | Description |
|-----------|---------|-------------|
| `.xcoll` | v2 | Light export — metadata + element IDs |
| `.xcollx` | v2 | Full export — + canvas + base64 images |
| `.rcoll` | v1 | Legacy format — game IDs only (import only) |

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
      "status": "completed",
      "author_comment": "All-time favorite",
      "added_at": 1706880000
    },
    {
      "media_type": "movie",
      "external_id": 550,
      "status": "completed",
      "added_at": 1706880000
    }
  ]
}
```

### Full Export (`.xcollx`)

Includes everything from light export plus `canvas` and `images`:

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
      "status": "completed",
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
    "movie_posters/550": "iVBORw0KGgo..."
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

### Item Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| media_type | string | yes | `"game"`, `"movie"`, or `"tvShow"` |
| external_id | number | yes | IGDB ID (games) or TMDB ID (movies/TV) |
| platform_id | number | no | IGDB platform ID (games only) |
| status | string | no | Item status (default: `"not_started"`) |
| author_comment | string | no | Author's comment |
| added_at | number | no | Unix timestamp |
| _canvas | object | no | Per-item canvas data (full only) |

### Canvas Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| viewport | object | no | Zoom and offset: `{scale, offset_x, offset_y}` |
| items | array | yes | Canvas items |
| connections | array | yes | Canvas connections |

### Images Object

Key format: `{ImageType.folder}/{externalId}`

Examples:
- `game_covers/1234` — game cover for IGDB ID 1234
- `movie_posters/550` — movie poster for TMDB ID 550
- `tv_show_posters/1399` — TV show poster for TMDB ID 1399

Values are base64-encoded PNG image data.

---

## v1 Format (`.rcoll`) — Legacy

```json
{
  "version": 1,
  "name": "My SNES Classics",
  "author": "username",
  "created": "2025-02-02T12:00:00Z",
  "description": "Best RPGs for SNES",
  "games": [
    {
      "igdb_id": 1234,
      "platform_id": 19,
      "comment": "All-time favorite"
    }
  ]
}
```

### v1 Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| version | number | yes | Always `1` |
| name | string | yes | Collection name |
| author | string | yes | Creator name |
| created | string | yes | ISO 8601 date |
| description | string | no | Collection description |
| games | array | yes | List of games |

### v1 Game Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| igdb_id | number | yes | IGDB game ID |
| platform_id | number | yes | IGDB platform ID |
| comment | string | no | Author's comment |

---

## How Import Works

### v2 Light (`.xcoll`)
1. App reads the file and creates a collection
2. Inserts items with their metadata (status, comments)
3. Fetches full game/movie/TV data from IGDB/TMDB using IDs

### v2 Full (`.xcollx`)
1. Same as light import
2. Restores collection-level canvas (viewport, items, connections)
3. Restores per-item canvases (embedded in `_canvas` field of each item)
4. Restores cover images from base64 to local disk cache

### v1 Legacy (`.rcoll`)
1. App reads the file
2. Fetches game metadata from IGDB using the IDs
3. Creates collection with game items
