# TheTVDB API

REST client for TheTVDB v4. Movies and TV series, with TheTVDB's own season and
episode data.

- Docs: https://thetvdb.github.io/v4-api/
- Repo (swagger source): https://github.com/thetvdb/v4-api
- Endpoint: `https://api4.thetvdb.com/v4`
- Licence / attribution: https://thetvdb.com/api-information

## Layers

| File | Purpose |
|---|---|
| `../tvdb_api.dart` | Facade. Entry point for the rest of the code (`tvdbApiProvider`). Owns the request locale and delegates to the sub-clients. |
| `tvdb_types.dart` | `TvdbApiException`. |
| `tvdb_http_client.dart` | Dio transport. Exchanges the API key for a bearer token, re-logs in once on 401, unwraps the `{status, data}` envelope, maps Dio → `TvdbApiException`. |
| `tvdb_search_api.dart` | `/search` for both record kinds (`searchMovies`, `searchSeries`). |
| `tvdb_movies_api.dart` | Movie detail (`/movies/{id}/extended`) and browse (`/movies/filter`). |
| `tvdb_series_api.dart` | Series detail, seasons, episodes, browse, and the shared `/genres` catalog. |

## Key points

- **Auth is a login, not a key header.** `POST /login` with `{"apikey": …}`
  returns a JWT valid for a month. The token is cached in memory only — it is
  one request to mint again, and it must be dropped when the key changes.
  A 401 means the token expired: re-login once and retry, a second 401 is real.
- **Two error shapes.** Success is `{"status":"success","data":…}`, a 404 is
  `{"status":"failure","message":…}`, but a **401 is `{"message":…}` with no
  `status` field**. A parser that keys off `status` breaks exactly on an expired
  token.
- **Nothing is localized server-side.** `language=rus` on `/search` does not
  translate anything. Every record carries its translations inline and the
  mappers pick the app locale out of them (`tvdb_json.dart`). Note TheTVDB uses
  **both** `por` and `pt` for Portuguese.
- **`short=true` is not optional in practice.** It nulls `artworks` and
  `characters`, taking `/series/{id}/extended` from 157 KB to 26 KB while
  keeping the poster in `image`. `meta=translations` is the only way to get a
  movie overview at all — the movie record has no `overview` field.
- **No user rating.** `score` is a popularity number in the millions, not a
  0–10 rating, so `Movie.rating` / `TvShow.rating` stay null for this provider.
- **Search cannot filter by genre.** `/search` accepts `year`, `country`,
  `language`, `network`, `company`, `director`, `primaryType` and `remote_id` —
  but no genre in any spelling (`genre=` returns zero rows, `genres=` is
  silently ignored). Genre narrowing exists only on `/…/filter`, by numeric id.
  Movie search hits do carry genre names, so `TvdbMoviesSource` narrows them
  client-side; series hits carry none.
- **Episodes paginate at 500.** `/series/{id}/episodes/default` needs several
  pages for long-running shows; follow `links.next`.
- **The swagger is not authoritative for vocabularies.** It declares
  `status` as `[1,2,3]` for movies, while `/movies/statuses` returns five
  (1 Announced, 2 Pre-Production, 3 Filming / Post-Production, 4 Completed,
  5 Released). Series really are three (`/series/statuses`: 1 Continuing,
  2 Ended, 3 Upcoming). Prefer the vocabulary endpoints: `/genres`,
  `/movies/statuses`, `/series/statuses`, `/seasons/types`, `/countries`,
  `/languages`, `/content/ratings`, `/artwork/types`.
- **`country` and `lang` are marked required on `/…/filter`** in the swagger but
  the endpoint answers without them; only `lang` is sent, so browse is not
  pinned to one country.
- **Image URLs differ per endpoint.** `/search` and `/…/extended` return
  absolute `artworks.thetvdb.com` URLs, `/…/filter` returns a bare path.
  `tvdbImageUrl` normalizes both; a real thumbnail is the `_t` suffix.
