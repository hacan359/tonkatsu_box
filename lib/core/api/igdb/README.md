# IGDB API

REST client for IGDB v4, authenticated via Twitch OAuth (Client Credentials grant).

- Docs: https://api-docs.igdb.com/
- Twitch OAuth: `https://id.twitch.tv/oauth2/token`
- IGDB endpoint: `https://api.igdb.com/v4`

## Layers

| File | Purpose |
|---|---|
| `../igdb_api.dart` | Facade. Entry point for the rest of the code (`igdbApiProvider`). |
| `igdb_types.dart` | `TwitchAuthResult`, `IgdbApiException`, `IgdbTokenRefreshedCallback`. |
| `igdb_http_client.dart` | Dio + Twitch OAuth (`getAccessToken`, `validateCredentials`), credential state, auto-refresh on 401, Dio → `IgdbApiException` mapping. |
| `igdb_platforms_api.dart` | `fetchPlatforms` (paginated), `fetchPlatformsByIds`. |
| `igdb_games_api.dart` | `searchGames`, `multiSearchGamesByName`, `lookupSteamGames`, `getGameById/ById/Ids`, `getTopGamesByPlatform`, `browseGames`. |
| `igdb_genres_api.dart` | `fetchGenres` for the lookup-table seed. |

## Key points

- **OAuth.** Credentials live in `IgdbHttpClient`. On 401 a single `_tryRefreshToken` attempt fires (`client_credentials` grant), guarded by `_isRefreshing` so parallel 401s don't storm the token endpoint. The fresh token is surfaced via `onTokenRefreshed` so the caller can persist it to `SharedPreferences`.
- **Multiquery cap.** IGDB caps `/multiquery` at 10 sub-queries per request — `IgdbGamesApi.maxMultiQueryBatch = 10`. The caller is responsible for batching.
- **Per-request cap.** IGDB caps normal endpoints at 500 records per request; `fetchPlatforms` and `getGamesByIds` batch internally.
- **Query DSL.** IGDB is not GraphQL: requests are strings like `fields …; where …; search "…"; limit N; offset M;`. Section order matters — `search` comes last.
- **NULL in unique indexes.** Not directly an IGDB concern, but the related migration v37 uses `COALESCE(platform_id, -1)` so two NULLs don't count as distinct — see `migration_v37.dart`.
- **Steam lookup.** Two-step: `external_games` (`external_game_source = 1`) maps Steam appId → IGDB game id, then `getGamesByIds` pulls the full payload (deduped).
