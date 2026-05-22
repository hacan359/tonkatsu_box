# AniList API

GraphQL client for AniList. Public endpoint, no auth, rate-limited at ~90 req/min.

- Docs: https://anilist.gitbook.io/anilist-apiv2-docs
- Endpoint: `https://graphql.anilist.co`

## Layers

| File | Purpose |
|---|---|
| `../anilist_api.dart` | Facade. Entry point for the rest of the code (`aniListApiProvider`). |
| `anilist_types.dart` | Exceptions and data classes (`AniListListEntry`, `AniListMalLookupResult`). |
| `anilist_queries.dart` | GraphQL queries as `static const`. Fields are pinned to actual usage. |
| `anilist_graphql_client.dart` | Dio + Dio → `AniListApiException` / `AniListRateLimitException` mapping. |
| `anilist_media_parser.dart` | Pure parsers for `Page { media }` and fuzzy dates. |
| `anilist_media_api.dart` | Search, browse and get-by-id for anime and manga. |
| `anilist_mal_lookup_api.dart` | MAL id → AniList media. `*Tolerant` variants survive rate-limits and report the unresolved ids. |
| `anilist_user_list_api.dart` | `MediaListCollection` — public user lists (anime/manga). |

## Key points

- **Batching.** AniList caps `perPage` at 50 — see `aniListMaxPerPage` in `anilist_queries.dart`. Id-list queries are batched automatically.
- **Rate limit.** HTTP 429 becomes `AniListRateLimitException` with a parsed `retryAfter` (`Retry-After` → `X-RateLimit-Reset` → 60s default). The `*Tolerant` methods in MAL lookup wait and retry the batch up to `maxRateLimitRetries` times; the rest propagate the exception upward.
- **GraphQL errors come back with HTTP 200.** They're unwrapped by the caller via `unwrapData` / `logErrors`. User-list lookups also classify `"not found"` / `"private"` messages into typed exceptions.
- **User lists.** Custom lists are skipped (they duplicate entries from the canonical lists). `isAdult: true` entries are filtered out.
- **Query fields.** Queries only request fields the UI / models actually read. Legacy DB columns (`mean_score`, `popularity`, `season`, `season_year`, `country_of_origin`, `next_airing_at`) are kept for compatibility with old rows but are no longer fetched from the API.
