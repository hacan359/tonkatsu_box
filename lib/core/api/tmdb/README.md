# TMDB API

REST client for The Movie Database (TMDB) v3, authenticated via an API key
passed as the `api_key` query parameter on every request.

- Docs: https://developer.themoviedb.org/reference
- Endpoint: `https://api.themoviedb.org/3`

## Layers

| File | Purpose |
|---|---|
| `../tmdb_api.dart` | Facade. Entry point for the rest of the code (`tmdbApiProvider`). Delegates to the sub-clients and coordinates genre-cache invalidation. |
| `tmdb_types.dart` | `TmdbApiException`, `TmdbPagedResult`, `TmdbFindResult`, `TmdbGenre`, `TmdbMediaType`, `MultiSearchResult`. |
| `tmdb_http_client.dart` | Dio transport. Owns the API key + request language, injects both into `get`, plus `validateApiKey`, `extractResults`, Dio → `TmdbApiException` mapping. |
| `tmdb_genres_api.dart` | Genre catalogs (`/genre/{movie,tv}/list`) + the per-language cache (`ensureMovieGenreMap` / `ensureTvGenreMap`) and `resolveGenreIds`. |
| `tmdb_movies_api.dart` | Movie search / detail / lists / discover. |
| `tmdb_tv_api.dart` | TV search / detail / seasons / episodes / lists / discover. |
| `tmdb_reviews_api.dart` | `getMovieReviews`, `getTvReviews` (pinned to en-US). |
| `tmdb_find_api.dart` | Cross-type lookups: `findByImdbId` / `findByTvdbId` and `multiSearch`. |

## Key points

- **Auth.** The API key lives in `TmdbHttpClient` and is injected as `api_key`
  on every request; `ensureApiKey` throws `TmdbApiException('API key not set')`
  before any call when it is missing.
- **Language.** Stored on the client and injected as `language` (default
  `ru-RU`). Reviews override it to `en-US` via the `language` arg on `get`.
- **Genre cache.** TMDB list endpoints return only `genre_ids`, while detail
  endpoints return full `genres` objects. `TmdbGenresApi` caches the
  id→name maps per type and `resolveGenreIds` rewrites list items into the
  detail shape so `Model.fromJson` sees one format. The maps are
  language-dependent, so the facade calls `clearCache` on `setLanguage`
  (when the language actually changes) and on `clearApiKey`. Movies and TV
  have **separate** catalogs — `multiSearch` resolves each subset on its own.
- **404 handling.** `getMovie` / `getTvShow` and `_findByExternalId` treat 404
  as "not found" (`null` / empty `TmdbFindResult`) rather than an error.
- **Find sources.** `/find/{id}` matches Kodi items scraped with IMDB
  (`imdb_id`) or TVDB (`tvdb_id`) IDs; only `movie_results` / `tv_results` are
  consumed.
- **Multi-search.** `/search/multi` returns mixed media; `person` and any
  other unsupported `media_type` are dropped.
