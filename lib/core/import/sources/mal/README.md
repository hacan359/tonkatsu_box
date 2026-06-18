# MyAnimeList import

Imports anime and manga from a MyAnimeList XML export. Built on the shared
[import layer](../../README.md).

- **Input:** anime and/or manga XML files + an overwrite-existing toggle
  (`MalImportService.import`).
- **Source:** MAL XML export. Rows carry MAL ids, resolved to AniList media via
  a tolerant batch lookup over the AniList GraphQL API (it owns the rate-limit
  retry; the adapter just relays its progress). Failed lookups are skipped so a
  later re-import can retry them.
- **Media:** `anime` / `manga`.
- **Write:** through `ImportWriter`. New items are batch-inserted; on overwrite,
  existing items merge status / progress / dates / rating. Titles AniList can't
  resolve batch into the wishlist under one `MyAnimeList` tag.
