# Tonkatsu Box — selfhost server

Pure-Dart server for the selfhost web build. It is **not** part of the Flutter
build graph: the app never imports it, and it never imports the app. Both sides
share `packages/core` — models, DAOs and the one migration chain.

Status: phase 3 skeleton — boots, owns the database, serves the web client.
`/rpc` (DAO dispatch) is the next slice; its wire contract is already specified
in [`PROTOCOL.md`](PROTOCOL.md).

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

`GET /health` → `{"status":"ok","schemaVersion":N,"protocolVersion":1}`.

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
