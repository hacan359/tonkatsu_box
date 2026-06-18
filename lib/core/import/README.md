# Import layer

Shared infrastructure for importing a user's library from third-party services
(Steam, Trakt, Kinorium, RetroAchievements, MyAnimeList, AniList, …).

The layer follows **ports & adapters**: one port (`ImportSource`) with many
adapters (one per source, under `sources/`). The reusable domain pieces —
collection writing, TMDB matching, rate-limit retry — live at the root and are
**injected** into adapters, not inherited.

> Status: **Kinorium, Steam, RetroAchievements, MyAnimeList and AniList** are all
> adapters on this layer. `trakt_zip_import_service.dart` in `core/services` is
> the last importer still carrying its own copy of this logic.

## Layers

| File | Purpose |
|---|---|
| `import_source.dart` | The port: `ImportSource` + `ImportOptions`. Each adapter implements `import(options) → UniversalImportResult` with progress callbacks. |
| `import_writer.dart` | Shared write-side: resolve-or-create the collection, batch-insert new items, selectively update existing ones (per-source merge policy via a closure), batch-write wishlist fallbacks. Goes through the **repositories**, never the DAOs. |
| `tmdb_matcher.dart` | Matches a title against TMDB by name (original + localized query, year then no-year, pick-best, animation-by-genre). For sources whose rows carry no TMDB id. |
| `rate_limited_retry.dart` | Source-agnostic exponential backoff; the caller decides what counts as a rate limit. |
| `sources/<name>/` | One adapter per source, each with its own `README.md`. |

## What is shared vs per-source

**Shared (here):** collection resolve/create, batch item write with re-sync
change detection, wishlist fallback (import tag + text dedup), per-type tallies,
rate-limit retry, TMDB-by-name matching.

**Per-source (in the adapter):** input parsing/fetching (file vs username vs
token), the matching strategy (TMDB vs IGDB vs AniList — rows may already carry
ids), the re-sync merge policy, and media-cache upsert (type-specific DAOs).

## Adding a new source

1. Create `sources/<name>/` with a `README.md`.
2. Define `<Name>ImportOptions extends ImportOptions`.
3. Implement `<Name>ImportService implements ImportSource`:
   - parse/fetch raw entries;
   - resolve them (a matcher such as `TmdbMatcher`, or ids already on the rows);
   - upsert the fetched media into the cache via the relevant DAOs;
   - build `ImportCandidate`s and call `ImportWriter.writeItems`;
   - send unmatched titles to `ImportWriter.writeWishlist` with
     `buildImportTag(displayName)`;
   - return a `UniversalImportResult`.
4. Add a Riverpod provider wiring the repositories, the API client, and the
   shared helpers.

See `docs/ARCHITECTURE.md` → "Import layer" for the high-level picture.
