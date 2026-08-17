# Tonkatsu Box — selfhost server

Pure-Dart server for the selfhost web build. It is **not** part of the Flutter
build graph: the app never imports it, and it never imports the app. Both sides
share `packages/core` — models, DAOs and the one migration chain.

Status: boots, owns the database, serves the web client, dispatches all 23 DAOs
over `/rpc` and proxies the external APIs. Wire contract:
[`PROTOCOL.md`](PROTOCOL.md).

## Run

```bash
dart pub get --directory server
dart run server/bin/server.dart --data-dir ./data --web-root ./build/web
```

| Option | Env | Default |
|--------|-----|---------|
| `--address` | `TONKATSU_ADDRESS` | `0.0.0.0` |
| `--port` | `TONKATSU_PORT` | `8080` |
| `--data-dir` | `TONKATSU_DATA_DIR` | `data` |
| `--web-root` | `TONKATSU_WEB_ROOT` | `web` |

Command line wins over the environment. A missing or unbuilt `--web-root` is not
fatal — the server then answers `/health` only.

## Docker

```bash
cp .env.example .env   # optional — edit the data folder, port, PUID/PGID
docker compose up --build
```

Everything the server stores lives in **one host folder** — the database, the
covers cache, migration snapshots and `keys.json`. It defaults to `./data` next
to `docker-compose.yml` and is set with `TONKATSU_DATA_PATH` in `.env`. Backing
up the app is copying that folder while the container is stopped; restoring is
copying it back.

The entrypoint chowns the folder to `PUID`/`PGID` (default 1000:1000) and drops
root before starting the server, so the files are editable by the host user.

Docker Desktop on Windows: a folder on a Windows drive works on current
versions (virtiofs file sharing — WAL and integrity verified), just slower
than a WSL-native path like `/home/<user>/tonkatsu-data`. Either way, never
open the live database in another tool — locking across the Windows boundary
is not to be trusted.

`GET /health` → `{"status":"ok","schemaVersion":N,"protocolVersion":1}`.

`POST /rpc` → `{protocol, dao, method, args}`; answers `{ok:true, result}` or
`{ok:false, error:{kind, message}}`. A DAO-level failure still answers 200 —
only a malformed request is a 4xx.

## API proxy

`ANY /proxy/<slug>/<path>` forwards to the upstream that `slug` names in
`packages/core/lib/api/proxy_targets.dart`. Anything not in that table is a 404
before a byte leaves the machine — it is an allowlist, not an open relay. Every
call goes out with a real `User-Agent` (browsers strip theirs, and AniList
answers 403 without one) and with the server's credentials attached; an
`Authorization` header from the caller is dropped rather than forwarded.

`GET /proxy/keys` answers the configured credentials — values included, so the
settings screen in the browser shows and edits them exactly as on desktop.
`POST /proxy/keys` stores changes into `<data-dir>/keys.json`; an empty value
clears a key.

Credentials come from `<data-dir>/keys.json`, overridden by
`TONKATSU_KEY_<NAME>` in the environment:

```json
{ "tmdb": "…", "igdb_client_id": "…", "igdb_client_secret": "…" }
```

Names: `tmdb`, `tvdb`, `steamgriddb`, `igdb_client_id`, `igdb_client_secret`,
`ra_username`, `ra`, `comicvine`, `googlebooks`, `hardcover`,
`simkl_client_id`, `ss_dev_id`, `ss_dev_password`, `ss_ssid`,
`ss_sspassword`. A request needing one that is missing answers **503** — a
configuration problem, not a client one. IGDB's Twitch token is exchanged and
cached here, so the client secret never reaches a browser.

ScreenScraper needs its dev pair (`ss_dev_id`/`ss_dev_password`): it is never
baked into the image, so either the operator sets it here or the web settings
screen does, which shows those two fields on web only. Both pairs then live
on the server like every other key.

Not wired: Kodi (a host on the user's own LAN, which an allowlist cannot
cover).

## Database

`<data-dir>/tonkatsu_box.db`, the same file name and the same chain
(`MigrationRegistry.all`) the desktop app uses. On boot:

1. an existing file is probed — `quick_check` and its schema version;
2. a schema **newer** than the build aborts the boot instead of being
   downgraded, and a failed integrity check aborts it too;
3. pending migrations are preceded by a snapshot copy in
   `<data-dir>/snapshots/` (the WAL is checkpointed first, so the copy is a
   single self-contained file);
4. a fresh directory gets a database built by replaying the chain from zero.

## Tests

```bash
dart pub get --directory server
dart test --directory server
```
