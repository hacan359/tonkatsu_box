# Kinorium import

Imports a [Kinorium](https://kinorium.com) list from its emailed CSV export.
First adapter built on the shared [import layer](../../README.md).

## Source format

The export is **UTF-16 LE (with BOM), tab-separated, every field double-quoted**
(`""` escapes a literal quote). Columns are addressed **by header name**, not
position, because the two export shapes order columns differently:

- watched list — starts with `My rating`, no `ListTitle`;
- "Буду смотреть" (watchlist) — starts with `ListTitle`.

Only a few columns are read: `Title`, `Original Title`, `Type`, `Year`,
`My rating`, `Date`, `Genres`, `Actors`, `Directors`, `Note`. `Type` is in
Russian (`Фильм` / `Сериал` / `Мультфильм` / `Мультсериал` / `Эпизод`).

## How it works

1. **Parse** the file into `KinoriumEntry` rows (`KinoriumCsvParser`).
2. **Match** every row against TMDB (`TmdbMatcher`): rows carry no TMDB id, so
   each title costs a search. The query prefers the original title and falls
   back to the localized one; the year filter is dropped on retry. Animated
   types map to the animation media type.
3. **Write** the whole scope at once (`ImportWriter`): upsert the matched
   movies/shows, resolve-or-create the collection, batch-insert items, then
   batch-write unmatched titles to the wishlist under one `Kinorium` tag.

Watched titles import as completed with their rating and watch date; the
"Watchlist" toggle imports everything as planned. Re-importing into an existing
collection refreshes only the rating and note when they changed.

## Files

| File | Purpose |
|---|---|
| `kinorium_entry.dart` | `KinoriumEntry` row + `KinoriumType` enum (source-private DTO). |
| `kinorium_csv_parser.dart` | `KinoriumCsvParser`: UTF-16 decode + by-name TSV parse. |
| `kinorium_import_service.dart` | `KinoriumImportService` (the adapter) + `KinoriumImportOptions`. |

UI lives separately in `lib/features/settings/` (`content/kinorium_import_content.dart`,
`screens/kinorium_import_screen.dart`).
