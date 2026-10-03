[← Back to README](../README.md)

# 📁 Custom Cards Import

Bring your own list into Tonkatsu Box from a JSON or CSV file. Each row becomes
a card. With the source lookup switch on, a row that matches exactly one record
in a catalog (TMDB, IGDB, Kitsu and others) becomes a real card instead of a
custom one.

Settings → Import → **Import custom cards**. Download a template there to start
from a file that already imports cleanly.

## File formats

| Format | Rules |
|--------|-------|
| **JSON** | A top-level array of objects. Keys starting with `_` are ignored, so you can keep notes next to the data. |
| **CSV** | UTF-8 (a BOM is fine), comma separated, RFC 4180 quoting: wrap a field in `"…"` when it holds a comma, a newline or a quote; write a quote inside as `""`. The first row is the header; columns are matched by name, order does not matter. Blank lines are skipped. |

The extension picks the parser. Without one, a file whose first character is
`[` is read as JSON, anything else as CSV.

A broken row never fails the whole file. Rows with a blocking error (no title,
no type, unknown type) are shown in the preview and skipped; a bad optional
field is dropped and the row still imports.

## Fields

Only `title` and `type` are required.

| Field | Value | Notes |
|-------|-------|-------|
| `title` | text | Required. |
| `type` | `game`, `movie`, `tv_show`, `animation`, `visual_novel`, `manga`, `anime`, `book`, `audio`, `custom` | Required, case-insensitive. Picks the card's look and which sources are asked. |
| `alt_title` | text | Original or alternative name. Also used when matching against sources. |
| `description` | text | Shown on a custom card. Ignored when the row resolves to a real card. |
| `year` | 1000–9999 | Release year. Narrows the source lookup. |
| `genres` | `Action, Drama` | Comma separated, stored as is. |
| `link` | URL | Opened from the card. |
| `cover` | `http(s)` URL | Downloaded after import. For a real card it is used only when the source has no cover. |
| `platform` | `SNES`, `PlayStation 2`, … | Abbreviation or full name from the platform catalog, case-insensitive. Unknown text stays as a label on a custom card. |
| `format` | anime: `TV`, `TV_SHORT`, `MOVIE`, `OVA`, `ONA`, `SPECIAL`, `MUSIC`; manga: `MANGA`, `MANHWA`, `MANHUA`, `NOVEL`, `LIGHT_NOVEL`, `ONE_SHOT` | Only for `anime` and `manga` rows. |
| `unit_total` | integer ≥ 1 | Episodes, chapters or pages in total. |
| `unit_group_total` | integer ≥ 1 | Seasons or volumes in total. |
| `status` | `not_started`, `in_progress`, `completed`, `dropped`, `planned`, `replaying`, `ignored` | Default `not_started`. A status other than `not_started` stamps start and finish dates with today unless the row gives them. |
| `rating` | 0–10, decimals allowed | `8,5` and `8.5` both work. |
| `comment` | text | Your note on the card. |
| `rewatch_count` | integer ≥ 0 | Replays, rewatches or rereads. |
| `started_at`, `completed_at` | `YYYY-MM-DD` | Explicit dates win over the ones the status implies. |
| `time_spent_minutes` | integer ≥ 0 | |
| `favorite` | `true` / `false`, `1` / `0`, `yes` / `no` | |
| `current_episode`, `current_season` | integer ≥ 0 | Progress against `unit_total` / `unit_group_total`. |
| `tags` | `jrpg, classics` | Comma separated. Missing tags are created. |

Rows are deduplicated by title, case-insensitively, against the target
collection and against earlier rows of the same file. Duplicates start
unchecked in the preview; you can tick them back.

## Source lookup

Off by default. Turn on **Look up cards in sources** on the import screen and
every row except `custom` and `audio` is searched by its `title` in the
sources of its type, in this order:

| Type | Sources |
|------|---------|
| `movie` | TMDB → TheTVDB |
| `tv_show` | TMDB → TVmaze → TheTVDB |
| `animation` | TMDB (movies and series in one list, animated titles only) |
| `game` | IGDB |
| `anime` | Kitsu → AniList |
| `manga` | AniList → MangaDex → MangaBaka → Kitsu |
| `visual_novel` | VNDB |
| `book` | OpenLibrary → Google Books → Hardcover; Fantlab first when the title has Cyrillic letters |
| `audio`, `custom` | never looked up |

A source without its key (TMDB, TheTVDB, IGDB, Hardcover) is skipped. A source
that fails is skipped too; the row moves on to the next one.

### What counts as a match

Each source returns a page of results. A result counts only when:

1. one of its titles (main, original, English or native) equals the row's
   `title` or `alt_title` after normalisation: case, punctuation and spacing
   are ignored, `&` reads as `and`, `ё` as `е`, any alphabet is kept;
2. its year equals the row's `year`, when the row has one;
3. for a game, the platform rule below holds.

A prefix is never a match: `Dune` does not match `Dune: Part Two`.

| Results after the filter | Outcome |
|--------------------------|---------|
| exactly one | real card from that source; the walk stops |
| none | the next source is asked; after the last one, a custom card |
| several | a custom card; later sources are not asked, they would only add candidates |

`Dune` with `year: 2021` resolves to one film. `Dune` without a year matches
1984 and 2021 and stays a custom card. The result screen lists every title that
matched several records.

### Games and platforms

A game in a collection always sits on a platform, so a match needs one the
import can prove:

| `platform` in the file | Game found | Outcome |
|------------------------|------------|---------|
| known to the catalog | has that platform | real card on it |
| known to the catalog | lacks that platform | custom card |
| unknown to the catalog | any | custom card, IGDB is not asked |
| none | one platform | real card on it |
| none | several platforms | custom card |
| none | no platforms | real card without a platform |

The platform from the file is also sent to IGDB as a filter, so ports on other
platforms do not join the candidates.

### Which data comes from where

For a real card the source owns the metadata: title, description, cover,
genres, year, episode and volume counts, format and link from the file are
dropped. The file's `cover` is kept as the card's cover only when the source
has none.

Your own fields always come from the file: `status`, `rating`, `comment`,
`rewatch_count`, `started_at`, `completed_at`, `time_spent_minutes`,
`favorite`, `current_episode`, `current_season`, `tags`.

A real card that is already in the collection (same source, id and platform)
is skipped and counted under "skipped": its own fields stay as they are, and
the row's `tags` are added next to the tags it already has. Two rows resolving
to the same record give one card.

### Progress and result

The import cannot be cancelled. The dialog shows the stage, the row and the
source being asked (`Dune → TMDB`), the running counts of found, custom and
ambiguous rows, and stays open until the import ends. The result screen shows
imported cards by type, skipped rows, cover download errors and the titles
that matched several records.

### Rate limits

Requests run one row at a time. IGDB and AniList are paced to their published
limits; a `429` from any source is retried with backoff before the source is
given up. A thousand movies take a few minutes.

## Example

```json
[
  {
    "title": "Dune",
    "type": "movie",
    "year": 2021,
    "status": "completed",
    "rating": 9,
    "completed_at": "2024-03-01",
    "tags": "sci-fi"
  },
  {
    "title": "Chrono Trigger",
    "type": "game",
    "platform": "SNES",
    "status": "completed",
    "time_spent_minutes": 1800
  },
  {
    "title": "My summer backlog",
    "type": "custom",
    "description": "Things to get to in July."
  }
]
```

The same rows as CSV:

```csv
title,type,year,platform,status,rating,completed_at,time_spent_minutes,tags,description
Dune,movie,2021,,completed,9,2024-03-01,,sci-fi,
Chrono Trigger,game,,SNES,completed,,,1800,,
My summer backlog,custom,,,,,,,,Things to get to in July.
```
