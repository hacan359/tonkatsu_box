[← Back to README](../README.md)

# 📦 Collection File Formats

Tonkatsu Box supports two file formats for sharing collections.

## Formats Overview

| Extension | Version | Description |
|-----------|---------|-------------|
| `.xcoll` | v3 | Light export — metadata + element IDs |
| `.xcollx` | v3 | Full export — + canvas + base64 images |

> [!WARNING]
> **The legacy `.rcoll` (v1) format is deprecated and no longer supported.** Files in v1 format will be rejected with a `FormatException`. All collections should use `.xcoll` or `.xcollx` going forward.

> [!NOTE]
> **v3 supersedes v2:** `user_rating` is now a one-decimal number (e.g. `8.5`) instead of an integer. The current build reads both v2 and v3 (legacy integer ratings load as doubles); older builds reject v3 files cleanly.

---

## Format (`.xcoll` / `.xcollx`)

### Light Export (`.xcoll`)

```json
{
  "version": 3,
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
    },
    {
      "media_type": "tv_show",
      "external_id": 42987,
      "source": "tvmaze"
    },
    {
      "media_type": "book",
      "external_id": 8193465,
      "source": "openLibrary",
      "native_id": "OL8193465W"
    }
  ]
}
```

### Full Export (`.xcollx`)

Includes everything from light export plus `canvas`, `images`, and `media`:

```json
{
  "version": 3,
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
      { "tmdb_id": 1399, "source": "tmdb", "title": "TV Show", "total_seasons": 8, "total_episodes": 73, "genres": "[\"Drama\"]", ... }
    ],
    "visual_novels": [
      { "id": "v17", "numeric_id": 17, "title": "Ever17", "alt_title": "Ever17 -the out of infinity-", "rating": 85.5, "vote_count": 1200, "released": "2002-08-29", "tags": "[\"Sci-fi\",\"Mystery\"]", ... }
    ],
    "mangas": [
      { "id": 30002, "source": "anilist", "title": "Berserk", "title_english": "Berserk", "title_native": "ベルセルク", "cover_url": "https://...", "genres": "[\"Action\",\"Drama\"]", "average_score": 93, "format": "MANGA", "country_of_origin": "JP", ... }
    ],
    "tv_seasons": [
      { "tmdb_show_id": 1399, "source": "tmdb", "season_number": 1, "name": "Season 1", "episode_count": 10, "poster_url": "https://image.tmdb.org/t/p/w500/...", "air_date": "2011-04-17" }
    ],
    "tv_episodes": [
      { "tmdb_show_id": 1399, "source": "tmdb", "season_number": 1, "episode_number": 1, "name": "Winter Is Coming", "overview": "...", "air_date": "2011-04-17", "still_url": "https://image.tmdb.org/t/p/w300/...", "runtime": 62 }
    ]
  }
}
```

---

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| version | number | yes | Always `3` (v2 also accepted on import) |
| format | string | yes | `"light"` or `"full"` |
| name | string | yes | Collection name |
| author | string | yes | Creator name |
| created | string | yes | ISO 8601 date |
| description | string | no | Collection description |
| user_data | boolean | no | `true` if items include personal data (status, dates, notes). Absent or `false` for catalog-only exports |
| items | array | yes | List of collection items |
| canvas | object | no | Collection-level canvas (full only) |
| images | object | no | Base64 cover images (full only) |
| media | object | no | Embedded Game/Movie/TvShow/VisualNovel/Manga/Anime/Book/TvSeason/TvEpisode data for offline import (full only) |
| tags | array | no | Global tag definitions used by the collection's items (full only). Each: `{ name, color?, text_color?, sort_order }` |
| tracker_data | array | no | Tracker progress data for games (full + user_data only). Each entry is a `tracker_game_data` row: `{ tracker_type, game_id, tracker_game_id, achievements_earned, achievements_total, ... }` |

### Item Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| media_type | string | yes | `"game"`, `"movie"`, `"tv_show"`, `"animation"`, `"visual_novel"`, `"manga"`, `"anime"`, `"book"`, or `"custom"` |
| external_id | number | yes | IGDB ID (games), TMDB ID (movies/TV), VNDB numeric ID (visual novels), or provider ID (manga / anime: AniList, MangaBaka, MangaDex, Kitsu) |
| source | string | no | Provider discriminator for multi-source media (manga, anime, book, tv_show): identity is `(external_id, source)`. Absent/`null` for single-source media and legacy files; defaults per type: manga/anime `"anilist"`, books `"openLibrary"`, TV shows `"tmdb"`, music `"musicBrainz"` |
| native_id | string | no | The provider's own id, when `external_id` can't reproduce it: books (`"OL8193465W"`, `"4050-86463"`) and MangaDex manga (its UUID), whose `external_id` is a hash. A light import needs it to refetch the item; files written before it exist leave those items unresolved |
| platform_id | number | no | IGDB platform ID (games) or AnimationSource (animation: 0=movie, 1=tvShow) |
| comment | string | no | Author's comment |
| user_rating | number | no | User rating (1.0–10.0, one decimal). Integers from v2 files load as doubles |
| _canvas | object | no | Per-item canvas data (full only) |
| tag_names | array | no | Names of all assigned tags in the item's display order — manual per-item order when set, global tag order otherwise (full only, resolved into the global tag set on import) |
| tag_name | string | no | First assigned tag name (full only). Legacy single-tag field kept for older app versions; readers prefer `tag_names` |
| _marks | array | no | Per-unit likes/notes. Present only when `user_data` is `true`; re-anchored to the new item id on import (see Item Marks) |
| _watched_episodes | array | no | Watched-episode marks of a TV/animation item (full + `user_data` only). Each entry: `{season, episode, watched_at}` with `watched_at` in Unix seconds or `null`. Re-scoped to the target collection on import; conflict-ignoring, so re-import merges. Absent in older files |
| _listened_tracks | array | no | Listened-track marks of a music item (full + `user_data` only). Each entry: `{disc, track, listened_at}` with `listened_at` in Unix seconds or `null`. Re-scoped to the target collection on import; conflict-ignoring, so re-import merges. Absent in older files |

**User data fields** (present only when top-level `user_data` is `true`):

| Field | Type | Description |
|-------|------|-------------|
| status | string | `"not_started"`, `"in_progress"`, `"completed"`, `"dropped"`, `"planned"`, or `"replaying"` |
| user_comment | string | User's personal notes |
| is_favorite | number | `1` if the user marked the item a favorite; absent or `0` otherwise |
| current_season | number | Current season (TV shows) |
| current_episode | number | Current episode (TV shows) |
| added_at | number | Unix timestamp (seconds) when item was added |
| sort_order | number | Manual sort position |
| started_at | number | Unix timestamp (seconds) when started |
| completed_at | number | Unix timestamp (seconds) when completed |
| last_activity_at | number | Unix timestamp (seconds) of last activity |
| rewatch_count | number | Rewatch counter (MAL/AniList semantics: `0` = completed once, `N` = repeats). Absent/`null` = not tracked; never overwrites a locally tracked value on re-import |

### Item Marks

Each element of an item's `_marks` array is one like and/or note on a single
unit of that title. Marks carry no item id — they are nested inside their item
and re-anchored to the freshly assigned `collection_item_id` on import. Empty
marks (no like and no note) are never exported. Timestamps are Unix seconds.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| unit_type | string | yes | `"episode"`, `"season"`, `"chapter"`, `"volume"`, `"page"`, `"part"`, or a custom string |
| parent_number | number | yes | Season / volume number, or `0` |
| unit_number | number | yes | Episode / chapter / page number, or `0` for a season/volume-level mark |
| is_favorite | number | yes | `1` if liked, else `0` |
| user_comment | string | no | Free-text note |
| liked_at | number | no | When the like was set |
| updated_at | number | yes | Last modification time |

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
- `tv_show_posters/tmdb_1399` — TV show poster, namespaced by provider (`tmdb_` / `tvmaze_`). Pre-0.40 files use a bare `tv_show_posters/1399`; they are restored under that key and the poster is re-downloaded on first display, because animation posters share this folder and keep the bare id
- `vn_covers/17` — visual novel cover for VNDB numeric ID 17
- `manga_covers/anilist_123` — manga cover, namespaced by provider (`anilist_` / `mangabaka_`). Pre-v44 files use a bare `manga_covers/123` and are remapped to `anilist_` on import
- `anime_covers/anilist_123` — anime cover, namespaced by provider (`anilist_` / `kitsu_`). Pre-v60 files use a bare `anime_covers/123` and are remapped to `anilist_` on import

**Canvas images** — `imageId` is FNV-1a 32-bit hash of the image URL:
- `canvas_images/a1b2c3d4` — image added to the canvas board

**Collection hero image** — at most one entry, `imageId` is the original file extension:
- `collection_hero/jpg` — hero banner for the collection (rich view cover)

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
| albums | array | Album objects from MusicBrainz (id, source, mbid, title, artists, primary_type, release_year, genres, rating, release_mbid, track_count, disc_count, cover_url, external_url, ...); `id` is fnv1a64 of the release-group MBID, so it is stable across devices |
| music_tracks | array | AlbumTrack objects of the picked release (source, album_id, disc_number, position, title, length_ms, artists); lets an offline import restore the track list without a MusicBrainz round-trip |

All arrays are optional — only non-empty categories are included.

### Tier Lists Object

Contains tier list data for the exported collection. Only present when the collection has associated tier lists.

| Field | Type | Description |
|-------|------|-------------|
| id | int | Tier list ID (not preserved on import — new ID assigned) |
| name | string | Tier list name |
| collection_id | int? | Source collection ID (null for global) |
| definitions | array | Tier definitions: `{ tier_key, label, color (0xAARRGGBB int), sort_order }` |
| entries | array | Items placed in tiers: `{ collection_item_id, tier_key, sort_order, external_id, media_type, platform_id?, source? }` |

Entries include `external_id`, `media_type`, and optional `platform_id` / `source` fields for cross-collection resolution on import. The import process builds an `itemIdMapping` (`"media_type:external_id[:platform_id][@source]" → newItemId`) and resolves entries via this map rather than raw collection_item_id values. For games, the key includes `platform_id` to distinguish the same game on different platforms; for multi-source media it includes `source`, without which two titles sharing a numeric id across providers (an AniList and a Kitsu anime) would collapse onto one item. Lookup falls back to the keys without platform and source for backward compatibility with older exports. Animation items are stored in `movies` (animated films) or `tv_shows` (animated series) based on their `AnimationSource`. Visual novel items are stored in `visual_novels` with VNDB string IDs (e.g. "v17"). Manga items are stored in `mangas` with AniList integer IDs. Seasons are preloaded when a TV show or animation series is added to a collection. Episodes are included from the local cache for each TV show in the collection.

### Tags Object

Contains the global tag definitions used by the exported collection's items. Only present in full exports when at least one item is tagged.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Tag name (unique app-wide, case-insensitive) |
| color | int? | Tag background color (0xAARRGGBB int), null for default |
| text_color | int? | Tag label text color (0xAARRGGBB int), null for default |
| sort_order | int | Display order |

Item-tag assignments are stored per-item via the `tag_names` array (see Item Object); the legacy single `tag_name` field is still written and accepted. On import, names are resolved case-insensitively into the global tag set (missing tags are created with the exported colors), then item links are written into the `item_tags` junction. The `tag_names` order carries the item's manual tag arrangement: when it differs from the global tag order, explicit per-item positions are written on import, otherwise the item keeps following the global sort.

### Tracker Data Object

Contains RetroAchievements (or other tracker) progress data for games in the collection. Only present in full exports when "Include user data" is enabled and games have tracker data.

| Field | Type | Description |
|-------|------|-------------|
| tracker_type | string | Tracker identifier: `"ra"`, `"steam"`, `"trakt"` |
| game_id | int | IGDB game ID (links to `games.id`) |
| tracker_game_id | string | Game ID in the tracker (RA GameID, Steam AppID) |
| tracker_game_title | string? | Game title in the tracker |
| achievements_earned | int? | Number of earned achievements |
| achievements_total | int? | Total achievements |
| achievements_earned_hardcore | int? | Hardcore achievements (RA) |
| award_kind | string? | Award type: `"mastered-hardcore"`, `"beaten-softcore"`, etc. |
| award_date | int? | Unix timestamp of award |
| last_played_at | int? | Unix timestamp of last activity |
| last_synced_at | int | Unix timestamp of last sync |

On import, tracker data is upserted into `tracker_game_data` via `TrackerDao.upsertGameDataBatch()`. This preserves the RA achievements section in game detail cards without requiring a re-import from RetroAchievements.

When `media` is present during import, data is restored directly from the file via `fromDb()` — no API calls to IGDB/TMDB/VNDB are needed. TV seasons and episodes are also restored if present.

When `media` is absent (light export or older full exports), the app refetches each item from the provider named by its `source`: TMDB or TVmaze for shows, AniList or Kitsu for anime, AniList / MangaBaka / MangaDex / Kitsu for manga, and the five book providers. A missing `source` falls back to the media type's default (`tmdb` for shows, `anilist` for manga and anime), which is what pre-0.40 files carry. Books and MangaDex manga also need `native_id`; without it the item is left unresolved rather than fetched from the wrong provider. One provider failing only drops its own items — the rest of the import continues.

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
   and watched-episode marks (embedded in `_watched_episodes`, when
   `user_data` is present)
6. Restores cover images and canvas images from base64 to local disk cache
7. Restores tier lists — creates tier list, saves definitions, resolves entries via `itemIdMapping` (`media_type:external_id` → new item ID)
8. Restores tracker data (RA progress) if present — upserts into `tracker_game_data`
9. Restores per-item marks (embedded in `_marks` field of each item, when `user_data` is present) — re-anchored to the new item ID; idempotent on re-import
