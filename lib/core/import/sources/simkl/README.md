# Simkl import

Imports the whole Simkl account — movies, shows and anime arrive in one
`GET /sync/all-items` call (`extended=full`, `episode_watched_at=yes`,
`memos=yes`). Spec with the verified API behavior:
`dev/backlog/release_41/tz-simkl.md`.

## Auth

PIN flow (`SimklApi.requestPin` / `pollPin`) — the user enters a 5-char code
at simkl.com/pin, no redirect URI and no client secret in the build. The
token effectively lives until revoked; persisting it is the user's opt-in
choice on the import screen (`SettingsKeys.simklAccessToken`). The client id
comes baked into official builds via `--dart-define SIMKL_CLIENT_ID`
(`ApiDefaults.simklClientId`) and is never surfaced in the UI. Builds without
it (F-Droid, self-built) show a key field right on the import screen instead
(the Steam pattern: "remember" checkbox on by default,
`SettingsKeys.simklClientId`).

## Resolution paths

| Section | Path |
|---|---|
| movies / shows | `ids.tmdb` → `TmdbApi.getMovie/getTvShow`, animation split by genres (the Trakt path) |
| anime | `ids.kitsu` batched via `filter[id]`; fallback `/mappings` by MAL, then AniDB → `DataSource.kitsu` item |

Anime deliberately lands as Kitsu (not TMDB): the id chain avoids title
matching entirely, and Kitsu is the one anime source whose episode tracker
supports per-episode marks (`CollectionItem.usesEpisodeTracker`).

Anything unresolved — no id, failed fetch, stale mapping — goes to the text
wishlist under `buildImportTag('Simkl')`. Nothing is dropped silently.

## Statuses

`watching→inProgress`, `plantowatch→planned`, `completed→completed`,
`dropped→dropped`, `hold→planned` + the `on-hold` global tag (our
`ItemStatus` has no "on hold"; the tag keeps held entries distinguishable
from ordinary plans).

## Episode marks

Written after `writeItems` via `markEpisodesWatchedAt` (one batched
transaction per title) with the Simkl `watched_at` per episode, not the import
date. The pass reports progress under `ImportStage.restoringMedia` — expanding
completed titles costs a metadata request each.

- Shows: Simkl season/episode numbers match TMDB numbering — written as is
  under `DataSource.tmdb`.
- Anime: Simkl always sends a single season with absolute episode numbers
  (Bleach: 1..366). Our synthesized Kitsu seasons keep the same absolute
  numbers inside, so the absolute number is the join key: the full Kitsu
  episode list gives "absolute number → synthesized season", the Simkl season
  number is ignored. Verified live on Bleach (16 synthesized seasons).
- Completed titles arrive from Simkl with NO `seasons` block at all (verified
  live: completing Bleach dropped it). They are expanded into marks for every
  episode from the source metadata (TMDB seasons / Kitsu list, specials
  excluded), dated by the entry's `last_watched_at`. Existing marks keep
  their own dates — inserts use `ConflictAlgorithm.ignore`.

The note (`user_comment`) starts with a `[Simkl](simkl.com/...)` markdown
link built from `ids.simkl` + `ids.slug`, followed by the user's memo.

## UI

`lib/features/settings/screens/simkl_import_screen.dart` +
`content/simkl_import_content.dart`: PIN block with polling, account name
from `/users/settings` (guards against a wrong browser session), the
remember-token checkbox, import mode, target collection, inline progress,
shared `ImportResultScreen`.
