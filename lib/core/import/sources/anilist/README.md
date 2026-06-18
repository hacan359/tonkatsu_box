# AniList import

Imports anime and manga lists from a public AniList account. Built on the shared
[import layer](../../README.md).

- **Input:** AniList username + import mode (new-only / overwrite) + anime/manga
  toggles (`AniListImportService.import`).
- **Source:** public user lists via the AniList GraphQL API. Rows already carry
  AniList ids, so there is no title search.
- **Media:** `anime` / `manga`.
- **Write:** through `ImportWriter`. New items are batch-inserted; in overwrite
  mode existing items merge status (via `mergeExternalStatus`), max progress,
  date range and rating. No wishlist fallback (every row carries an id).

Unknown user, private profile and API errors are thrown so the settings screen
can localize them; only a successful run returns a `UniversalImportResult`.
