# Trakt import

Imports a [Trakt.tv](https://trakt.tv) profile from its account data export
(the ZIP you request under Settings → Data export on Trakt).

## Source format

A ZIP of JSON files. Two layouts are supported and auto-detected:

- **new** — JSON at the archive root (depth 1); the username comes from
  `user-profile.json`;
- **old** — files nested under `username/` (depth ≥ 2); the username is the
  top folder.

Files read (old path / new path): `watched/watched-movies.json` /
`watched-movies.json`, `watched/watched-shows.json`, `ratings/ratings-movies.json`,
`ratings/ratings-shows.json`, `lists/watchlist.json` / `lists-watchlist.json`.
Every entry carries the title's ids, including the **TMDB id** — so unlike
Kinorium, rows need no name search; they resolve straight to TMDB by id.

## How it works

1. **Validate** (`validateZip`) returns a [TraktZipInfo] preview (per-section
   counts + username) for the import screen, before any writes.
2. **Parse** the selected sections into private DTOs.
3. **Fetch** each unique TMDB id once (`getMovie` / `getTvShow`), upsert the
   media into the cache, and record whether it's animation (by genre).
4. **Write** through [ImportWriter] in three `writeItems` passes over the same
   collection:
   - *watched* → completed (movies) or completed/in-progress (shows, from the
     season data), stamping the watch date;
   - *ratings* → the user rating, only set when the local item has none;
   - *watchlist* → planned items, leaving anything already present untouched.
   The re-sync merge never downgrades a local status or overwrites a local
   rating/date. Watched **episodes** are marked directly (no collection-item
   analogue). Titles with no TMDB id or whose TMDB fetch failed fall back to
   the text wishlist.

The three passes run sequentially so each sees the previous pass's inserts (a
rated, watched title is imported once, then its rating is merged in).

## Files

| File | Purpose |
|---|---|
| `trakt_import_service.dart` | `TraktImportService` (the adapter) + `TraktImportOptions` + `TraktZipInfo`. |

UI lives separately in `lib/features/settings/`
(`content/trakt_import_content.dart`, `screens/trakt_import_screen.dart`).
